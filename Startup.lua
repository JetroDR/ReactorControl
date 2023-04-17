local name = "ReactorControl"
local debug = true

local StartupModeFile = "OS/files/StartupMode.txt"

local file = {
    reactorcontrol = {
        name.."/System/Control.lua",
        name.."/System/Display.lua",
        name.."/System/Redstone.lua",
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
    StartupMode = name.."_normal"
end

if StartupMode == name.."_normal" then
    for i = 1, #file.reactorcontrol do
        if i ~= 1 then
            multishell.launch({},file.reactorcontrol[i])
        end
    end
    multishell.setTitle(1,"Control")
    multishell.setTitle(2,"Display")
    multishell.setTitle(3,"Redstone")
    if debug then
        shell.run("fg")
        multishell.setTitle(4,"Debug")
    end
    multishell.setFocus(1)
    shell.run(file.reactorcontrol[1])
elseif StartupMode == name.."_Installer" then
    shell.run(name.."/Installer.lua")
end