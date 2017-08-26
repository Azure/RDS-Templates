<#  
.SYNOPSIS  
    powershell script to list or create a new Azure SQL server and / or database in Azure Resource Manager
    
.DESCRIPTION  
    powershell script to list or create a new Azure SQL server and / or database in Azure Resource Manager
    to enable script execution, you may need to Set-ExecutionPolicy Bypass -Force

    Copyright 2017 Microsoft Corporation

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    
    requires azure powershell sdk (install-module azurerm)
    script does the following:
        logs into azure rm
        checks location for validity and for availability of Azure SQL
        checks for resource group and creates if not exists
        checks resource group for azure sql servers
        if sql server is specified, will query server for existing database
        will generate / prompt for sql server name if one is not existing / specified
        checks password for complexity requirements
        creates sql server and database with firewall rules
        on success displays connection string info
    
    https://aka.ms/azure-rm-sql-create.ps1
    https://docs.microsoft.com/en-us/azure/sql-database/sql-database-get-started-powershell
    https://docs.microsoft.com/en-us/azure/sql-database/sql-database-performance-guidance

    minimum parameters : resource group, location, databaseName, adminPassword
 
.NOTES  
   File Name  : azure-rm-sql-create.ps1
   Author     : jagilber
   Version    : 170808 made $sqlVersion a variable defaulting to 12.0. authenticate-azurerm
   History    : 
                170522 adding to wiki
                170516 added -generateUniqueName
                170514 added description
.EXAMPLE  
    .\azure-rm-sql-create.ps1 -resourceGroupName newResourceGroup -location eastus -databaseName myNewDatabase -adminPassword myNewP@ssw0rd
    create a new sql database on an existing or new sql server

.EXAMPLE  
    .\azure-rm-sql-create.ps1 -resourceGroupName newResourceGroup -location eastus -databaseName myNewDatabase -credentials (get-credential) -generateUniqueName
    create a new sql database on a new random named sql server using prompted credentials

.EXAMPLE  
    .\azure-rm-sql-create.ps1 -resourceGroupName existingResourceGroup -listAvailable
    list available sql servers and databases in resource group existingResourceGroup

.EXAMPLE  
    .\azure-rm-sql-create.ps1 -resourceGroupName existingResourceGroup -server sql-server-01 -listAvailable
    list existing databases on sql-server-01 in resource group existingResourceGroup

.EXAMPLE  
    .\azure-rm-sql-create.ps1 -resourceGroupName existingResourceGroup -server sql-server-01 -serviceTier S0 -databaseName TestDB
    create a new sql database TestDB on sql-server-01 using service tier S0

.PARAMETER resourceGroupName
    required paramater for the resource group name for new database and sql server

.PARAMETER location
    required paramater for the resource group name region location

.PARAMETER serverName
    if specified, will be used for the sql server name.
    will check and if not exists, create new sql server. if named sql server exists, existing sql server will be used. 
    if not specified, or not exists, will prompt for name or will generate random name if generateUniqueName is specified.

.PARAMETER databaseName
    if specifed, will be used for the database name.
    will check and if not exists, create new database.
    if not specified, will generate random name if generateUniqueName is specified.

.PARAMETER adminUserName
    if specified, will be used for sql administrator logon.
    if not specified, 'sql-administrator' will be used.
    NOTE: admin and administrator can NOT be used.

.PARAMETER adminPassword
    requred parameter for the sql administrator password.
    will be checked for current azure rm password complexity requirements.

.PARAMETER credentials
    if specified, will be used for the sql administrator and password credentials
    NOTE: use (get-credential) as the argument.

.PARAMETER generateUniqueName
    if specified, will generate random sql server name which have to be globally unique

.PARAMETER nsgStartIpAllow
    if specified, ip address will be the starting range of ip addresses to allow

.PARAMETER nsgEndIpAllow
    if specified, ip address will be the ending range of ip addresses to allow

.PARAMETER maskPassword
    if specified, will not display provided password in connection string output

.PARAMETER listAvailable
    if specified, will list available sql servers and databases in resource gropup

.PARAMETER serviceTier
    if specified, will use the provided service tier.
    by default, will use cheapest tier 'Basic'
    https://docs.microsoft.com/en-us/azure/sql-database/sql-database-performance-guidance

.PARAMETER sqlServerVersion
    sql server version. default is 12.0
#>  

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,
    [string]$location,
    [string]$servername,
    [string]$adminUserName = "sql-administrator",
    [string]$adminPassword,
    [pscredential]$credentials,
    [string]$nsgStartIpAllow = "0.0.0.0",
    [string]$nsgEndIpAllow = "255.255.255.255",
    [string]$databaseName,
    [switch]$generateUniqueName,
    [switch]$maskPassword,
    [switch]$listAvailable,
    [switch]$nolog,
    [string]$serviceTier = "Basic", #cheapest
    [string]$sqlServerVersion = "12.0"
)

