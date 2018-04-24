

gci $PSScriptRoot -Filter "*.Build.ps1"|%{. $_.FullName}

$Buildsettings = @{
    Root =  Get-ProjectRoot
    Modules = @("InvokeBuild","Pester")
    Version = "0.1.0.$(get-date -f "yyMMddHHmm")"
    Build = @{
        DynamicTag = $true
        Value      = "%Root%\Build\%Version%"
    }
    Dev = @{
        DynamicTag = $true
        Value      = "%Root%\Dev"
    }
    ModuleName = (Split-Path Get-ProjectRoot -Leaf)
}
$Buildsettings = Convert-Dynamictags -hashtable $Buildsettings -Tag "Dynamictag" -Dynamicvariable "%"

foreach($module in $Buildsettings.Modules)
{
    try {
        Write-host "Importing module $module"
        import-module $module -ErrorAction Stop -Force
    }
    catch {
        Write-host "Could not find $moudle. Installing from PSGet"
        Find-module $module|install-module -Scope CurrentUser -Force
    }
}

Enter-Build {
    'Loading modules...'
}

task Task1 {
    'Doing Task1...'
}

task Task2 {
    'Doing Task2...'
}



# Task Default -depends Build

# # while([]$Path)

# Task GatherFiles -depends CreateBuildDirectory {
#     Write-host "testing" -ForegroundColor Green
# }

# Task CreateBuildDirectory {
#     if(!(test-path $Buildsettings.Build))
#     {
#         mkdir $Buildsettings.Build
#     }
# }

# # Task "Create Ps1Xml file"{

# # }

# Task Build -depends GatherFiles
# ([System.IO.DirectoryInfo]$pwd.path).