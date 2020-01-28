
$Base = join-path $PSScriptRoot

if($PSVersionTable.PSVersion -lt "5.1")
{
    Throw "Your Powershell version is too low! $($PSVersionTable.PSVersion) < 5.1"
}
elseif($PSVersionTable.PSVersion -lt "6.0")
{
    Write-verbose "Desktop edition. not dotnet 45"
}
elseif($PSVersionTable.PSVersion -lt "7.0"){
    Write-verbose "Core edition"
}
else {
    throw "No handling for $($PSVersionTable.PSVersion) yet"
}