$erroractionpreference = "Continue"
$warningPreference = "Continue"
$logFile = "azure-rm-create-sql.log"
$script:credential = $null
$script:servername = $servername
$script:databasename = $databaseName
$script:createSqlServer = $false
$script:createSqlDatabase = $false

# ----------------------------------------------------------------------------------------------------------------
function main()
{
    log-info "$([System.DateTime]::Now):starting"

    if (!(Get-Module AzureRM -ListAvailable))
    {
        if ((read-host "powershell module azure rm sdk (azurerm) is required for this script. is it ok to install?[y|n]") -imatch "y")
        {
            Install-Module AzureRM
            Import-Module AzureRM
        }
        else
        {
            return
        }
    }

    # see if we need to auth
    authenticate-azureRm

    if ($listAvailable)
    {
        list-availableSqlServers
        return
    }

    if ($location)
    {
        log-info "checking location $($location)"

        if (!(Get-AzureRmLocation | Where-Object Location -Like $location) -or [string]::IsNullOrEmpty($location))
        {
            (Get-AzureRmLocation).Location
            write-warning "location: $($location) not found. supply -location using one of the above locations and restart script."
            exit 1
        }
    }

    log-info "checking for existing resource group $($resourceGroupName)"

    # create resource group if it does not exist
    $resourceGroupInfo = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

    if (!$resourceGroupInfo)
    {
        if ($location)
        {
            log-info "creating resource group $($resourceGroupName) in location $($location)"   
            New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
        }
        else
        {
            log-info "resource group does not exist and location not specified. exiting"
            exit 1
        }
    }
    else
    {
        log-info "resource group $($resourceGroupName) already exists."
        if (!$location)
        {
            $location = $resourceGroupInfo.Location
        }

    }

    # make sure sql available in region
    $sqlAvailable = Get-AzureRmSqlCapability -LocationName $location
    log-info "sql server capability in $($location) : $($sqlAvailable.Status)"

    if (!$sqlAvailable)
    {
        log-info "sql not available in this region. exiting"
        return
    }

    # verify edition
    $editions = $sqlAvailable.SupportedServerVersions.supportedEditions.EditionName
    if (!($editions -ieq $serviceTier))
    {
        log-info "please choose another service tier."
        log-info "tiers available in this location:"
        log-info $editions
        return
    }

    # verify version
    $versions = $sqlAvailable.SupportedServerVersions.ServerVersionName
    if (!($versions -ieq $sqlServerVersion))
    {
        log-info "please choose another version."
        log-info "versions available in this location:"
        log-info $versions
        return
    }

    $created = create-database
   
    if (!$created -and $generateUniqueName)
    {
        # retry 1 time in case of server name issue or db exists on server specified and -generateUniqueName was passed
        log-info "clearing server name and retrying 1 time"
        $script:servername = ""
        $created = create-database
    }

    if ($created)
    {
        if ($maskPassword -or !$script:createSqlServer)
        {
            $adminPassword = "{enter_sql_password_here}"
        }

        log-info "connection string ADO:`r`nServer=tcp:$($script:servername).database.windows.net,1433;Initial Catalog=$($script:databaseName);Persist Security Info=False;User ID=$($adminUserName);Password=$($adminPassword);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        $odbcString = "connection string ODBC Native client:`r`nDRIVER=SQL Server Native Client 11.0;Server=tcp:$($script:servername).database.windows.net,1433;Database=$($script:databaseName);Uid=$($adminUserName)@$($script:servername);Pwd=$($adminPassword);Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
        log-info $odbcString

        return $odbcString
    }

    return $false
}

# ----------------------------------------------------------------------------------------------------------------
function authenticate-azureRm()
{
    # make sure at least wmf 5.0 installed
    if ($PSVersionTable.PSVersion -lt [version]"5.0.0.0")
    {
        log-info "update version of powershell to at least wmf 5.0. exiting..." -ForegroundColor Yellow
        start-process "https://www.bing.com/search?q=download+windows+management+framework+5.0"
        # start-process "https://www.microsoft.com/en-us/download/details.aspx?id=50395"
        exit
    }

    #  verify NuGet package
    $nuget = get-packageprovider nuget -Force

    if (-not $nuget -or ($nuget.Version -lt [version]::New("2.8.5.22")))
    {
        log-info "installing nuget package..."
        install-packageprovider -name NuGet -minimumversion ([version]::New("2.8.5.201")) -force
    }

    $allModules = (get-module azure* -ListAvailable).Name
    #  install AzureRM module
    if ($allModules -inotcontains "AzureRM")
    {
        # at least need profile, resources, sql
        if ($allModules -inotcontains "AzureRM.profile")
        {
            log-info "installing AzureRm.profile powershell module..."
            install-module AzureRM.profile -force
        }
        if ($allModules -inotcontains "AzureRM.resources")
        {
            log-info "installing AzureRm.resources powershell module..."
            install-module AzureRM.resources -force
        }
        if ($allModules -inotcontains "AzureRM.compute")
        {
            log-info "installing AzureRm.compute powershell module..."
            install-module AzureRM.sql -force
        }
            
        Import-Module azurerm.profile        
        Import-Module azurerm.resources        
        Import-Module azurerm.sql            
    }
    else
    {
        Import-Module azurerm
    }

    # authenticate
    try
    {
        Get-AzureRmResourceGroup | Out-Null
    }
    catch
    {
        try
        {
            Add-AzureRmAccount
        }
        catch
        {
            log-info "exception authenticating. exiting $($error | out-string)" -ForegroundColor Yellow
            exit 1
        }
    }

    #Save-AzureRmContext -Path $profileContext -Force
}

