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

add-type -AssemblyName microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms

#Right now the stratagem list is hardcoded, but I intend to generate it dynamically by scraping data off a Wiki page and storing that in the stratagems.json file

if ($update) {
    Write-Host "Updating Stratagems"

    $StratagemHashTable = @{}

    
    
    #Copy-Item .\stratagems.json stratagems.json.bak

    $wikiURL = "https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2)"
    #$wikiURL = "http://www.egyptianhieroglyphs.net/gardiners-sign-list/domestic-and-funerary-furniture/"

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


                $name = @($cells[1] | ForEach-Object { ("" + $_.InnerText).Trim() })
                
                $coolDown = @($cells[3] | ForEach-Object { ("" + $_.InnerText).Trim() })
                $uses = @($cells[4] | ForEach-Object { ("" + $_.InnerText).Trim() })
                $activationTime = @($cells[5] | ForEach-Object { ("" + $_.InnerText).Trim() })

                $info = @{
                    'Alias'           = ''
                    'Code'            = $inputCode
                    'Cooldown'        = $coolDown
                    'Uses'            = $uses
                    'Activation Time' = $activationTime
                }

                $StratagemHashTable.Add($name,$info)
                continue
            }
        }
    }


    foreach ($key in $StratagemHashTable.Keys) {

        if($key -eq $strat){
            Write-Host $key $StratagemHashTable.$key.Code -ForegroundColor Cyan
        }
    }
    
} 

$stratagemCodeFile = (Get-Content $stratagesmDataFile -Raw) | ConvertFrom-Json

$requestedCode = $stratagemCodeFile.stratagems | Where-Object { $_.Name -eq $strat }

$code = $requestedCode.code

#Output the code for troubleshooting
$code
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


 