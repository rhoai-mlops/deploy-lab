# install IPA

helm repo add redhat-cop https://redhat-cop.github.io/helm-charts
helm upgrade --install ipa redhat-cop/ipa --namespace=ipa --create-namespace --set app_domain=<CLUSTER_DOMAIN> --set ocp_auth.enabled=true


# create users
IPA_NAMESPACE="${1:-ipa}"

# 1. On your host, get the IPA admin password and set the students password.
oc project ${IPA_NAMESPACE}
IPA_ADMIN_PASSWD=$(oc get secret ipa-password --template='{{ range .data }}{{.}}{{end}}' -n ipa | base64 -d)
STUDENT_PASSWORD='thisisthepassword'

# 2. On the container running IPA Server, create `student` group and add users to it.
oc rsh `oc get po -l app=ipa -o name -n ${IPA_NAMESPACE}` bash << EOF
echo ${IPA_ADMIN_PASSWD} | kinit admin
export GROUP_NAME=student
ipa group-add \${GROUP_NAME} --desc "ML500 Student Group" || true
# in a loop add random users to the group 
for i in {1..24};do
  export USER_NUMBER="user\$i"
  echo 'thisisthepassword' | ipa user-add \${USER_NUMBER} --first=\${USER_NUMBER} --last=\${USER_NUMBER} --email=\${USER_NUMBER}@redhatlabs.dev --password
  ipa group-add-member \${GROUP_NAME} --users=\$USER_NUMBER
  printf "\n\n User \${USER_NUMBER} is created"
done
  echo 'Passw0rd123' | ipa user-add ldap_admin --first=ldap_admin --last=ldap_admin --email=ldap_admin@redhatlabs.dev --password
EOF

# Install Operators
# with kustomize?

# install helm chart
git clone https://github.com/rhoai-mlops/deploy-lab.git 
cd deploy-lab/charts/
helm upgrade --install ml500-base . --namespace ml500 --create-namespace


#install model registry kustomize
cd ../model-registry
oc apply -k .