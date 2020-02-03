[cmdletbinding()]
param()

Properties {
    $git = "https://github.com/microsoftgraph/microsoft-graph-docs.git"
    $localgitfolder = "$PSScriptRoot\Graphdocs"
    $WorkingDirectory = "$PSScriptRoot\Working"
    # $ZipUrl = "https://github.com/microsoftgraph/microsoft-graph-docs/archive/master.zip"
    # $srcPath = $PSScriptRoot 
    $Apis = [ordered]@{
        "v1.0"   = "api-reference/v1.0/api"
        beta = "api-reference/beta/api"
    }
    $InformationPreference = "Continue"
}

task default -depends downloadrepo, ExtractApiData

function GetMDTitles
{
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.MatchInfo[]])]
    param (
        $Path,
        [ValidateRange(2,10)]
        $MaxTitleTags = 5
    )
    
    return @(Select-string -Path $Path -Pattern "^[#]{1,5} \w+")
}

function Get-MdTable {
    [CmdletBinding()]
    param (
        [string[]]$Content,
        [int]$Startline,
        [int]$Endline,
        [int]$MaxTitleLength = 15
    )
    $tables = @{}

    for ($i = $Startline; $i -lt $Endline; $i++) {
        if($Content[$i] -like "|*")
        {
            Write-verbose "Found table start at line $i"
            $tbl = @()
            while($Content[$i] -like "|*")
            {
                if($Content[$i] -notlike "|*:--*")
                {
                    # Write-Verbose $Content[$i]
                    $tbl += ($Content[$i] -replace "[nN]ot [sS]upported\.|[nN]ot [sS]upported","")
                }
                $i++
            }
            $tables.$([guid]::NewGuid().Guid) = $tbl
        }
    }

    if($tables.count -eq 0)
    {
        throw "Could not find any table between lines $startline -> $Endline"
    }
    Write-Verbose "Found $($tables.Count) tables"

    $tables.Keys|%{
        $TableMD = $tables.$_|ForEach-Object{$_.substring(1) -replace "[() ]",""}
        $TableMD[0] = @($TableMD[0].split("|")|%{
            if($_.length -gt $MaxTitleLength)
            {
                $_.substring(0,$MaxTitleLength)
            }
            else {
                $_ 
            }
        }) -join "|"
        # Write-verbose ($TableMD|ConvertTo-Json)
        Write-Output ($TableMD|ConvertFrom-Csv -Delimiter "|")
    } 
}

function Get-DocumentMetadata 
{
    [CmdletBinding()]
    param (
        [System.IO.FileInfo]$Document,
        [String[]]$Content
    )
    $ret = @{
        HasKeys = $false
        KeyEnd = 0
        HasEmptyLines = $false
        KeySet = @{
        }
    }
    if($Content[0] -like "---*")
    {
        $ret.HasKeys = $true
        $Line = 1
        :SkipTags While($true)
        {
            if($line -eq $Content.Count)
            {
                Throw "Document $document`: Found start of page metadata, but not end.. is something missing?"
            }
            elseif($content[$Line] -like "---*")
            {   
                $line++
                $ret.KeyEnd = $line

                break :SkipTags
            }
            elseif($content[$Line] -match "^\s*$")
            {
                $ret.HasEmptyLines = $true
            }
            $line++
        }
        try{
            $ret.KeySet = ConvertFrom-Yaml -Yaml $(($Content[0..$line]|?{$_ -notlike "---*"}) -join "`n") -Verbose
        }
        catch{
            Throw "Error reading metadata at document $($Document.Fullname.Replace($basedir,'')): $($_.Exception.InnerException.Message)"
        }
    }

    return $ret
}

task CleanFolder {
    Write-Information "Cleaning $PSScriptRoot"
    $items = gci $PSScriptRoot -Exclude "*.ps1", ".gitignore","ApiDef_*.json" -force | remove-item -Recurse -Force
}

task downloadrepo -depends CleanFolder {
    cd $PSScriptRoot
    $GitFolder = get-item (Join-Path $localgitfolder ".git") -Force -ErrorAction SilentlyContinue

    if([string]::IsNullOrEmpty($GitFolder))
    {
        Write-Information "Downloading files from git: $git"
        git clone $git $localgitfolder
    }
    else {
        Write-Information "Reset everything under $localgitfolder, and pull data from repo"
        cd $localgitfolder
        git reset --hard HEAD
        git clean -f -d
        git pull
    }
    # gci (Join-Path $localgitfolder $site) -Recurse
}

