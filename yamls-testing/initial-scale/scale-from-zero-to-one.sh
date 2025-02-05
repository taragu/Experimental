#! /bin/bash

set -xe
set -o pipefail

export INGRESSIP=$(kubectl get svc istio-ingressgateway -n istio-system -ocustom-columns=D:.status.loadBalancer.ingress[0].ip --no-headers)
echo ">INGRESS: " $INGRESSIP

export APP=$(kubectl get ksvc/echo -ocustom-columns=D:.status.url --no-headers | cut -d'/' -f3)
echo ">APP: " $APP

curl -sf -H "Host: $APP" "http://$INGRESSIP?sleep=30s"&




