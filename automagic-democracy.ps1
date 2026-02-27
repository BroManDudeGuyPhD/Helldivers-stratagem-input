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
    [Parameter(Mandatory = $false)]
    [string]$strat,

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

Add-Type -AssemblyName microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore, PresentationFramework

# The following are all "vanity" functions, and will have a setting to disable them in the future. They serve no function other than being pretty

$MenuVertical = "█";
$MenuHorizontal = "━";
function Vanity-NewLine ($lines, $ForegroundColor){
    if($null -eq $ForegroundColor){
        $ForegroundColor = "Green"
    }

    for ($i = 0; $i -lt $lines; $i++) {
        Vanity-Text $MenuVertical -ForegroundColor $ForegroundColor
    }
}

function Vanity-Tab ($lines, $ForegroundColor){

    if($null -eq $ForegroundColor){
        $ForegroundColor = "Green"
    }

    Vanity-Text -text $MenuVertical -ForegroundColor $ForegroundColor -NoReset $true

    for ($i = 0; $i -lt $lines; $i++) {
        Vanity-Text -text $MenuHorizontal -ForegroundColor $ForegroundColor -NoReset $true
    }
    Vanity-Text -text " "-NoReset $true
}
function Vanity-Text ($text, $ForegroundColor, $BackgroundColor, [bool]$NoReset, [bool]$SkipTyping){
    $SplitText = $text.ToCharArray();

    foreach ($char in $SplitText){
        
        if($null -eq $ForegroundColor){
            $ForegroundColor = "Green"
        }

        if($null -eq $BackgroundColor){
            $BackgroundColor = "Black"
        }

        Write-Host $char -NoNewline -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor


        #Vanity delay for typing effect

        if ($char -eq "."){
            if($SplitText.Length -eq 1){
                Start-Sleep -Milliseconds 20  
            }
            else{
                Start-Sleep -Milliseconds 50
            }
        }

        elseif($SkipTyping -eq $true){
            Start-Sleep -Milliseconds 0
        }

        # Menu characters
        elseif ($char -eq " ") {
            Start-Sleep -Milliseconds 0.5
        }
        elseif($char -eq $MenuVertical){
            Start-Sleep -Milliseconds 50
        }
        elseif($char -eq $MenuHorizontal){
            Start-Sleep -Milliseconds 90
        }

        # Normal Condition
        else{
            Start-Sleep -Milliseconds 60
        }
        
    }
    
    if($NoReset -eq $true){
        return
    }

    Write-Host ""

}

function Vanity-Logo($text, $ForegroundColor, $BackgroundColor){
    $SplitText = $text.ToCharArray();
    $previousValue = "";
    foreach ($char in $SplitText){
        
        if($null -eq $ForegroundColor){
            $ForegroundColor = "Green"
        }

        if($null -eq $BackgroundColor){
            $BackgroundColor = ""
        }

        if($char -eq "|"){
            if($previousValue -eq "="){
                Write-Host $char -ForegroundColor $ForegroundColor
            }

            else{
                Write-Host $char -NoNewline -ForegroundColor $ForegroundColor
            }
        }
        else{
            Write-Host $char -NoNewline -ForegroundColor $ForegroundColor
        }

        #Vanity delay for typing effect
        if ($char -eq "."){
            Start-Sleep -Milliseconds 10
        }
        elseif ($char -eq " ") {
            Start-Sleep -Milliseconds 0
        }
        else{
            Start-Sleep -Milliseconds 0
        }
        $previousValue = $char
    }
    Write-Host""
}


# Main Script Functions

function Setup {
    <#  Runs setup to make sure system will support script functions, mainly the vanity stuff for now
        For vanity to work, UTF-8 must be enabled or the terminal will output giberish for some of the characters used to form menus
        The workaround is basically:
            1. open intl.cpl from the Run program 
            2. Choose Administrative menu
            3. Change system locale
            4. Check "Beta; Use Unicode UTF-8 for worldwide language support"
            5. Restart computer
        https://www.delftstack.com/howto/powershell/powershell-utf-8-encoding-chcp-65001/#google_vignette  #>

    Write-Host "You should see a vertical bar here: $MenuVertical"
    Write-Host "You should see a horizontal bar here: $MenuHorizontal"
}

