#1. Copy to Web server UI Bits.
robocopy  \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WebServer\jem \\azfjemiis03\e$\Inetpub\wwwroot\JemDev1 /S
#2. Copy to App server Service Bits.
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\AppServer\jem \\azfjemiis04\e$\inetpub\wwwroot\JemDev1 /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\JEMAdminSvc \\azfjemiis04\e$\NTService\JEMAdminSvc1 /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\JEMWQSvc \\azfjemiis04\e$\NTService\JEMWQSvc1 /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\JEMDupMonSvc \\azfjemiis04\e$\NTService\JEMDupMonSvc1 /S
robocopy \\azcujemdeviis02\d$\Jem_ARM_V6_Bits\WindowsNT\SAPMSMQ \\azfjemiis04\e$\NTService\SAPMSMQ1 /S
#3. Copy to SQL server BackUp to Restore Bits.
robocopy \\azcujemtstsql01\e$\ProdBackUp \\azfjemsql04\e$\MSSQL12.MSSQLSERVER\MSSQL\bak1 /S
