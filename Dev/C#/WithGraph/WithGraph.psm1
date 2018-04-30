$CsharpNugetPackagesPath = get-childitem (join-path (split-path $psscriptroot -Parent) "packages") 
foreach ($folder in $CsharpNugetPackagesPath)
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

