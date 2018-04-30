describe "WithGraph DLL"{
    #\bin\Debug\WithGraph.dll
    $Module = Join-Path $PSScriptRoot "\bin\Debug\WithGraph.dll"
    # Get-ChildItem $PSScriptRoot -Filter "Withgraph.dll" -Recurse|
    # Sort-Object LastWriteTimeUtc -Descending|
    #     Select-Object -First 1
    it "Can import without error"{
        {Import-Module $Module -Force}|should -Not -Throw
    }

    Import-Module $Module -Force


    It "Folder <Name> Tests passed" -TestCases $(
        @(Get-ChildItem $PSScriptRoot -Directory -Recurse|where{
            [bool](gci $_.FullName -Filter "*.test.ps1")}|%{
                @{
                    name = $_.name
                    Fullname = $_.fullname
                }
            }
        )
    ) {
        Param
        (
            $Name,
            $FullName
        )

        <#
        Customizes the output Pester writes to the screen. Available options are None, Default,
        Passed, Failed, Pending, Skipped, Inconclusive, Describe, Context, Summary, Header, All, Fails.
        #>
        $Tests = (Invoke-Pester -Script (gci $FullName -Filter "*.test.ps1").FullName -PassThru -Show Summary)
        if($tests.failedcount -gt 0)
        {
            $tests|convertto-json|Out-File (Join-Path $FullName "Testresult.json")
        }
        $Tests.failedcount | should -be 0
    } 

}

# Get-ChildItem $PSScriptRoot -Directory -Recurse|where{
#     [bool](gci $_.FullName -Filter "*.test.ps1")
# }|%{
#     (Invoke-Pester -Script (gci $_.FullName -Filter "*.test.ps1").FullName -Show None -PassThru)
# }
