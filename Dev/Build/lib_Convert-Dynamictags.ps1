<#
    $Testhash = @{
        Root =  "test\path"
        ModuleName = split-path "test\path" -Leaf
        Modules = @("InvokeBuild","Pester")
        Version = "0.1.$(get-date -f "yyMMdd").$(get-date -f "HHmm")"
        auild3 = @{
            DynamicTag = $true
            Value      = "%Build2%"
        }
        Build = @{
            DynamicTag = $true
            Value      = "%Root%\Build\%Version%"
        }
        Build2 = @{
            DynamicTag = $true
            Value      = "%Build%"
        }
    }
    Convert-Dynamictags -hashtable $Testhash -Tag "DynamicTag" -Dynamicvariable "%" -Verbose

#>
Function Convert-Dynamictags
{
    [cmdletbinding()]
    param
    (
        #HashTable
        [hashtable]$hashtable,
        #what tag to look for
        [String]$Tag,

        [string]$Dynamicvariable = "%"
    )

    DynamicParam {
        #if it calls upon itself, deliver this parameter
        $Thiscommand = (Get-PSCallStack)[0].Command
        #this is the hashtable it it working with right now. If it finds more hashtables in this Table, it will recurivley call upon itself, using this Value to reference the current "scope"
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
        if($Global:__DynamictagsDoAnotherPass -eq $null)
        {
            $Global:__DynamictagsDoAnotherPass = $false
        }

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
            $DoThisLater = $false
            if ($WorkingHashtable["value"] -like "*$Dynamicvariable*")
            {
                write-verbose "`tInput: '$($WorkingHashtable["value"])'"

                #Split on DynamicValue = "test\%Test%\t" = "test\","%","test","%","\t"
                $split = @($WorkingHashtable["value"] -split "($Dynamicvariable)")|? {$_}

                <#
                    When record is true, pick up whatever is next and find this in the full hashtable
                    turns on or off if it comes to dynamicvariable
                #>
                $record = $false          
                :DynamicSearch for ($i = 0; $i -lt $split.Count; $i++)
                {
                    if ($split[$i] -eq $Dynamicvariable)
                    {
                        $record = !$record
                    }
                    elseif ($record -eq $true)
                    {
                        #STEP 1: Find the referenced value
                        if($split[$i] -like "*.*")
                        {
                            Write-verbose "`tRecurse reference: $($split[$i])"
                            $ref = $hashtable
                            foreach($value in $($split[$i].ToString().Split('.')))
                            {
                                $ref = $ref[$value]
                            }
                        }
                        else
                        {
                            $Ref = $hashtable[$split[$i]]
                        }
                        #$Ref = $hashtable[$split[$i]]

                        #Step 2: Check if it found Bool,String or int.  
                        $TestArray = @([bool],[int],[String])
                        if(!$TestArray.where{$Ref -is $_})
                        {
                            #Test if its a Dynamic Hash, like the one we are checking out. 
                            #This means that the value is not ready to be consumed and we need to take a second pass on the whole hashtable again (then with the reference value updated).
                            if([bool]$ref.$Tag -and [bool]$ref.Value -and ($ref -is [hashtable]))
                            {
                                $Global:__DynamictagsDoAnotherPass = $true
                                $DoThisLater = $true
                                Write-Verbose "`tGoing to do another iteration of this hashtable because the current value '$($split[$i])' refers to a value thats also a dynamic value."
                                break :dynamicSearch
                            }
                            else
                            {
                                #The value is something else.. throwing
                                throw "Current reference '$($split[$i])' is not a desired refence: $($ref.gettype()) . should be $(($TestArray|%{$_.tostring()}) -join ', ')  or dynamic value"
                            }
                        }
                        
                        #Test for null
                        if($Ref -eq $null)
                        {
                            Throw "Could not find $($split[$i]) in hashtable"
                        }

                        Write-Verbose "`t`t$($split[$i]) = $($Ref)"
                        $split[$i] = $Ref
                    }
                }
                if($DoThisLater -eq $false)
                {
                    $WorkingHashtable["value"] = $(($split|? {$_ -ne $Dynamicvariable}) -join '')  
                    $DoThisLater = $false
                }           
            }
            if($DoThisLater -eq $false)
            {
                Write-Verbose "`tReturn '$($WorkingHashtable["value"])'"
                return $WorkingHashtable["value"]
            }
            else {
                Write-Verbose "`tReturning same value. Will do another iteration"
                return $WorkingHashtable
            }

        }
        @($WorkingHashtable.GetEnumerator()).ForEach{
            if ($_.value.gettype().name -eq "hashtable")
            {
                Write-verbose "Checking out $($_.name)=@{..}"
                $WorkingHashtable[$_.name] = Convert-Dynamictags -hashtable $hashtable -RefHashtable $_.value -Tag $Tag -Dynamicvariable $Dynamicvariable
            }
        }
        
        #Top iteration of hashtable. 
        #Check if __DynamictagsDoAnotherPass has been turned true. means a value could not be found as the value its referencing is also a Dynamic variable
        #$Lastcommand = (Get-PSCallStack)[1].Command
        if($PSBoundParameters.RefHashtable -eq $null)
        {
            while($Global:__DynamictagsDoAnotherPass -eq $true) 
            {
                Write-verbose "Doing a secondary run becuase there was reference to a value that has not been found out yet"
                $Global:__DynamictagsDoAnotherPass = $false
                $WorkingHashtable = Convert-Dynamictags -hashtable $hashtable -Tag $Tag -Dynamicvariable $Dynamicvariable
            }
            $Global:__DynamictagsDoAnotherPass = $null
            return $WorkingHashtable
        }
        else {
            return $WorkingHashtable
        }
        
    }
}

##Test
# $Testhash = @{
#     Root =  "test\path"
#     ModuleName = split-path "test\path" -Leaf
#     Modules = @("InvokeBuild","Pester")
#     Version = "0.1.$(get-date -f "yyMMdd").$(get-date -f "HHmm")"
#     InnerRef = @{
#         Test = "Value"
#     }
#     InnerrefTest = @{
#         DynamicTag = $true
#         Value      = "%InnerRef.Test%"
#     }
#     Normal = @{
#         DynamicTag = $true
#         Value      = "%Root%"
#     }
#     # ErrorObj = [pscustomobject]@{
#     #     DynamicTag = $true
#     #     Value      = "%Build2%"
#     # }
#     aRecurseTest = @{
#         DynamicTag = $true
#         Value      = "%Normal%"
#     }
# }

# Convert-Dynamictags -hashtable $Testhash -Tag "DynamicTag" -Dynamicvariable "%" -Verbose