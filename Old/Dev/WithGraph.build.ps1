param(
)

#remember to use ". invoke-build" before fixing this document to get the proper autocomplete

#Starting Build in new process, so the cus
Task . Startbuild

task Gather GatherPowershell, GatherCsharp
Task GeneratePsXml GeneratePsXmlPowershell,GeneratePsXmlCsharp

Task build CreateBuildFolder, RemoveOlderBuilds, Gather, GeneratePsxml #, ModuleManifest


Enter-Build {
    import-module PSFramework
    $Loadfiles = gci "$PSScriptRoot\Build" -Filter "Build_*.ps1"
    $Loadfiles| % {. $_.FullName -verbose}
    Write-Output "Setting up Variable"
    Get-Variable _*|? {$_.name.count -gt 2}| % {
        Write-verbose $_.name
        #Remove-Variable $_.Name -Force
    }

    $Script:_Filefilter = @{
        Powershell = @{
            Public  = "*.public.ps1"
            Private = "*.private.ps1"
        }
    }

    $Script:_Module = @{
        Root    = Get-ProjectRoot
        Name    = split-path (Get-ProjectRoot) -Leaf
        Version = "0.1.$(get-date -f "yyMMdd").$(get-date -f "HHmm")"
        GUID    = ([guid]::NewGuid().guid)
    }

    $script:_Directory = @{
        Build = @{
            DynamicTag = $true
            Value      = "%Module.Root%\Build\%Module.Version%"
        }
        Dev   = @{
            DynamicTag = $true
            Value      = "%Module.Root%\Dev"
        }
    }

    $script:_Csharp = @{
        Root         = (Join-path $PSScriptRoot "c#")
        Assemblyname = @{
            DynamicTag = $true
            Value      = "%Module.Name%Core"
        }
    }

    #Create a Common Hashtable to each hashtable can Identify eachother
    $Script:Common = @{}
    get-variable _*| % {
        $Script:Common.$($_.name.replace('_', '')) = $_.value
    }
    #$common|gm
    $Script:Common = Convert-Dynamictags -hashtable $Common -Tag "Dynamictag" -Dynamicvariable "%"
}

Task StartBuild {
    Start-Process PowerShell -ArgumentList "-noexit -command ""cd '$psscriptroot' ; invoke-build Build""" -Wait
}

Task RemoveOlderBuilds {
    $OldBuilds = gci (split-path $_Directory.build) -Directory|sort CreationTimeUtc -Descending|select -Skip 4
    Write-Output "Removing $(@($OldBuilds).Count) old projects"
    $OldBuilds|remove-item -Recurse
}

task CreateBuildFolder {
    $Build = $_Directory.build
    if (Test-Path $Build)
    {
        Write-Output "Removing $($Build)"
        rmdir $Build -ErrorAction SilentlyContinue -Force -Recurse|out-null
    }

    $Createfolders = @(
        $build,
        (Join-Path $Build "Code\PS"),
        (Join-Path $Build "Code\Csharp"),
        (Join-Path $Build "PSXML")
    )

    mkdir $Createfolders -Force| % {
        Write-Output "`t mkdir $($_.fullname.Replace("$Build\",'\'))"
    }
}

Task GatherPowershell {
    $Source = (Join-Path $script:_Directory.dev "Powershell")
    $Filefilter = @($script:_FileFilter.Powershell.values)
    $Destination = (Join-Path $script:_Directory.build "Code\ps")

    Write-Output "Gathering powershell files from $Source"
    Write-Output "tags: $($Filefilter -join ', ')"

    $PSFiles = @(Get-ChildItem $Source -Include $Filefilter -Recurse)

    Write-output "Processing $($PSFiles.count) Files"
    $PSFiles| % {
        $Fraction = (split-path $_.fullname).Replace($Source, '')
        $NewPath = Join-Path $Destination $Fraction
        if (!(Test-Path $NewPath))
        {
            Write-Output "`tCreating new dir: $newpath"
            mkdir $NewPath|out-null
        }
        Copy-Item -Path $_.fullname -Destination $NewPath|out-null
    }
}

