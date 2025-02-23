git clone https://github.com/rhoai-mlops/deploy-lab.git

## Install GitOps Operator and Instance
helm upgrade --install ml500-gitops gitops --namespace ml500 --create-namespace

## Install Operators (this will be in an AppSet)
helm upgrade --install ml500-operators operators --namespace ml500 --create-namespace

## Install helm chart (this will be in an AppSet)
helm upgrade --install ml500-base charts/ --namespace ml500 --create-namespace

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
        -p '[{"op":"'add'","path":"/spec/config/env", "value":[{"name": "DISABLE_DEFAULT_ARGOCD_INSTANCE", "value":"true"}] },{"op":"'add'","path":"/spec/config/env/1","value":{"name": "ARGOCD_CLUSTER_CONFIG_NAMESPACES", "value":"'${NS}'"}}]'
oc patch --type=merge DataScienceCluster/default-dsc -p '{"spec": {"components": {"trustyai": {"managementState": "Managed", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://api.github.com/repos/trustyai-explainability/trustyai-service-operator-ci/tarball/service-acca8f52f3f163444b2fc68003af5cae13f04762"}]}}}}}'
