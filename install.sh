
# Install the operators
helm dep up operators
helm upgrade --install ai500-base operators --namespace ai500 --create-namespace

# Wait for all operators (CSVs) to be ready
echo "Waiting for operators to install..."
for ns in openshift-operators redhat-ods-operator openshift-operators-redhat; do
  while true; do
    TOTAL=$(oc get csv -n "$ns" --no-headers 2>/dev/null | wc -l)
    SUCCEEDED=$(oc get csv -n "$ns" --no-headers 2>/dev/null | grep -c Succeeded)
    if [ "$TOTAL" -gt 0 ] && [ "$TOTAL" -eq "$SUCCEEDED" ]; then
      echo "All CSVs in $ns are Succeeded"
      break
    fi
    echo "Waiting for CSVs in $ns ($SUCCEEDED/$TOTAL Succeeded)..."
    sleep 10
  done
done

# Install the toolings
helm dep up toolings
helm upgrade --install ai500-toolings toolings --namespace ai500 --create-namespace

# Wait for DataScienceCluster to become Ready
echo "Waiting for DataScienceCluster to become Ready..."
oc wait --for=condition=Ready datasciencecluster --all --timeout=300s

# Patch inferenceservice-config ConfigMap
oc annotate configmap inferenceservice-config -n redhat-ods-applications opendatahub.io/managed="false" --overwrite
oc patch configmap inferenceservice-config -n redhat-ods-applications --type=json \
  -p '[{"op":"add","path":"/data/logger","value":"{\"image\": \"registry.redhat.io/rhoai/odh-kserve-agent-rhel9@sha256:191aa92865c26ef1e5f9856a8ca91263782b4627db65bfcc61c9879537d34b0b\", \"memoryRequest\": \"100Mi\", \"memoryLimit\": \"1Gi\", \"cpuRequest\": \"100m\", \"cpuLimit\": \"1\", \"defaultUrl\": \"http://default-broker\", \"caBundle\": \"kserve-logger-ca-bundle\", \"caCertFile\": \"service-ca.crt\", \"tlsSkipVerify\": false}"}]'

# Patch trustyai-service-operator-config ConfigMap
oc annotate configmap trustyai-service-operator-config -n redhat-ods-applications opendatahub.io/managed="false" --overwrite
oc -n redhat-ods-applications patch configmap trustyai-service-operator-config --type=merge \
  -p '{"data":{"trustyaiServiceImage":"quay.io/ckavili/trustyai-service-python:latest"}}'

# Apply user workload monitoring config
oc -n openshift-user-workload-monitoring patch configmap user-workload-monitoring-config --type=merge -p '{"data": {"config.yaml": "prometheus:\n  logLevel: debug\n  retention: 15d\nalertmanager:\n  enabled: true\n  enableAlertmanagerConfig: true\n"}}'

# Install the student content
helm upgrade --install ai500-student-content student-content --namespace ai500 --create-namespace

# Patch OAuth to point to ai500 htpasswd
oc patch --type=merge OAuth/cluster -p '{"spec": {"identityProviders": [{"name": "Students", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd-ml500"}}}, {"name": "htpasswd_provider", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd"}}}]}}'

# Enable default route for image registry
oc patch config.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

# Disable affinity assistant in Tekton to avoid it hogging PVCs
oc patch tektonconfig config --type=merge \
  -p '{"spec":{"pipeline":{"disable-affinity-assistant":true,"coschedule":"disabled"}}}'
oc patch configmap feature-flags -n openshift-pipelines --type merge -p '{"data":{"disable-affinity-assistant":"true","coschedule":"disabled"}}'
oc patch configmap config-defaults -n openshift-pipelines --type merge -p '{"data":{"default-affinity-assistant-pod-template":"","default-pod-template":""}}'
oc delete pod -l app=tekton-pipelines-controller -n openshift-pipelines

# Make ArgoCD cluster wide
attendees=$(grep attendees student-content/values.yaml | cut -d':' -f2 | tr -d ' ')
NS=""
for ((i=1; i<=attendees; i++)); do
  if [ $i -eq 1 ]; then
    NS="user${i}-toolings"
  else
    NS="${NS},user${i}-toolings"
  fi
done
oc -n openshift-gitops-operator patch subscriptions.operators.coreos.com/openshift-gitops-operator --type=json \
  -p '[{"op":"add","path":"/spec/config/env","value":[{"name":"DISABLE_DEFAULT_ARGOCD_INSTANCE","value":"true"}]},{"op":"add","path":"/spec/config/env/1","value":{"name":"ARGOCD_CLUSTER_CONFIG_NAMESPACES","value":"'"${NS}"'"}}]'
