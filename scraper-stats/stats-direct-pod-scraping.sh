set -x

export num=100
echo "> creating ksvc with $num pods"
cat <<EOF | kubectl create -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: echo
spec:
  traffic:
  - latestRevision: true
    percent: 100
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "100"
    spec:
      containerConcurrency: 1
      containers:
        - image: duglin/echo
          env:
            - name: CRASH1
              value: bar
EOF

export REVNAME=$(kubectl get revision --output=jsonpath="{.items..metadata.name}")
echo "> getting data for direct pod scraping for revision $REVNAME"

for i in $(seq 50); do
    echo "> i = $i"

    # Sleep for 20 seconds before collecting data
    echo "> sleeping for 20 seconds"
    sleep 20

    # Data for direct pod scraping
    echo "-----> 99 percentile"
    val99=$(curl -g 'http://127.0.0.1:9090/api/v1/query?query=histogram_quantile(0.99,sum(rate(autoscaler_scrape_time_bucket{namespace_name="default",configuration_name="echo",revision_name="'$REVNAME'"}[30s]))by(le))' | jq -r '.data.result[].value[1]')
    echo "-----> 95 percentile"
    val95=$(curl -g 'http://127.0.0.1:9090/api/v1/query?query=histogram_quantile(0.95,sum(rate(autoscaler_scrape_time_bucket{namespace_name="default",configuration_name="echo",revision_name="'$REVNAME'"}[30s]))by(le))' | jq -r '.data.result[].value[1]')
    echo "-----> 90 percentile"
    val90=$(curl -g 'http://127.0.0.1:9090/api/v1/query?query=histogram_quantile(0.90,sum(rate(autoscaler_scrape_time_bucket{namespace_name="default",configuration_name="echo",revision_name="'$REVNAME'"}[30s]))by(le))' | jq -r '.data.result[].value[1]')
    echo "-----> 50 percentile"
    val50=$(curl -g 'http://127.0.0.1:9090/api/v1/query?query=histogram_quantile(0.50,sum(rate(autoscaler_scrape_time_bucket{namespace_name="default",configuration_name="echo",revision_name="'$REVNAME'"}[30s]))by(le))' | jq -r '.data.result[].value[1]')

    printf "$val50,$val90,$val95,$val99\n" >> ~/Desktop/stats.csv
done

#echo "> cleanup"
#kubectl delete ksvc echo

