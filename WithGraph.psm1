
gci "$PSScriptRoot\src\pwsh\private" -Filter "*.ps1"|%{
    . $_.FullName
}

gci "$PSScriptRoot\src\pwsh\public" -Filter "*.ps1"|%{
    . $_.FullName
}

# $script:Config = Get-Moduleconfig 
# $script:GraphClient = $null
# $Global:GraphAuth = $null
