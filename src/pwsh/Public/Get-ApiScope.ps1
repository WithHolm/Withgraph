function Get-GraphApiScope
{
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateSet("Beta", "v1.0")]
        [String]$Version,
        [String]$Product,
        [String]$ByUrl
    )
    
    begin
    {
        $path = join-path $MyInvocation.MyCommand.Module.ModuleBase "src/MicrosoftDocs"
        $Path = (gci -Path $path -Filter "*_$version.json") | select -First 1
        $Json = Get-Variable -Scope script -Name $version -ErrorAction SilentlyContinue
        if ($Json)
        {
            $Data
        }
        else
        {
            $Data = [System.IO.File]::ReadAllText($path.FullName) | ConvertFrom-Json
            Set-Variable -Scope script -Name $Version
        }
    }
    
    process
    {
        if($Product)
        {
            $Data = $Data | ? { $_.product -like $Product }
        }

        if($ByUrl)
        {
            $Data = $Data|?{$true -in $_.call|%{"$ByUrl*" -like $_.match}}
        }
        Write-Verbose "Found $($Data.count)"
        $Data       
    }
    
    end
    {
        
    }
}