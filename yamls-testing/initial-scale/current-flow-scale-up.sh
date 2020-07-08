#! /bin/bash

set -xe
set -o pipefail

export INGRESSIP=$(kubectl get svc istio-ingressgateway -n istio-system -ocustom-columns=D:.status.loadBalancer.ingress[0].ip --no-headers)
echo ">INGRESS: " $INGRESSIP

export APP=$(kubectl get ksvc/echo-current -ocustom-columns=D:.status.url --no-headers | cut -d'/' -f3)
echo ">APP: " $APP

echo "> hit the autoscaler with burst of requests"
for i in `seq 60000000`; do
    curl -H "Host: $APP" "http://$INGRESSIP?sleep=1s"&
done





