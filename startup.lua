Name = "startup.lua"
Version = "0.2.0"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    config = Path.."/System/Files/config.cfg",
    log = Path.."/System/Files/ReactorControl.log",
}

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

function update_checker()
    for i = 1, #config.files.boot do
        myFile = fs.open(Path..config.files.boot[i].file, "r")
        fileContents = myFile.readAll()
        myFile.close()

        local _, numberChars = fileContents:lower():find('version = "')
        local fileVersion = ""
        local char = ""

        while char ~= '"' do
            numberChars = numberChars + 1
            char = fileContents:sub(numberChars,numberChars)
            fileVersion = fileVersion .. char
        end

        fileVersion = fileVersion:sub(1,#fileVersion-1)
        log("debug", config.files.boot[i].name.." Version: "..fileVersion)

        -- Insert GitHub Version logic
        gitHubVersion = fileVersion -- Temp version fix

        if fileVersion == gitHubVersion then
            log("debug", Path..config.files.boot[i].file.." up to date")
        else
            log("debug", Path..config.files.boot[i].file.." out of date, update required")
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
    update_checker()
    boot()
end

main()
multishell.setFocus(2)