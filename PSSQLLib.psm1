################################################################################
#  Written by Sander Stad, SQLStad.nl
# 
#  (c) 2016, SQLStad.nl. All rights reserved.
# 
#  For more scripts and sample code, check out http://www.SQLStad.nl
# 
#  You may alter this code for your own *non-commercial* purposes (e.g. in a
#  for-sale commercial tool). Use in your own environment is encouraged.
#  You may republish altered code as long as you include this copyright and
#  give due credit, but you must obtain prior permission before blogging
#  this code.
# 
#  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
#  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
#  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
#  PARTICULAR PURPOSE.
#
#  Changelog:
#  v1.0: 
#    Initial version
#  v1.1: 
#    Added several functions for hosts
#  v1.2: 
#    Added functionality to get the host system information
#    Cleaned up code, make it more readable
#    Changed parameters to be consistent throughout functions
#  v1.3: 
#    Added extra error catching
#  v1.3.1: 
#    Added function for retrieving disk latencies
#  v1.3.2:
#    Added functionality for retrieving backups
#  v1.3.3:
#    Added functionality for retrieving the system uptime
#    Added functionality for retrieving the instance uptime
#  v1.4.0
#    Added structures to the functions
#  v1.4.1
#    Added functionality for using ports connecting to SQL Server
#    Changed the try/catch procedures to catch more error and work more efficiently
#  v1.5
#    Added functionality to export database objects to .sql script files
#    Changed the error messages in the functions to be more descriptive
#  v1.5.1
#    Added functionality to export SQL Server objects to .sql script files
################################################################################

function Get-HostHarddisk
{
    <# 
    .SYNOPSIS
        Checks the host's harddisks
    .DESCRIPTION
        The function return the data of all the drives with size, available space, percentage used etc
    .PARAMETER hst
        This is the host that needs to be connected
    .EXAMPLE
        Get-HostHarddisk "SQL01"
    .EXAMPLE
        Get-HostHarddisk -hst "SQL01"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$hst = $null
    )

    try
    {
        # Get the data
	    $drives= Get-WmiObject -Class Win32_LogicalDisk -Computername $hst -Errorvariable errorvar | Where {$_.drivetype -eq 3}

        # Create the result array
        $result = @()

        # Get the results
        $result = $drives | Select -property `
		    @{N="Disk";E={$_.DeviceID}},VolumeName, `
		    @{N="FreeSpaceMB";E={"{0:N2}" -f ($_.Freespace/1Mb)}}, `
		    @{N="SizeMB";E={"{0:N2}" -f ($_.Size/1Mb)}}, `
		    @{N="PercentageUsed";E={"{0:N2}" -f (($_.Size - $_.FreeSpace) / $_.Size * 100)}}

        return $result
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}

function Get-HostHardware
{
    <# 
    .SYNOPSIS
        Checks the host's hardware
    .DESCRIPTION
        The function return the data of hardware in de host like number of processors
        manufacturer, current timezone etc
    .PARAMETER hst
        This is the host that needs to be connected
    .EXAMPLE
        Get-HostHardware "SQL01"
    .EXAMPLE
        Get-HostHardware -hst "SQL01"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$hst = $null
    )

    try
    {
        # Get the data
	    $computer = Get-Wmiobject -Class win32_computersystem -Computername $hst -Errorvariable errorvar

        $result = @()

        # Get the result
        $result = $computer | Select Description,NumberOfLogicalProcessors,NumberOfProcessors, `
		    @{N="TotalPhysicalMemoryGB";E={"{0:N2}" -f ($_.TotalPhysicalMemory/1Gb)}}, `
		    Model,Manufacturer,PartOfDomain,CurrentTimeZone,DaylightInEffect

        # Return the result
        return $result
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}

function Get-HostOperatingSystem
{
    <# 
    .SYNOPSIS
        Checks the host's OS
    .DESCRIPTION
        The function return the data of OS in de host like the architecture,
        the OS language, the version etc
    .PARAMETER hst
        This is the host that needs to be connected
    .EXAMPLE
        Get-HostOperatingSystems "SQL01"
    .EXAMPLE
        Get-HostOperatingSystems -hst "SQL01"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$hst = $null
    )

    try
    {
        # Get the data
        $os = Get-WmiObject -Class win32_operatingsystem -Computername $hst -Errorvariable errorvar

        $result = @()

        # Get the results
        $result = $os | Select `
		    OSArchitecture,OSLanguage,OSProductSuite,OSType,BuildNumbe,`
		    BuildType,Version,WindowsDirectory,PlusVersionNumber,`
		    @{N="FreePhysicalMemoryMB";E={"{0:N2}" -f ($_.FreePhysicalMemory / 1Mb)}},`
		    @{N="FreeSpaceInPagingFilesMB";E={"{0:N2}" -f ($_.FreeSpaceInPagingFiles)}},`
		    @{N="FreeVirtualMemoryMB";E={"{0:N2}" -f ($_.FreeVirtualMemory)}},`
		    PAEEnabled,ServicePackMajorVersion,ServicePackMinorVersion

        #return the result
        return $result
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

}