# ----------------------------------------------------------------------------------------------------------------
function check-credentials()
{
    try
    {
        log-info "checking adminUserName account name $($adminUsername)"
        if ($adminUsername.ToLower() -eq "admin" -or $adminUsername.ToLower() -eq "administrator")
        {
            log-info "adminUserName cannot be 'admin' or 'administrator'. exiting"
            return
        }

        log-info "using admin name: $($adminUserName)"
        log-info "checking password"

        if (!$credentials)
        {
            if ([string]::IsNullOrEmpty($adminPassword))
            {
                $script:credential = Get-Credential
            }
            else
            {
                $SecurePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force  
                $script:credential = new-object Management.Automation.PSCredential -ArgumentList $adminUsername, $SecurePassword
            }
        }
        else
        {
            $script:credential = $credentials
        }

        $adminUsername = $script:credential.UserName
        $adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:credential.Password)) 
        $count = 0

        # uppercase check
        if ($adminPassword -match "[A-Z]") { $count++ }
        # lowercase check
        if ($adminPassword -match "[a-z]") { $count++ }
        # numeric check
        if ($adminPassword -match "\d") { $count++ }
        # specialKey check
        if ($adminPassword -match "\W") { $count++ } 

        if ($adminPassword.Length -lt 8 -or $adminPassword.Length -gt 123 -or $count -lt 3)
        {
            Write-warning @"
                azure password requirements at time of writing (3/2017):
                The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 
                    1) Contains an uppercase character
                    2) Contains a lowercase character
                    3) Contains a numeric digit
                    4) Contains a special character.
        
                correct password and restart script. 
"@
            exit 1
        }

        return $true
    }
    catch
    {
        log-info "exception: checking credentials $($error)"
        $error.Clear()
        return $false
    }
}