function Update-Json {
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

    # Use the Fandom MediaWiki API — returns JSON with raw wikitext, bypasses Cloudflare entirely.
    # Works in both Windows PowerShell 5.1 (powershell.exe) and PowerShell 7 (pwsh).
    # The wikitext encodes arrow directions as {{U}}, {{D}}, {{L}}, {{R}} templates.
    $apiURL = "https://helldivers.fandom.com/api.php?action=parse&page=Stratagem_Codes&prop=wikitext&format=json"

    try {
        $response = Invoke-WebRequest -Uri $apiURL -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Failed to fetch stratagem data: $_" -ForegroundColor Red
        return
    }

    $wikitext = ($response.Content | ConvertFrom-Json).parse.wikitext.'*'
    if (-not $wikitext) {
        Write-Host "Could not parse wikitext from API response." -ForegroundColor Red
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

        # Generate alias: strip model prefix so "MG-43 Machine Gun" -> "Machine Gun"
        # Split on first "-", then skip the model number token after the dash
        if ($name.Contains("-")) {
            $shortName = $name -split '-', 2
            $parts = $shortName[1] -split ' ', 2
            $alias = if ($parts.Count -ge 2) { $parts[1].Trim() } else { $shortName[1].Trim() }
        } else {
            # No model prefix; use full name as alias (e.g. "Orbital Laser", "Eagle Rearm")
            $alias = $name
        }
        if (-not $alias) { $alias = $name }

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
            "Alias"          = $alias
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

    Vanity-NewLine 2
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "Stratagems UPDATED" -ForegroundColor Cyan
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "Total: $($newStratagemNames.Count) stratagems" -ForegroundColor Cyan -SkipTyping $true
    if ($oldStratagemNames.Count -gt 0) {
        if ($added.Count -gt 0) {
            Vanity-Tab 4 -ForegroundColor Green
            Vanity-Text "+$($added.Count) added" -ForegroundColor Green -SkipTyping $true
            foreach ($n in $added) {
                Vanity-Tab 6 -ForegroundColor Green
                Vanity-Text $n -ForegroundColor Green -SkipTyping $true
            }
        }
        if ($removed.Count -gt 0) {
            Vanity-Tab 4 -ForegroundColor Yellow
            Vanity-Text "-$($removed.Count) removed" -ForegroundColor Yellow -SkipTyping $true
            foreach ($n in $removed) {
                Vanity-Tab 6 -ForegroundColor Yellow
                Vanity-Text $n -ForegroundColor Yellow -SkipTyping $true
            }
        }
        if ($added.Count -eq 0 -and $removed.Count -eq 0) {
            Vanity-Tab 4 -ForegroundColor Cyan
            Vanity-Text "No changes from previous data" -ForegroundColor Cyan -SkipTyping $true
        }
    }
    Vanity-NewLine 2
    Vanity-Tab 4
}


Function Learn-Keypress($value) {
    try {
        # This is there the script reads stratagems.json to check for the codes. If the file is missing, you get a popup
        # The datafile does NOT have to be generated this way, the -update command can be used when running the script
	
        $value = $value.Replace('"', "") # Removes any quotes from parameter input
        $stratagemCodeFile = (Get-Content $stratagesmDataFile -Raw -ErrorAction Stop) | ConvertFrom-Json
        $requestedCode = $stratagemCodeFile.Democracy.Stratagems | Where-Object { $_.Name -eq $value -or $_.Alias -eq $value }

        if ($null -eq $requestedCode) {
            $requestedCode = $stratagemCodeFile.Democracy.Stratagems | Where-Object { $_.Name.contains($value) -or $_.Alias.contains($value) }

            if ($null -eq $requestedCode) {
                return "No Stratagems matching $($value)"
            }
            return $requestedCode
        }

        return $requestedCode.code
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
    Vanity-NewLine 2 -ForegroundColor Magenta 
    Vanity-Tab 2 -ForegroundColor Magenta 
    Vanity-Text "Main Menu" -ForegroundColor Magenta 
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "1: Search Stratagems" -ForegroundColor Cyan -SkipTyping $true
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "2: UPDATE Stratagems" -ForegroundColor Cyan -SkipTyping $true
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "3: Configure Ship Modules " -ForegroundColor Cyan -SkipTyping $true
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "4: Stratagem Hero$([char]174) *COMING SOON*" -ForegroundColor Cyan -SkipTyping $true
    Vanity-Tab 4 -ForegroundColor Cyan
    Vanity-Text "   (Q)uit - (H)elp - (M)enu" -ForegroundColor White -SkipTyping $true
}

function terminal() {
    [System.Console]::Clear()
    Write-Host "|------------------------------------------------------------------------------------------------------------- |" -ForegroundColor DarkBlue
    Vanity-Logo @'                                                                                                                
|            $$$$$$\              $$\                       $$$$$$\    $$\                         $$\         |
|           $$  __$$\             $$ |                     $$  __$$\   $$ |                        $$ |        |
|           $$ /  $$ |$$\   $$\ $$$$$$\    $$$$$$\         $$ /  \__|$$$$$$\    $$$$$$\  $$$$$$\ $$$$$$\       |
|           $$$$$$$$ |$$ |  $$ |\_$$  _|  $$  __$$\ $$$$$$\\$$$$$$\  \_$$  _|  $$  __$$\ \____$$\\_$$  _|      |
|           $$  __$$ |$$ |  $$ |  $$ |    $$ /  $$ |\______|\____$$\   $$ |    $$ |  \__|$$$$$$$ | $$ |        |
|           $$ |  $$ |$$ |  $$ |  $$ |$$\ $$ |  $$ |       $$\   $$ |  $$ |$$\ $$ |     $$  __$$ | $$ |$$\     |
|           $$ |  $$ |\$$$$$$  |..\$$$$  |\$$$$$$  |.......\$$$$$$  |..\$$$$  |$$ |.....\$$$$$$$ | \$$$$  |    |
|...........\__|..\__|.\______/....\____/..\______/.........\______/....\____/.\__|......\_______|..\____/.... |                                                                                                                                                                                                                                                                 
'@.Trim() -ForegroundColor Magenta
Vanity-Logo "|                                                                                                              |" -ForegroundColor Magenta
Vanity-Logo "| Author: BroManDudeGuyPhD               Automated Stratagem Deployment                           version 1.2  |" -ForegroundColor Cyan
Vanity-Logo "|----------------------------------------- Aiding Democracy since 2024 --------------------------------------- |" -ForegroundColor Magenta

    Show-Menu
    do {
        Vanity-NewLine 1
        Vanity-Tab 2
        $selection = Read-Host "Please make a selection" 
        switch ($selection) {
            '1' {
                $enteredCode = Read-Host "Stratagem Name"
                $code = Learn-Keypress -value $enteredCode
                $code
            } '2' {
                Update-Json
            } '3' {
                'Coming soon Helldiver... go spread Democracy in the meantime'
            }'4' {
                'Ship Configuration coming soon Helldiver... go spread Democracy in the meantime'
            }'h' {
                'To execute stratagem input, run the script like automagic-democracy -strat "Autocannon". You may not see anything happen, but you can download a keyboard visualizer to check that it is working. If you are having trouble getting started, check out https://github.com/BroManDudeGuyPhD/Helldivers-stratagem-input'
            }
            'help' {
                'To execute stratagem input, run the script like automagic-democracy -strat "Autocannon". You may not see anything happen, but you can download a keyboard visualizer to check that it is working. If you are having trouble getting started, check out https://github.com/BroManDudeGuyPhD/Helldivers-stratagem-input'
            }
            'm' {
                Show-Menu
            }
            'menu' {
                Show-Menu
            }
            ''{
                Show-Menu
            }
            default {
                if ($selection -ne 'q'){
                    Vanity-Tab 4 -ForegroundColor Red
                    Vanity-Text "`'$selection`' is not a valid selection" -ForegroundColor Red
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
    $code = Learn-Keypress -value $strat
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