Task GatherCsharp {
    $Root = $_Csharp.root
    $Destination = (Join-Path $script:_Directory.build "Code\Csharp")
    $Assemblyname = $_Csharp.Assemblyname

    Write-Output "The c# Repo is $($Root):"

    $SourcePath = $(join-path $Root "$Assemblyname\bin")

    Write-Output "`tFinding The Newest module DLL in $SourcePath"
    $csharpdll = Get-ChildItem $SourcePath -Filter "$Assemblyname*" -Recurse|Sort LastWriteTimeUtc|Select -Last 1

    $SourcePath = split-path $csharpdll.fullname
    write-output "`tFound file at $SourcePath. Copying the whole folder"
    
    Get-ChildItem $SourcePath -Force| % {
        Write-Output "`t$($_.fullname.replace($Root,''))"
        $_|copy-item -Destination $Destination -Recurse
    }
}

Task LoadDLL -Before GeneratePsXmlCsharp {  
    $DllPath =  "$($_Directory.build)\Code\csharp"
    $Assemblyname = $_Csharp.Assemblyname

    $DLL = (Get-ChildItem $DllPath -Filter "$Assemblyname*"|select -First 1)
    Write-Output "`t Load DLL: $($dll.fullname)"
    Import-Module $DLL.fullname -Force
    #[void][System.Reflection.Assembly]::LoadFile($DLL.fullname)
}



task GeneratePsXmlPowershell{

}

task GeneratePsXmlCsharp{
    ### Set Variables
    $CustomTypeTags = @{
        Class        = "PsClassAttribute"
        PropertyShow = "PsPropertyShowAttribute"
        PropertyHide = "PsPropertyHideAttribute"
    }

    $Assemblyname = $_Csharp.Assemblyname
    $XmlSaveDir = Join-Path $_Directory.build "PSXML"
    $FragmentEnd = "__fragment__.xml"
    ### 
    #Find assembly in reflection
    Write-Output "`tSearching for assembly like '$Assemblyname'"
    $Assembly = Get-PSMDAssembly -Filter "*$Assemblyname*"
    if (!$Assembly)
    {
        throw "Could not find assembly"
    }

    #Search the specified assembly for classes that have a specific custom attribute
    Write-Output "`tFinding all classes in assembly with tag like '$($CustomTypeTags.Class)'"
    $classes = @($Assembly |Find-PSMDType|? {$_.CustomAttributes.AttributeType.name -like "$($CustomTypeTags.Class)"})

    #search in those classes to find properties that have specific custom attributes
    Write-Output "`tFound $($classes.count) classes. Searching for Hidden properties. Untagged are by default Public"
    $classes.foreach{
        $UsingClass = new-object $_.fullname
        $Hiddenproperties = $_.DeclaredProperties|? {$_.CustomAttributes.AttributeType.name -eq $($CustomTypeTags.PropertyHide)}
        Write-host "`t`t`tHiding $($Hiddenproperties.name -join ',')"

        $param = @{
            InputObject = $UsingClass
            ExcludeProperty = $Hiddenproperties.name
            Fragment = $true
        }
        New-PSMDFormatTableDefinition @param -Verbose
    }|Merge-PSDMFormatTableDefinitions -SaveName (join-path $_Directory.build "psxml\csharp.ps1xml")
}

task GatherxmlFragments {
    $XmlSaveDir = Join-Path $_Directory.build "PSXML"
    $FinalXMLPath = join-path $XmlSaveDir "$($Script:_Module.Name).psxml"
    $FragmentEnd = "__fragment__.xml"
    New-PSMDFormatTableDefinition -
    Get-ChildItem $XmlSaveDir -Filter "*$FragmentEnd*"
}

Task Test {
    Invoke-Pester -CodeCoverage $buildsettings.dev -Show None
    #pester $buildsettings.
}

Task ModuleManifest {
    $Manifest = $buildsettings.ModuleManifest
    New-ModuleManifest @Manifest 
}