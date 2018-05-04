[cmdletbinding()]
param()
$Loadfiles = gci "$PSScriptRoot" -Filter "lib_*.ps1"
Write-Output "Loading $(@($Loadfiles).count) Helpers"
$Loadfiles| % {
    Write-Verbose "Loading $($_.FullName)"
    . $_.FullName
}