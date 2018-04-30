param(
)

#remember to use ". invoke-build" before fixing this document to get the proper autocomplete

#Starting Build in new process, so the cus
Task . Startbuild
Task Build RemoveOlderBuilds,CreateBuildFolder,GatherFiles,GeneratePsxml,ModuleManifest


Enter-Build {
    import-module PSFramework
    $Loadfiles = gci "$PSScriptRoot\Build" -Filter "lib_*.ps1"
    Write-Output "Loading $(@($Loadfiles).count) Helpers"
    $Loadfiles|%{. $_.FullName}
    Write-Output "Setting up Variable"
    #gci function:/
    $script:Buildsettings = @{
        Root =  Get-ProjectRoot
        ModuleName = split-path (Get-ProjectRoot) -Leaf
        Modules = @("InvokeBuild","Pester")
        Version = "0.1.$(get-date -f "yyMMdd").$(get-date -f "HHmm")"
        Build = @{
            DynamicTag = $true
            Value      = "%Root%\Build\%Version%"
        }
        Dev = @{
            DynamicTag = $true
            Value      = "%Root%\Dev"
        }
        FileFilter = @{
            #* What does the build script search for?
            Powershell =@{
                Public = "*.public.ps1"
                Private = "*.private.ps1"
            }
            Csharp = @{
                SolutionDLL = @{
                    Public = @{
                        DynamicTag = $true
                        Value      = "%ModuleName%.dll"
                    }
                }
                references = @{
                    Ignore = @(
                        "Microsoft.PowerShell*"
                    )
                }
            }
        }
        DotNetVersion=@(
            "Net46",
            "Net45",
            "Net40",
            "Net30",
            "Net20",
            "portable-net45+win8+wpa81"
        )

        ModuleManifest = @{
            Path = @{
                DynamicTag = $true
                Value      = "%Build%\%Modulename%.psd1"
            }
            Author = "Philip Meholm @Withholm"
            RootModule = @{
                DynamicTag = $true
                Value      = "Code\csharp\%ModuleName%.dll"
            }
            GUID = ([guid]::NewGuid().guid)
            ModuleVersion = @{
                DynamicTag = $true
                Value      = "%Version%"
            }

            
        }
    }
    $Script:Buildsettings = Convert-Dynamictags -hashtable $Script:Buildsettings -Tag "Dynamictag" -Dynamicvariable "%" -verbose
}

Task StartBuild {
    Start-Process PowerShell -ArgumentList "-noexit -command ""cd '$psscriptroot' ; invoke-build Build""" -Wait
}

Task RemoveOlderBuilds{
    $OldBuilds = gci (split-path $buildsettings.build) -Directory|sort CreationTimeUtc -Descending|select -Skip 4
    Write-Output "Removing $(@($OldBuilds).Count) old projects"
    $OldBuilds|remove-item -Recurse
}

task CreateBuildFolder{
    if(Test-Path $Buildsettings.build)
    {
        Write-Output "Removing $($buildsettings.build)"
        rmdir $Buildsettings.build -ErrorAction SilentlyContinue -Force -Recurse|out-null
    }

    mkdir $Buildsettings.build -Force|%{
        Write-Output "Created $($_.fullname)"
    }

    mkdir @((Join-Path $Buildsettings.build "Code\PS"),
            (Join-Path $Buildsettings.build "Code\Csharp"),
            (Join-Path $Buildsettings.build "Code\Csharp\Dep"),
            (Join-Path $buildsettings.build "PSXML")) -Force|%{
        Write-Output "`t mkdir $($_.fullname.Replace($Buildsettings.build,''))"
    }

    
}

