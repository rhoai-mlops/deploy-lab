# install Gitea Operator
oc apply -k https://github.com/rhpds/gitea-operator/OLMDeploy 

# TODO: Install Operators
# - OpenShift Serverless
# - OpenShift Service Mesh
# - Authorino
# - OpenShift AI
# - OpenShift Pipelines
# - OpenShift GitOps

# install helm chart
git clone https://github.com/rhoai-mlops/deploy-lab.git 
cd deploy-lab/charts/
helm upgrade --install ml500-base . --namespace ml500 --create-namespace
cd ..
# Patch OAuth to point to ML500 htpasswd

oc patch --type=merge OAuth/cluster -p '{"spec": {"identityProviders": [{"name": "Students", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd-ml500"}}}, {"name": "htpasswd_provider", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd"}}}]}}'

# Configure TrustyAI
oc patch ConfigMap/user-workload-monitoring-config  -p '{"data": {"config.yaml": "prometheus:\n  logLevel: debug\n  retention: 15d"}}' -n openshift-user-workload-monitoring
oc patch DataScienceCluster/default-dsc -p '{"spec": {"components": {"trustyai": {"managementState": "Managed", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://github.com/RHRolun/trustyai-service-operator/tarball/main"}]}}}}}'

#install model registry kustomize

ATTENDEES=$(grep attendees ./charts/values.yaml)
cd model-registry
for I in $(seq 0 $((${ATTENDEES#*:}-1))) ; do 
  export NAMESPACE=user${I}
  KTEMP=$(mktemp -d)
  cat kustomization.tmpl | envsubst > ${KTEMP}/kustomization.yaml
  oc apply -k ${KTEMP}
  rm -rf ${KTEMP}
done
