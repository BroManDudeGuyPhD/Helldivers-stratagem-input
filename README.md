# Helldivers Stratagem Input
Helldivers 2 Stratagem input for PC

I acheived voice command strategems in Helldivers 2 using Alexa, Home Assistant, and the HASS.Agent app on my W11 PC  
https://github.com/LAB02-Research/HASS.Agent  

The basic flow is  
Alexa routine -> Home Assistant switch -> HASS.Agent command -> Script execution  
I've also had luck with Siri and the Homekit Add-on  

Unfortunately, each stratagem is a unique command in the HASS.Agent. But really, I use the same loadout and only a few variations
So I've mapped what I feel are the most common loadouts, but the switch statement is easily expandable

The param is where the script captures the text entered in at the command line. The command would look like  
    `powershell.exe -File "C:\Users\username\automagic-democracy.ps1" -strat "Airstrike"`  
If the script is placed somewhere on your Windows path, you can call it with just  
    `automagic-democracy -strat "Airstrike"`  

However, the HASS.Agent program cannot call it directly, I believe because it isn't running the commands in powershell but CMD,  so the longform is required  
Inside the HASS.Agent, I set up a Custom Command of type switch, with the command formatted like  
    `powershell.exe -File "C:\Users\andre\automagic-democracy.ps1" -strat "Orbital Laser"`
