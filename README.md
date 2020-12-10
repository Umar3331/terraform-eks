# HOW TO USE

1) Clone repo and go inside main folder
2) Run **terraform int**. If it fails because you are using Terraform 14 go to **/.terraform/modules/** in cloned project folder, find respective module and uncomment version constraints in **versions.tf**
4) Run **terraform apply**. Resource creation should take approx 10 - 15 minutes.
5) Install and configure **aws**, **kubectl** & **helm**.
6) Point kubeconfig to cluster: **aws eks --region your-region update-kubeconfig --name test-cluster**.
7) Generate hex values by running command: **openssl rand -hex 32**.
8) Edit **values.yml** file and paste generated hex.
10) Set up helm: **helm repo add jupyterhub https://jupyterhub.github.io/helm-chart** and **helm repo update**.
11) Deploy j-hub: **helm install jupyterhub jupyterhub/jupyterhub --values values.yml**.
12) Wait a bit and then get j-hub address: **kubectl --namespace=default get svc proxy-public**.
13) Password and login is kept in values.yml file. By default: **admin** and **supersecretpassword!**.
14) To clean up run **terraform destroy**.

![alt text](https://github.com/JanisRancans/terraform-eks/blob/main/jhub-running-python.png?raw=true)
