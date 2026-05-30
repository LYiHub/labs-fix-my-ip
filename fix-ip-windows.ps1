param(
    [Parameter(Position = 0)]
    [ValidateSet("apply", "restore")]
    [string]$Mode = "apply",

    [string]$Gateway = "192.168.14.9",
    [string]$Dns = "198.18.0.2",
    [string]$StateDirectory = "$env:ProgramData\FixMyIP"
)

$ErrorActionPreference = "Stop"
$StateFile = Join-Path $StateDirectory "target-adapters.txt"

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Convert-PrefixLengthToSubnetMask {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 32)]
        [int]$PrefixLength
    )

    $octets = for ($i = 0; $i -lt 4; $i++) {
        $remainingBits = $PrefixLength - ($i * 8)

        if ($remainingBits -ge 8) {
            255
        }
        elseif ($remainingBits -le 0) {
            0
        }
        else {
            [int](256 - [math]::Pow(2, 8 - $remainingBits))
        }
    }

    return ($octets -join ".")
}

function Get-CurrentTargetAdapters {
    Get-NetAdapter -Physical |
        Where-Object { $_.Status -eq "Up" } |
        ForEach-Object {
            $adapter = $_
            $ipv4 = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.IPAddress -notlike "169.254.*" -and
                    $_.IPAddress -ne "127.0.0.1" -and
                    $_.PrefixOrigin -ne "WellKnown"
                } |
                Sort-Object -Property SkipAsSource, PrefixOrigin |
                Select-Object -First 1

            if ($null -ne $ipv4) {
                [pscustomobject]@{
                    Adapter      = $adapter
                    InterfaceId  = $adapter.InterfaceIndex
                    InterfaceAlias = $adapter.Name
                    IPAddress    = $ipv4.IPAddress
                    PrefixLength = $ipv4.PrefixLength
                    SubnetMask   = Convert-PrefixLengthToSubnetMask -PrefixLength $ipv4.PrefixLength
                }
            }
        }
}

function Invoke-Netsh {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & netsh @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "netsh failed with exit code $LASTEXITCODE: netsh $($Arguments -join ' ')"
    }
}

function Apply-NetworkSettings {
    $targets = @(Get-CurrentTargetAdapters)

    if ($targets.Count -eq 0) {
        throw "No active physical IPv4 adapters were found."
    }

    New-Item -ItemType Directory -Path $StateDirectory -Force | Out-Null
    Set-Content -Path $StateFile -Value ($targets.InterfaceAlias) -Encoding UTF8

    foreach ($target in $targets) {
        Write-Host "Apply $($target.InterfaceAlias): IP=$($target.IPAddress), subnet=$($target.SubnetMask), gateway=$Gateway, DNS=$Dns"

        Invoke-Netsh -Arguments @(
            "interface", "ipv4", "set", "address",
            "name=$($target.InterfaceAlias)",
            "static",
            $target.IPAddress,
            $target.SubnetMask,
            $Gateway,
            "1"
        )

        Set-DnsClientServerAddress -InterfaceIndex $target.InterfaceId -ServerAddresses $Dns
    }

    Write-Host "Updated $($targets.Count) adapter(s)."
}

function Get-RestoreAdapterNames {
    if (Test-Path $StateFile) {
        return @(Get-Content -Path $StateFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    Write-Host "State file not found. Restoring all active physical IPv4 adapters."
    return @((Get-CurrentTargetAdapters).InterfaceAlias)
}

function Restore-NetworkSettings {
    $adapterNames = @(Get-RestoreAdapterNames)

    if ($adapterNames.Count -eq 0) {
        throw "No adapters were found to restore."
    }

    foreach ($adapterName in $adapterNames) {
        $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue

        if ($null -eq $adapter) {
            Write-Warning "Skip $adapterName: adapter not found."
            continue
        }

        Write-Host "Restore $adapterName: DHCP address, automatic DNS."

        Invoke-Netsh -Arguments @(
            "interface", "ipv4", "set", "address",
            "name=$adapterName",
            "source=dhcp"
        )

        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
    }

    if (Test-Path $StateFile) {
        Remove-Item -Path $StateFile -Force
    }

    Write-Host "Restored $($adapterNames.Count) adapter(s)."
}

if (-not (Test-Administrator)) {
    throw "This script must be run from an elevated PowerShell session."
}

switch ($Mode) {
    "apply" { Apply-NetworkSettings }
    "restore" { Restore-NetworkSettings }
}
