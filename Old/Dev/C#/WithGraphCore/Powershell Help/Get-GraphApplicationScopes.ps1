
$TopLevel = git rev-parse --show-toplevel
$HTMLDLL = Get-ChildItem -Path $TopLevel -Filter "HtmlAgilityPack.dll" -Recurse|select -First 1
Add-Type -Path $HTMLDLL.FullName
$url = "https://developer.microsoft.com/en-us/graph/docs/concepts/permissions_reference"

$Web = [HtmlAgilityPack.HtmlWeb]::new()
$doc = $web.Load($url)
$values = $doc.DocumentNode.SelectNodes("//tbody/tr")
$allPermissions = @()
foreach($value in $values)
{
    $Array = $value.innertext.split("`n")|%{$_.trim()}|?{$_ -ne ""}
    if($Array.count -eq 4)
    {
        $allPermissions += [PSCustomObject]@{
            Permission = $array[0]
            ShortDesc = $array[1]
            LongDec = $array[2]
            RequiresAdmin = if($array[3] -match "no"){$false}else{$true}
            Raw = $array
        }
    }
}
$allPermissions|ConvertTo-Json
#Invoke-WebRequest -Uri $url