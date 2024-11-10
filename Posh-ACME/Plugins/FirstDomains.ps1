$UserAgent = "Posh ACME/1.0"
function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(Mandatory, Position = 2)]
        [PSCredential]$FirstDomainsCreds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Do work here to add the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.
    $WebSession = Get-FirstDomainsLogin $FirstDomainsCreds
    $RootName = Get-FirstDomainsRootName $RecordName $WebSession
    Add-FirstDomainsRecord $RecordName $TxtValue $RootName $WebSession

    <#
    .SYNOPSIS
        Add a DNS TXT record to 1st Domains

    .DESCRIPTION
        Description for 1st Domains

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(Mandatory, Position = 2)]
        [PSCredential]$FirstDomainsCreds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Do work here to remove the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.
    $WebSession = Get-FirstDomainsLogin $FirstDomainsCreds
    $RootName = Get-FirstDomainsRootName $RecordName $WebSession
    $Id = Get-FirstDomainsRecordId $TxtValue $RootName $WebSession
    Remove-FirstDomainsRecord $Id $RootName $WebSession

    <#
    .SYNOPSIS
        Remove a DNS TXT record from 1st Domains

    .DESCRIPTION
        Description for 1st Domains

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, just
    # leave the function body empty.

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to 1st Domains

    .DESCRIPTION
        Description for 1st Domains

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications.
    #>
}

############################
# Helper Functions
############################

# Add a commented link to API docs if they exist.

# Add additional functions here if necessary.

# Try to follow verb-noun naming guidelines.
# https://msdn.microsoft.com/en-us/library/ms714428
function Get-FirstDomainsLogin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [PSCredential]$FirstDomainsCreds
    )

    $body = @{ 
        action           = "login"
        account_login    = $FirstDomainsCreds.UserName
        account_password = $FirstDomainsCreds.GetNetworkCredential().Password
    }
    
    $resp = Invoke-RestMethod -Method Post -Body $body -UserAgent $UserAgent -SessionVariable "WebSession" -Uri "https://1stdomains.nz/client/login.php" @script:UseBasic
    Write-Debug $resp
    return $WebSession
}

function Add-FirstDomainsRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RootName,
        [Parameter(Mandatory, Position = 3)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    $body = @{ 
        library        = "zone_manager"
        action         = "add_record"
        domain_name    = $RootName
        host_name      = $RecordName
        record_type    = "TXT"
        record_content = $TxtValue
    }

    $headers = @{
        Referer = "https://1stdomains.nz/client/account_manager.php"
    }
    
    $resp = Invoke-RestMethod -Method Post -Body $body -Headers $headers -UserAgent $UserAgent -WebSession $WebSession -Uri "https://1stdomains.nz/client/json_wrapper.php" @script:UseBasic
    Write-Debug $resp
}

function Remove-FirstDomainsRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordId,
        [Parameter(Mandatory, Position = 1)]
        [string]$RootName,
        [Parameter(Mandatory, Position = 2)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    $body = @{ 
        library         = "zone_manager"
        action          = "del_records"
        domain_name     = $RootName
        checked_records = $RecordId
    }

    $headers = @{
        Referer = "https://1stdomains.nz/client/account_manager.php"
    }

    $resp = Invoke-RestMethod -Method Post -Body $body -Headers $headers -UserAgent $UserAgent -WebSession $WebSession -Uri "https://1stdomains.nz/client/json_wrapper.php" @script:UseBasic
    Write-Debug $resp
}

function Get-FirstDomainsRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RootName,
        [Parameter(Mandatory, Position = 1)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    $body = @{ 
        library     = "zone_manager"
        action      = "load_records"
        domain_name = $RootName
    }

    $headers = @{
        Referer = "https://1stdomains.nz/client/account_manager.php"
    }

    $resp = Invoke-RestMethod -Method Post -Body $body -Headers $headers -UserAgent $UserAgent -WebSession $WebSession -Uri "https://1stdomains.nz/client/json_wrapper.php" @script:UseBasic
    Write-Debug $resp
    return $resp
}

function Get-FirstDomainsRecordId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 1)]
        [string]$RootName,
        [Parameter(Mandatory, Position = 2)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    $body = @{ 
        library     = "zone_manager"
        action      = "load_records"
        domain_name = $RootName
    }

    $headers = @{
        Referer = "https://1stdomains.nz/client/account_manager.php"
    }

    $resp = Invoke-RestMethod -Method Post -Body $body -Headers $headers -UserAgent $UserAgent -WebSession $WebSession -Uri "https://1stdomains.nz/client/json_wrapper.php" @script:UseBasic
    Write-Debug $resp
    foreach ($row in $resp.rows) {
        if ($row.cell[3] -eq $TxtValue) { 
            return $row.cell[0]
        }
    }
}

function Get-FirstDomainsRootName {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:FirstDomainsRecordZones) { 
        $script:FirstDomainsRecordZones = @{} 
    }

    # check for the record in the cache
    if ($script:FirstDomainsRecordZones.ContainsKey($RecordName)) {
        return $script:FirstDomainsRecordZones.$RecordName
    }

    $splits = $RecordName -split '\.'
    $currentLine = ""
    for ($i = $splits.Count - 1; $i -ge 0; $i--) {
        if ($currentLine -ne "") { 
            $currentLine = $splits[$i] + "." + $currentLine 
        }
        else {
            $currentLine = $splits[$i] + "" 
        }

        if ($i -eq $splits.Count - 1) {
            continue
        }

        $body = @{ 
            library     = "zone_manager"
            action      = "load_records"
            domain_name = $currentLine
        }

        $headers = @{
            Referer = "https://1stdomains.nz/client/account_manager.php"
        }

        $resp = Invoke-RestMethod -Method Post -Body $body -Headers $headers -UserAgent $UserAgent -WebSession $WebSession -Uri "https://1stdomains.nz/client/json_wrapper.php" @script:UseBasic
        Write-Debug $resp
        if (-not $resp.errors) {
            $script:FirstDomainsRecordZones.$RecordName = $currentLine
            return $currentLine
        }
    }
}
