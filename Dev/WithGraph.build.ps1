param(
)

#remember to use ". invoke-build" before fixing this document to get the proper autocomplete
Task . Startbuild
Task Build RemoveOlderBuilds,CreateBuildFolder,GatherFiles,GeneratePsxml


Enter-Build {
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
    }
    $Script:Buildsettings = Convert-Dynamictags -hashtable $Script:Buildsettings -Tag "Dynamictag" -Dynamicvariable "%"
}

Task StartBuild {
    Start-Process PowerShell -ArgumentList "-noexit -command ""cd $psscriptroot ; invoke-build Build -verbose """
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
            (Join-Path $Buildsettings.build "Code\Csharp\Dep")) -Force|%{
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

    $csharp |Copy-Item -Destination (Join-Path $Buildsettings.build "Code\Csharp")
    write-output "`tFound $(@($csharp).count) Files"
    
    $CsharpNugetPackagesPath = (join-path $(split-path $Solution.FullName) "packages")
    if(!(Test-Path $CsharpNugetPackagesPath))
    {
        Throw "Could not find packages folder"
    }
    Write-Output "`tGathering C# Packages"

    $CopyTo = (Join-Path $Buildsettings.build "Code\Csharp\dep")
    foreach ($folder in Get-ChildItem $CsharpNugetPackagesPath -Directory -Exclude $Buildsettings.FileFilter.Csharp.references.Ignore)
    {
        $LibFolder = Join-Path $folder.fullname "lib" -Resolve
        $VersionFolder = ""
        :VersionCheck Foreach($Version in $Buildsettings.DotNetVersion)
        {
            $VersionFolder = (join-path $LibFolder $Version)
            if(test-path $VersionFolder)
            {
                break :VersionCheck
            }
            else {
                $VersionFolder = ""   
            }
        }
        if(!$VersionFolder)
        {
            Throw "Could not find the correct .net version of $($folder.name). Avalible: $((Get-ChildItem $LibFolder -Directory).Name -join ', ').Please update buildsettings.DotNetVersion"
        }

        Write-verbose "$($folder.name) = $(split-path $VersionFolder -Leaf)"
        get-childitem $VersionFolder -Filter "*.dll"|Copy-Item -Destination $CopyTo -Force
    } 
    Write-output "`tGathered $(@(gci $CopyTo).count) Packages" 
}

Task LoadDLL -Before GeneratePsxml{
    
    $DLL = (Get-ChildItem "$($buildsettings.build)\Code\csharp" -Filter "*.dll"|select -First 1)
    Write-Output "`t Load DLL: $($dll.fullname)"
    #[void][System.Reflection.Assembly]::LoadFrom($DLL.fullname)
    $param = @{
        PathToDLL = (Get-ChildItem "$($buildsettings.build)\Code\csharp" -Filter "*.dll" -Recurse|select -First 1).FullName
        Searchoption = "AllDirectories"
    }
    Invoke-AssemblyLoader @param
    # $Dependencies = get-childitem (Join-Path $Buildsettings.build "Code\Csharp\dep")
    # $csharp = (Get-ChildItem $buildsettings.build -Filter "*.dll" -Recurse)

    # Write-verbose "$($Dependencies.count) Dependencies"

    # Add-Type -Path $csharp.FullName -ReferencedAssemblies @($Dependencies.FullName)
}

task GeneratePsxml {
    Write-Output "Gathering info from the PsXml"
    Write-Output "C#"

    $CustomTypeTags = @{
        Class = "PsClassAttribute"
        PropertyShow = "PsPropertyShowAttribute"
        PropertyHide = "PsPropertyHideAttribute"
    }
    #Get-PSMDAssembly -Filter "*$($buildsettings.ModuleName)*" |New-PSMDFormatTableDefinition
    Write-Output "Searching for assembly like '$($buildsettings.ModuleName)'"
    $Assembly = Get-PSMDAssembly -Filter "*$($buildsettings.ModuleName)*"
    if(!$Assembly)
    {
        throw "Could not find assembly"
    }

    Write-Output "Finding all classes in assembly with tag like '$($CustomTypeTags.Class)'"
    $classes = @($Assembly |Find-PSMDType|?{$_.CustomAttributes.AttributeType.name -like "$($CustomTypeTags.Class)"})

    Write-Output "Found $($classes.count) classes. Searching for Hidden properties. Untagged are by default Public"
    foreach($Class in $classes)
    {
        #$Class
        $Hiddenproperties = $class.DeclaredProperties|?{$_.CustomAttributes.AttributeType.name -eq $($CustomTypeTags.PropertyHide)}
        Write-Output "Excluding $(($Hiddenproperties.name|%{"'$_'"}) -join ', ')"
        $UsingClass = Invoke-AssemblyLoader -Type $class -SearchOption "AllDirectories"
        $UsingClass|New-PSMDFormatTableDefinition -ExcludeProperty $Hiddenproperties.name
        # $class|fl * -Force
        # #$class|gm
        # $class.Assembly.location
        #new-object $Class|New-PSMDFormatTableDefinition -ExcludeProperty $Hiddenproperties.name
        #$Class|New-PSMDFormatTableDefinition
    }
}

Task Test {
    Invoke-Pester -CodeCoverage $buildsettings.dev -Show None
    #pester $buildsettings.
}

# task GatherFiles {
#     get-childitem -Path $Buildsettings.Dev -Recurse "WithGraph.dll"
# }

# task Task2 {
#     'Doing Task2...'
# }