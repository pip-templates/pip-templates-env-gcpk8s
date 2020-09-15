#!/usr/bin/env pwsh

param
(
    [Alias("c", "Path")]
    [Parameter(Mandatory=$false, Position=0)]
    [string] $ConfigPath
)

$ErrorActionPreference = "Stop"

# Load support functions
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }
. "$($path)/../lib/include.ps1"
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

# Select or create project
if ($resources.gcp_project_id -ne $null) {
    # Select existing project
    $currProjectId = gcloud config get-value project
    if ($currProjectId -ne $resources.gcp_project_id){
        gcloud config set project $($resources.gcp_project_id)
        if ($lastExitCode -eq 0) {
            Write-Host "Project with id $($resources.gcp_project_id) selected."
        }
    }
} else {
    # Create new project
    $resources.gcp_project_id = "$($config.gcp_project_name)".Replace(" ","-").ToLower()
    $create = Read-Host "Do you want to create a new GCP project with id [$($resources.gcp_project_id)]? (y/n)"
    if ($create.ToLower() -eq "y") {
        gcloud projects create $resources.gcp_project_id --name="$($config.gcp_project_name)"
        if ($lastExitCode -eq 0) {
            Write-Host "Project $($config.gcp_project_name) successfully created."
            $resources.gcp_project_number = $(gcloud projects list --format=json --filter="projectId:$($resources.gcp_project_id)" | ConvertFrom-Json).projectNumber
            gcloud config set project $($resources.gcp_project_id)

            # Link new project to billing account
            gcloud alpha billing accounts projects link $resources.gcp_project_id --billing-account="$($config.gcp_billing_account_id)"
        }
    } else {
        Write-Error "Project creation aborded and 'gcp_project_id' is missing in resource file..."
    }
}

# Create k8s cluster
gcloud beta container --project $resources.gcp_project_id clusters create $config.k8s_cluster_name `
    --zone "$($config.k8s_cluster_zone)" `
    --no-enable-basic-auth `
    --cluster-version "$($config.k8s_cluster_version)" `
    --machine-type "$($config.k8s_nodes_machine_type)" `
    --image-type "$($config.k8s_nodes_image)" `
    --disk-type "$($config.k8s_nodes_disk_type)" `
    --disk-size "$($config.k8s_nodes_disk_size)" `
    --node-labels "environment=$($config.env_name)" `
    --metadata disable-legacy-endpoints=true `
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" `
    --num-nodes "$($config.k8s_nodes_count)" `
    --enable-stackdriver-kubernetes `
    --enable-ip-alias `
    --network "projects/$($resources.gcp_project_id)/global/networks/default" `
    --subnetwork "projects/$($resources.gcp_project_id)/regions/$($config.k8s_cluster_zone -replace '.{2}$')/subnetworks/default" `
    --default-max-pods-per-node "$($config.k8s_nodes_max_pods)" `
    --no-enable-master-authorized-networks `
    --addons HorizontalPodAutoscaling,HttpLoadBalancing `
    --enable-autoupgrade `
    --enable-autorepair `
    --max-surge-upgrade 1 `
    --max-unavailable-upgrade 0

if ($lastExitCode -ne 0) {
    Write-Error "Failed to create k8s cluster. Watch logs above"
}

# Configure kubectl
$configure = Read-Host "Do you want to configure kubectl to cluster $($config.k8s_cluster_name) (y/n)?"
if ($configure.ToLower() -eq "y") {
    gcloud container clusters get-credentials $config.k8s_cluster_name --zone $config.k8s_cluster_zone
}

# Get k8s endpoint
$resources.k8s_endpoint = $(gcloud container clusters list --format=json --filter="name:$($config.k8s_cluster_name)" | ConvertFrom-Json).endpoint

# Write resources
Write-EnvResources -Path $ConfigPath -Resources $resources
