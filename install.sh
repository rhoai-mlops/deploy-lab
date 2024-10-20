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


#install model registry kustomize
cd ../model-registry
oc apply -k .