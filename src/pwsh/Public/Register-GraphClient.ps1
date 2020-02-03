Function Register-GraphClient
{
    [CmdletBinding(DefaultParameterSetName = "Multitenant")]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = "clientId / applicationId (Not objectId)"
        )]
        [String]$applicationId,

        [parameter(
            HelpMessage = "For native clients (IE. powershell scripts), you want to use 'urn:ietf:wg:oauth:2.0:oob'. 
            This needs to be added to application redirect uri in az portal"
        )]
        [String]$redirectUri,

        [Microsoft.Identity.Client.AzureCloudInstance]$AzureInstance = "AzurePublic",

        [parameter(
            Mandatory,
            ParameterSetName = "Tenant",
            HelpMessage = "
            For Work or School account in your org, use your tenant ID, or domain
            for any Work or School accounts, use `organizations`
            for any Work or School accounts, or Microsoft personal account, use `common`
            for Microsoft Personal account, use consumers
            "
        )]
        [String]$tenant,

        [parameter(
            HelpMessage = "enable/disable logging"
        )]
        [bool]$EnableLog,

        [parameter(
            HelpMessage = "enable/disable logging of Personally Identifiable Information (PII). 
            You can set it to true for advanced debugging requiring PII. See https://aka.ms/msal-net-logging"
        )]
        [switch]$piiLog

    )

    $ClientAppOptions = [Microsoft.Identity.Client.PublicClientApplicationOptions]::new()
    $ClientAppOptions.ClientName = $MyInvocation.MyCommand.Module.Name
    $ClientAppOptions.ClientVersion = $MyInvocation.MyCommand.Module.Version

    # ($global:GraphClient.AppConfig.ClientId -ne $ApplicationID -or $global:GraphClient.AppConfig.TenantId -ne $Tenant)

    #region redirectUri
    if ([String]::IsNullOrEmpty($redirectUri))
    {
        if ($PSVersionTable.PSEdition -eq "Core") 
        { 
            $redirectUri = "http://localhost"
        }
        else
        { 
            $redirectUri = "urn:ietf:wg:oauth:2.0:oob" 
        }
    }

    $ClientAppOptions.RedirectUri = $Redirecturi
    #endregion

    #Region Tenant
    if (![string]::IsNullOrEmpty($tenant))
    {
        # Write-GraphLog -LogLevel Verbose -Message "Adding tenant:'$tenant'"
        $ClientAppOptions.TenantId = $tenant
    }
    else 
    {
        # Write-GraphLog -LogLevel Verbose -Message "Adding module default Tenant:'$((Get-ModuleConfig).Tenant)'"
        $ClientAppOptions.TenantId = Get-ModuleConfig -Val Tenant
    }
    #endregion
    
    #region ApplicationID/ClientID
    if ([String]::IsNullOrEmpty($applicationId))
    {
        $applicationId = Get-ModuleConfig -Val ApplicationId
    }
    $ClientAppOptions.ClientId = $ApplicationID
    #endregion

    #region AzureInstance
    if ([String]::IsNullOrEmpty($AzureInstance))
    {
        $AzureInstance = Get-ModuleConfig -Val AzureInstance
    }
    $ClientAppOptions.AzureCloudInstance = $AzureInstance
    #endregion
    
    $RegisterClient = $false
    if ($global:GraphClient)
    {
        Write-Verbose "ClientID: $($global:GraphClient.AppConfig.ClientId) = $($ApplicationID)"
        Write-Verbose "Tenant: $($global:GraphClient.AppConfig.TenantId) = $($Tenant)"
        $RegisterClient = ($global:GraphClient.AppConfig.ClientId -ne $ApplicationID -or $global:GraphClient.AppConfig.TenantId -ne $Tenant)
    }
    else
    {
        $RegisterClient = $true
    }

    Write-GraphLog -LogLevel Verbose  -message "clientapp for tenant '$($ClientAppOptions.TenantId)' with applicationId: $($ClientAppOptions.ClientId). PII enabled:$($piiLog.IsPresent)"
    if ($EnableLog)
    {
        $ClientAppOptions.EnablePiiLogging = $piiLog.IsPresent
    }
    $_LogLevel = [Microsoft.Identity.Client.LogLevel]::Info

    if ($VerbosePreference -eq "Continue")
    {
        $_LogLevel = [Microsoft.Identity.Client.LogLevel]::Verbose
    }

    ($ClientAppOptions | ConvertTo-Json -Depth 1).split("`n") | % {
        Write-Verbose $_
    }
    if($RegisterClient)
    {
        if ($EnableLog)
        {
            $ClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($ClientAppOptions).WithLogging(${Function:Write-GraphLog}, $_LogLevel, $piiLog.IsPresent, $true).Build()
        }
        else
        {
            $ClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($ClientAppOptions).Build()
        }
    
        Write-Verbose "Setting global:ClientApp"
        $global:GraphClient = [Microsoft.Identity.Client.IPublicClientApplication]$ClientApp
    }
    return $global:GraphClient
}