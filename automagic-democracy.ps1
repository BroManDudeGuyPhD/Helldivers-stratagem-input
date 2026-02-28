<#

Code by BroManDudeGuyPhD
Purpose: Spread Democracy more effectively with this strategem keypress tool.
Initiated 5/16/2024

.SYNOPSIS
Automate keypresses for Helldivers 2 Stratagems using an automaticlly generated list of stratagem codes

.EXAMPLE
automagic-democracy -update
automagic-democracy -strat "Airstrike"
powershell.exe -File "C:\pathToScript\automagic-democracy.ps1" -strat "Airstrike"

.PARAMETER strat
The literal stratagem name, like "Airstrike". Names can be found in stratagems.json
Some names are like AC-8 Autocannon. Alias trims that to "Autocannon", and the strat entered is also checked against the alias value, so either the full literal name or shortened alias value can be passed to the script

.PARAMETER update
Fetches paramater names and codes from online Wiki

.PARAMETER terminal
Opens up an interactive terminal

.PARAMETER setup
Runs setup function

.OUTPUTS
Will create stratagems.json if not already present in home directory. 
This is parsed data from the Helldivers 2 wiki at https://helldivers.wiki.gg/wiki/Stratagems

.NOTES
README.md has more information, but access the Repo for the most info at https://github.com/BroManDudeGuyPhD/Helldivers-stratagem-input

.LINK
https://github.com/BroManDudeGuyPhD/Helldivers-stratagem-input
#>


param (
    [Alias("stratagem", "code", "strategem")]
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$strat,

    [Alias("init", "initialize")]
    [Parameter(Mandatory = $false)]
    [string]$setup,

    [Parameter(Mandatory = $false)]
    [switch]$update,

    [Alias("test", "testing", "help")]
    [Parameter(Mandatory = $false)]
    [switch]$terminal
)

# Wait time in milliseconds between keypresses
$keypressWaitTime = 70
$stratagesmDataFile = "democracy.json"
$script:AnimTurbo  = $false   # set to $true on keypress to skip remaining animation delays

Add-Type -AssemblyName microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore, PresentationFramework

# ═══════════════════════════════════════════════════════
# SUPER EARTH ANIMATION ENGINE
# ═══════════════════════════════════════════════════════

# Per-character typewriter with random timing jitter; any keypress sets turbo mode
function Write-Char {
    param([string]$Text, [string]$Color = "Green", [int]$Delay = 22, [bool]$Jitter = $true)
    foreach ($ch in $Text.ToCharArray()) {
        Write-Host $ch -NoNewline -ForegroundColor $Color
        if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); $script:AnimTurbo = $true }
        if (-not $script:AnimTurbo) {
            $ms = if ($Jitter) { $Delay + (Get-Random -Maximum 18) } else { $Delay }
            Start-Sleep -Milliseconds $ms
        }
    }
}

# Single tree line — prefix | label : value, value auto-colored by content
function Write-TreeLine {
    param(
        [string]$Prefix      = "  ├── ",
        [string]$Label       = "",
        [string]$Value       = "",
        [string]$PrefixColor = "Green",
        [string]$LabelColor  = "Yellow",
        [string]$ValueColor  = ""
    )
    Write-Char $Prefix $PrefixColor 5 $false
    if ($Label) { Write-Char ($Label + " ") $LabelColor 18 $true }
    if (-not $ValueColor) {
        if     ($Value -match 'online|locked|confirmed|engaged|acquired|active|acknowledged|updated|loaded|sanctified') { $ValueColor = "Cyan"    }
        elseif ($Value -match 'error|failed|unavailable')                                                               { $ValueColor = "Red"     }
        elseif ($Value -match 'pending|scanning|acquiring|now')                                                         { $ValueColor = "Magenta" }
        else                                                                                                            { $ValueColor = "Green"   }
    }
    Write-Char $Value $ValueColor 22 $true
    Write-Host ""
}

# ⚙══...══⚙ divider — always appears instantly; default width matches the logo bar
function Write-Divider {
    param([string]$Color = "Green", [int]$Width = 108)
    $bar = "  ⚙" + ("═" * $Width) + "⚙"
    Write-Host $bar -ForegroundColor $Color
}

# Background runspace spinner — call Start-Spinner before a blocking op, Stop-Spinner after
function Start-Spinner {
    param([string]$Message)
    $frames = @("⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏")
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript({
        param($msg, $frames)
        $i = 0
        while ($true) {
            [Console]::Write("`r  $($frames[$i % $frames.Count])  $msg  ")
            $i++
            Start-Sleep -Milliseconds 80
        }
    }).AddArgument($Message).AddArgument($frames)
    [void]$ps.BeginInvoke()
    return @{ PS = $ps; RS = $rs }
}