function Get-HostSQLServerServices
{
    <# 
    .SYNOPSIS
        Get the SQL Server services
    .DESCRIPTION
        The function return all the services present on the server regarding SQL Server
    .PARAMETER hst
        This is the host that needs to be connected
    .EXAMPLE
        Get-HostSQLServerServices "SQL01"
    .EXAMPLE
        Get-HostSQLServerService -hst "SQL01"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$hst = $null
    )

    try
    {
        return Get-WmiObject win32_Service -Computer $hst | where {$_.DisplayName -match "SQL Server"} | `
		    select SystemName, DisplayName, Name, State, Status, StartMode, StartName 
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}

function Get-HostSystemInformation()
{
	<# 
    .SYNOPSIS
        Get the system information of the host
    .DESCRIPTION
        Select information from the system like the domain, manufacturer, model etc.
    .PARAMETER hst
        This is the host that needs to be connected
    .EXAMPLE
        Get-HostSystemInformation "SQL01"
    .EXAMPLE
        Get-HostSystemInformation -hst "SQL01"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$hst = $null
    )

    try
    {
        $data = Get-WmiObject -class "Win32_ComputerSystem" -Namespace "root\CIMV2" -ComputerName $hst
            
        $result = @()
        $result = $data | Select `
            Name,Domain,Manufacturer,Model, `
            NumberOfLogicalProcessors,NumberOfProcessors,LastLoadInfo, `
            @{Name='TotalPhysicalMemoryMB';Expression={[math]::round(($_.TotalPhysicalMemory / 1024 / 1024))}}


        return $result

    }
    catch
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

}

function Get-HostUptime
{
     <# 
    .SYNOPSIS
        Get the uptime of the host
    .DESCRIPTION
        The script will retrieve the boot time and local time.
        Based on the start time the uptime will be calculated.
    .PARAMETER hst
        This is the instance that needs to be connected
    .EXAMPLE
        Get-HostUptime "SQL01"
	.EXAMPLE
        Get-HostUptime -hst "SQL01"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$hst = $env:COMPUTERNAME
        , [Parameter(Mandatory = $false, Position=2)]
        $cred = [System.Management.Automation.PSCredential]::Empty 
    )

    try 
    { 
        $os = Get-WmiObject win32_operatingsystem -ComputerName $hst -ErrorAction Stop -Credential $cred
        
        $result = @()

        $bootTime = $os.ConvertToDateTime($os.LastBootUpTime) 
        $uptime = $os.ConvertToDateTime($os.LocalDateTime) - $bootTime

        $uptimeString = $uptime.Days.ToString() + " Day(s) " + $uptime.Hours.ToString() + ":" + $uptime.Minutes.ToString() + ":" + $uptime.Seconds.ToString()

        $result = $os | Select -property `
            @{N="BootTime";E={$bootTime}}, `
            @{N="Uptime";E={$uptimeString}} 


        return $result
    } 
    catch [Exception] 
    { 
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

}

##################################################

function Get-SQLAgentJobs
{ 
    <# 
    .SYNOPSIS
        Returns the SQL Server jobs 
    .DESCRIPTION
        The function return all the jobs present in the SQL Server with information
        like the jobtype, enabled or not, date created, last run date etc.
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLAgentJobs "SQL01"
    .EXAMPLE
        Get-SQLAgentJobs "SQL01\INST01"
    .EXAMPLE
        Get-SQLAgentJobs "SQL01\INST01" 4321
    .EXAMPLE
        Get-SQLAgentJobs -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLAgentJobs -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )


    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Get the jobs
        $server.JobServer.Jobs

        # Create the result array
        $result = @()

        # Get the results
        $result = $jobs | Select `
		    Name,JobType,IsEnabled,DateCreated,DateLastModified,LastRunDate,`
		    LastRunOutcome,NextRunDate,OwnerLoginName,Category | Sort-Object Name 

        # Return the result
        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

}

function Get-SQLConfiguration
{
    <# 
    .SYNOPSIS
        Get the contents of the configuration of the instance
    .DESCRIPTION
        The script will connect to the instance and execute a query to get the 
        configuration settings. It wil return a table with the configurations.
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLConfiguration "SQL01"
    .EXAMPLE
        Get-SQLConfiguration "SQL01\INST01"
    .EXAMPLE
        Get-SQLConfiguration "SQL01\INST01" 4321
    .EXAMPLE
        Get-SQLConfiguration -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLConfiguration -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )

    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
                
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Define the array
        $result = @()

        # Get the configurations
        $configuration = $server.Configuration

        # Get all the properties
        $result = $configuration.Properties 

        # Return the result
        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

    
}

function Get-SQLDatabaseFiles
{
    <# 
    .SYNOPSIS
        Get the database files for each database 
    .DESCRIPTION
        The function return all the database files from all databases
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .PARAMETER dbfilter
        This is used to return only show details on certain databases
    .EXAMPLE
        Get-Get-SQLDatabaseFiles "SQL01"
    .EXAMPLE
        Get-Get-SQLDatabaseFiles "SQL01\INST01"
    .EXAMPLE
        Get-Get-SQLDatabaseFiles "SQL01\INST01" 4321
    .EXAMPLE
        Get-Get-SQLDatabaseFiles -inst "SQL01\INST01"
    .EXAMPLE
        Get-Get-SQLDatabaseFiles -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )

    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Define the array
        $dataFiles = @()
        $logFiles = @()
        $result = @()
        # Get all the databases
        $databases = $server.Databases

        # Loop through all the databases
        foreach($database in $databases)
        {
            try{
                # Get the filegroups for the database
                $filegroups = $database.FileGroups

                # Loop through all the filegroups
                foreach($filegroup in $filegroups)
                {
                    # Get all the data files from the filegroup
                    $files = $filegroup.Files

                    # Loop through all the data files
                    foreach($file in $files)
                    {
                        $result += $file | Select `
					        @{Name="DatabaseName"; Expression={$database.Name}}, Name, `
					        @{Name="FileType";Expression={"ROWS"}}, `
					        @{Name="Directory"; Expression={$file.FileName | Split-Path -Parent}}, `
					        @{Name="FileName"; Expression={$file.FileName | Split-Path -Leaf}}, `
					        Growth, GrowthType, Size, UsedSpace
                    }
                }

                # Get all the data files from the filegroup
                $files = $database.LogFiles

                # Loop through all the log files
                foreach($file in $files)
                {
                    $result += $file | Select `
				        @{Name="DatabaseName"; Expression={$database.Name}}, Name, `
				        @{Name="FileType";Expression={"LOG"}}, `
				        @{Name="Directory"; Expression={$file.FileName | Split-Path -Parent}}, `
				        @{Name="FileName"; Expression={$file.FileName | Split-Path -Leaf}}, `
				        Growth, GrowthType, Size, UsedSpace
                }
            } 
            catch{
            
            } 

        }

        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

    
}

