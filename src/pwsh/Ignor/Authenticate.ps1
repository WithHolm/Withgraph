# add-type -Path (Join-Path (split-path $PSScriptRoot) "csharp\pkg\microsoft.identity.client")
$ErrorActionPreference = "stop"
$src = 
if($PSVersionTable.PSEdition -eq "Core")
{
    add-type -path "C:\git\Withgraph\src\cSharp\Graphcli\nuget\microsoft.identity.client\4.8.0\lib\netcoreapp2.1\Microsoft.Identity.Client.dll"
}
else {
    add-type -path "C:\git\Withgraph\src\cSharp\Graphcli\nuget\microsoft.identity.client\4.8.0\lib\net45\Microsoft.Identity.Client.dll"
}

# $global:ClientApp = $null
# $global:GraphAuth = $null
# $Script:ModuleDetails = @{
#     Name = "WithGraph"
#     Version = [version]"0.2"
#     Config = @{
#         piiLog = $true 
#         applicationId = "e082df64-83d2-452a-9bd0-e042159fd1f4"
#     }
# }

Function Write-GraphLog
{
    param(
        [Microsoft.Identity.Client.LogLevel]$LogLevel,
        [String]$Message,
        [bool]$PII
    )
    $Message = "[$($LogLevel.ToString())][PII:$($PII)] $message"
    if($LogLevel -eq [Microsoft.Identity.Client.LogLevel]::Verbose)
    {
        Write-Verbose $Message
    }
    elseif($LogLevel -eq [Microsoft.Identity.Client.LogLevel]::Info)
    {
        Write-Information $Message
    }
    else {
        Write-Verbose $Message
    }
}

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

Function Register-ClientApp
{
    [CmdletBinding(DefaultParameterSetName="Multitenant")]
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
        [String]$redirectUri = $(if($PSVersionTable.PSEdition -eq "Core"){"http://localhost"}else{"urn:ietf:wg:oauth:2.0:oob"}),

        [Microsoft.Identity.Client.AzureCloudInstance]$AzureInstance = "AzurePublic",

        [parameter(ParameterSetName = "Multitenant")]
        [ValidateSet("Common","organizations","consumers")]
        [String]$multiTenant = "Common" ,

        [parameter(
            ParameterSetName = "SingleTenant",
            HelpMessage = "Supports both tenantId and tenantName"
            )]
        [String]$tenant,

        [parameter(
            HelpMessage = "enable/disable logging"
            )]
        [bool]$EnableLog = $false,

        [parameter(
            HelpMessage = "enable/disable logging of Personally Identifiable Information (PII). 
            You can set it to true for advanced debugging requiring PII. See https://aka.ms/msal-net-logging"
            )]
        [switch]$piiLog

    )

    <#
       - For Work or School account in your org, use your tenant ID, or domain
       - for any Work or School accounts, use `organizations`
       - for any Work or School accounts, or Microsoft personal account, use `common`
       - for Microsoft Personal account, use consumers
    #>
    # [Microsoft.Identity.Client.AadAuthorityAudience]::
    Write-Verbose "Creating clientapp for '$($tenant)$($multiTenant)' with applicationId: $applicationId. PII enabled:$($piiLog.IsPresent)"
    $ClientAppOptions =[Microsoft.Identity.Client.PublicClientApplicationOptions]::new()
    $ClientAppOptions.ClientName = $Script:ModuleDetails.Name
    $ClientAppOptions.ClientVersion = $Script:ModuleDetails.Version
    if($PSCmdlet.ParameterSetName -eq "Multitenant")
    {
        $ClientAppOptions.TenantId = $MultiTenant
    }
    else {
        $ClientAppOptions.TenantId = $Tenant
    }
    $ClientAppOptions.AzureCloudInstance = $AzureInstance
    $ClientAppOptions.ClientId = $ApplicationID
    $ClientAppOptions.RedirectUri = $Redirecturi
    if($EnableLog)
    {
        $ClientAppOptions.EnablePiiLogging = $piiLog.IsPresent
    }
    $_LogLevel = [Microsoft.Identity.Client.LogLevel]::Info

    if($VerbosePreference -eq "Continue")
    {
        $_LogLevel = [Microsoft.Identity.Client.LogLevel]::Verbose
    }

    ($ClientAppOptions|ConvertTo-Json -Depth 1).split("`n")|%{
        Write-Verbose $_
    }

    if($EnableLog)
    {
        $ClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($ClientAppOptions).WithLogging(${Function:Write-GraphLog},$_LogLevel,$piiLog.IsPresent,$true).Build()
    }
    else {
        $ClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($ClientAppOptions).Build()
    }

    Write-Verbose "Setting global:ClientApp"
    $global:ClientApp = [Microsoft.Identity.Client.IPublicClientApplication]$ClientApp
}

