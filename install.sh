# install Gitea Operator
oc apply -k https://github.com/rhpds/gitea-operator/OLMDeploy 

# TODO: Install Operators
# - OpenShift Serverless
# - OpenShift Service Mesh
# - Authorino
# - OpenShift AI
# - OpenShift Pipelines
# - OpenShift GitOps
# - Kubernetes image puller

# install helm chart
git clone https://github.com/rhoai-mlops/deploy-lab.git 
cd deploy-lab/charts/
helm upgrade --install ml500-base . --namespace ml500 --create-namespace
cd ..
# Patch OAuth to point to ML500 htpasswd

oc patch --type=merge OAuth/cluster -p '{"spec": {"identityProviders": [{"name": "Students", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd-ml500"}}}, {"name": "htpasswd_provider", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd"}}}]}}'

# Patch Argo CD to be cluster level (for this training purposes)
attendees=`grep attendees charts/values.yaml | cut -d':' -f2`
for ((i=1; i<=$attendees; i++))
do
  if [ $i -eq 1 ]; then
    NS="user$i-mlops"
  else
    NS+="$var,user$i-mlops"
  fi
done
oc -n openshift-gitops-operator patch subscriptions.operators.coreos.com/openshift-gitops-operator --type=json \
        -p '[{"op":"'add'","path":"/spec/config", "value": {}},{"op":"'add'","path":"/spec/config/env", "value":[{"name": "DISABLE_DEFAULT_ARGOCD_INSTANCE", "value":"true"}] },{"op":"'add'","path":"/spec/config/env/1","value":{"name": "ARGOCD_CLUSTER_CONFIG_NAMESPACES", "value":"'${NS}'"}}]'

# Configure TrustyAI
oc patch ConfigMap/user-workload-monitoring-config  -p '{"data": {"config.yaml": "prometheus:\n  logLevel: debug\n  retention: 15d"}}' -n openshift-user-workload-monitoring
oc patch --type=merge DataScienceCluster/default-dsc -p '{"spec": {"components": {"trustyai": {"managementState": "Managed", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://api.github.com/repos/RHRolun/trustyai-service-operator/tarball/44e4bb7d6914fd7c8fc7eb445e0cf608861bef90"}]}}}}}'
oc patch --type=merge DataScienceCluster/default-dsc -p '{"spec": {"components": {"modelregistry": {"managementState": "Managed", "registriesNamespace": "rhoai-model-registries", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://api.github.com/repos/opendatahub-io/model-registry-operator/tarball/v0.2.10"}]}}}}}'

#install model registry kustomize

# ATTENDEES=$(grep attendees ./charts/values.yaml)
# cd model-registry
# for I in $(seq 0 $((${ATTENDEES#*:}-1))) ; do 
#   export NAMESPACE=user${I}
#   KTEMP=$(mktemp -d)
#   cat kustomization.tmpl | envsubst > ${KTEMP}/kustomization.yaml
#   oc apply -k ${KTEMP}
#   rm -rf ${KTEMP}
# done
