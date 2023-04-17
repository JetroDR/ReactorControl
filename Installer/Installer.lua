--[[

    Name = Installer.lua
    Version = 0.3.1
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

function update()
    delete_all(files)
    download_all(files)
    log("\nLogFile: "..logFile)
    log("Rebooting...")
    myStartup = fs.open("OS/files/StartupMode.txt","w")
    myStartup.write(name.."_normal")
    myStartup.close()
    sleep(2)
    os.reboot()
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
    branch = "main"
    checkUpdate = false
elseif #arg >= 1 and #args <= 2 then
    log(#arg.." argument"..(#arg > 1 and "s").." included:")
    for i = 1, #arg do
        log(arg[i])
        if arg[i] == "stable" or arg[1] == "main"  then
            branch = "main"
        elseif arg[i] == "update" then
            CheckUpdate = true
        end
    end
    
else
    log("Invalid amount of arguments")
    error("Invalid amount of arguments")
end
if not(branch) then
    branch = "main"
end
if not(CheckUpdate) then
    CheckUpdate = false
end

relURL = repoURL..branch.."/"
log("\nBranch: "..branch)
 
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
    elseif key == keys.backspace then
        return false
    end
end