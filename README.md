# Helldivers Automated Stratagem Input  

All currently availiable stratagems are mapped in democracy.json.  
This process is automatic, if there are ever any changes the `-update` command can be run and the script will access the [Helldivers 2 Wiki](https://helldivers.fandom.com/wiki/Stratagem_Codes) to grab any new codes. The update will also be triggered automatically and give a context menu if the script runs and the democracy.json file is mnissing for some reason  

The update can be run very easily: 
`automagic-democracy.ps1 -update`  

  
## This script is a dedicated Macro Alternitive
Let's be honest, keyboard Macros make more strategic sense than voice control all the time, as cool as that may be.  
Once you set this up, you won't need to manually record the keypresses for any stratagems since all the codes are stored already, and can be easily updated too! Even though I personally have dedicated macro keys and use those for my Orbitals and Airstrikes, I have different loadouts I run, and not *that* many macro keys  
[Powertoys](https://learn.microsoft.com/en-us/windows/powertoys/install) is a Macro software alternative in W11, you can setup a custom hotkey or combo in the [Keyboard Manager](https://learn.microsoft.com/en-us/windows/powertoys/keyboard-manager), such as a function key or maybe Alt+1. You're able to set up a program to run on hotkey entry, so select the script and then enter the appropriate parameter

## VOICE ACTIVATED STRATAGEMS
I acheived [voice command stratagems](https://www.youtube.com/watch?v=x0HwI6L7jYI) in Helldivers 2 using Alexa, Home Assistant, and the [HASS.Agent](https://github.com/LAB02-Research/HASS.Agent) app on my W11 PC  
I've also had luck with Siri and the HomeKit Bridge Addon, which is _significantly_ faster  

The basic flow is  
`Alexa routine -> Home Assistant switch -> HASS.Agent command -> Script execution`  

Unfortunately, each stratagem is a unique command in the HASS.Agent. But really, I use the same loadout and only a few variations  

I get that having Home Assistant and a Home Assistant specific application is kind of overkill just for voice commands, but there are a few programs that integrate with Alexa like [triggerCMD](https://www.triggercmd.com/en/) that should allow the same functionality, albeit a bit slower  
 

## How to execute the script
The param is where the script captures the text entered in at the command line. The command would look like  
    `powershell.exe -File "C:\Users\username\automagic-democracy.ps1" -strat "Autocannon"`  
If the script is placed somewhere on your Windows path, you can call it with just  
    `automagic-democracy -strat "Autocannon"`  

However, the HASS.Agent program cannot call it directly, I believe because it isn't running the commands in powershell but CMD,  so the longform is required  
Inside the HASS.Agent, I set up a Custom Command of type switch, with the command formatted like  
    `powershell.exe -File "C:\Users\andre\automagic-democracy.ps1" -strat "Orbital Laser"`



Add me on [Steam](https://steamcommunity.com/id/BroManDudeGuyPhD/) if you are so inclined, and join me on the **SES Paragon of Family Values**
