Name = "Installer.lua"
Version = "0.4.0"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    log = Path.."/System/Files/ReactorControl_Installer.log",
    installation = {
        files = "/Installer/files.json",
    },
    apis = {
        screen = "/System/APIs/screen.lua",
    },
}
local config = {
    debug = true,
}

local arg = {...}
local update
local branch = "rework2.0"
local repoURL = "https://raw.githubusercontent.com/JetroDR/ReactorControl/"

function init_log()
    if fs.exists(files.log) then
        fs.delete(files.log)
    end
    myLog = fs.open(files.log, "w")
    myLog.write("["..Name.."] [INFO] ["..os.date("%d-%m-%Y %X").."] Installer Log File\n")
    myLog.close()
end

function log(type, text)
    if (type == "debug" and config.debug) or type ~= "debug" then
        myLog = fs.open(files.log, "a")
        myLog.write("["..Name.."] ["..string.upper(type).."] ["..os.date("%d-%m-%Y %X").."] "..text.."\n")
        myLog.close()
        if type == "error" then 
            error(text)
        end
    end
end

function read_file(FilePath)
    myFile = fs.open(FilePath,"r")
    data = textutils.unserialiseJSON(myFile.readAll())
    myFile.close()
    return data
end

function write_file(FilePath, data)
    if fs.exists(FilePath) then
        log("error", "Unable to create new file: file already exists: "..FilePath)
    else
        myFile = fs.open(FilePath, "w")
        myFile.write(data)
        myFile.close()
    end
end

function check_version(FilePath, URL)
    log("debug", "checking "..FilePath)
    if fs.exists(FilePath) then
        myFile = fs.open(FilePath, "r")
        fileContents = myFile.readAll()
        myFile.close()

        local _, numberChars = fileContents:lower():find('version = "')
        if numberChars then
            fileVersion = ""
            local char = ""

            while char ~= '"' do
                numberChars = numberChars + 1
                char = fileContents:sub(numberChars,numberChars)
                fileVersion = fileVersion .. char
            end
            fileVersion = fileVersion:sub(1,#fileVersion-1)
            log("debug", FilePath.." Version: "..fileVersion)
        else
            fileVersion = ""
            File_Contents = fileContents
        end
    else
        fileVersion = "File not found"
    end

     -- Insert GitHub Version logic
        
    if http.checkURL(URL) then
        myGithub = http.get(URL)
        fileContents = myGithub.readAll()
        myGithub.close()
            
        local _, numberChars = fileContents:lower():find('version = "')
        if numberChars then
            GithubVersion = ""
            local char = ""

            while char ~= '"' do
                numberChars = numberChars + 1
                char = fileContents:sub(numberChars,numberChars)
                GithubVersion = GithubVersion .. char
            end
            GithubVersion = GithubVersion:sub(1,#GithubVersion-1)
            log("debug", URL.." Version: "..GithubVersion)
        else
            GithubVersion = ""
            Github_Contents = fileContents
        end
    else
        GithubVersion = "File not found"
    end

    if fileVersion == GithubVersion  or File_Contents == Github_Contents then
        log("debug", FilePath.." up to date")
        return fileVersion
    else
        log("debug", FilePath.." out of date, update required")
        return false
    end
end

function download_file(URL,FilePath)
    FileVersion = check_version(FilePath, URL)
    term.setTextColor(colors.lightGray)
    term.write("GET "..FilePath)
    term.setTextColor(colors.blue)
    print((FileVersion ~= "" and " v"..FileVersion) or "")
    if not(FileVersion) then
        if fs.exists(FilePath) then
            log("warning", "File "..FilePath.." already exists, deleting old file")
            fs.delete(FilePath)
        end
        log("info", "Downloading "..URL.." as "..FilePath)
        if http.checkURL(URL) then
            myGithub = http.get(URL)
            data = myGithub.readAll()
            myGithub.close()
            write_file(FilePath,data)
        else
            log("error", "Unable to find URL:"..URL)
        end
    end
end

function create_startup()
    if fs.exists("startup.lua") then
        log("warning", "File startup.lua already exists, deleting old file")
        fs.delete("startup.lua")
    end
    log("info", "Creating startup.lua")
    myStartup = fs.open("startup.lua","w")
    myStartup.write('shell.run("ReactorControl/Startup.lua")')
end 

function arguments()
    if #arg == 0 then
        log("info", "No arguments included")
    elseif #arg >= 1 and #arg <= 2 then
        log("debug", #arg.." argument"..((#arg > 1 and "s") or "").." included:")
        for i = 1, #arg do
            log("debug", arg[i])
            if arg[i] == "stable" or arg[i] == "master"  then
                branch = "master"
            elseif arg[i] == "development" or arg[i] == "beta" then
                branch = "rework2.0"
            elseif arg[i] == "update" then
                --check_version()
                update = true
                log("ran Update")
            end
        end
    else
        log("error", "Invalid amount of arguments")
    end
end

function install_installation_files()
    table = {files.installation, files.apis}
    for i = 1, #table do
        for name, FilePath in pairs(table[i]) do
            download_file(repoURL..branch..FilePath, Path..FilePath)
        end
    end
end

function load_API()
    for APIname, APIpath in pairs(files.apis) do
        if fs.exists(Path..APIpath) then
            succes = os.loadAPI(Path..APIpath)
            if succes then
                log("info", "Loaded "..APIname.." API")
            else
                log("error", "Unable to load "..APIname.." API")
            end
        else
            log("error", "Unable to load "..APIname.." API due to file not found")
        end
    end
end

function install_files()
    screen.clear()
    screen.clearLine(1,colors.gray)
    w,h = term.getSize()
    screen.drawText(math.floor((w - string.len(Path.." - "..Name.." "..Version))/2),1, Path.." - "..Name.." "..Version)
    print("")

    myFiles = fs.open(Path..files.installation.files, "r")
    installation_files = textutils.unserialiseJSON(myFiles.readAll())
    myFiles.close()

    for tableName, table in pairs(installation_files) do
        for FileName, FilePath in pairs(table) do
            download_file(repoURL..branch.."/"..FilePath, Path.."/"..FilePath)
        end
    end
end

function main()
    init_log()
    arguments()
    if not(update) then
        install_installation_files()
        load_API()
        install_files()
        --configure_settings()
    end
end

main()