function Get-SQLDatabasePrivileges
{
    <# 
    .SYNOPSIS
        Gets the users in the database and looks up the roles
    .DESCRIPTION
        The function return all the database users with their roles in the database
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLDatabasePrivileges "SQL01"
    .EXAMPLE
        Get-SQLDatabasePrivileges "SQL01\INST01"
    .EXAMPLE
        Get-SQLDatabasePrivileges "SQL01\INST01" 4321
    .EXAMPLE
        Get-SQLDatabasePrivileges -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLDatabasePrivileges -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )
    
    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Create the result array
        $result = @()

        # Create the memberRoles array
        $userRoles = @()

        # Get all the databases
        $databases = $server.Databases
    
        # Loop through the databases
        foreach($database in $databases)
        {
            # Get all the logins
            $users = $database.Users
        
            # Get all the roles
            $roles = $database.Roles
        
            # Loop through the logins
            foreach($user in $users)
            {
                # Check if user is not a system user
                if(
				    ($user.Name -ne "dbo") `
				    -and ($user.Name -notlike "##*") `
				    -and ($user.Name -ne "INFORMATION_SCHEMA") `
				    -and ($user.Name -ne "sys") `
				    -and ($user.Name -ne "guest"))
                {

                    # Loop through the roles
                    foreach($role in $roles)
                    {
                        # Get all the members of the role
                        $roleMembers = $role.EnumMembers()

                        # Check if the login is in the list
                        if($roleMembers -contains $user.Name)
                        {
                            $userRoles += $role.Name
                        }
                    }

                    # Combine the results
                    $result += $database | Select `
					    @{N="DatabaseName";E={$database.Name}},`
					    @{N="UserName";E={$user.Name}},`
					    @{N="UserType"; E={$user.LoginType}},`
					    @{N="DatabaseRoles";E={([string]::Join(",", $userRoles))}}
                }

                # Clear the array
                $userRoles = @()
            }
        }

        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}

function Get-SQLDatabases
{
    <# 
    .SYNOPSIS
        Get the SQL Server database settings
    .DESCRIPTION
        This function gets the settings of the prent databases and returns
        the data in the form of a table.
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-Get-SQLDatabases "SQL01"
    .EXAMPLE
        Get-Get-SQLDatabases "SQL01\INST01"
    .EXAMPLE
        Get-Get-SQLDatabases "SQL01\INST01" 4321
    .EXAMPLE
        Get-Get-SQLDatabases -inst "SQL01\INST01"
    .EXAMPLE
        Get-Get-SQLDatabases -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )

    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Define the array
        $result = @()
        # Get all the databases
        $databases = $server.Databases

        # Get the properties of each database
        $result = $databases | Select `
		    ID,Name,AutoClose,AutoCreateIncrementalStatisticsEnabled,`
		    AutoCreateStatisticsEnabled,AutoShrink,AutoUpdateStatisticsAsync,AutoUpdateStatisticsEnabled,`
		    AvailabilityGroupName,CloseCursorsOnCommitEnabled,Collation,`
		    CompatibilityLevel,CreateDate,DataSpaceUsage,`
		    DelayedDurability,EncryptionEnabled,HasDatabaseEncryptionKey,HasFileInCloud,HasFullBackup,`
		    IndexSpaceUsage,IsDbSecurityAdmin,IsFullTextEnabled,IsManagementDataWarehouse,IsMirroringEnabled,`
		    LastBackupDate,LastDifferentialBackupDate,LastLogBackupDate,`
		    Owner,PageVerify,PolicyHealthState,PrimaryFilePath,ReadOnly,`
		    RecoveryModel,RecursiveTriggersEnabled,Size,SnapshotIsolationState,SpaceAvailable,`
		    Status,TargetRecoveryTime,Trustworthy,UserAccess,UserName,Version 

        # Return the result
        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

    
}

function Get-SQLDatabaseUsers
{
    <# 
    .SYNOPSIS
        Get the database users 
    .DESCRIPTION
        The function returns all the database users present
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .PARAMETER dbfilter
        This is used to return only show details on certain databases
    .EXAMPLE
        Get-SQLDatabaseUsers "SQL01"
    .EXAMPLE
        Get-SQLDatabaseUsers "SQL01\INST01"
    .EXAMPLE
        Get-SQLDatabaseUsers "SQL01\INST01" 4321
    .EXAMPLE
        Get-SQLDatabaseUsers -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLDatabaseUsers -inst "SQL01\INST01" -port 4321
    .EXAMPLE
        Get-SQLDatabaseUsers -inst "SQL01\INST01" -port 4321 -dbfilter "tempdb,msdb"
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
		[Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
		, [Parameter(Mandatory = $false, Position=3)]
        [ValidateNotNullOrEmpty()]
        [string]$dbfilter = $null
    )
    
    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Create the result array
        $result = @()

        # Get all the databases
        $databases = $server.Databases

        # Loop through the databases
        foreach($database in $databases)
        {
            # Get the database users
            $databaseUsers = $database.Users 

            # Get the result
            $result += $databaseUsers | Select `
			    Parent,Name,AsymmetricKey,AuthenticationType,Certificate,`
			    CreateDate,DateLastModified,DefaultLanguageLcid,DefaultLanguageName,`
			    DefaultSchema,HasDBAccess,ID,IsSystemObject,Login,LoginType,`
			    PolicyHealthState,Sid,UserType 
        }
    
        # Return the results
        return $result 
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
    
}