Function Invoke-GraphAuthentication
{
    [CmdletBinding()]
    param(
        [string[]]$scopes = @("user.read"),
        [Microsoft.Identity.Client.IPublicClientApplication]$ClientApp = $global:ClientApp
    )
    # $ClientApp
    if(!$ClientApp)
    {
        Register-ClientApp -ApplicationID $ModuleDetails.Config.applicationId
        $ClientApp = $global:ClientApp
    }

    #This is the c# way.. but it requires static methods
    # $_accounts = $ClientApp.GetAccountsAsync()
    # while(!$_accounts.AsyncWaitHandle.WaitOne(30)){}
    # $Accounts = $_accounts.Result
    # $account = $Accounts | Select-Object -first 1

    #ps way
    # if(!$Global:GraphAuth)
    # {
    #     $account = $global:GraphAuth.account
    # }


    Write-Verbose "Found $(@($account).count) accounts in current session"

    $ResultText = [string]::Empty
    $resultErr = $null

    try
    {
        Write-Verbose "Starting Silent token thing..."
        $SilentAuthResultTask = $ClientApp.AcquireTokenSilent($scopes, $global:GraphAuth.account).ExecuteAsync()
        while(!$AuthResultTask.AsyncWaitHandle.WaitOne(30)){}
        $Authresult = $SilentAuthResultTask.Result
    }
    catch [Microsoft.Identity.Client.MsalUiRequiredException]
    {
        Write-GraphLog -LogLevel Warning "UI: $($_)"
        try
        {
            $AuthResultTask = $ClientApp.AcquireTokenInteractive($scopes).WithAccount($account).WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).ExecuteAsync()
            while(!$AuthResultTask.AsyncWaitHandle.WaitOne(30)){
            }
            if($AuthResultTask.Status -eq "Faulted")
            {
                $AuthResultTask|ConvertTo-Json -Depth 2 #.Exception.InnerExceptions
            }
            else {
                $Authresult = $AuthResultTask.Result
            }
        }
        catch{
            Write-GraphLog -LogLevel Error -Message "Error aquiring interractive token: $_"
        }
    }
    catch{
        Write-GraphLog -LogLevel Error -Message "Error aquiring silent token: $_"
    }

    if($Authresult){
        Write-GraphLog -LogLevel Info "Setting Global:GraphAuth"
        $global:GraphAuth = $Authresult
    }
    # $ResultText
    # if($resultErr)
    # {
    #     $resultErr
    # }
}


# Function Connect-Withgraph {
#     [CmdletBinding()]
#     param (
    
#     )
#         # $Endpoint
#         $ClientID = "e082df64-83d2-452a-9bd0-e042159fd1f4"
#         # $redirct = "http://localhost"
#         $tenant = "common"
#         $redirect ="urn:ietf:wg:oauth:2.0:oob"
#         $Wait = 3000
#         $InformationPreference = "continue"
        
#         [string[]]$scopes = @("user.read");
        
