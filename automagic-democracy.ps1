<#
    Code by BroManDudeGuyPhD
    Purpose: Spread Democracy more effectively with this strategem keypress tool.
    5/16/2024
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$strat,
    [Parameter(Mandatory = $false)]
    [switch]$update
)

#wait time in milliseconds between keypresses
$keypressWaitTime = 70
$stratagesmDataFile = "stratagems.json"

Add-Type -AssemblyName microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore,PresentationFramework

#Right now the stratagem list is hardcoded, but I intend to generate it dynamically by scraping data off a Wiki page and storing that in the stratagems.json file

function Update-Json{
	Write-Host "Updating Stratagems"

    $StratagemJson= @{}
	$StratagemList = New-Object System.Collections.ArrayList
    
    #Copy-Item .\stratagems.json stratagems.json.bak

    $wikiURL = "https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2)"

    #Invoke-WebRequest $wikiURL
    #(Invoke-WebRequest -Uri $wikiURL).Images | Select-Object src 
    $request = Invoke-WebRequest -Uri $wikiURL
    
    $tables = @($request.ParsedHtml.getElementsByTagName("TABLE"))

    foreach ($table in $tables) {

        $rows = @($table.Rows)
        
        foreach ($row in $rows) {
            $inputCode = ""

            $cells = @($row.Cells)
            
            if ($cells[0].tagName -eq "TD") {

                $cells[2].childNodes | Foreach-Object {
					#Looks in the table cell that contains stratagem codes for images, and uses image name to determine direction
                    if ($_.className -eq 'image') { 
                        $arrowDirection = $_

                        $arrowDirection = $arrowDirection.href
                        $splitArray = $arrowDirection -split '.png'
                        $temp = $splitArray[0]
                        $lastChar = $temp[-1]


                        if($lastChar -match "U"){
                            $inputCode+="U"
                        }

                        elseif($lastChar -match "D"){
                            $inputCode+="D"
                        }

                        elseif($lastChar -match "L"){
                            $inputCode+="L"
                        }

                        elseif($lastChar -match "R"){
                            $inputCode+="R"
                        }

                    }
                }

				#Parse the HTML to determine info for each Stratagem

                $name = $cells[1] | ForEach-Object { ("" + $_.InnerText).Trim() }
                $coolDown = $cells[3] | ForEach-Object { ("" + $_.InnerText).Trim() }
                $uses = $cells[4] | ForEach-Object { ("" + $_.InnerText).Trim() }
                $activationTime = $cells[5] | ForEach-Object { ("" + $_.InnerText).Trim() }
				#$activationTime = @($cells[5] | ForEach-Object { ("" + $_.InnerText).Trim() })
				
				#This may not be super important, but, doing a bit of formatting on the strings
				$name = $name.Replace('"',"")
				$coolDown = $coolDown.Replace("seconds","").Replace("second","")
				$activationTime = $activationTime.Replace("seconds","").Replace("second","")
				
				#$name = $name.Replace('"',"")
				#$name = $name -replace '"',""

				

                $StratagemList.Add(@{"Name"=$name;
				"Alias"="";"Code"=$inputCode;
				"Cooldown"=$coolDown;
				"Uses"=$uses;
				"ActivationTime"=$activationTime;})

                continue
            }
        }
    }

	$Stratagems = @{"Stratagems"=$StratagemList;}
	$StratagemJson.Add("Democracy",$Stratagems)
	$StratagemJson | ConvertTo-Json -Depth 10 | Out-File $stratagesmDataFile

    foreach ($key in $StratagemJson.Democracy.Stratagems) {
		
        if($key.Name -eq $strat){
            Write-Host $key.Name $key.Code -ForegroundColor Cyan
        }
		
    }
}
if ($update) {
	Update-Json
} 


try {
# This is there the script reads stratagems.json to check for the codes. If the file is missing, you get a popup
# The datafile does NOT have to be generated this way, the -update command can be used when running the script
	$stratagemCodeFile = (Get-Content $stratagesmDataFile -Raw -ErrorAction Stop) | ConvertFrom-Json
	$requestedCode = $stratagemCodeFile.Democracy.Stratagems | Where-Object { $_.Name -eq $strat }
	$code = $requestedCode.code
}
catch [System.Management.Automation.ItemNotFoundException]{
	$ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
	$MessageboxTitle = "No stratagem data file found!"
	$Messageboxbody = "I can automatically generate the JSON file by accessing the internet and grabbing data from the Helldivers 2 Wiki, or you can download stratagams.json from the repo. May I attempt to generate the file now?"
	$MessageIcon = [System.Windows.MessageBoxImage]::Warning
	$Result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)

	if ($Result -eq "Yes"){
		Write-Host "Downloading info from https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2)" -ForegroundColor Magenta
		Update-Json
	}

}

#Output the code for troubleshooting
#$code
function Enter-Keypress {
    param (
        [string[]]$stratagemCode
    )
        
    $keyPresses = $stratagemCode.ToCharArray();

    #Strategem Keypress type setting in-game MUST be "press" for this function to work. I could not get holding down CTRL to work
    [System.Windows.Forms.SendKeys]::SendWait("^"); #This is the CTRL Key Press
    
    foreach ($key in $keyPresses) {
        #Loops thru each character of the codes entered manually above, presses the corresponding arrow, then waits 50 ms
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


# Main
if ($null -ne $code) {
    Enter-Keypress -stratagemCode $code
}