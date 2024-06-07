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

.OUTPUTS
Will create stratagems.json if not already present in home directory. 
This is parsed data from the Helldivers 2 wiki at https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2 

.NOTES
README.md has more information, but access the Repo for the most info at https://github.com/BroManDudeGuyPhD/Helldivers-stratagem-input

.LINK
https://github.com/BroManDudeGuyPhD/Helldivers-stratagem-input
#>


param (
    [Alias("stratagem", "code", "strategem")]
    [Parameter(Mandatory = $false)]
    [string]$strat,

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

function Update-Json {
    Write-Host "Updating Stratagems"

    $DataFileJson = @{}
    $StratagemList = New-Object System.Collections.ArrayList
    
    # At some point I want to implement customizable aliases for stratagems, this is a backup I've commented out for now since only the raw data is stored
    # Copy-Item .\stratagems.json stratagems.json.bak

    $wikiURL = "https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2)"

    $request = Invoke-WebRequest -Uri $wikiURL
    $tables = @($request.ParsedHtml.getElementsByTagName("TABLE"))

    foreach ($table in $tables) {

        $rows = @($table.Rows)
        
        foreach ($row in $rows) {
            $inputCode = ""
            $cells = @($row.Cells)
            
            if ($cells[0].tagName -eq "TD") {
                $cells[2].childNodes | Foreach-Object {
                    # Looks in the table cell that contains stratagem codes for images, and uses image name to determine direction
                    if ($_.className -eq 'image') { 
                        $arrowDirection = $_
                        $arrowDirection = $arrowDirection.href
                        $splitArray = $arrowDirection -split '.png'
                        $temp = $splitArray[0]
                        $lastChar = $temp[-1]

                        if ($lastChar -match "U") {
                            $inputCode += "U"
                        }
                        elseif ($lastChar -match "D") {
                            $inputCode += "D"
                        }
                        elseif ($lastChar -match "L") {
                            $inputCode += "L"
                        }
                        elseif ($lastChar -match "R") {
                            $inputCode += "R"
                        }
                    }
                }

                # Parse the HTML to determine info for each Stratagem
                $name = $cells[1] | ForEach-Object { ("" + $_.InnerText).Trim() }
                $coolDown = $cells[3] | ForEach-Object { ("" + $_.InnerText).Trim() }
                $uses = $cells[4] | ForEach-Object { ("" + $_.InnerText).Trim() }
                $activationTime = $cells[5] | ForEach-Object { ("" + $_.InnerText).Trim() }
                # $activationTime = @($cells[5] | ForEach-Object { ("" + $_.InnerText).Trim() })

                # Stratagem Name formatting
                # Some names are like AC-8 Autocannon. Alias trims that to "Autocannon"
                # However, "Eagle Rearm" will not have a unique alias value
                $name = $name.Replace('"', "")

                if ($name.Contains("-")) {
                    $shortName = $name -split '-', 2;
                    $alias = $shortName[1] -split ' ', 2;
                    $alias = $alias[1..($alias.Length - 1)]
                    $alias
                }

                # If there is no need for an alias, just fill in alias falue with name to prevent search issues
                else {
                    $alias = $name;
                    $name
                }


                # Cooldown & Activation Time formatting
                # Removes minute conversion, leaving only refferences to seconds
                $coolDown = $coolDown.Replace("seconds", "").Replace("second", "")
                $cooolDownSeconds = $coolDown.Split("(");
                $cooolDownSeconds = $cooolDownSeconds[0].Trim();

                $activationTime = $activationTime.Replace("seconds", "").Replace("second", "")
                $activationTimeSeconds = $activationTime.Split("("); 
                $activationTimeSeconds = $activationTimeSeconds[0].Trim();

                # Adding all the parsed and formatted data to a List
                [void]$StratagemList.Add(@{"Name" = $name;
                        "Alias"                   = "$alias";
                        "Code"                    = $inputCode;
                        "Cooldown"                = $cooolDownSeconds;
                        "Uses"                    = $uses;
                        "ActivationTime"          = $activationTimeSeconds;
                    })

                continue
            }
        }
    }

    $Stratagems = @{"Stratagems" = $StratagemList; }
    $DataFileJson.Add("Democracy", $Stratagems)

    <#
    foreach ($key in $StratagemJson.Democracy.Stratagems) {
		
        if($key.Name -eq $strat -Or $key.Alias -eq $strat){
            Write-Host $key.Name $key.Code -ForegroundColor Cyan
        }
		
    }
    #>

    
    $ModuleList = New-Object System.Collections.ArrayList
    $ShipModuleJson = @{}
    
    $wikiURL = "https://helldivers.fandom.com/wiki/Super_Destroyer"
    $moduleRequest = Invoke-WebRequest -Uri $wikiURL
    $p = @($moduleRequest.ParsedHtml.getElementsByTagName("p") | Where-Object { $null -ne $_.InnerText })
    $ul = @($moduleRequest.ParsedHtml.getElementsByTagName("ul") | Where-Object { $null -ne $_.InnerText })

    $moduleNameAndDescription = @($p | Where-Object { $_.InnerText.Contains(":") -and $_.InnerHTML.contains("<B>") })
    $moduleInfo = $ul.InnerText | Where-Object { $_.contains("Effect:") }
    
    $iterator = 0
    foreach ($module in $moduleInfo) {

        $moduleInfoSplit = $module -split 'Cost:';
        $moduleEffect = $moduleInfoSplit[0].Replace("Effect: ", "").Replace('"', "").trim()
        $moduleCost = $moduleInfoSplit[1].Replace(" Samples ", "").trim()
        $moduleNameSplit = $moduleNameAndDescription[$itterator].InnerText -split ':'
        $moduleName = $moduleNameSplit[0].trim()
        $moduleDescription = $moduleNameSplit[1].Replace('"', "").trim()

        [void]$ModuleList.Add(@{"Name" = $moduleName;
                "Description"          = $moduleDescription;
                "Effect"               = $moduleEffect;
                "Cost"                 = $moduleCost;
            })

        $iterator++
    }

    $Modules = @{"Ship Modules" = $ModuleList; }
    #$DataFileJson.Add("Democracy",$Modules)
    $DataFileJson.Democracy += $Modules
    $DataFileJson | ConvertTo-Json -Depth 10 | Out-File $stratagesmDataFile  

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
    Write-Host  " "
    Write-Host "Main Menu"
    Write-Host " "
    Write-Host "1: Search Stratagems" -ForegroundColor Cyan
    Write-Host "2: UPDATE Stratagems" -ForegroundColor Red
    Write-Host "3: Configure Ship Modules " -ForegroundColor Cyan
    Write-Host "4: Stratagem Hero$([char]174) *COMING SOON*" -ForegroundColor Magenta
    Write-Host "(Q)uit - (H)elp - (M)enu"
    Write-Host  " "
}

function terminal() {
    [System.Console]::Clear()
    Write-Host "|=============================================================================================================|" -ForegroundColor DarkBlue
    Write-Host @'                                                                                                                
|............$$$$$$\..............$$\.......................$$$$$$\....$$\.........................$$\........|
|           $$  __$$\             $$ |                     $$  __$$\   $$ |                        $$ |       |
|           $$ /  $$ |$$\   $$\ $$$$$$\    $$$$$$\         $$ /  \__|$$$$$$\    $$$$$$\  $$$$$$\ $$$$$$\      |
|           $$$$$$$$ |$$ |  $$ |\_$$  _|  $$  __$$\ $$$$$$\\$$$$$$\  \_$$  _|  $$  __$$\ \____$$\\_$$  _|     |
|           $$  __$$ |$$ |  $$ |  $$ |    $$ /  $$ |\______|\____$$\   $$ |    $$ |  \__|$$$$$$$ | $$ |       |
|           $$ |  $$ |$$ |  $$ |  $$ |$$\ $$ |  $$ |       $$\   $$ |  $$ |$$\ $$ |     $$  __$$ | $$ |$$\    |
|           $$ |  $$ |\$$$$$$  |..\$$$$  |\$$$$$$  |.......\$$$$$$  |..\$$$$  |$$ |.....\$$$$$$$ | \$$$$  |   |
|...........\__|..\__|.\______/....\____/..\______/.........\______/....\____/.\__|......\_______|..\____/....|                                                                                                                                                                                                                                                                 
'@.Trim() -ForegroundColor Magenta
    Write-Host "|                                                                                                             |" -ForegroundColor Magenta
    Write-Host "| Author: BroManDudeGuyPhD               Automated Stratagem Deployment                           version 1.1 |" -ForegroundColor Cyan
    Write-Host "|----------------------------------------- Aiding Democracy since 2024 ---------------------------------------|" -ForegroundColor DarkBlue

    Show-Menu
    do {
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

else {
    terminal
}

