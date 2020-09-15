# Overview

This is a built-in module to environment [pip-templates-env-master](https://github.com/pip-templates/pip-templates-env-master). 
This module stores scripts for management google cloud kubernetes environment.

# Usage

- Download this repository
- Copy *src* and *templates* folder to master template
- Add content of *.ps1.add* files to correspondent files from master template
- Add content of *config/config.k8s.json.add* to json config file from master template and set the required values

# Config parameters

Config variables description

| Variable | Default value | Description |
|----|----|---|
| gcp_billing_account_id | XXXXXX-XXXXXX-XXXXXX | Id of your billing account, can be get from https://console.cloud.google.com/billing |
| gcp_project_name | pip Templates | Name of google project |
| env_name | pip-templates | Environment name, used as k8s node label |
| k8s_cluster_name | pip-templates-stage | Kubernetes cluster name |
| k8s_cluster_zone | us-east1-b | Kubernetes cluster availability zone |
| k8s_cluster_version | 1.15.12-gke.2 | Google cloud kubernetes version |
| k8s_nodes_count | 2 | Kubernetes nodes count |
| k8s_nodes_machine_type | e2-micro | Kubernetes node virtual machines type |
| k8s_nodes_image | UBUNTU | Kubernetes node virtual machines image |
| k8s_nodes_disk_type | pd-standard | Kubernetes node disk type |
| k8s_nodes_disk_size | 100 | Kubernetes node disk size |
| k8s_nodes_max_pods | 110 | Maximum number of pods per node |
