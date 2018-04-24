Function Convert-Dynamictags
{
    [cmdletbinding()]
    param
    (
        [hashtable]$hashtable,
        [String]$Tag,
        [string]$Dynamicvariable = "%"
        # #Not normally used
        # [hashtable]$RefHashtable
    )

    DynamicParam {
        #if it calls upon itself, deliver this parameter
        $Thiscommand = (Get-PSCallStack)[0].Command
        #Write-Verbose $Thiscommand
        #$LastCommand = (Get-PSCallStack)[1].Command
        if ($Thiscommand -eq "Convert-Dynamictags") {
            #create a new ParameterAttribute Object
            $ageAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ageAttribute.Position = 3
 
            #create an attributecollection object for the attribute we just created.
            $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
 
            #add our custom attribute
            $attributeCollection.Add($ageAttribute)
 
            #add our paramater specifying the attribute collection
            $ageParam = New-Object System.Management.Automation.RuntimeDefinedParameter('RefHashtable', [hashtable], $attributeCollection)
 
            #expose the name of our parameter
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('RefHashtable', $ageParam)
            return $paramDictionary
       }
    }
    process
    {
        $RefHashtable = $PSBoundParameters.RefHashtable

        if ([bool]$RefHashtable)
        {
            $WorkingHashtable = $RefHashtable
        }
        else
        {
            $WorkingHashtable = $hashtable
        }
        
        if ($WorkingHashtable[$Tag] -ne $null)
        {
            write-verbose "`tFound Tag: $tag. searching for value with dynamicvariable '$Dynamicvariable'"
            if ($WorkingHashtable["value"] -like "*%*")
            {
                write-verbose "`tInput: '$($WorkingHashtable["value"])'"
                $split = @($WorkingHashtable["value"] -split "($Dynamicvariable)")|? {$_}
                $Recordvalues = @()
                $record = $false
                for ($i = 0; $i -lt $split.Count; $i++)
                {
                    if ($record -eq $false -and $split[$i] -eq $Dynamicvariable)
                    {
                        $record = $true
                    }
                    elseif ($record -eq $true -and $split[$i] -eq $Dynamicvariable)
                    {
                        $record = $false
                    }
                    elseif ($record -eq $true)
                    {
                        Write-Verbose "`t`t$($split[$i]) = $($hashtable[$split[$i]])"
                        if($hashtable[$split[$i]] -eq $null)
                        {
                            Throw "Could not find $($split[$i]) in hashtable"
                        }
                        $split[$i] = $hashtable[$split[$i]]
                    }
                }
                $WorkingHashtable["value"] = $(($split|? {$_ -ne $Dynamicvariable}) -join '')           
            }
            Write-Verbose "`tReturn '$($WorkingHashtable["value"])'"
            return $WorkingHashtable["value"]
        }
        @($WorkingHashtable.GetEnumerator()).ForEach{

            if ($_.value.gettype().name -eq "hashtable")
            {
                Write-verbose "Checking out $($_.name)=@{..}"
                $WorkingHashtable[$_.name] = Convert-Dynamictags -hashtable $hashtable -RefHashtable $_.value -Tag $Tag -Dynamicvariable $Dynamicvariable
            }
        }
        return $WorkingHashtable
    }
}