function Stop-Spinner {
    param($Spinner, [string]$FinalMessage = "")
    try { $Spinner.PS.Stop() } catch {}
    $Spinner.PS.Dispose()
    $Spinner.RS.Close()
    $Spinner.RS.Dispose()
    [Console]::Write("`r" + (" " * 80) + "`r")
    if ($FinalMessage) { Write-Host $FinalMessage }
}

# Boot sequence — plays on terminal launch
function Invoke-StratagemBoot {
    Write-Divider "Green"
    $entries = @(
        @{ Segs = @(@("  ├── ","Green"),@("[ SUPER EARTH ] ","Cyan"),   @("Establishing orbital uplink..........","Green")); Res = @(" ONLINE",  "Cyan") },
        @{ Segs = @(@("  ├── ","Green"),@("[ SUPER EARTH ] ","Cyan"),   @("Loading stratagem database...........","Green")); Res = @(" LOADED",  "Cyan") },
        @{ Segs = @(@("  ├── ","Green"),@("[ DEMOCRACY   ] ","Yellow"), @("Calibrating arrow-key input relay....","Green")); Res = @(" LOCKED",  "Cyan") },
        @{ Segs = @(@("  └── ","Green"),@("[ DEMOCRACY   ] ","Yellow"), @("Arming stratagem deployment array....","Green")); Res = @(" ENGAGED", "Red")  }
    )
    foreach ($entry in $entries) {
        foreach ($seg in $entry.Segs) { Write-Char $seg[0] $seg[1] 22 $true }
        if (-not $script:AnimTurbo) { Start-Sleep -Milliseconds (180 + (Get-Random -Maximum 340)) }
        Write-Char $entry.Res[0] $entry.Res[1] 32 $true
        Write-Host ""
        if (-not $script:AnimTurbo) { Start-Sleep -Milliseconds 120 }
    }
    Write-Divider "Green"
    Write-Host ""
}


# Main Script Functions

function Setup {
    <#  Run setup to verify UTF-8 is active for the animation engine.
        If box/spinner characters below appear garbled, enable UTF-8:
            1. Open intl.cpl from the Run dialog
            2. Administrative tab → Change system locale
            3. Check "Beta: Use Unicode UTF-8 for worldwide language support"
            4. Restart
        https://www.delftstack.com/howto/powershell/powershell-utf-8-encoding-chcp-65001/  #>

    Write-Char "  ⚙  UTF-8 rendering test" "Cyan" 22 $true
    Write-Host ""
    Write-TreeLine "  ├── " "BOX CHARS :" "⚙ ═ ├ └ │" "Green" "Yellow" "Green"
    Write-TreeLine "  ├── " "SPINNER   :" "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏" "Green" "Yellow" "Green"
    Write-TreeLine "  └── " "STATUS    :" "If all symbols display cleanly, UTF-8 is active" "Green" "Yellow" "Cyan"
}