# ----------------------------------------------------------------------------------------------------------------
function create-database()
{
    $script:createSqlServer = $false
    $script:createSqlDatabase = $false
    $sqlServersAvailable = @(enum-sqlServers -sqlServer $script:servername -resourceGroup $resourceGroupName)

    if (!$generateUniqueName -and $sqlServersAvailable.Count -gt 0 -and !$script:servername)
    {
        log-info $sqlServersAvailable
        $script:servername = read-host "enter server name to use for new database"
    }
    elseif (!$script:servername -and $generateUniqueName)
    {
        $script:servername = "sql-server-$(Get-Random)"
        log-info "server name not provided. using random name $($script:servername)"
    }

    if (!$script:serverName)
    {
        log-info "error: need server name or use -generateUniqueName. exiting"
        return $false
    }

    if ($sqlServersAvailable.Count -lt 1 -or $sqlServersAvailable.ServerName -inotmatch $script:servername)
    {
        $script:createSqlServer = $true
    }
    
    if (!$script:databasename -and $generateUniqueName)
    {
        $script:databasename = "sql-database-$(Get-Random)"
        log-info "database name not provided. using random name $($script:databasename)"
    }

    if (!$script:createSqlServer)
    {
        # for odbc string in case server wasnt created
        $adminUserName = (enum-sqlServers -resourceGroup $resourceGroupName -sqlServer $script:servername).SqlAdministratorLogin

        # if database name specified / generated and it exists, exit
        $sqlDatabasesAvailable = @(enum-sqlDatabases -sqlServer $script:servername -resourceGroup $resourceGroupName)

        if ($script:databasename -and $sqlDatabasesAvailable.DatabaseName -imatch $script:databasename)
        {
            log-info "error: database $($script:databaseName) already exists on server $($script:servername). exiting"
            return $false
        }
    }
   
    if ($script:databasename)
    {
        $script:createSqlDatabase = $true
    }

    # everything should be populated, if not exit
    if (!$script:createSqlServer -and !$script:createSqlDatabase)
    {
        log-info "error:invalid configuration. see help. exiting"
        return $false
    }

    log-info "using server name $($script:servername)"
    log-info "creating sql server : $($script:createSqlServer) creating sql db : $($script:createSqlDatabase)"
    $error.Clear()

    try
    {
        if ($script:createSqlServer)
        {
            log-info "create a logical server"
            if (!(check-credentials))
            {
                return $false
            }

            $ret = New-AzureRmSqlServer -ResourceGroupName $resourceGroupName `
                -ServerName $script:servername `
                -Location $location `
                -SqlAdministratorCredentials $script:credential `
                -ServerVersion $sqlServerVersion

            if ($error)
            {
                log-info "error creating sql server. returning: $($error)"
                $error.Clear()
                return $false
            }

            log-info "create a logical server result:"
            log-info $ret

            log-info "configure a server firewall rule"
            $ret = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname `
                -ServerName $script:servername `
                -FirewallRuleName "AllowSome" -StartIpAddress $nsgStartIpAllow -EndIpAddress $nsgEndIpAllow

            if ($error)
            {
                log-info "error creating sql server. returning: $($error)"
                $error.Clear()
                return $false
            }

            log-info "configure a logical server firewall result:"
            log-info $ret
        }

        if ($script:createSqlDatabase)
        {
            log-info "creating empty database $($script:databasename)"

            $ret = New-AzureRmSqlDatabase  -ResourceGroupName $resourceGroupName `
                -ServerName $script:servername `
                -DatabaseName $script:databaseName `
                -RequestedServiceObjectiveName $serviceTier

            if ($error)
            {
                log-info "error creating sql database. returning: $($error)"
                $error.Clear()
                return $false
            }

            log-info "create database result:"
            log-info $ret
        }

        return $true
    }
    catch
    {
        log-info "error:$($error)"
        return $false
    }
}

# ----------------------------------------------------------------------------------------------------------------
function enum-sqlDatabases($sqlServer, $resourceGroup)
{
    if (!$sqlServer)
    {
        return $false
    }
    
    log-info "checking sql dbs on server $($sqlServer)"
    $sqlDatabasesAvaliable = @()

    if (!$script:databasename)
    {
        $sqlDatabasesAvaliable = @(Get-AzureRmSqlDatabase -ServerName $sqlServer -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue)
    }
    else
    {
        $sqlDatabasesAvaliable = @(Get-AzureRmSqlDatabase -ServerName $sqlServer -ResourceGroupName $resourceGroup -DatabaseName $script:databasename -ErrorAction SilentlyContinue)
    }
    return $sqlDatabasesAvaliable
}

# ----------------------------------------------------------------------------------------------------------------
function enum-sqlServers($resourceGroup, $sqlServer)
{
    log-info "checking for sql servers in resource group $($resourceGroup)"
    $serverInfo = @()

    if (!$sqlServer)
    {
        $serverInfo = @(Get-AzureRmSqlServer -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue)
        
    }
    else
    {
        $serverInfo = @(Get-AzureRmSqlServer -ServerName $sqlServer -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue)
    }
    
    return $serverInfo        
}

# ----------------------------------------------------------------------------------------------------------------
function list-availableSqlServers()
{
    $sqlServersAvailable = new-object Collections.ArrayList

    if ($resourceGroupName -eq "*")
    {
        $resourceGroups = @((Get-AzureRmResourceGroup).ResourceGroupName)
    }
    else
    {
        $resourceGroups = @($resourceGroupName)
    }

    foreach ($resourceGroup in $resourceGroups)
    {
        $serverInfo = @(enum-sqlServers -resourceGroup $resourceGroup)

        foreach ($server in $serverInfo.ServerName)
        {
            log-info "--------------------------------"
            log-info "--------------------------------"
            log-info " SQL SERVER: $($server)"
            log-info "--------------------------------"
            log-info "--------------------------------"

            $dbInfo = @(enum-sqlDatabases -sqlServer $server -resourceGroup $resourceGroup)
            
            foreach ($db in $dbInfo)
            {
                log-info "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
                log-info $db
                log-info "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
            }
            
            $dbCount += $dbInfo.Count    
        }
        
        $sqlCount += $serverInfo.Count
    }

    log-info "sql servers available: $($sqlCount) sql databases available: $($dbCount)"
}

# ----------------------------------------------------------------------------------------------------------------
function log-info($data)
{
    $data = $($data | format-list * | out-string)

    if ($data -imatch "error|warning|exception|fail|terminate")
    {
        Write-Warning $data
    }
    else
    {
        write-host $data
    }

    if (!$nolog)
    {
        out-file -Append -InputObject $data -FilePath $logFile
    }
}
# ----------------------------------------------------------------------------------------------------------------

main
log-info "$([System.DateTime]::Now):finished"