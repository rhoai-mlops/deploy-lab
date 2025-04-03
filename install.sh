git clone https://github.com/rhoai-mlops/deploy-lab.git

## Install GitOps Operator and Instance
helm upgrade --install ml500-gitops gitops --namespace ml500 --create-namespace

## Install Operators (this will be in an AppSet)
helm upgrade --install ml500-operators operators --namespace ml500 --create-namespace

## Install helm chart (this will be in an AppSet)
helm upgrade --install ml500-base charts/ --namespace ml500 --create-namespace

# Patch OAuth to point to ML500 htpasswd
oc patch --type=merge OAuth/cluster -p '{"spec": {"identityProviders": [{"name": "Students", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd-ml500"}}}, {"name": "htpasswd_provider", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd"}}}]}}'

oc patch --type=merge DataScienceCluster/default-dsc -p '{"spec": {"components": {"trustyai": {"managementState": "Managed", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://api.github.com/repos/trustyai-explainability/trustyai-service-operator-ci/tarball/service-acca8f52f3f163444b2fc68003af5cae13f04762"}]}}}}}'

# Make Argo CDs cluster wide