function Update-Json {
    $script:AnimTurbo = $false
    $DataFileJson = @{}
    $StratagemList = New-Object System.Collections.ArrayList

    # Back up existing data file before overwriting — used for change analytics below
    $backupFile = Join-Path $env:TEMP "democracy.json.bak"
    $oldStratagemNames = @()
    if (Test-Path $stratagesmDataFile) {
        Copy-Item -Path $stratagesmDataFile -Destination $backupFile -Force
        try {
            $oldJson = Get-Content $stratagesmDataFile -Raw | ConvertFrom-Json
            $oldStratagemNames = @($oldJson.Democracy.Stratagems | ForEach-Object { $_.Name })
        } catch { }
    }

    # Kick off the web fetch in the background so it runs during the boot animation
    $apiURL = "https://helldivers.fandom.com/api.php?action=parse&page=Stratagem_Codes&prop=wikitext&format=json"
    $fetchJob = Start-Job -ScriptBlock {
        param($url)
        Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
    } -ArgumentList $apiURL

    Write-Host ""
    Write-Divider "Green"
    $boot = @(
        @{ Segs = @(@("  ├── ","Green"),@("[ MECHANICUS ] ","Cyan"),   @("Awakening servo-skull array..........","Green")); Res = @(" ACTIVE",      "Cyan") },
        @{ Segs = @(@("  ├── ","Green"),@("[ MECHANICUS ] ","Cyan"),   @("Sanctifying data-shrine uplink.......","Green")); Res = @(" CONSECRATED", "Cyan") },
        @{ Segs = @(@("  ├── ","Green"),@("[ OMNISSIAH  ] ","Yellow"), @("Blessing acquisition subroutines.....","Green")); Res = @(" SANCTIFIED",  "Red")  },
        @{ Segs = @(@("  └── ","Green"),@("[ OMNISSIAH  ] ","Yellow"), @("Machine spirit communion complete....","Green")); Res = @(" ACKNOWLEDGED","Red")  }
    )
    foreach ($entry in $boot) {
        foreach ($seg in $entry.Segs) { Write-Char $seg[0] $seg[1] 22 $true }
        if (-not $script:AnimTurbo) { Start-Sleep -Milliseconds (160 + (Get-Random -Maximum 300)) }
        Write-Char $entry.Res[0] $entry.Res[1] 32 $true
        Write-Host ""
        if (-not $script:AnimTurbo) { Start-Sleep -Milliseconds 100 }
    }
    Write-Divider "Green"
    Write-Host ""

    # Collect the fetch result — if the animation ran long enough it's already done; otherwise wait
    $spin = Start-Spinner "Awaiting machine spirit response..."
    try {
        $response = Receive-Job -Job $fetchJob -Wait -ErrorAction Stop
        Stop-Spinner $spin
    } catch {
        Stop-Spinner $spin
        Remove-Job -Job $fetchJob -Force
        Write-TreeLine "  └── " "ERROR :" "Failed to fetch stratagem data: $_" "Green" "Red" "Red"
        return
    }
    Remove-Job -Job $fetchJob -Force

    $wikitext = ($response.Content | ConvertFrom-Json).parse.wikitext.'*'
    if (-not $wikitext) {
        Write-TreeLine "  └── " "ERROR :" "Could not parse wikitext from API response." "Green" "Red" "Red"
        return
    }

    # Split into table rows on any "|-" line (may have trailing style attributes)
    $rows = $wikitext -split '\n[ \t]*\|-[^\n]*\n'

    foreach ($row in $rows) {
        # Collect lines that are table cells (start with |) — excluding "|-" and "|}" lines
        $cellLines = $row -split '\n' | Where-Object { $_ -match '^\s*\|' -and $_ -notmatch '^\s*\|[\-\}]' }

        # Need at least 6 cells: icon | name | code | cooldown | uses | activation
        if ($cellLines.Count -lt 6) { continue }

        # Cell 0: icon — must be a [[File:]] link; guards against colspan/section rows
        if ($cellLines[0] -notmatch '\[\[File:') { continue }

        # Cell 1: name — extract from [[Name]] wikilink
        if ($cellLines[1] -notmatch '\[\[([^\|\]]+)') { continue }
        $name = $matches[1].Trim().Replace('"', "")
        if ($name -eq "") { continue }

        # Cell 2: input code — built from {{U}}, {{D}}, {{L}}, {{R}} templates
        $inputCode = ""
        foreach ($m in [regex]::Matches($cellLines[2], '\{\{([UDLR])\}\}')) {
            $inputCode += $m.Groups[1].Value
        }
        if ($inputCode -eq "") { continue }

        # Generate aliases array. For model-prefixed names like "AC-8 Autocannon" produce
        # both the model designator ("AC-8") and the short name ("Autocannon").
        # For unprefixed names like "Orbital Laser" produce a single alias equal to the name.
        $aliases = [System.Collections.Generic.List[string]]::new()
        if ($name.Contains("-")) {
            # Model designator = first space-delimited word (e.g. "AC-8", "MG-43", "AX/ARC-3")
            $nameParts = $name -split ' ', 2
            $modelAlias = $nameParts[0].Trim()
            [void]$aliases.Add($modelAlias)
            if ($nameParts.Count -ge 2) {
                # Short name: split on first "-", take the part after, then skip the leading
                # model-number token — e.g. "8 Autocannon" -> "Autocannon"
                $shortName = $name -split '-', 2
                $parts = $shortName[1] -split ' ', 2
                $shortAlias = if ($parts.Count -ge 2) { $parts[1].Trim() } else { $shortName[1].Trim() }
                if (-not $shortAlias) { $shortAlias = $nameParts[1].Trim() }
                if ($shortAlias -and $shortAlias -ne $modelAlias) { [void]$aliases.Add($shortAlias) }
            }
        } else {
            # No model prefix; single alias = full name (e.g. "Orbital Laser", "Eagle Rearm")
            [void]$aliases.Add($name)
        }

        # Extract the value from a wikitext cell — handles both "|VALUE" and "| style=... |VALUE"
        # Taking the last pipe-delimited segment works for both formats
        $getValue = { param($line) ($line -split '\|')[-1].Trim() }

        # Cells 3-5: cooldown | uses | activation time
        # Strip "seconds"/"second" labels and parenthetical minute conversions
        $cooldown = (& $getValue $cellLines[3]) -replace 'seconds?', ''
        $cooldown = ($cooldown -split '\(')[0].Trim()

        $uses = & $getValue $cellLines[4]

        $activationTime = (& $getValue $cellLines[5]) -replace 'seconds?', ''
        $activationTime = ($activationTime -split '\(')[0].Trim()

        [void]$StratagemList.Add(@{
            "Name"           = $name
            "Aliases"        = $aliases.ToArray()
            "Code"           = $inputCode
            "Cooldown"       = $cooldown
            "Uses"           = $uses
            "ActivationTime" = $activationTime
        })
    }

    $Stratagems = @{ "Stratagems" = $StratagemList }
    $DataFileJson.Add("Democracy", $Stratagems)

    $ModuleList = New-Object System.Collections.ArrayList

    # $wikiURL = "https://helldivers.fandom.com/wiki/Super_Destroyer"
    # $moduleRequest = Invoke-WebRequest -Uri $wikiURL

    # $moduleNameAndDescription = @($moduleRequest.ParsedHtml.getElementsByTagName("p") | Where-Object { $null -ne $_.InnerText })
    # $moduleInfo= @($moduleRequest.ParsedHtml.getElementsByTagName("ul") | Where-Object { $null -ne $_.InnerText })

    # $moduleNameAndDescription = @($moduleNameAndDescription | Where-Object { $_.InnerText.Contains(":") -and $_.InnerHTML.contains("<B>") })
    # $moduleInfo = $moduleInfo.InnerText | Where-Object { $_.contains("Effect:") }

    # $iterator = 0
    # foreach ($module in $moduleInfo) {

    #     $module = $module -split 'Cost:';
    #     $moduleEffect = $module[0].Replace("Effect: ", "").Replace('"', "").trim()
    #     $moduleCost = $module[1].Replace(" Samples ", "").trim()
    #     $moduleNameSplit = $moduleNameAndDescription[$iterator].InnerText -split ':'
    #     $moduleName = $moduleNameSplit[0].trim()
    #     $moduleDescription = $moduleNameSplit[1].Replace('"', "").trim()

    #     [void]$ModuleList.Add(@{"Name" = $moduleName;
    #             "Description"          = $moduleDescription;
    #             "Effect"               = $moduleEffect;
    #             "Cost"                 = $moduleCost;
    #         })

    #     $iterator++
    # }

    $Modules = @{ "Ship Modules" = $ModuleList }
    $DataFileJson.Democracy += $Modules
    $DataFileJson | ConvertTo-Json -Depth 10 | Out-File $stratagesmDataFile

    # Change analytics — compare new list against backup
    $newStratagemNames = @($StratagemList | ForEach-Object { $_["Name"] })
    $added   = @($newStratagemNames | Where-Object { $oldStratagemNames -notcontains $_ })
    $removed = @($oldStratagemNames | Where-Object { $newStratagemNames -notcontains $_ })

    Write-Host ""
    Write-Divider "Cyan"
    Write-TreeLine "  ├── " "STATUS :" "Stratagems UPDATED" "Green" "Yellow" "Cyan"
    Write-TreeLine "  ├── " "TOTAL  :" "$($newStratagemNames.Count) stratagems" "Green" "Yellow" "Cyan"
    if ($oldStratagemNames.Count -gt 0) {
        if ($added.Count -gt 0) {
            Write-TreeLine "  ├── " "ADDED  :" "+$($added.Count)" "Green" "Yellow" "Green"
            for ($i = 0; $i -lt $added.Count; $i++) {
                $pfx = if ($i -eq $added.Count - 1) { "  │   └── " } else { "  │   ├── " }
                Write-TreeLine $pfx "" $added[$i] "Green" "Yellow" "Green"
            }
        }
        if ($removed.Count -gt 0) {
            Write-TreeLine "  ├── " "REMOVED:" "-$($removed.Count)" "Green" "Yellow" "Yellow"
            for ($i = 0; $i -lt $removed.Count; $i++) {
                $pfx = if ($i -eq $removed.Count - 1) { "  │   └── " } else { "  │   ├── " }
                Write-TreeLine $pfx "" $removed[$i] "Green" "Yellow" "Yellow"
            }
        }
        if ($added.Count -eq 0 -and $removed.Count -eq 0) {
            Write-TreeLine "  ├── " "DELTA  :" "No changes from previous data" "Green" "Yellow" "DarkGray"
        }
    }
    Write-TreeLine "  └── " "FILE   :" $stratagesmDataFile "Green" "Yellow" "Cyan"
    Write-Divider "Cyan"
}


