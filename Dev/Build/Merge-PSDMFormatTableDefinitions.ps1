Function Merge-PSDMFormatTableDefinitions
{
    [CmdletBinding(DefaultParameterSetName="FileInfoStream")]
    param(       
        [Parameter(
            ParameterSetName='FileInfoStream',
            ValueFromPipeline = $true)
        ]
        [System.IO.FileInfo]$FileObject,

        #If you have a path where the files is 
        [Parameter(ParameterSetName='Path')]
        [System.IO.DirectoryInfo]$Path,


        [Parameter(ParameterSetName='Path')]
        [String]$Filter,

        [Parameter(ParameterSetName='Path')]
        [ValidateSet("AllDirectories", "TopDirectoryOnly")]
        [System.IO.SearchOption]$SearchOption = "TopDirectoryOnly",

        [Parameter(ParameterSetName='__AllParameterSets')]
        [System.IO.FileInfo]$SaveName
    )

    Begin{
$xmlFullStart =@'
<?xml version="1.0" encoding="utf-16"?>
<Configuration>
    <ViewDefinitions>                 
'@
$xmlFullEnd =@'              
    </ViewDefinitions>
</Configuration>
'@

        $xml = @()
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq "Path")
        {
            return $path.GetFiles($Filter,$SearchOption)|%{Merge-PSDMFormatTableDefinitions -FileObject $_}
        }
        elseif($PSCmdlet.ParameterSetName -eq "FileInfoStream") 
        {
            $thisObject = @{
                xml = ""
                Path = $FileObject.FullName
            }
            $ThisXML = (Get-Content $FileObject.FullName)
            if([bool]$([xml]$ThisXML).configuration)
            {
                $thisxmlString = ([regex]::Match($ThisXML,".*(?'fragment'\s<!--.*</View>).*").groups['fragment'].value)            
                $thisObject.xml = $($thisxmlString -split ">\s"|%{"$_>"})
                $thisObject.xml = $thisObject.xml|%{$_.replace(">>",">")}
            }
            else 
            {
                $thisObject.xml =$thisxml
            }
            $xml += $thisObject
        }
    }
    End{
        #Setting the full string together
        $Returnxml = $xmlFullStart
        $Returnxml += [System.Environment]::NewLine

        $xml|%{
            $_.xml|%{                
                $Returnxml += $_
                $Returnxml += [System.Environment]::NewLine
            }
        }

        $Returnxml += [System.Environment]::NewLine
        $Returnxml += $xmlFullEnd

        if([String]::IsNullOrEmpty($SaveName))
        {
            $Returnxml
        }
        else {
            if($SaveName.Extension -notlike "ps1xml")
            {
                Write-Warning "Document saved with the extension:'$($SaveName.Extension)'. For it to work with Powershell you should save it as '.ps1xml'."
            }
            if($SaveName.Exists)
            {
                $SaveName.Delete()
            }

            $Returnxml|Out-File $SaveName.FullName
        }
        
    }

}

get-childitem "C:\git\Withgraph\Build\0.1.180502.0759\PSXML" -Filter "*.xml"|Merge-PSDMFormatTableDefinitions -SaveName "C:\git\Withgraph\Build\0.1.180502.0759\PSXML\test.psml" 