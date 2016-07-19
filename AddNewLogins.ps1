Param
(
    [Parameter(Mandatory=$true)]
    [String]   $RemoteComputer,
    [String]   $sqlServer,
    [String]   $loginName,
    [String]   $dbUserName,
    [String]   $password,
    [String[]] $databasenames,
    [String]   $roleName
)
function DbRestore ($sqlServer,$loginName,$dbUserName,$password,$databasenames,$roleName) 
{
    #import SQL Server module
    Import-Module SQLPS -DisableNameChecking

    $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sqlServer

    # drop login if it exists
    if ($server.Logins.Contains($loginName))  
    {   
        Write-Host("Deleting the existing login $loginName.")
           $server.Logins[$loginName].Drop() 
    }

    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $loginName
    $login.LoginType = 'SqlLogin'
    $login.PasswordExpirationEnabled = $false
    $login.Create($password)
    Write-Host("Login $loginName created successfully.")

     foreach($databaseToMap in $databasenames)  
     {
        $database = $server.Databases[$databaseToMap]
        if ($database.Users[$dbUserName])
        {
            Write-Host("Dropping user $dbUserName on $database.")
            $database.Users[$dbUserName].Drop()
        }

        $dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $database, $dbUserName
        $dbUser.Login = $loginName
        $dbUser.Create()
        Write-Host("User $dbUser created successfully.")
        #assign database role for a new user
        $dbrole = $database.Roles[$roleName]
        $dbrole.AddMember($dbUserName)
        $dbrole.Alter()
        Write-Host("User $dbUser successfully added to $roleName role.")
     }
  }
Invoke-Command -ComputerName $RemoteServer -ScriptBlock ${function:DbRestore} -ArgumentList $sqlServer,$loginName,$dbUserName,$password,$databasenames,$roleName