task GatherFiles  {
    Write-Output "Gathering Powershell Files with tag: $($script:Buildsettings.FileFilter.Powershell.values -join ', ')"
    $PSFiles = Get-ChildItem (Join-Path $script:Buildsettings.dev Powershell) -Include $script:Buildsettings.FileFilter.Powershell.values
    $PSFiles |Copy-Item -Destination (Join-Path $Buildsettings.build "Code\PS")
    write-output "`t Found $(@($PSFiles).count) Files"


    Write-Output "Gathering C# Stuff"
    Write-Output "`tFinding .sln"
    $Solution = Get-ChildItem $script:Buildsettings.dev -Filter "*.sln" -Recurse
    if(@($Solution).count -ne 1)
    {
        Throw "Error finding .sln file. Supposed to find 1, Found $(@($Solution).count)"
    }
    Write-Output "`tC# Repo is $(split-path $Solution.FullName)"

    Write-Output "`tFinding The Newest module DLL"
    $csharp = Get-ChildItem $(split-path $Solution.FullName) -Filter "Withgraph.dll" -Recurse|
                Sort-Object LastWriteTimeUtc -Descending|
                    Select-Object -First 1

    if(@($csharp).count -ne 1)
    {
        Throw "Error finding .DLL file. Supposed to find 1, Found $(@($csharp).count)"
    }

    #$csharp |Copy-Item -Destination (Join-Path $Buildsettings.build "Code\Csharp")
    write-output "`tFound File at $($csharp.fullname.replace($(split-path $Solution.FullName),'')). Copying the whole folder"
    
    Get-ChildItem (split-path $csharp.fullname) -Force|%{
        Write-Output "`t$($_.fullname.replace((split-path $csharp.fullname),''))"
        $_|copy-item -Destination (Join-Path $Buildsettings.build "Code\Csharp") -Recurse
    }
}

Task LoadDLL -Before GeneratePsxml{
    
    $DLL = (Get-ChildItem "$($buildsettings.build)\Code\csharp" -Filter "*$($buildsettings.ModuleName)*.dll"|select -First 1)
    
    Write-Output "`t Load DLL: $($dll.fullname)"
    [void][System.Reflection.Assembly]::LoadFrom($DLL.fullname)
}

task GeneratePsxml {
    Write-Output "Gathering info from the PsXml"
    Write-Output "`tC#"
    Write-Output "`t----"

    $CustomTypeTags = @{
        Class = "PsClassAttribute"
        PropertyShow = "PsPropertyShowAttribute"
        PropertyHide = "PsPropertyHideAttribute"
    }
    #Get-PSMDAssembly -Filter "*$($buildsettings.ModuleName)*" |New-PSMDFormatTableDefinition
    Write-Output "`tSearching for assembly like '$($buildsettings.ModuleName)'"
    $Assembly = Get-PSMDAssembly -Filter "*$($buildsettings.ModuleName)*"
    if(!$Assembly)
    {
        throw "Could not find assembly"
    }

    Write-Output "`tFinding all classes in assembly with tag like '$($CustomTypeTags.Class)'"
    $classes = @($Assembly |Find-PSMDType|?{$_.CustomAttributes.AttributeType.name -like "$($CustomTypeTags.Class)"})

    Write-Output "`tFound $($classes.count) classes. Searching for Hidden properties. Untagged are by default Public"
    foreach($Class in $classes)
    {
        Write-output "`t`tClass: $($class.fullname)"

        $Hiddenproperties = $class.DeclaredProperties|?{$_.CustomAttributes.AttributeType.name -eq $($CustomTypeTags.PropertyHide)}
        $Hiddenproperties.name|%{Write-output "`t`t`tHiding '$_'"}
        $UsingClass = Invoke-AssemblyLoader -Type $class -SearchOption "AllDirectories"

        #Create and export Xml fragment
        $SaveDir = Join-Path $buildsettings.build "PSXML"
        $classxml = $UsingClass|New-PSMDFormatTableDefinition -ExcludeProperty $Hiddenproperties.name -Fragment
        $classxml|Out-File (Join-Path $SaveDir "$($class.fullname).xml") -Force
        Write-Output "`t`t-----"
    }
}

Task Test {
    Invoke-Pester -CodeCoverage $buildsettings.dev -Show None
    #pester $buildsettings.
}

Task ModuleManifest {
    $Manifest = $buildsettings.ModuleManifest
    New-ModuleManifest @Manifest 
}