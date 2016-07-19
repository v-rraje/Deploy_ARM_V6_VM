<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,
  
 [Parameter(Mandatory=$True)]
 [string]
 $StorageAccountName,

 [Parameter(Mandatory=$True)]
 [string]
 $parametersFilePath,

 [Parameter(Mandatory=$True)]
 [string]
 $templateFilePath,
 
 [string]
 $resourceGroupLocation="West US",

 [string]
 $subscriptionId="472e0eab-03f7-40c9-a6c3-d1d493b9ee5d",

 [string]
 $deploymentName="JemDev"
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace -Force;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
Write-Host "Logging in...";
# Login-AzureRmAccount;
try {
#Check if the user is already logged in for this session
$AzureRmContext = Get-AzureRmContext | out-null
Write-verbose “Connected to Azure”
} catch {
#Prompts user to login to Azure account
Login-AzureRmAccount | out-null

#$azureAccountName ="jem-dev@microsoft.com"
#$azurePassword = ConvertTo-SecureString "May@2016" -AsPlainText -Force
#$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
#Login-AzureRmAccount -Credential $psCred

Write-verbose “logged into Azure.”
$error.Clear()
}

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.network","microsoft.storage");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment -Procuring Storage Account.
Write-Host "Starting deployment For Storage Account Creation For '$StorageAccountName'";

$StorageAccount = @{
    ResourceGroupName = $resourceGroupName;
    Name = $StorageAccountName;
    SkuName = 'Standard_LRS';
    Location = $resourceGroupLocation;#TODO : check for the location.
    }

$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
if (!$storageAcc.StorageAccountName)
{  
   Write-Host "Creating Storage Account... $StorageAccountName"
   New-AzureRmStorageAccount @StorageAccount;
 }
 else
 {
 Write-Host "Taking already existing Storage Account: '$StorageAccountName' from  Resource Group: '$resourceGroupName' "
 }

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
} else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;
}
