
# Install the operators
helm upgrade --install ml500-base operators --namespace ml500 --create-namespace

oc wait --for=jsonpath='{.status.availableReplicas}'=1 -n openshift-gitops deployment/cluster

# Install the toolings
helm upgrade --install ml500-toolings toolings --namespace ml500 --create-namespace

# Install the toolings
helm upgrade --install ml500-student-content student-content --namespace ml500 --create-namespace


# Patch OAuth to point to ML500 htpasswd
oc patch --type=merge OAuth/cluster -p '{"spec": {"identityProviders": [{"name": "Students", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd-ml500"}}}, {"name": "htpasswd_provider", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd"}}}]}}'

# oc patch --type=merge DataScienceCluster/default-dsc -p '{"spec": {"components": {"trustyai": {"managementState": "Managed", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://api.github.com/repos/ckavili/trustyai-service-operator-ci/tarball/service-acca8f52f3f163444b2fc68003af5cae13f04762"}]}}}}}'

oc -n openshift-user-workload-monitoring patch configmap user-workload-monitoring-config --type=merge -p '{"data": {"config.yaml": "prometheus:\n  logLevel: debug\n  retention: 15d\nalertmanager:\n  enabled: true\n  enableAlertmanagerConfig: true\n"}}'

oc patch config.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

# Make ArgoCD cluster wide
attendees=`grep attendees student-content/values.yaml | cut -d':' -f2`
 for ((i=0; i<=$attendees; i++))
 do
   if [ $i -eq 1 ]; then
     NS="user$i-toolings"
   else
     NS+="$var,user$i-toolings"
   fi
 done
 oc -n openshift-gitops-operator patch subscriptions.operators.coreos.com/openshift-gitops-operator --type=json \
         -p '[{"op":"'add'","path":"/spec/config/env", "value":[{"name": "DISABLE_DEFAULT_ARGOCD_INSTANCE", "value":"true"}] },{"op":"'add'","path":"/spec/config/env/1","value":{"name": "ARGOCD_CLUSTER_CONFIG_NAMESPACES", "value":"'${NS}'"}}]'


# Disable affinity assistant in Tekton to avoid it hogging PVCs
oc patch configmap feature-flags -n openshift-pipelines --type merge -p '{"data":{"disable-affinity-assistant":"true","coschedule":"disabled"}}'
oc patch configmap config-defaults -n openshift-pipelines --type merge -p '{"data":{"default-affinity-assistant-pod-template":"","default-pod-template":""}}'
oc delete pod -l app=tekton-pipelines-controller -n openshift-pipelines

# Finish RHACS installation
oc -n rhacs-operator wait central/stackrox-central-services --for=condition=Deployed=True --timeout=300s
CENTRAL="$(oc -n rhacs-operator get routes/central -o jsonpath='{.spec.host}')"
curl -sk -u admin:myPassw0rd -XPOST -d '{"name": "admin token", "role": null, "roles": ["Admin"]}' https://${CENTRAL}/v1/apitokens/generate > rhacs-admin-token.json
TOKEN="$(jq -r .token < rhacs-admin-token.json)"
curl -sk -H "Authorization: Bearer ${TOKEN}" -XPOST -d '{"name": "local-cluster"}' https://${CENTRAL}/v1/cluster-init/init-bundles > cluster-init-bundle.json
jq -r .kubectlBundle < cluster-init-bundle.json | base64 -d | oc -n rhacs-operator create -f -
cat <<EOF | oc apply -f -
apiVersion: platform.stackrox.io/v1alpha1
kind: SecuredCluster
metadata:
  annotations:
    feature-defaults.platform.stackrox.io/admissionControllerEnforcement: Disabled
  name: stackrox-secured-cluster-services
  namespace: rhacs-operator
spec:
  admissionControl:
    bypass: BreakGlassAnnotation
    enforcement: Enabled
    failurePolicy: Ignore
    replicas: 2
  auditLogs:
    collection: Enabled
  clusterName: local-cluster
  perNode:
    collector:
      collection: CORE_BPF
  processBaselines:
    autoLock: Enabled
  scanner:
    scannerComponent: AutoSense
  scannerV4:
    scannerComponent: AutoSense
EOF

# NOTE: it will take a couple of hours for vuln updates to be downloaded

