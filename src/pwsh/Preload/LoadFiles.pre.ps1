[CmdletBinding()]
Param(
)

$InformationPreference = "Continue"
function Get-ModuleRoot
{
    [CmdletBinding()]
    Param(
        [System.IO.DirectoryInfo]$FromPath = $PSScriptRoot
    )
    Begin{}
    Process
    {
        While(!$FromPath.GetFiles("*.psm1"))
        {
            # Write-Information $FromPath.FullName
            $frompath = $FromPath.Parent
        }
        $FromPath.FullName
    }
    End{}
}

Function Import-Dll
{
    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory
        )]
        [System.IO.FileInfo]$DllPath
    )
    if(!$DllPath.Exists)
    {
        throw [System.IO.FileLoadException]::new("Could not find file $($dllpath.FullName)")
    }
    Write-debug "Loading dll $($DllPath.FullName)"
    Add-Type -Path $DllPath.FullName
}

$Root = Get-ModuleRoot
$Nuget_Partial = "src\cSharp\Graphcli\nuget"
$Nuget = (Join-Path $Root $Nuget_Partial)
$ModuleDataFilePath = gci $Root -Filter "*.psd1"|select -First 1
if(!(Test-Path $ModuleDataFilePath))
{
    throw "Could not find datafile to get the config at path $root"
}
$ModuleDataFile = (Import-PowerShellDataFile -Path $ModuleDataFilePath)
$DLLsToLoad = $ModuleDataFile.PrivateData.DllsToLoad
if([string]::IsNullOrEmpty($DLLsToLoad))
{
    throw "Could not find dlls to load config"
}

Foreach($Config in $DLLsToLoad)
{
    Write-debug "Starting load of $($config.name)"
    $LibPath = (join-path $nuget "$($config.name)\$($config.version)\lib")
    if(!($LibPath))
    {
        Throw "Could not find libpath for $($config.name)\$($config.version): $libpath"
    }
    try{
        if($PSVersionTable.PSVersion -ge "6.0")
        {
            Import-Dll -DllPath (join-path $LibPath "$($config.core)\$($config.name).dll")
        }
        elseif($PSVersionTable.PSVersion -ge "5.1")
        {
            Import-Dll -DllPath (join-path $LibPath "$($config.dotnet)\$($config.name).dll")
        }
        else {
            Write-debug "throw"
            throw
        }
    }
    catch
    {
        Write-Warning $_
        Import-Dll -DllPath (join-path $LibPath "$($config.standard)\$($config.name).dll")
    }
}