#!/bin/bash

set -e
kubectl delete ksvc/bugsvc > /dev/null 2>&1 || true
kubectl delete ksvc/bugsvc2 > /dev/null 2>&1 || true

# 58860 20-01-12 00:03:32 00 0 0 812.7 UTC(NIST) *
now=$(curl -s http://time.nist.gov:13)
hour=${now:15:2}
[[ ${hour:0:1} == "0" ]] && hour=${hour:1}
min=${now:18:2}
[[ ${min:0:1} == "0" ]] && min=${min:1}
(( min = min + 2 ))
if (( min > 59 )) ; then
  (( min = min - 60 ))
  (( hour++ ))
fi
export CRASH=$(printf "%02d:%02d" $hour $min)

echo "Time now: ${now:15:5}
echo "Will die: ${CRASH}

kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: bugsvc
spec:
  template:
    spec:
      containers:
      - image: duglin/echo
        env:
          - name: CRASH
            value: ${CRASH}
EOF
sleep 30
URL=$(kubectl get ksvc/bugsvc -o custom-columns=URL:.status.url --no-headers)

echo "Send curl just to make sure it works"
curl $URL

echo "Wait for it to scale to zero"
while kubectl get pods | grep bugsvc ; do
  sleep 10
done

echo "Sleep for 2 minutes just to make sure we're past the crash time"
sleep 120

echo "Create bugsvc2 so it fails immediately"
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: bugsvc2
spec:
  template:
    spec:
      containers:
      - image: duglin/echo
        env:
          - name: CRASH
            value: "true"
EOF
echo "Now curl bugsvc again to force it to scale up to 1"
curl $URL &

echo "Pods should be failing, but bugsvc2 will eventually vanish"
kubectl get pods -w