task ExtractApiData -depends downloadrepo{
    #foreach currapi in v1, beta keys
    foreach ($CurrApi in $Apis.Keys)
    {
        $ApiDefinition = @()
        Write-Information "Extracting data for '$CurrApi' api"

        # beta = "api-reference/beta/api"
        $UsingApi = $Apis.$CurrApi

        #current working directory
        $cwd = (Join-Path $localgitfolder $UsingApi)
        #|? basename -eq "calendargroup-delete"
        foreach($File in (Get-ChildItem $cwd -File -Filter "*.md"))
        {
            $_Title = $null
            $_version = $null
            $_product = $null
            $_description = $null
            $_Calls = $null
            $_Permissions = $null
            try{
                #foreach file in cwd
                $_version = $CurrApi

                $Content = [System.IO.File]::ReadAllLines($File)
                $metadata = Get-DocumentMetadata -Document $File -Content $Content
                # $metadata.KeySet
                $_product = $metadata.keyset."ms.prod"
                $_Title = $metadata.keyset.title
                $_description = $metadata.keyset.description

                #Get Permissions
                    #Get Title = permissions and next title
                $Titles = GetMDTitles -Path $file.Fullname
                $Permtitle = $titles|?{$_.Line -match "^[#]{1,4} Permissions" -or $_.Line -match "^[#]{1,4} Prerequisites"}|select -first 1
                if([string]::IsNullOrEmpty($PermTitle))
                {
                    Write-Error "Cannot find Permissions or Prerequisites title in document"
                }
                $NextTitle = $Titles|?{$_.LineNumber -gt $PermTitle.LineNumber}|Select-Object -First 1

                Write-Verbose "Permission goes from $($PermTitle.LineNumber) -> $($nexttitle.LineNumber)"
                
                $TableHash = @{
                    Content = $Content
                    Startline = $Permtitle.LineNumber 
                    Endline = $NextTitle.LineNumber
                }

                $PermTable = Get-MdTable @TableHash 

                $_Permissions = @{
                    DelegatedWork = @()
                    DelegatedPersonal = @()
                    Application = @()
                }
                foreach($tbl in $PermTable)
                {
                    if(![string]::IsNullOrWhiteSpace($PermTable.Permissiontype))
                    {
                        <#
                            Permissiontype                    Permissionsfrom
                            --------------                    ---------------
                            Delegatedworkorschoolaccount      SecurityEvents.Read.All,SecurityEvents.ReadWrite.All
                            DelegatedpersonalMicrosoftaccount
                            Application                       SecurityEvents.Read.All,SecurityEvents.ReadWrite.All
                            Delegatedworkorschoolaccount      EntitlementManagement.ReadWrite.All
                            DelegatedpersonalMicrosoftaccount
                            Application
                        #>
                        foreach($item in $PermTable)
                        {
                            $scope = @($item.Permissionsfrom.split(",")|?{$_})
                            switch -wildcard ($item.Permissiontype)
                            {
                                "*workorschool*"{
                                    $_Permissions.DelegatedWork = $scope
                                    break
                                }
                                "*personal*"{
                                    $_Permissions.DelegatedPersonal = $scope
                                    break
                                }
                                "app*"{
                                    $_Permissions.Application = $scope
                                    break
                                }
                                default{
                                    throw "Unknown permissiontype: $($item.Permissiontype)"
                                }
                            }
                        }
                    }
                    else {
                        <#
                        Calendar      Delegatedworkor                    Delegatedperson                    Application
                        --------      ---------------                    ---------------                    -----------
                        usercalendar  Calendars.Read,Calendars.ReadWrite Calendars.Read,Calendars.ReadWrite Calendars.Read,Calendars.ReadWrite
                        groupcalendar Group.Read.All,Group.ReadWrite.All
                        #>
                        foreach($item in $PermTable)
                        {
                            $_Permissions.DelegatedPersonal = @($item.Delegatedperson.split(",")|?{$_})
                            $_Permissions.DelegatedWork = @($item.Delegatedworkor.split(",")|?{$_})
                            $_Permissions.Application = @($item.Application.split(",")|?{$_})
                        }
                    }
                }


                # #Get webaddress 
                # # -> line where it stars with ```, possibly has whitespace and is followed by HTTP or http
                $WebCallLine = ($file|Select-String '^```\s{0,1}[HTPhtp]{4}'|select -First 1)
                $EndWebCallLine = ($file|Select-String '^```'|?{$_.LineNumber -gt $WebCallLine.LineNumber}|select -First 1)
                $_Calls = @()
                Write-Verbose "Http code block from $($WebCallLine.LineNumber) -> $($EndWebCallLine.LineNumber-1)"
                foreach($line in $content[$WebCallLine.LineNumber..($EndWebCallLine.LineNumber-1)])
                {
                    if(!$line.ToString().StartsWith('```'))
                    {
                        Write-Verbose "$line"
                        $_CallType = $line.Split(" ")[0]
                        $_CallAddress = ($line.Split(" ")|select -Skip 1) -join " "
                        $_Callmatch = $_CallAddress -replace "(\{[a-zA-Z_ |]{2,}\})","*"
                        $thiscall = [ordered]@{
                            Type = $_CallType
                            Address = $_CallAddress
                            match = $_Callmatch
                        }
                        if([String]::IsNullOrEmpty($thiscall.Type) -or 
                        [String]::IsNullOrEmpty($thiscall.Address) -or 
                        [String]::IsNullOrEmpty($thiscall.match)
                        ){}
                        else
                        {
                            $_Calls += $thiscall
                        }
                        # $_Calls += [ordered]@{
                        #     Type = $_CallType
                        #     Address = $_CallAddress
                        #     match = $_Callmatch
                        # }
                    }
                }

         
            }
            catch{
                $stacktrace = $_.ScriptStackTrace.split("at")[1].replace("`n",'')
                Write-Warning "Error handling file $CurrApi/$($file.basename): $_`: at $($stacktrace)"
            }
            $this = [ordered]@{
                version = $_version
                product = $_product
                title =  $_Title
                ApiDocPath = @{
                    #https://github.com/microsoftgraph/microsoft-graph-docs/blob/master/api-reference/v1.0/api/user-list.md
                    github = "$($git.Replace(".git",''))/blob/master/$($File.Fullname.replace($localgitfolder,'').replace('\','/'))"
                    #https://docs.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http
                    website = "https://docs.microsoft.com/en-us/graph/api/$($file.basename)?view=graph-rest-$($CurrApi.replace("v",''))&tabs=http"
                }
                description = $_description
                Permissions = $_Permissions
                Call = $_Calls
            } 
            $ApiDefinition += $this  
        }
        $encoding = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "ApiDef_$CurrApi.json"),($ApiDefinition|ConvertTo-Json -Depth 4),$encoding)
        # $ApiDefinition|ConvertTo-Json -Depth 4
    }
    gci $PSScriptRoot -Exclude "*.ps1", ".gitignore","ApiDef_*.json" -force | remove-item -Recurse -Force
}

