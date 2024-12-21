Name = "startup.lua"
Version = "0.2.2"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    config = Path.."/System/Files/config.cfg",
    log = Path.."/System/Files/ReactorControl.log",
}

local branch = "rework2.0"
local repoURL = "https://raw.githubusercontent.com/JetroDR/ReactorControl/"
local need_update = false

function init_log()
    if fs.exists(files.log) then
        fs.delete(files.log)
    end
    myLog = fs.open(files.log, "w")
    myLog.write("["..Name.."] [INFO] ["..os.date("%d-%m-%Y %X").."] OS Log File\n")
    myLog.close()
end

function log(type, text)
    if (type == "debug" and config.settings.debug.value) or type ~= "debug" then
        myLog = fs.open(files.log, "a")
        myLog.write("["..Name.."] ["..string.upper(type).."] ["..os.date("%d-%m-%Y %X").."] "..text.."\n")
        myLog.close()
        if type == "warning" then
            table.insert(config.warnings, text)
            write_config()
        elseif type == "error" then 
            table.insert(config.errors, text)
            write_config()
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

function write_config()
    if config then
        table.sort(config)
        myCfg = fs.open(files.config,"w")
        myCfg.write(textutils.serialise(config))
        myCfg.close()
    else
        log("error","Config is nill")
    end
end

function check_version(FilePath, URL)
    log("debug", "checking "..FilePath)
    File_Contents = ""
    if fs.exists(FilePath) then
        myFile = fs.open(FilePath, "r")
        fileContents = ""
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
            log("debug", "Local Version: "..fileVersion)
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
        fileContents = ""
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
            log("debug", "GitHub Version: "..GithubVersion)
        else
            GithubVersion = ""
            Github_Contents = fileContents
        end
    else
        GithubVersion = "File not found"
    end
    if fileVersion == GithubVersion then
        log("info", FilePath.." up to date "..fileVersion)
        return fileVersion
    else
        if File_Contents == Github_Contents then
            log("info", FilePath.." up to date "..File_Contents)
            return fileVersion
        else
            log("info", FilePath.." out of date, update required")
            need_update = true
            return false
        end
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
    print("-- BOOTING "..Path.." v"..Version.." --")
    if config.settings.check_for_updates.value then
        for i = 1, #config.files.boot do
            FileVersion = check_version(Path..config.files.boot[i].file, repoURL..branch..config.files.boot[i].file)
            term.setTextColor(colors.lightGray)
            term.write("GET "..Path..config.files.boot[i].file)
            term.setTextColor(colors.blue)
            print((FileVersion == false and "") or (FileVersion ~= "" and " v"..FileVersion) or "")
        end
    end
    if need_update then
        term.setTextColor(colors.red)
        print("")
        print(Path.." "..Version.." out of date, update required.")
        print("Do you wish to update? [Y/N]")
        input = string.lower(read())
        if input == "y" then
            shell.run(Path.."/Installer/Installer.lua")
            os.reboot()
        else
            boot()
        end
    else
        boot()
    end
end

main()