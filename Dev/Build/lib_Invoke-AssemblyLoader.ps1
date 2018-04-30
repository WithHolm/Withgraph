Function Invoke-AssemblyLoader
{
    [cmdletbinding()]
    param(
        [System.Reflection.TypeInfo]$Type,
        [String]$PathToDLL,
        [System.IO.SearchOption]$SearchOption
    )
    try {
        if([bool]$PathToDLL)
        {        
            #Write-Verbose "Loading $PathToDLL"
            Add-Type -Path $PathToDLL
            Write-Verbose "Loaded $PathToDLL"
        }
        elseif($Type -ne $null)
        {
            $PathToDLL = $type.Assembly.location
            new-object $type.FullName
            Write-Verbose "Loaded $($type.FullName)"
            #new-object
        }

    }
    catch {
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
        if($Type -ne $null)
        {
            $PathToDLL = ""
        }
        return Invoke-AssemblyLoader -Type $Type -PathToDLL $PathToDLL -SearchOption $SearchOption
    }
     #-ReferencedAssemblies @($Dependencies.FullName)
}
#[system.reflection.assembly]::lo