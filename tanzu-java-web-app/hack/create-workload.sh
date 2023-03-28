#!/usr/bin/env bash


function rename_deployment() {
  if [ ! $# -eq 1 ]; then
    echo "Incorrect number of args, specify the new deployment name"
    usage
    exit 1
  fi

  local delivery_temp_file
  delivery_temp_file=$(mktemp /tmp/delivery_XXXXXX.yml)
  echo "File created: $delivery_temp_file"

  kubectl get cm tanzu-java-web-app-https-server -n default -ojsonpath="{.data.delivery\.yml}" > "$delivery_temp_file"
  export WORKLOAD_NAME="$1"
  yq -i 'select(.kind == "Deployment").metadata.name = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Deployment").metadata.labels["carto.run/workload-name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Deployment").spec.selector.matchLabels["carto.run/workload-name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Deployment").spec.selector.matchLabels["tanzu.app.live.view.application.name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Deployment").spec.template.metadata.labels["carto.run/workload-name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Deployment").spec.template.metadata.labels["tanzu.app.live.view.application.name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  # for service
  yq -i 'select(.kind == "Service").metadata.name = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Service").metadata.labels["carto.run/workload-name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Service").spec.selector["carto.run/workload-name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"
  yq -i 'select(.kind == "Service").spec.selector["tanzu.app.live.view.application.name"] = strenv(WORKLOAD_NAME)' "$delivery_temp_file"

  # change scheme in probes
  yq -i 'select(.kind == "Deployment").spec.template.spec.containers[0].livenessProbe.httpGet.scheme = "HTTPS"' "$delivery_temp_file"
  yq -i 'select(.kind == "Deployment").spec.template.spec.containers[0].readinessProbe.httpGet.scheme = "HTTPS"' "$delivery_temp_file"

  kubectl -f "$delivery_temp_file"

  kubectl annotate service "$WORKLOAD_NAME" projectcontour.io/upstream-protocol.tls="8443"

}




"$@"
