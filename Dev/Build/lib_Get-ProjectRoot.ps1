Function Get-ProjectRoot
{
    param(
        [System.IO.DirectoryInfo]$path = $PSScriptRoot,
        [int]$MaxTraverse = 5
    )

    $count = 0
    while(!$path.GetDirectories(".git") -and $count -lt $MaxTraverse)
    {
        $path = $path.Parent
        $count++
    }

    if([bool]$path.GetDirectories(".git"))
    {
        return $path.FullName
    }
    else {
        Throw "Could not find the git folder"
    }
}

#Get-ProjectName