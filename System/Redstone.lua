Name = "Redstone.lua"
Version = "0.2.0"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    config = Path.."/System/Files/config.cfg",
    log = Path.."/System/Files/ReactorControl.log",
}

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

function main()
    read_config()
    --init_apis()
    --init_peripherals()
    log("debug", Name)
end

main()