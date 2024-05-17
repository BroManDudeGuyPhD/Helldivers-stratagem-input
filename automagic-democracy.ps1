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

 #An expandable list of stratagems, the presses are done in the Key-Press function so this is easily expandable
 switch ($strat) {

    #Orbitals
    "Precision Strike"{
        $code = "RRD"
    }

    "Orbital Laser"{
        $code = "RDURD"
    }

    "Orbital Railcannon"{
        $code = "RUDDR"
    }


    #--Eagles--
    "Strafing Run"{
        $code = "URR"
    }

    "Airstrike"{
        $code = "URDR"
    }

    "Cluster Bomb"{
        $code = "URDDR"
    }

    "Napalm"{
        $code = "URDU"
    }

    "Rocket Pods"{
        $code = "URUL"
    }

    "500kg bomb"{
        $code = "URDDD"
    }
    

    #--Support Weapons--
    "Machine Gun"{
        $code = "DLDUR"
    }

    "Anit-Material Rifle"{
        $code = "DLRUD"
    }

    "Autocannon"{
        $code = "DLDUUR"
    }
    
    "Rail gun"{
        $code = "DRDULR"
    }

    "Spear"{
        $code = "DDUDD"
    }

    "Laser cannon"{
        $code = "DLDUL";
    }


    #--Backpacks--
    "Laser Drone"{
        $code = "DULURR"
    }

    "Gun Drone"{
        $code = ""
    }


    #--Supplies--
    "Resupply"{
        $code = "DDUR"
    }

    "Reinforce"{
        $code = "UDRLU"
    }

    "Artillery"{
        #SEAF Artillery
        $code = "RUUD"
    }

    "Hellbomb"{
        $code = "DULDURDU"
    }
 }


function Enter-Keypress {
    param (
        [string[]]$stratagemCode
    )
        
    $keyPresses = $stratagemCode.ToCharArray();

    #Strategem Keypress type setting in-game MUST be "press" for this function to work. I could not get holding down CTRL to work
    [System.Windows.Forms.SendKeys]::SendWait("^"); #This is the CTRL Key Press
    
    foreach ($key in $keyPresses) {
        #Loops thru each character of the codes entered manually above, presses the corresponding arrow, then waits 50 ms
        Start-Sleep -Milliseconds 50
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


#Main

if ($null -ne $code) {
    Enter-Keypress -stratagemCode $code
}


 