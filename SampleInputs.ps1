#*************Procuring ARM V6 VM's for Web and APP and SQL and Deploying bits on it ********************#
# Author : v-rraje
# Created Date : 7/18/2015
# Modified Date : 7/18/2015
# Description : Automated deploy bits on newly procured ARM v6 VM's (Web,APP,SQL).

#*************Procuring ARM V6 VM's for Web and APP and SQL and Deploying bits on it ********************#

# This is to Procure ARM V6 Vms for JEM Web Server.
$resourceGroupName='azfjemstrs'
$StorageAccountName='azfjemstr01'
$parametersFilePath='parameters_IIS01.json'
$templateFilePath='template.json'
.\deploy_VM.ps1 $resourceGroupName $StorageAccountName $parametersFilePath $templateFilePath

# This is to Procure ARM V6 Vms for JEM APP Server.
$resourceGroupName='azfjemstrs'
$StorageAccountName='azfjemstr01'
$parametersFilePath='parameters_IIS02.json'
$templateFilePath='template.json'
.\deploy_VM.ps1 $resourceGroupName $StorageAccountName $parametersFilePath $templateFilePath

# This is to Procure ARM V6 Vms for JEM SQL Server. 
$resourceGroupName='azfjemstrs'
$StorageAccountName='azfjemstr01'
$parametersFilePath='parameters_SQL.json'
$templateFilePath='template.json'
.\deploy_VM.ps1 $resourceGroupName $StorageAccountName $parametersFilePath $templateFilePath


#*****************START: Web and App and NT Service and SQL Bits. ************************************#
$NewWebServer='azfjemiis03'
$NewAppServer='azfjemiis04'
$NewSQLServer='azfjemsql04'
Invoke-Command -ComputerName $NewWebServer -ScriptBlock {
    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True
}
Invoke-Command -ComputerName $NewAppServer -ScriptBlock {
    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True
}
Invoke-Command -ComputerName $NewSQLServer -ScriptBlock {
    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True
    new-item E:\MSSQL11.MSSQLSERVER\MSSQL\DATA -itemtype directory
}

#1. Copy to Web server UI Bits.
robocopy  \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WebServer\jem \\azfjemiis03\e$\Inetpub\wwwroot\JemDev /S
#2. Copy to App server Service Bits.
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\AppServer\jem \\azfjemiis04\e$\inetpub\wwwroot\JemDev /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\JEMAdminSvc \\azfjemiis04\e$\NTService\JEMAdminSvc /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\JEMWQSvc \\azfjemiis04\e$\NTService\JEMWQSvc /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\JEMDupMonSvc \\azfjemiis04\e$\NTService\JEMDupMonSvc /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\SAPMSMQ \\azfjemiis04\e$\NTService\SAPMSMQ /S
#3. Copy to SQL server BackUp to Restore Bits.
robocopy \\azcujemtstsql01\e$\ProdBackUp \\azfjemsql04\e$\MSSQL12.MSSQLSERVER\MSSQL\bak /S

#*****************END: Web and App and NT Service and SQL Bits. ************************************#

#$NewWebServer='azfjemiis03'
#****************START: This is to deploy jem web server. ******************************************#
$RemoteComputers=$NewWebServer
$iisAppPoolName='JemDev'
$ServiceAccountName='redmond\jem-dev'
$ServiceAccountPwd='May@2016'
$iisWebSiteName='JemDev'
$iisAppNames=@()
$servicePaths=@()
$directoryPath='E:\inetpub\wwwroot\JemDev'
$IsQueueEnabled=0
$QueueNames=@() 
.\EnvironmentSetup.ps1 -RemoteComputers $RemoteComputers $iisAppPoolName $ServiceAccountName $ServiceAccountPwd $iisWebSiteName $iisAppNames $servicePaths $directoryPath $IsQueueEnabled $QueueNames

#$NewAppServer='azfjemiis04'
# This is to deploy jem app server.
$RemoteComputers=$NewAppServer
$iisAppPoolName='JemDev'
$ServiceAccountName='redmond\jem-dev'
$ServiceAccountPwd='May@2016'
$iisWebSiteName='JemDev'
$iisAppNames=@(
'AdminDataService','CloudSASService',
'CloudService','IHCCPostingService',
'IHCCPostPostingService','InfraAdminService',
'InfraService','JEApprovalWorkflow',
'JEMMasterDataService','JEMMobility','JEMNotification','JEPostingService',
'JEPostPosting','JEPrePostingService','PostPostingService')
$servicePaths=@(
'E:\NTService\JEMAdminSvc\Microsoft.FIT.JEM.WS.AdminService.exe;AdminService',
'E:\NTService\JEMWQSvc\Microsoft.FIT.JEM.WS.WorkQueueService.exe;WorkQueueService',
'E:\NTService\JEMDupMonSvc\DuplicateJEsMonitoringService.exe;DuplicateJEsMonitoringService',
'E:\NTService\SAPMSMQ\Microsoft.FIT.JEM.WS.SAPResponseService.exe;SAPResponseService')
$directoryPath='E:\inetpub\wwwroot\JemDev'
$IsQueueEnabled=1
$QueueNames=@('jefileQueue','jemdeadMSMQ','jemmsmq','jexlmsmq') 
.\EnvironmentSetup.ps1 -RemoteComputers $RemoteComputers $iisAppPoolName $ServiceAccountName $ServiceAccountPwd $iisWebSiteName $iisAppNames $servicePaths $directoryPath $IsQueueEnabled $QueueNames
#****************END: This is to deploy jem web server. ******************************************#

$NewSQLServer='azfjemsql04'
$RemoteServer=$NewSQLServer
$sqlServer=$NewSQLServer
$loginName = "fareast\v-rraje"
$dbUserName = "fareast\v-rraje"
$password = "May2016^"
$databasenames = @("master")
$roleName = "sysadmin"
.\AddNewLogins.ps1 $RemoteServer $sqlServer $loginName $dbUserName $password $databasenames $roleName

#$NewSQLServer='azfjemsql04'
#************************START: This is to Restore SQL Server for JEM_DATA & JemInfra & FeedStore DB.************************#
# Restore Jem_Data
$RemoteServer=$NewSQLServer
$SqlServer=$NewSQLServer
$dbname='jem_data'
$Restore=1 #If restore is set to 1 then restore will happen.
$Backup=0 #If restore is set to 1 then Backup will happen.
.\SQLBackupRestoration.ps1 $RemoteServer $SqlServer $dbname $Restore $Backup

#$NewSQLServer='azfjemsql04'
# Restore JemInfra
$RemoteServer=$NewSQLServer
$SqlServer=$NewSQLServer
$dbname='jemInfra'
$Restore=1 #If restore is set to 1 then restore will happen.
$Backup=0 #If restore is set to 1 then Backup will happen.
.\SQLBackupRestoration.ps1 $RemoteServer $SqlServer $dbname $Restore $Backup
#************************END: This is to Restore SQL Server for JEM_DATA & JemInfra & FeedStore DB.************************#

