Function Write-GraphLog
{
    param(
        [Microsoft.Identity.Client.LogLevel]$LogLevel,
        [String]$Message,
        [bool]$PII
    )
    $PII = if($PII){"[PII]"}else{""}
    $Message = "[$($LogLevel.ToString())]$PII $message"
    if($LogLevel -eq [Microsoft.Identity.Client.LogLevel]::Verbose)
    {
        Write-Verbose $Message
    }
    elseif($LogLevel -eq [Microsoft.Identity.Client.LogLevel]::Info)
    {
        Write-Information $Message
    }
    else {
        Write-Verbose $Message
    }
}