Function Learn-Keypress($value) {
    try {
        # This is there the script reads stratagems.json to check for the codes. If the file is missing, you get a popup
        # The datafile does NOT have to be generated this way, the -update command can be used when running the script
	
        $value = $value.Replace('"', "") # Removes any quotes from parameter input
        $stratagemCodeFile = (Get-Content $stratagesmDataFile -Raw -ErrorAction Stop) | ConvertFrom-Json
        $requestedCode = $stratagemCodeFile.Democracy.Stratagems | Where-Object { $_.Name -eq $value -or $_.Aliases -contains $value }

        if ($null -eq $requestedCode) {
            $requestedCode = $stratagemCodeFile.Democracy.Stratagems | Where-Object { $_.Name.Contains($value) -or ($_.Aliases | Where-Object { $_.Contains($value) }) }

            if ($null -eq $requestedCode) {
                return "No Stratagems matching $($value)"
            }
            # Multiple partial matches possible — take the first; caller can refine
            $requestedCode = @($requestedCode)[0]
            return $requestedCode.Code
        }

        return $requestedCode.Code
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
        $MessageboxTitle = "No stratagem data file found!"
        $Messageboxbody = "I can automatically generate the JSON file by accessing the internet and grabbing data from the Helldivers 2 Wiki, or you can download democracy.json from the repo. May I attempt to generate the file now?"
        $MessageIcon = [System.Windows.MessageBoxImage]::Warning
        $Result = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

        if ($Result -eq "Yes") {
            Write-Host "Downloading info from https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2)" -ForegroundColor Magenta
            Update-Json
        }

    }
}

