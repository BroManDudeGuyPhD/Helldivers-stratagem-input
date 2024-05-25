# Helldivers Automated Stratagem Input  

I acheived [voice command stratagems](https://www.youtube.com/watch?v=x0HwI6L7jYI) in Helldivers 2 using Alexa, Home Assistant, and the [HASS.Agent](https://github.com/LAB02-Research/HASS.Agent) app on my W11 PC   

The basic flow is  
Alexa routine -> Home Assistant switch -> HASS.Agent command -> Script execution  
I've also had luck with Siri and the HomeKit Bridge Addon, which is _significantly_ faster

Unfortunately, each stratagem is a unique command in the HASS.Agent. But really, I use the same loadout and only a few variations  

However ALL stratagems are mapped in stratagems.json. If there are ever any changes the `-update` command can be run locally to access the [Helldivers 2 Wiki](https://helldivers.fandom.com/wiki/Stratagem_Codes_(Helldivers_2)) and grab any new codes. The update will also be triggered automatically and give a context menu if the script runs and the file is mnissing for some reason  
`automagic-democracy.ps1 -update`  

__________________________________________________  
I get that having Home Assistant and a Home Assistant specific application is kind of overkill just for voice commands, but there are a few programs that integrate with Alexa like [triggerCMD](https://www.triggercmd.com/en/) that should allow the same functionality, albeit a bit slower  
__________________________________________________ 

The param is where the script captures the text entered in at the command line. The command would look like  
    `powershell.exe -File "C:\Users\username\automagic-democracy.ps1" -strat "Airstrike"`  
If the script is placed somewhere on your Windows path, you can call it with just  
    `automagic-democracy -strat "Airstrike"`  

However, the HASS.Agent program cannot call it directly, I believe because it isn't running the commands in powershell but CMD,  so the longform is required  
Inside the HASS.Agent, I set up a Custom Command of type switch, with the command formatted like  
    `powershell.exe -File "C:\Users\andre\automagic-democracy.ps1" -strat "Orbital Laser"`



Add me on [Steam](https://steamcommunity.com/id/BroManDudeGuyPhD/) if you are so inclined, and join me on the **SES Paragon of Family Values**
