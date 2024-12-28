This project outlines the steps to setup a multi-node cluster using Kubernetes in Docker (KIND) using terraform and deploy the famous kafka-banzai opertors using FluxCD

Objectives:
1. Use Terraform to create a local multi-node KIND cluster
2. Use Terraform to create a github repo to be used by FluxCD
3. Bootstrap Flux with the repo created above.
4. Deploy Kafka-Banzai framework using Flux
   - deploy a helm chart using Flux
   - deploy some k8s manifests using Flux

Pre-Requisites:
1. Github Account and a [Github PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
2. KIND ( choco install kind )
3. Kubectl ( choco install kubernetes-cli )
4. Terraform ( choco install terraform --pre  )
5. FluxCD ( choco install flux )

This projects uses three github repos:
1. Kafka-Banzai-on-kind: Hosts the terraform config to deploy infrastructure: It creates a kind cluster, a gitub repo and bootsraps fluxcd on the newly created repository
2. bb-app-source: Hosts the manifest files to be deployed on the k8s cluster. I have limted this to hold the application related manifests only.
3. terraform-flux-kafka: This is the new repo created by terraform and it uses for bootsrapping fluxcd. This will be used to host all the cluster level config and flux manifest files

Steps:
1. Define Terraform modules to create three resources: KIND cluster, Github pvt repo and bootstrap fluxcd.
   - Use the terraform files under ./terraform/
   - terraform init
   - terraform plan
   - terraform apply
 You should be able to verify that flux controllers are up and running by running a 'kubectl get all -n flux-system' , alternatively you should be able to see the controller manifests in the newly created github repository.
2. Now that our infra is in place, lets start with a simple application deployment.
   There are some simple k8s manifest files (for a namspace, deployment and a service) in the bb-app-source repo at this path /bb-app-source/manifests/1-demo. L
   - Flux must know where our app manifests live, lets create a flux source for this:
      - run flux create source git bb-app-source   --url=https://github.com/singhkgurtej/bb-app-source.git   --branch=1-demo --export > bb-apps-source.yaml
      - move this file to the terraform-flux-kafka repo under /flux/dev-cluster/bb-app/  (just to keep things organized)
   - Now that flux know where our manifest lives, it needs to know where it should be deployed. It uses Kustomizations to that. Lets create a kustomization for our source:
      - flux create kustomization bb-app --source=gitRepository/bb-app --prune=true --interval=60m --wait=true --health-check-timeout=3m - -export > xk-kustomization.yaml
      - Again move this file to the terraform-flux-kafka repo under /flux/dev-cluster/bb-app/
   - Commit your changes and push to the terraform-flux-kafka remote (git push origin)
   As soon as you merge your changes to main branch, you should see flux reconciling your changes. It should start by creating the two manifest we defined above, source and kustomization.
   - run a flux get all -A and you should see both of the above
   - run a kubectl get all -A and you should see the namespace, deployment and the service running
   Great Job, we now have our manifests deployed automatically, similarly flux will reconcile your changes as soon as there are changes to the main branch
3. Lets take things a bit further and try deploying the famous kafka-banzai (Koperator) operator. This should give you an idea on how helm charts are deployed by FluxCD
   ****** We will try following the instructions mentioned on their official github handle (here) and will adjust them according to flux architecture. ****
3.1 Install [Zookeeper operators](https://github.com/pravega/zookeeper-operator)
   - Install ZooKeeper using Pravega’s Zookeeper Operator: Again we need to create a flux source so that flux knows where our helm chart lives:
     - flux create source helm zookeeper --url=https://charts.pravega.io -n zookeeper --export >zk-source.yaml 
     - Move this file to to the terraform-flux-kafka repo under /flux/dev-cluster/zookeeper/
   - Now similar to Kustomizations, flux needs to know where the chart and what chart is to be deployed, welcome HelmReleases. Lets create one for our above helm source.
     - flux create hr zk-helmrelease --source=helmrepository/zookeeper --chart=zookeeper-operator  --export > zk-helm-release.yaml
     - Again to be organized, lets move this to terraform-flux-kafka repo/flux/dev-cluster/zookeeper/
   - Create a ZooKeeper cluster
     - Define the Zookeeper manifest as given on the documentation under our manifests repo bb-app-source/manifests/zookeeper/
   - Commit and push your changes and wait for flux to reconcile the changes.
   - Confirm if the zookeeper object is up by running kubectl get -all -n zookeeper
   - You should also be able to see the new source and helm release by running flux get all -n zookeeper
3.2 Install Koperator
   - install the Koperator CRD
     - Copy the CRD manifest as defined in the documentation (https://github.com/banzaicloud/koperator/releases/download/v0.25.1/kafka-operator.crds.yaml) under terraform-flux-kafka repo/flux/dev-cluster/koperator/
       [ You can even move it to the manifest and it should work just fine repo but I've tried keeping all cluster level config under the terraform-flux-kafka repo]
   - Install Koperator operator using helm: Create a flux source as this helm chart lives at a different repo than zookeepers.
     - flux create source helm kafka-helm-source --url https://kubernetes-charts.banzaicloud.com -n kafka --export > kafka-helm-source.yaml 
     - Move this file to to the terraform-flux-kafka repo under /flux/dev-cluster/koperator
   - create a HelmReleases for the kafka helm source
     - flux create hr kafka-helmrelease --source=helmrepository/kafka-helm-source --chart=kafka-operator -n kafka --export > kafka-helm-release.yaml
     - Again to be organized, lets move this to terraform-flux-kafka repo/flux/dev-cluster/koperator/
   - Create a kafka cluster
     - Define the Kafka manifest as given on the documentation under our manifests repo bb-app-source/manifests/kafka/
   - Commit and push your changes and wait for flux to reconcile the changes.
   - Confirm if the kafka object is up by running kubectl get -all -n kafka
   - You should also be able to see the new source and helm release by running flux get all -n kafka

Voila!!!! QED, You have a local kafka cluster running

Next: Trying deploying the Kafka Producer and Consumer as given in the documentation and understand the data flow for Kafka

Clean up: 
   - cd kafka-banza-on-kind/terraform/
   - terraform destroy