# Output the code for troubleshooting
# $code
function Enter-Keypress {
    param (
        [string[]]$stratagemCode
    )
        
    $keyPresses = $stratagemCode.ToCharArray();

    # Strategem Keypress type setting in-game MUST be "press" for this function to work. I could not get holding down CTRL to work
    [System.Windows.Forms.SendKeys]::SendWait("^"); # This is the CTRL Key Press
    
    foreach ($key in $keyPresses) {
        # Loops thru each character of the codes entered manually above, presses the corresponding arrow, then waits 50 ms
        Start-Sleep -Milliseconds $keypressWaitTime
        if ($key -eq "U") {
            [System.Windows.Forms.SendKeys]::SendWait("{UP}");
        }
        if ($key -eq "L") {
            [System.Windows.Forms.SendKeys]::SendWait("{LEFT}");
        }
        if ($key -eq "D") {
            [System.Windows.Forms.SendKeys]::SendWait("{DOWN}");
        }
        if ($key -eq "R") {
            [System.Windows.Forms.SendKeys]::SendWait("{RIGHT}");
        }
    }
}

function Get-Funky {
    # Written by Matt
    # https://stackoverflow.com/questions/35022078/how-do-i-output-ascii-art-to-console
    param([string]$Text)

    # Use a random colour for each character
    $Text.ToCharArray() | ForEach-Object {
        switch -Regex ($_) {
            # Ignore new line characters
            "`r" {
                break
            }
            # Start a new line
            "`n" {
                Write-Host " "; break
            }
            # Use random colours for displaying this non-space character
            "[^ ]" {
                # Splat the colours to write-host
                $writeHostOptions = @{
                    ForegroundColor = ([system.enum]::GetValues([system.consolecolor])) | get-random
                    # BackgroundColor = ([system.enum]::GetValues([system.consolecolor])) | get-random
                    NoNewLine       = $true
                }
                Write-Host $_ @writeHostOptions
                break
            }
            " " { Write-Host " " -NoNewline }
        } 
    }
}

