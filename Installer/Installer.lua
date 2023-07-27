--[[

    Name = Installer.lua
    Version = 0.3.3
    Author = Jetro

]]

-- Variables

local name = "ReactorControl-Installer"

local logFile = "OS/files/logs/"..name..".log"

local arg = {...}
local branch
local checkUpdate
local relURL
local repoURL = "https://raw.githubusercontent.com/Jetro2203/ReactorControl/"
local repoAPI = "https://raw.githubusercontent.com/Jetro2203/APIs/main/"

-- Functions

function log(data)
    myLog = fs.open(logFile,"a")
    myLog.write(data.."\n")
    myLog.close()
end

function read_file(location)
    myFiles = fs.open(location,"r")
    data = textutils.unserialiseJSON(myFiles.readAll())
    myFiles.close()
    return data
end

function write_file(location, data)
    if fs.exists(location) then
        log("Unable to create new file: file already exists: "..location)
        error("Unable to create new file: file already exists: "..location)
    else
        myFile = fs.open(location, "w")
        myFile.write(data)
        myFile.close()
    end
end

function download_file(URL,location)
    if fs.exists(location) then
        log("File "..location.." already exists, deleting old file")
        fs.delete(location)
    end
    log("Downloading "..URL.." as "..location)
    if http.checkURL(URL) then
        myGithub = http.get(URL)
        data = myGithub.readAll()
        myGithub.close()
        write_file(location,data)
    else
        error("Unable to find URL:"..URL)
    end
end

function create_startup()
    if fs.exists("startup.lua") then
        log("File startup.lua already exists, deleting old file")
        fs.delete("startup.lua")
    end
    log("Creating startup.lua")
    myStartup = fs.open("startup.lua","w")
    myStartup.write('shell.run("ReactorControl/Startup.lua")')
end 

-- Main
 
shell.run("clear")
 
if fs.exists(logFile) then
    fs.delete(logFile)
end
myLog = fs.open(logFile,"w")
myLog.close()

if #arg == 0 then
    log("No arguments included")
    branch = "master"
    checkUpdate = false
elseif #arg >= 1 and #arg <= 2 then
    log(#arg.." argument"..((#arg > 1 and "s") or "").." included:")
    for i = 1, #arg do
        log(arg[i])
        if arg[i] == "stable" or arg[i] == "master"  then
            branch = "master"
        elseif arg[i] == "development" or arg[i] == "beta" then
            branch = "development"
        elseif arg[i] == "update" then
            CheckUpdate = true
        end
    end
    
else
    log("Invalid amount of arguments")
    error("Invalid amount of arguments")
end
if not(branch) then
    branch = "master"
end
if not(CheckUpdate) then
    CheckUpdate = false
end

relURL = repoURL..branch.."/"
log("\nBranch: "..branch.."\n")
 
print(name)
if CheckUpdate then

else
    print("Installing "..branch.." version")
    print("Press enter to continue or backspace to abort")
    event, key = os.pullEvent("key")
    if key == keys.enter then
        download_file(relURL.."Installer/files.json","ReactorControl/Installer/files.json")
        files = read_file("ReactorControl/Installer/files.json")
        for folderName, folder in pairs(files) do
            if folderName == "OS/APIs/" then
                for file, URL in pairs(folder) do
                    download_file(repoAPI..URL,folderName..file)
                end
            else
                for file, URL in pairs(folder) do
                    download_file(relURL..URL,folderName..file)
                end
            end
        end
        create_startup()
    elseif key == keys.backspace then
        return false
    end
end

myStartup = fs.open("OS/files/StartupMode.txt","w")
myStartup.write("normal")
myStartup.close()
os.reboot()