function Get-SQLDiskLatencies
{
    <# 
    .SYNOPSIS
        Get the latencies SQL Server registered on disk
    .DESCRIPTION
        The script will execute a query against the instance and retrieve
        the read and write latencies which SQL Server collected.
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLDiskLatencies "SQL01"
    .EXAMPLE
        Get-SQLDiskLatencies "SQL01\INST01"
    .EXAMPLE
        Get-SQLDiskLatencies "SQL01\INST01" 4321
	.EXAMPLE
        Get-SQLDiskLatencies -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLDiskLatencies -inst "SQL01\INST01" port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )

    $query = '
        SELECT 
            DB_NAME(vfs.database_id) AS [Database],
            LEFT (mf.physical_name, 2) AS [Drive],
            mf.physical_name AS [PhysicalFileName],
            --virtual file latency
            CASE WHEN num_of_reads = 0
                THEN 0 ELSE (io_stall_read_ms / num_of_reads) END AS [ReadLatency],
            CASE WHEN num_of_writes = 0 
                THEN 0 ELSE (io_stall_write_ms / num_of_writes) END AS [WriteLatency],
            CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
                THEN 0 ELSE (io_stall / (num_of_reads + num_of_writes)) END AS [Latency],
            --avg bytes per IOP
            CASE WHEN num_of_reads = 0 
                THEN 0 ELSE (num_of_bytes_read / num_of_reads) END AS [AvgBPerRead],
            CASE WHEN io_stall_write_ms = 0 
                THEN 0 ELSE (num_of_bytes_written / num_of_writes) END AS [AvgBPerWrite],
            CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
                THEN 0 ELSE ((num_of_bytes_read + num_of_bytes_written) / 
                    (num_of_reads + num_of_writes)) END AS [AvgBPerTransfer],    
            num_of_reads AS [CountReads],
            num_of_writes AS [CountWrites],
            (num_of_reads+num_of_writes) AS [CountTotalIO],
            CONVERT(NUMERIC(10,2),(CAST(num_of_reads AS FLOAT)/ CAST((num_of_reads+num_of_writes) AS FLOAT) * 100)) AS [PercentageRead],
            CONVERT(NUMERIC(10,2),(CAST(num_of_writes AS FLOAT)/ CAST((num_of_reads+num_of_writes) AS FLOAT) * 100)) AS [PercentageWrite]
        FROM sys.dm_io_virtual_file_stats (NULL,NULL) AS vfs
        JOIN sys.master_files AS mf
            ON vfs.database_id = mf.database_id
            AND vfs.file_id = mf.file_id
        ORDER BY DB_NAME(vfs.database_id);
        GO
    '

    try{
        $result = Invoke-Sqlcmd -ServerInstance $inst -Query $query
    }
    catch [Exception]
    {
       $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
        

    return $result
}