#         # Below are the clientId (Application Id) of your app registration and the tenant information. 
#         #  You have to replace:
#         #  - the content of ClientID with the Application Id for your app registration
#         #  - the content of Tenant by the information about the accounts allowed to sign-in in your application:
#         #    - For Work or School account in your org, use your tenant ID, or domain
#         #    - for any Work or School accounts, use `organizations`
#         #    - for any Work or School accounts, or Microsoft personal account, use `common`
#         #    - for Microsoft Personal account, use consumers
        
#         $ClientApp = [Microsoft.Identity.Client.IPublicClientApplication][Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create(
#             $ClientID).WithRedirectUri($redirect). WithAuthority(
#                 [Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic,
#                 $tenant).Build()
#                 # $ClientApp.RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
#                 # $ClientApp.AppConfig
                
#                 $accounts = $ClientApp.GetAccountsAsync()
#                 [void] $accounts.Wait($Wait)
#                 $account = $accounts.Result | select -first 1
                
#                 # $accounts
                
#                 $ResultText = [string]::Empty
#                 $resultErr = $null
#                 try
#                 {
#                     $AuthResultTask = $ClientApp.AcquireTokenSilent($scopes, $account).ExecuteAsync()
#                     while($AuthResultTask.AsyncWaitHandle.WaitOne(200)){}
#                     $Authresult = $AuthResultTask.Result
#                 }
#                 catch [Microsoft.Identity.Client.MsalUiRequiredException]
#                 {
#                     Write-Information "UI: $($_)"
#                     try{
#             # [Microsoft.Identity.Client.AccountId]::
#             $WebviewOptions = [Microsoft.Identity.Client.SystemWebViewOptions]::new()
#             # $WebviewOptions.
#             $AuthResultTask = $ClientApp.AcquireTokenInteractive($scopes).WithAccount($account).WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).ExecuteAsync()
#             while(!$AuthResultTask.IsCompleted){
#                 Start-Sleep -Milliseconds 200
#                 # $AuthResultTask
#             }
#             # if($AuthResultTask.Status -eq "Faulted")
#             # {
#                 #     throw $AuthResultTask.Exception
#                 # }
#                 # $AuthResultTask  
#                 $Authresult = $AuthResultTask.Result
#             }
#             catch [Microsoft.Identity.Client.MsalException] {
#                 Write-warning $_.Exception.Message
#             }
#             catch{
#                 $ResultText = "Error aquiring interractive token: $_"
#                 $resultErr = $_
#                 # Throw "Error aquiring interractive token: $_"
#             }
#     }
#     catch{
#         $ResultText = "Error aquiring interractive token: $_"
#         $resultErr = $_
#         # Throw "Error aquiring silent token: $_"
#     }
#     if($Authresult){
#         $global:GraphAuth = $Authresult
        
#         # $Script:GraphAuth
        
#         # $Script:GraphAuth.gettype()
#     }
#     $ResultText
#     if($resultErr)
#     {
#         $resultErr
#     }
#     # $accounts|gm
    
    
#     # $Accounts = $ClientApp.GetAccountAsync().Wait($Wait)
#     # $Firstaccount = $Accounts.
    
# }

$InformationPreference = "Continue"
Invoke-GraphAuthentication -Verbose

# $global:ClientApp.AppConfig
# $global:ClientApp.AppConfig|gm
# $GraphEndpoint = "https://graph.microsoft.com/v1.0/me"
Invoke-WithGraphApi -URL "https://graph.microsoft.com/v1.0/me"
Invoke-WithGraphApi -URL "https://graph.microsoft.com/v1.0/directoryRoles"

# <#
# Delegated (work or school account) 	RoleManagement.Read.Directory, Directory.Read.All, RoleManagement.ReadWrite.Directory, Directory.ReadWrite.All, Directory.AccessAsUser.All
# #>
# @{
#    Delegated = @(
#         "RoleManagement.Read.Directory", "Directory.Read.All", "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All", "Directory.AccessAsUser.All"
#    ) 
#    Application = @(
#         "RoleManagement.Read.Directory", "Directory.Read.All", "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All"
#    )
# }
# Invoke-WithGraphApi -URL "https://graph.microsoft.com/v1.0/directoryRoles"

