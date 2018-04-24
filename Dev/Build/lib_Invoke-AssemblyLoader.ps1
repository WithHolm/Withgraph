Function Invoke-AssemblyLoader
{
    param(
        [System.Reflection.TypeInfo]$Type,
        [String]$PathToDLL,
        [System.IO.SearchOption]$SearchOption
    )
    try {
        if([bool]$PathToDLL)
        {        
            Write-Verbose "Loading $PathToDLL"
            Add-Type -Path $PathToDLL
        }
        elseif($Type -ne $null)
        {
            $PathToDLL = $type.Assembly.location
            new-object $type.FullName
            #new-object
        }

    }
    catch {
        #[System.IO.SearchOption]::AllDirectories
        #$_.Exception.LoaderExceptions.FileName|fl * -Force
        $References = $_.Exception.LoaderExceptions.FileName
        $References|%{
            Write-verbose "Missing Reference: $_"
            $recurse = ($SearchOption -eq [System.IO.SearchOption]::AllDirectories)
            $Referencefile = get-childitem (split-path $PathToDLL) -Filter "*$($_.split(',')[0])*" -Recurse:$recurse
            if(!$Referencefile)
            {
                Throw "Could not find reference file '$($_.split(',')[0])' under $searchbase"
            }
            Invoke-AssemblyLoader -PathToDLL $Referencefile.FullName -SearchOption $SearchOption
        }
    }
     #-ReferencedAssemblies @($Dependencies.FullName)
}
#[system.reflection.assembly]::lo