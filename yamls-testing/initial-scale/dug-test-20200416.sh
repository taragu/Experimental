set -x
./kn service delete echo
echo -n "This should not scale at all - press enter" ; read a
./kn service create echo --image duglin/echo
echo -n "Curl it - should scale to 1 - press enter" ; read a
curl -H "Host: echo.default.example.com" http://169.46.6.83
echo -n "ready for next test - press enter" ; read a
./kn service delete echo
echo -n "should scale to 1 - press enter" ; read a
./kn service create echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=1
echo -n "ready for next test - press enter" ; read a
./kn service delete echo
echo -n "Should scale to 10 immediately - press enter" ; read a
./kn service create echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=10
echo -n "ready for next test - press enter" ; read a
./kn service delete echo

# weird again
echo -n "Should scale to 10 immediately and then down to 5 after 90 seconds - press enter" ; read a
./kn service create echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=10 --min-scale=5
echo -n "ready for next test - press enter" ; read a
./kn service delete echo

echo -n "Should scale to 10 immediately and stay there - press enter" ; read a
./kn service create echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=5 --min-scale=10
echo -n "ready for next test - press enter" ; read a
./kn service delete echo
echo -n "Should not scale at all yet - press enter" ; read a
./kn service create echo --image duglin/echo
echo -n "Should scale to 10 immediately - press enter" ; read a
./kn service update echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=0 --min-scale=10

# doesn't scale to 0 immediately
echo -n "Should scale to 0 immediately - press enter" ; read a
./kn service update echo --image duglin/echo --annotation autoscaling.knative.dev/initialScale=0 --min-scale=0
echo -n "ready for next test - press enter" ; read a
./kn service delete echo

