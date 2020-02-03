#
# Module manifest for module 'Withgraph'
#
# Generated by: Phil
#
# Generated on: 28-Jan-20
#

@{
# Script module or binary module file associated with this manifest.
RootModule = '.\WithGraph.psm1'

# Version number of this module.
ModuleVersion = '0.0.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'd9a35b00-a85e-45b3-98c4-1806963ee2bb'

# Author of this module
Author = 'Philip Meholm'

# Company or vendor of this module
CompanyName = 'Nimtech'

# Copyright statement for this module
Copyright = '(c) Phil. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @(
    ".\src\pwsh\Preload\LoadFiles.pre.ps1"
)

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    Config = @{
        EnableLog = $false
        # PII is GDPR non compliant
        PIILog = $false 
        ApplicationId = "e082df64-83d2-452a-9bd0-e042159fd1f4"
        Tenant = "Common"
        AzureInstance = "AzurePublic"
        Scope = @("User.Read")
        # Param = @{
        #     GraphClient = @{
        #         ApplicationId = (Get-ModuleConfig).ApplicationId
        #         Multitenant = (Get-ModuleConfig).TenantId
        #     }
        # }
    }

    # ModuleConfig = @{
    #     Levels = @{
    #         1 = @{
    #             Name = "Module"
    #             Actions = @("Get")
    #             Path = "$PSScriptRoot\Withgraph.psd1#/PrivateData/Config"
    #         }
    #         2 = @{

    #         }
    #     }

    # }
    DllsToLoad = @(
        @{
            Name = "microsoft.identity.client"
            Version = "4.8.0"
            Standard = "netstandard1.3"
            Dotnet = "net45"
            Core = "netcoreapp2.1"
            Requires = @()
        }
    )
    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