function Get-SQLInstanceSettings
{
    <# 
    .SYNOPSIS
        Get the SQL Server instance settings
    .DESCRIPTION
        This function gets the settings of the instance and return
        the data in the form of a table.
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLInstance "SQL01"
    .EXAMPLE
        Get-SQLInstance "SQL01\INST01"
    .EXAMPLE
        Get-SQLInstance "SQL01\INST01" 4321
    .EXAMPLE
        Get-SQLInstance -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLInstance -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )

    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Define the array
        $result = @()

        # Get the instance settings
        $result = $server | Select `
		    AuditLevel,BackupDirectory,BrowserServiceAccount,BrowserStartMode,BuildClrVersionString,`
		    BuildNumber,ClusterName,ClusterQuorumState,ClusterQuorumType,Collation,CollationID,`
		    ComparisonStyle,ComputerNamePhysicalNetBIOS,DefaultFile,DefaultLog,Edition,ErrorLogPath,`
		    FilestreamLevel,FilestreamShareName,HadrManagerStatus,InstallDataDirectory,InstallSharedDirectory,`
		    InstanceName,IsCaseSensitive,IsClustered,IsFullTextInstalled,IsHadrEnabled,IsSingleUser,IsXTPSupported,`
		    Language,LoginMode,MailProfile,MasterDBLogPath,MasterDBPath,MaxPrecision,NamedPipesEnabled,NetName,`
		    NumberOfLogFiles,OSVersion,PerfMonMode,PhysicalMemory,PhysicalMemoryUsageInKB,Platform,Processors,`
		    ProcessorUsage,Product,ProductLevel,ResourceLastUpdateDateTime,ResourceVersionString,RootDirectory,`
		    ServerType,ServiceAccount,ServiceInstanceId,ServiceName,ServiceStartMode,SqlCharSet,SqlCharSetName,`
		    SqlDomainGroup,SqlSortOrder,SqlSortOrderName,Status,TapeLoadWaitTime,TcpEnabled,VersionMajor,VersionMinor,`
		    VersionString,Name,Version,EngineEdition,ResourceVersion,BuildClrVersion,DefaultTextMode 

        # Return the result
        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}

function Get-SQLInstanceUptime
{
    <# 
    .SYNOPSIS
        Get the uptime of the SQL Server instance
    .DESCRIPTION
        The script will execute a query against the instance and retrieve
        the start time. Based on the start time the uptime will be calculated.
        This function can be used from SQL Server 2008 or later
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLInstanceUptime "SQL01"
    .EXAMPLE
        Get-SQLInstanceUptime "SQL01\INST01"
    .EXAMPLE
        Get-SQLInstanceUptime "SQL01\INST01" 4321
	.EXAMPLE
        Get-SQLInstanceUptime -inst "SQL01\INST01"
	.EXAMPLE
        Get-SQLInstanceUptime -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )

    $query = "
        DECLARE	@start_time DATETIME ,
	        @end_time DATETIME ,
	        @difference DATETIME;

        SELECT	@start_time = sqlserver_start_time ,
		        @end_time = GETDATE() ,
		        @difference = @end_time - @start_time
        FROM	sys.dm_os_sys_info;

        SELECT	@start_time AS [start_time] ,
		        CONVERT(VARCHAR(10), DATEPART(DAY, @difference) - 1) + ' Day(s) '
		        + RIGHT(CONVERT(VARCHAR(10), 100 + DATEPART(HOUR, @difference)), 2)
		        + ':' + RIGHT(CONVERT(VARCHAR(10), 100 + DATEPART(MINUTE, @difference)),
					            2) + ':' + RIGHT(CONVERT(VARCHAR(10), 100
									            + DATEPART(SECOND, @difference)), 2) AS [uptime]
    "

    try{
        $result = Invoke-Sqlcmd -ServerInstance $inst -Query $query
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

    return $result
}

function Get-SQLServerBackups
{
    <# 
    .SYNOPSIS
        Get the database backups
    .DESCRIPTION
        The function will return a list of backups over the last x days.
        The default amount of days is 7 days.
        
        It's possible to enter multiple databases in the database filter parameter.
        Just seperate the databases with a comma (,)

        It's possible to enter multiple backup types in the backup type filter parameter.
        Just seperate the backup types with a comma (,)
        Possible backup types are:
            - D: Full back (database backup)
            - I: Incremental
            - L: Log backup
    .PARAMETER instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLServerBackups "SQL01"
    .EXAMPLE
        Get-SQLServerBackups "SQL01\INST01"
    .EXAMPLE
        Get-SQLServerBackups "SQL01\INST01" 4321
	.EXAMPLE
        Get-SQLServerBackups -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLServerBackups -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
        , [Parameter(Mandatory = $false, Position=3)]
        [int]$days = 7
        , [Parameter(Mandatory = $false, Position=4)]
        [string]$databaseFilter = $null
        , [Parameter(Mandatory = $false, Position=5)]
        [string]$backupTypeFilter = $null
        
    )
    
    # Setup the query
    $query = " 
        SELECT 
	        '$inst' AS [server_name],
	        bs.database_name AS [database_name], 
	        bs.backup_start_date AS [start_date], 
	        bs.backup_finish_date AS [finish_date],
	        DATEDIFF(mi, bs.backup_start_date, bs.backup_finish_date) AS [duration],
	        bs.expiration_date [experation_date],
	        CASE bs.type 
		        WHEN 'D' THEN 'Full' 
		        WHEN 'I' THEN 'Differential'
		        WHEN 'L' THEN 'Log' 
	        END AS [backup_type], 
	        CAST((bs.backup_size / 1024/ 1024) AS INT) AS [size_mb], 
	        bmf.logical_device_name AS [logical_device_name], 
	        bmf.physical_device_name AS [physical_device_name],  
	        bs.name AS [backup_set],
	        bs.description AS [description]
        FROM
	        msdb.dbo.backupmediafamily bmf
        INNER JOIN msdb.dbo.backupset bs
	        ON bmf.media_set_id = bs.media_set_id 
        WHERE
	        bs.backup_start_date >= DATEADD(d, -$days, GETDATE()) 
    "
    
    if($databaseFilter.Length -ge 1) 
    {
        if($databaseFilter.Contains(","))
        {
            $databaseFilter = $databaseFilter.Replace(" ", "")
            $databaseFilter = $databaseFilter.Replace(",", "','")
            $databaseFilter = $databaseFilter.Insert(0, "'").Insert(($databaseFilter.Length + 1), "'")

            $query += "AND bs.database_name IN ($databaseFilter) "
        }
        else
        {
            $query += "AND bs.database_name = '$databaseFilter' "
        }
    }

    if($backupTypeFilter.Length -ge 1)
    {
        if($backupTypeFilter.Contains(","))
        {
            $backupTypeFilter = $backupTypeFilter.Replace(" ", "").ToUpper()
            $backupTypeFilter = $backupTypeFilter.Replace(",", "','")
            $backupTypeFilter = $backupTypeFilter.Insert(0, "'").Insert(($backupTypeFilter.Length + 1), "'")

            $query += "AND bs.type IN ($backupTypeFilter) "
        }
        else
        {
            $backupTypeFilter = $backupTypeFilter.ToUpper()
            $query += "AND bs.type = '$backupTypeFilter' "
        }
    }

    try{
        $result = Invoke-Sqlcmd -ServerInstance $inst -Query $query
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }

    return $result
}

function Get-SQLServerPrivileges
{
    <# 
    .SYNOPSIS
        Returns each server login with their server roles
    .DESCRIPTION
        This function will return all the logins on the database server
        and check whether they are member of a server role.
    .PARAMETER  instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .EXAMPLE
        Get-SQLServerPrivileges "SQL01"
    .EXAMPLE
        Get-SQLServerPrivileges "SQL01\INST01"
    .EXAMPLE
        Get-SQLServerPrivileges "SQL01\INST01" 4321
    .EXAMPLE
        Get-SQLServerPrivileges -inst "SQL01\INST01"
    .EXAMPLE
        Get-SQLServerPrivileges -inst "SQL01\INST01" -port 4321
    .INPUTS
    .OUTPUTS
        System.Array
    .NOTES
    .LINK
    #>
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433'
    )
    
    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'
        
    # Create the server object and retrieve the information
    try{
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Create the result array
        $result = @()

        # Create the array for the server roles
        $serverRoles = @()

        # Get all the logins
        $logins = $server.Logins

        # Loop through the logins
        foreach($login in $logins)
        {
        
            if(($login.Name -notlike "##*"))
            {
                # Get all the server
                $serverRoles = ($login.ListMembers()) -join ","

                # Make the result
                if($serverRoles.Count -gt 1)
                {
                    $result += $login | Select `
					    Name,LoginType,CreateDate,DateLastModified,IsDisabled,`
					    @{N="ServerRoles";E=([string]::Join(",", $serverRoles))} | Sort-Object Name 
                }
                else
                {
                    $result += $login | Select `
					    Name,LoginType,CreateDate,DateLastModified,IsDisabled,`
					    @{N="ServerRoles";E={$serverRoles}} | Sort-Object Name 
                }

                # Clear the array
                $serverRoles = @()
            }
        }

        return $result
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }  
}


function Export-DatabaseObject
{
    <# 
    .SYNOPSIS
        Generates export files of database objects
    .DESCRIPTION
        This function will return generate an export file of database objects to a .sql file.
        This includes tables, views, stored procedures and user defined functions.
    .PARAMETER  instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .PARAMETER path
        Path to export to
    .PARAMETER dblist
        List with databases to export. Is comma seperated.
    .PARAMETER includetimestamp
        Boolean to include a timestamp directory to export to
    .PARAMETER includetables
        Boolean to include or exclude tables. Can be value $false/$true or 0/1.
    .PARAMETER includeviews
        Boolean to include or exclude views. Can be value $false/$true or 0/1.
    .PARAMETER includesp
        Boolean to include or exclude stored procedures. Can be value $false/$true or 0/1.
    .PARAMETER includeudf
        Boolean to include or exclude user defined functions. Can be value $false/$true or 0/1.
    .EXAMPLE
        Export-DatabaseObject "SQL01" -path 'C:\Temp\export'
    .EXAMPLE
        Export-DatabaseObject -inst "SQL01\INST01" -path 'C:\Temp\export'
    .EXAMPLE
        Export-DatabaseObject -inst "SQL01\INST01" 4321 -path 'C:\Temp\export'
    .EXAMPLE
        Export-DatabaseObject -inst "SQL01\INST01" -dblist 'db1,db2' -path 'C:\Temp\export'
    .EXAMPLE
        Export-DatabaseObject -inst "SQL01\INST01" -includeudf $false -path 'C:\Temp\export'
    .INPUTS
    .OUTPUTS
        Script files
    .NOTES
    .LINK
    #>
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()][string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433',
        [Parameter(Mandatory = $true, Position=3)]
        [ValidateNotNullOrEmpty()][string]$path = $null,
        [Parameter(Mandatory = $false, Position=4)]
        [string]$dblist = 'ALL',
        [Parameter(Mandatory = $false, Position=5)]
        [Alias("timestamp")]
        [bool]$includetimestamp = $true,
        [Parameter(Mandatory = $false, Position=6)]
        [Alias("inct")]
        [bool]$includetables = $true,
        [Parameter(Mandatory = $false, Position=7)]
        [Alias("incv")]
        [bool]$includeviews = $true,
        [Parameter(Mandatory = $false, Position=8)]
        [Alias("incsp")]
        [bool]$includesp = $true,
        [Parameter(Mandatory = $false, Position=9)]
        [Alias("incu")]
        [bool]$includeudf = $true
        
    )

    # Check if assembly is loaded
    Load-Assembly -name 'Microsoft.SqlServer.SMO'

    # Create the server object and retrieve the information
    try{
        # Make a connection to the database
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$inst,$port"

        # Set the destination
        $destination = "$path\$inst\"

        if((Test-Path $destination) -eq $false)
        {
            # Create the directory
            New-Item -ItemType Directory -Path "$destination" | Out-Null
        }

        $databases = @{}

        # Check if a selective list must be used
        if($dblist -eq 'ALL')
        {
            # Get the user databases, the system databases are excluded
            $databases = $server.Databases | Select Name | where {$_.Name -notmatch 'master|model|msdb|tempdb' }
        }
        else
        {
            $databases = @()

            #clean up the data
            $dblist = $dblist.Replace(' ', '')

            # Split the string
            $values = $dblist.Split(',') 

            foreach($value in $values)
            {
                $db = New-Object psobject
                $db | Add-Member -membertype noteproperty -name "Name" -Value $value
                $databases += $db
            }

        }

        # Check if there are any databases
        if($databases.Count -ge 1)
        {
            # Loop through
            foreach($database in $databases)
            {
                Write-Host "Starting Database Export: " $database.Name -ForegroundColor Green

                # Check if timestamp is needed
                if($includetimestamp)
                {
                    # Create a timestamp
                    $timestamp = Get-Date -Format yyyyMMddHHmmss
                    # Set the desitnation
                    $dbDestination = "$destination\" + $database.Name + "\$timestamp"
                }
                else
                {
                    # Set the desitnation
                    $dbDestination = "$destination\" + $database.Name 
                }

                # Create the variable for holding all the database objects
                $objects = $null

                # Check if the tables need to be included
                if($includetables)
                {
                    Write-Host "Retrieving Tables"  -ForegroundColor Green

                    # Get the tables
                    $objects += $server.Databases[$database.Name].Tables | where {!($_.IsSystemObject)}
                }

                # Check if the views need to be included
                if($includeviews)
                {
                    Write-Host "Retrieving Views" -ForegroundColor Green

                    # Get the views
                    $objects += $server.Databases[$database.Name].Views | where {!($_.IsSystemObject)}
                }

                # Check if the stored procedures need to be included
                if($includesp)
                {
                    Write-Host "Retrieving Stored Procedures" -ForegroundColor Green

                    # Get the stored procedures
                    $objects += $server.Databases[$database.Name].StoredProcedures | where {!($_.IsSystemObject)}
                }

                # Check if the user defined functions need to be included
                if($includeudf)
                {
                    Write-Host "Retrieving User Defined Functions" -ForegroundColor Green

                    # Get the stored procedures
                    $objects += $server.Databases[$database.Name].UserDefinedFunctions | where {!($_.IsSystemObject)}
                }

                Write-Host $objects.Length "objects found to export." -ForegroundColor Green 

                # Check if there any objects to export
                if($objects.Length -ge 1)
                {
                    # Create the scripter object
                    $scripter = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") $server #"$inst,$port"

                    # Set general options
                    $scripter.Options.AppendToFile = $false
                    $scripter.Options.AllowSystemObjects = $false
                    $scripter.Options.ClusteredIndexes = $true
                    $scripter.Options.DriAll = $true
                    $scripter.Options.ScriptDrops = $false
                    $scripter.Options.IncludeHeaders = $true
                    $scripter.Options.ToFileOnly = $true
                    $scripter.Options.Indexes = $true
                    $scripter.Options.WithDependencies = $false

                    foreach($item in $objects )
                    {
                        # Get the type of object
                        $typeDir = $item.GetType().Name

                        # Check if the directory for the item type exists
                        if((Test-Path "$dbDestination\$typeDir") -eq $false)
                        {
                            New-Item -ItemType Directory -Name "$typeDir" -Path "$dbDestination" | Out-Null
                        }

                        #Setup the output file for the item
                        $filename = $item -replace "\[|\]"
                        $scripter.Options.FileName = "$dbDestination\$typeDir\$filename.sql"

                        # Script out the object 
                        Write-Host "Scripting out $typeDir $item"
                        $scripter.Script($item)

                    }
                }
            }
        }
        else
        {
            Write-Host "No databases found." -ForegroundColor Magenta
        }
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}


function Export-SQLServerObject
{
    <# 
    .SYNOPSIS
        Generates export files of SQL Server objects
    .DESCRIPTION
        This function will return generate an export file of SQL Server objects to a .sql file.
        This includes server roles, logins, linked servers, triggers, database mail and jobs.
    .PARAMETER  instance
        This is the instance that needs to be connected
    .PARAMETER port
        This is the port of the instance that needs to be used
    .PARAMETER path
        Path to export to
    .PARAMETER includetimestamp
        Boolean to include a timestamp directory to export to
    .PARAMETER includeroles
        Boolean to include or exclude server roles. Can be value $false/$true or 0/1.
    .PARAMETER includelogins
        Boolean to include or exclude logins. Can be value $false/$true or 0/1.
    .PARAMETER includelinkedservers
        Boolean to include or exclude linked servers. Can be value $false/$true or 0/1.
    .PARAMETER includetriggers
        Boolean to include or exclude triggers. Can be value $false/$true or 0/1.
    .PARAMETER includemail
        Boolean to include or exclude database mail. Can be value $false/$true or 0/1.
    .PARAMETER includejobs
        Boolean to include or exclude jobs. Can be value $false/$true or 0/1.
    .EXAMPLE
        Export-SQLServerObject "SQL01" -path 'C:\Temp\export'
    .EXAMPLE
        Export-SQLServerObject -inst "SQL01\INST01" -path 'C:\Temp\export'
    .EXAMPLE
        Export-SQLServerObject -inst "SQL01\INST01" 4321 -path 'C:\Temp\export'
    .EXAMPLE
        Export-SQLServerObject -inst "SQL01\INST01" -includemail $false -path 'C:\Temp\export'
    .INPUTS
    .OUTPUTS
        Script files
    .NOTES
    .LINK
    #>
    param
    (
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()][string]$inst = $null,
        [Parameter(Mandatory = $false, Position=2)]
        [string]$port = '1433',
        [Parameter(Mandatory = $true, Position=3)]
        [ValidateNotNullOrEmpty()][string]$path = $null,
        [Parameter(Mandatory = $false, Position=4)]
        [Alias("timestamp")]
        [bool]$includetimestamp = $true,
        [Parameter(Mandatory = $false, Position=5)]
        [Alias("incr")]
        [bool]$includeroles = $true,
        [Parameter(Mandatory = $false, Position=6)]
        [Alias("incl")]
        [bool]$includelogins = $true,
        [Parameter(Mandatory = $false, Position=7)]
        [Alias("incls")]
        [bool]$includelinkedservers = $true,
        [Parameter(Mandatory = $false, Position=8)]
        [Alias("inct")]
        [bool]$includetriggers = $true,
        [Parameter(Mandatory = $false, Position=9)]
        [Alias("incm")]
        [bool]$includemail = $true,
        [Parameter(Mandatory = $false, Position=10)]
        [Alias("incj")]
        [bool]$includejobs = $true
        
    )

    #Load the assembly
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

    # Create the server object and retrieve the information
    try{
        # Check if assembly is loaded
        Load-Assembly -name 'Microsoft.SqlServer.SMO'

        Write-Host "Starting SQL Server Export: " $inst -ForegroundColor Green

        # Set the destination
        $destination = "$path\$inst\"

        # Check if timestamp is needed
        if($includetimestamp)
        {
            # Create a timestamp
            $timestamp = Get-Date -Format yyyyMMddHHmmss
            # Set the desitnation
            $destination = "$destination\$timestamp"
        }

        if((Test-Path $destination) -eq $false)
        {
            # Create the directory
            New-Item -ItemType Directory -Path "$destination" | Out-Null
        }

        # Create the variable for holding all the server objects
        [array]$objects = $null

        # Get the roles
        if($includeroles -eq $true)
        {
            Write-Host "Retrieving Server Roles"  -ForegroundColor Green
            $objects += $server.Roles | where {($_.IsFixedRole -eq $false) -and ($_.Name -ne 'public')}
        }

        # Get the logins
        if($includelogins -eq $true)
        {
            Write-Host "Retrieving Logins"  -ForegroundColor Green
            $objects += $server.Logins | where {$_.Name -notmatch 'BUILTIN*|NT SERVICE*|NT AUTHORITY*|##*|sa'}
        }


        # Get the linked servers
        if($includelinkedservers -eq $true)
        {
            Write-Host "Retrieving Linked Servers"  -ForegroundColor Green
            $objects += $server.LinkedServers
        }

        # Get the triggers
        if($includetriggers -eq $true)
        {
            Write-Host "Retrieving Triggers"  -ForegroundColor Green
            $objects += $server.Triggers
        }

        # Get the mail objects
        if($includemail -eq $true)
        {
            Write-Host "Retrieving Database Mail"  -ForegroundColor Green
            $objects += $server.Mail
            $objects += $server.Mail.Accounts
            $objects += $server.Mail.Profiles
        }

        # Get the job objects
        if($includejobs -eq $true)
        {
            Write-Host "Retrieving Jobs"  -ForegroundColor Green
            $objects += $server.JobServer.Operators
            $objects += $server.JobServer.Jobs
            $objects += $server.JobServer.Alerts
        }

        Write-Host $objects.Length "objects found to export." -ForegroundColor Green 

        # Check if there any objects to export
        if($objects.Length -ge 1)
        {
            # Create the scripter object
            $scripter = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") $server #"$inst,$port"

            # Set general options
            $scripter.Options.AppendToFile = $false
            $scripter.Options.AllowSystemObjects = $false
            $scripter.Options.ClusteredIndexes = $true
            $scripter.Options.DriAll = $true
            $scripter.Options.ScriptDrops = $false
            $scripter.Options.IncludeHeaders = $true
            $scripter.Options.ToFileOnly = $true
            $scripter.Options.Indexes = $true
            $scripter.Options.WithDependencies = $false

            foreach($item in $objects )
            {
                # Get the type of object
                $typeDir = $item.GetType().Name

                # Check if the directory for the item type exists
                if((Test-Path "$destination\$typeDir") -eq $false)
                {
                    New-Item -ItemType Directory -Name "$typeDir" -path "$destination" | Out-Null
                }

                #Setup the output file for the item
                $filename = $item -replace "\[|\]"
                
                # Check if the filename contains a "\", if so replace it
                if($filename -match "\\")
                {
                    $filename = $filename -replace "\\", "_"
                }

                $scripter.Options.FileName = "$destination\$typeDir\$filename.sql"

                # Script out the object 
                Write-Host "Scripting out $typeDir $item"
                
                $scripter.Script($item)
            }
        }
    }
    catch [Exception]
    {
        $errorMessage = $_.Exception.Message
        $line = $_.InvocationInfo.ScriptLineNumber
        $script_name = $_.InvocationInfo.ScriptName
        Write-Host "Error: Occurred on line $line in script $script_name." -ForegroundColor Red
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    }
}

##################################################

function Load-Assembly
{
    <# 
    .SYNOPSIS
        Check if a assembly is loaded and load it if neccesary
    .DESCRIPTION
        The script will check if an assembly is already loaded.
        If it isn't already loaded it will try to load the assembly
    .PARAMETER  name
        Full name of the assembly to be loaded
    .EXAMPLE
        Load-Assembly -name 'Microsoft.SqlServer.SMO'
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
    #>
     param(
          [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
          [String] $name
     )
     
     if(([System.AppDomain]::Currentdomain.GetAssemblies() | where {$_ -match $name}) -eq $null)
     {
        try{
            [System.Reflection.Assembly]::LoadWithPartialName($name) | Out-Null
        } 
        catch [System.Exception]
        {
            Write-Host "Failed to load assembly!" -ForegroundColor Red
            Write-Host "$_.Exception.GetType().FullName, $_.Exception.Message" -ForegroundColor Red
        }
     }
}

Export-ModuleMember -Function Get-HostHarddisk
Export-ModuleMember -Function Get-HostHardware
Export-ModuleMember -Function Get-HostOperatingSystem
Export-ModuleMember -Function Get-HostSQLServerServices
Export-ModuleMember -Function Get-HostSystemInformation
Export-ModuleMember -Function Get-HostUptime

Export-ModuleMember -Function Get-SQLAgentJobs
Export-ModuleMember -Function Get-SQLConfiguration
Export-ModuleMember -Function Get-SQLDatabaseFiles
Export-ModuleMember -Function Get-SQLDatabasePrivileges
Export-ModuleMember -Function Get-SQLDatabases
Export-ModuleMember -Function Get-SQLDatabaseUsers
Export-ModuleMember -Function Get-SQLDiskLatencies
Export-ModuleMember -Function Get-SQLInstanceSettings
Export-ModuleMember -Function Get-SQLInstanceUptime
Export-ModuleMember -Function Get-SQLServerBackups
Export-ModuleMember -Function Get-SQLServerPrivileges

Export-ModuleMember -Function Export-DatabaseObject
Export-ModuleMember -Function Export-SQLServerObject
