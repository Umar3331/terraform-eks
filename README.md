# CHANGELOG

* Added Helm provider and automated installation of Jupyterhub.
* Added local executing of kubectl and aws.
* Deleted redundant code.
* Deleted s3 buckets to make space for team to add their creations.
* Bit of code refactoring.

# HOW TO USE

1) Clone repo and go inside main folder
2) Run **terraform int**. If it fails because you are using Terraform 14 go to **/.terraform/modules/** in cloned project folder, find respective module and uncomment version constraints in **versions.tf**
3) Run **terraform apply**. Resource creation should take approx 10 - 15 minutes.
4) Install and configure **aws** & **kubectl**
5) Generate hex values by running command: **openssl rand -hex 32**.
6) Edit **values.yml** file and paste generated hex. Use **values.yml** to add more config.
7) Script should print out j-hub address. If not, proceed with **aws eks --region eu-central-1 update-kubeconfig --name test-cluster** and **kubectl --namespace=default get svc proxy-public**.
8) Password and login is kept in values.yml file. By default: **admin** and **supersecretpassword!**.
9) To clean up run **terraform destroy**.

![alt text](https://github.com/JanisRancans/terraform-eks/blob/main/jhub-running-python.png?raw=true)
