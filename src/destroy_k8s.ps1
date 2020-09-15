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

# Destroy k8s cluster
gcloud container clusters delete $config.k8s_cluster_name --zone $config.k8s_cluster_zone

# Cleanup resources
$resources.k8s_endpoint = $null

# Write resources
Write-EnvResources -Path $ConfigPath -Resources $resources