function Show-Menu {
    Write-Host ""
    Write-Divider "Magenta"
    Write-Char "  ⚙  STRATAGEM RELAY — MAIN MENU" "Magenta" 14 $true
    Write-Host ""
    Write-Divider "Magenta"
    Write-TreeLine "  ├── " "[ 1 ]" "Search Stratagems"             "Green" "Yellow" "Cyan"
    Write-TreeLine "  ├── " "[ 2 ]" "UPDATE Stratagems"             "Green" "Yellow" "Cyan"
    Write-TreeLine "  ├── " "[ 3 ]" "Configure Ship Modules"        "Green" "Yellow" "Cyan"
    Write-TreeLine "  ├── " "[ 4 ]" "Stratagem Hero® *COMING SOON*" "Green" "Yellow" "DarkGray"
    Write-TreeLine "  └── " "[ Q ]" "Quit  |  (H)elp  |  (M)enu"   "Green" "Yellow" "White"
    Write-Divider "Green"
}

function terminal() {
    $script:AnimTurbo = $false
    [System.Console]::Clear()
    Write-Divider "DarkBlue"
    $logo = @'
            $$$$$$\              $$\                       $$$$$$\    $$\                         $$\        
           $$  __$$\             $$ |                     $$  __$$\   $$ |                        $$ |       
           $$ /  $$ |$$\   $$\ $$$$$$\    $$$$$$\         $$ /  \__|$$$$$$\    $$$$$$\  $$$$$$\ $$$$$$\      
           $$$$$$$$ |$$ |  $$ |\_$$  _|  $$  __$$\ $$$$$$\\$$$$$$\  \_$$  _|  $$  __$$\ \____$$\\_$$  _|     
           $$  __$$ |$$ |  $$ |  $$ |    $$ /  $$ |\______|\____$$\   $$ |    $$ |  \__|$$$$$$$ | $$ |       
           $$ |  $$ |$$ |  $$ |  $$ |$$\ $$ |  $$ |       $$\   $$ |  $$ |$$\ $$ |     $$  __$$ | $$ |$$\    
           $$ |  $$ |\$$$$$$  |  \$$$$  |\$$$$$$  |       \$$$$$$  |  \$$$$  |$$ |     \$$$$$$$ | \$$$$  |   
           \__|  \__| \______/    \____/  \______/         \______/    \____/ \__|      \_______| \____/    
'@
    foreach ($line in ($logo -split "`n")) {
        Write-Host $line -ForegroundColor Magenta
        if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); $script:AnimTurbo = $true }
        if (-not $script:AnimTurbo) { Start-Sleep -Milliseconds 60 }
    }
    Write-Divider "DarkBlue"
    Write-Host ""
    Write-Host "    Author: BroManDudeGuyPhD          Automated Stratagem Deployment          v1.3" -ForegroundColor Cyan
    Write-Host ""
    Invoke-StratagemBoot
    Show-Menu
    do {
        Write-Host ""
        Write-Char "  ⚙  " "Green" 0 $false
        $selection = Read-Host "Command"
        switch ($selection) {
            '1' {
                Write-Char "  ├── " "Green" 0 $false
                $enteredCode = Read-Host "Stratagem designation"
                $code = Learn-Keypress -value $enteredCode
                if ($code) {
                    Write-TreeLine "  └── " "RESULT :" $code "Green" "Yellow" "Cyan"
                }
            }
            '2' { Update-Json }
            '3' { Write-TreeLine "  └── " "STATUS :" "Ship Modules coming soon — spread Democracy" "Green" "Yellow" "DarkGray" }
            '4' { Write-TreeLine "  └── " "STATUS :" "Stratagem Hero coming soon — spread Democracy" "Green" "Yellow" "DarkGray" }
            'h'    { Write-TreeLine "  └── " "HELP :" 'Run: automagic-democracy -strat "Autocannon"' "Green" "Yellow" "Cyan" }
            'help' { Write-TreeLine "  └── " "HELP :" 'Run: automagic-democracy -strat "Autocannon"' "Green" "Yellow" "Cyan" }
            'm'    { Show-Menu }
            'menu' { Show-Menu }
            ''     { Show-Menu }
            default {
                if ($selection -ne 'q') {
                    Write-TreeLine "  └── " "ERROR :" "'$selection' is not a valid selection" "Green" "Red" "Red"
                }
            }
        }
    }
    until ($selection -eq 'q')
}


# Main

if ($update) {
    Update-Json
} 

elseif ($terminal) {
    terminal
}

elseif ($strat) {
    $stratValue = ($strat -join " ").Trim()
    $code = Learn-Keypress -value $stratValue
    if ($code) {
        Enter-Keypress -stratagemCode $code
    }
}

elseif ($setup){
    Setup-Script
}

else {
    terminal
}

