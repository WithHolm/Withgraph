function Get-ModuleConfig
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory)]
        [ValidateSet("EnableLog","PIILog","ApplicationId","Tenant","AzureInstance","Scope")]
        [String]$Val
    )
    Begin
    {
        Write-GraphLog -LogLevel Verbose -Message "Getting GraphConfig: $val"
    }
    Process
    {
        $MyInvocation.MyCommand.Module.PrivateData.config.$val
    }
    End
    {
        # $MyInvocation.MyCommand.Module
    }
}