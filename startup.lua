Name = "startup.lua"
Version = "0.2.0"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    config = Path.."/System/Files/config.cfg",
    log = Path.."/System/Files/ReactorControl.log",
}

local branch = "rework2.0"
local repoURL = "https://raw.githubusercontent.com/JetroDR/ReactorControl/"

function init_log()
    if fs.exists(files.log) then
        fs.delete(files.log)
    end
    myLog = fs.open(files.log, "w")
    myLog.write("["..Name.."] [INFO] ["..os.date("%d-%m-%Y %X").."] OS Log File\n")
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

function read_config()
    if fs.exists(files.config) then
        myCfg = fs.open(files.config, "r")
        config = textutils.unserialise(myCfg.readAll())
        myCfg.close()
    else
        log("error","unable to find configfile")
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
            fileVersion = fileContents
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
            gitHubVersion = ""
            local char = ""

            while char ~= '"' do
                numberChars = numberChars + 1
                char = fileContents:sub(numberChars,numberChars)
                gitHubVersion = gitHubVersion .. char
            end
            gitHubVersion = gitHubVersion:sub(1,#gitHubVersion-1)
            log("debug", URL.." Version: "..gitHubVersion)
        else
            githubVersion = fileContents
        end
    else
        log("error", "Unable to find URL:"..URL)
    end
    
    if fileVersion == gitHubVersion then
        log("debug", FilePath.." up to date")
        return fileVersion
    else
        log("error", FilePath.." out of date, update required")
        return false
    end
end

function boot()
    for i = 1, #config.files.boot do
        if i ~= 1 then
            multishell.launch({}, Path..config.files.boot[i].file)
            log("info", "Launched "..Path..config.files.boot[i].file.." in multishell")
            multishell.setTitle(multishell.getCount(), config.files.boot[i].name)
            log("debug", "Changed multishell title #"..multishell.getCount().." to "..config.files.boot[i].name)
        end
    end

    multishell.setTitle(1, config.files.boot[1].name)
    log("debug", "Changed multishell title #1 to "..config.files.boot[1].name)
    shell.run(Path..config.files.boot[1].file)
    log("info", "Launched "..Path..config.files.boot[1].file.." in shell")
end

function main()
    init_log()
    read_config()
    print("[ CHECKING FOR UPDATES ]")
    for i = 1, #config.files.boot do
        print("Checking "..Path..config.files.boot[i].file)
        check_version(Path..config.files.boot[i].file, repoURL..branch..config.files.boot[i].file)
    end
    boot()
end

main()