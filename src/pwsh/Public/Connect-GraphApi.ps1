Function Connect-GraphApi
{
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [String]$ApplicationID,
        [string]$Tenant,
        [string[]]$scopes,
        [switch]$passthru
    )
    # $ClientApp
    
    
    if([string]::IsNullOrEmpty($ApplicationID))
    {
        $ApplicationID = $(Get-ModuleConfig -val ApplicationID)
    }

    if([string]::IsNullOrEmpty($Tenant))
    {
        $Tenant = $(Get-ModuleConfig -val tenant)
    }

    if([string]::IsNullOrEmpty($scopes))
    {
        $scopes = Get-ModuleConfig -val Scope
    }

    #Singleton ish.. will use value stored in global/Script
    $GraphClient = Register-GraphClient -ApplicationID $ApplicationID -tenant $tenant
    # $RegisterClient = $true
    # if($global:GraphClient)
    # {
    #     Write-Verbose "ClientID: $($global:GraphClient.AppConfig.ClientId) = $($ApplicationID)"
    #     Write-Verbose "Tenant: $($global:GraphClient.AppConfig.TenantId) = $($Tenant)"
    #     $RegisterClient  = ($global:GraphClient.AppConfig.ClientId -ne $ApplicationID -or $global:GraphClient.AppConfig.TenantId -ne $Tenant)
    # }

    # if ($RegisterClient)
    # {
    #     Write-GraphLog -LogLevel Verbose "Creating GraphClient"
    #     Register-GraphClient -ApplicationID $ApplicationID -tenant $tenant
    #     $GraphClient = $global:GraphClient
    # }
    
    
    # $GraphClient = $global:GraphClient
    # if (!$GraphClient)
    # {
    # }
    # else
    # {
    #     if ($GraphClient.AppConfig.ClientId -ne $ApplicationID -or $GraphClient.AppConfig.TenantId -ne $Tenant)
    #     {
    #         $RegisterClient = $true
    #     }
    # }



    #ps way
    if ($Global:GraphAuth)
    {
        $account = $global:GraphAuth.account | select -first 1
    }

    Write-Verbose "Found $(@($account|?{$_}).count) accounts in current session: $account"

    $ResultText = [string]::Empty
    $resultErr = $null

    try
    {
        Write-Verbose "Starting Silent token auth"
        $SilentAuthResultTask = $GraphClient.AcquireTokenSilent($scopes, $account).ExecuteAsync()

        # $SilentAuthResultTask
        while (!$SilentAuthResultTask.IsCompleted)
        {
            Start-Sleep -Milliseconds 20
            # $SilentAuthResultTask
            # $SilentAuthResultTask.AsyncWaitHandle.WaitOne(30)
        }
        $Authresult = $SilentAuthResultTask.Result
        # $SilentAuthResultTask
        # $SilentAuthResultTask.Result
    }
    catch [Microsoft.Identity.Client.MsalUiRequiredException]
    {
        Write-GraphLog -LogLevel Warning "UI: $($_)"
        try
        {
            $AuthResultTask = $GraphClient.AcquireTokenInteractive($scopes).WithAccount($account).WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).ExecuteAsync()
            if ($PSEdition -eq "Core")
            {
                Write-GraphLog -LogLevel Info -Message "Cannot handle if you cancel the request or close browser, but if you do, Ctrl+C"
            } 
            Write-GraphLog -LogLevel Info ""
            while (!$AuthResultTask.AsyncWaitHandle.WaitOne(30))
            {
                # $AuthResultTask
            }
            if ($AuthResultTask.Status -eq "Faulted")
            {
                $AuthResultTask | ConvertTo-Json -Depth 2 #.Exception.InnerExceptions
            }
            else
            {
                $Authresult = $AuthResultTask.Result
            }
        }
        catch
        {
            Write-GraphLog -LogLevel Error -Message "Error aquiring interractive token: $_"
        }
    }
    catch
    {
        Write-GraphLog -LogLevel Error -Message "Error aquiring silent token: $_"
    }

    if ($Authresult)
    {
        Write-GraphLog -LogLevel Verbose "Setting Global:GraphAuth"
        $global:GraphAuth = $Authresult
        if ($passthru)
        {
            $Authresult
        }
    }
}