--[[

    Name = Startup.lua
    Version = 0.1.1.1
    Author = Jetro

]]

local name = "ReactorControl"
local debug = true

local StartupModeFile = "OS/files/StartupMode.txt"

local file = {
    reactorcontrol = {
        name.."/System/Control.lua",
        name.."/System/Display.lua",
        name.."/System/Redstone.lua",
        name.."/System/Datalogger.lua",
    },
}

if fs.exists(StartupModeFile) then
    myMode = fs.open(StartupModeFile,"r")
    StartupMode = myMode.readLine()
    myMode.close()
else
    printError("Unable to determine startupMode: StartupModeFile missing")
    myMode =fs.open(StartupModeFile,"w")
    myMode.write(name.."_normal")
    myMode.close()
end

if StartupMode == nil or StartupMode == "" then
    StartupMode = "normal"
end

if StartupMode == "normal" then
    for i = 1, #file.reactorcontrol do
        if i ~= 1 then
            multishell.launch({},file.reactorcontrol[i])
        end
    end
    multishell.setTitle(1,"Control")
    multishell.setTitle(2,"Display")
    multishell.setTitle(3,"Redstone")
    multishell.setTitle(4,"Datalogger")
    if debug then
        shell.run("fg")
        multishell.setTitle(5,"Debug")
    end
    multishell.setFocus(1)
    shell.run(file.reactorcontrol[1])
elseif StartupMode == "installer" then
    shell.run(name.."/Installer/Installer.lua")
end