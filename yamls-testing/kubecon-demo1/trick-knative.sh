#! /bin/bash

set -xe
set -o pipefail

WAIT_TIME="${2:-5m}"

echo "> create the app"
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: goapp
  namespace: default
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/class: kpa.autoscaling.knative.dev
        autoscaling.knative.dev/metric: concurrency
        autoscaling.knative.dev/target: "6"
        autoscaling.knative.dev/targetUtilizationPercentage: "70"
    spec:
      containerConcurrency: 0
      containers:
      - image: docker.io/taragu/autoscale
        env:
          - name: TARGET
            value: "Go Sample v1"
EOF

        # autoscaling.knative.dev/target: "200"
        # autoscaling.knative.dev/targetUtilizationPercentage: "80"
        # autoscaling.knative.dev/targetBurstCapacity: "7"
        # autoscaling.knative.dev/PanicThresholdPercentageAnnotationKey: "100"

if ! [ -z $1 ] && [ $1 == "launch" ]; then
    sleep 15
fi

# may need to be updated depending on how many loadBalancers are configured
export INGRESSIP=$(kubectl get svc istio-ingressgateway -n istio-system -ocustom-columns=D:.status.loadBalancer.ingress[0].ip --no-headers)
echo ">INGRESS: " $INGRESSIP

export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.url --no-headers | cut -d'/' -f3)
echo ">APP: " $APP


echo "> Wait for it to be ready"
while ! curl -sf -H "Host: $APP" "http://$INGRESSIP" 1>/dev/null ; do
    sleep 1 ;
done

echo "> hit the autoscaler with burst of requests"
for i in `seq 2000`; do
    curl -sf -H "Host: $APP" "http://$INGRESSIP?sleep=10s"&
done

echo "> launch async requests"
for i in $(seq 50); do
    # sleep 1
    curl -sf -H "Host: $APP" "http://$INGRESSIP?sleep=$WAIT_TIME&check=$i"&
done



