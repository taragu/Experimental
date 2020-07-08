set -x
./kn service delete echo
./kn service create echo --image duglin/echo
sleep 5
curl -H "Host: echo.default.example.com" http://169.46.6.83
sleep 5
./kn service delete echo
./kn service create echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=1
sleep 2
curl -H "Host: echo.default.example.com" http://169.46.6.83
sleep 5
./kn service delete echo
./kn service create echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=10
sleep 2
curl -H "Host: echo.default.example.com" http://169.46.6.83

