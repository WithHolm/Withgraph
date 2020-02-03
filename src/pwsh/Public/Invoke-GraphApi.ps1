function Invoke-WithGraphApi {
    [CmdletBinding()]
    param (
        [string]$URL
    )
    
    begin {
        # if([string]::IsNullOrEmpty($global:GraphAuth))
        # {
        #     Connect-Withgraph
        # }
    }
    
    process {
        $Header = @{
            Authorization = $global:GraphAuth.CreateAuthorizationHeader()
        }
        Invoke-RestMethod -Method Get -Headers $Header -Uri $URL
    }
    
    end {
        
    }
}