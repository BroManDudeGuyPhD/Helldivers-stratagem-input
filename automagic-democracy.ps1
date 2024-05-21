<#
    Code by BroManDudeGuyPhD
    Purpose: Spread Democracy more effectively with this strategem keypress tool.
    5/16/2024
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$strat
 )

add-type -AssemblyName microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms

 #Right now the stratagem list is hardcoded, but I intend to generate it dynamically by scraping data off a Wiki page and storing that in the stratagems.json file

 $stratagemCodeFile = (Get-Content "stratagems.json" -Raw) | ConvertFrom-Json

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

#wait time in milliseconds between keypresses
$keypressWaitTime = 70

if ($null -ne $code) {
    Enter-Keypress -stratagemCode $code
}


 