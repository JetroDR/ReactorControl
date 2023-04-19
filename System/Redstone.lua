--[[

    Name = Redstone.lua
    Version = 0.1.0.4
    Author = Jetro

]]

-- Variables

local name = "ReactorControl"
local filename = name.."/System/Redstone.lua"

local file = {
    config = "ReactorControl/System/Config.cfg",
    log = "ReactorControl/System/log.log"
}

-- Functions

function config_read()
    if fs.exists(file.config) then
        myConfig = fs.open(file.config,"r")
        config = textutils.unserialise(myConfig.readAll())
        myConfig.close()
    else
        log("error","unable to find configfile")
        error()
    end
end

function config_write()
    if config then
        table.sort(config)
        myConfig = fs.open(file.config,"w")
        myConfig.write(textutils.serialise(config))
        myConfig.close()
    else
        log("error","Config is nill")
        error()
    end
end

function log(logType, data)
    myLog = fs.open(file.log,"a")
    myLog.write("["..string.upper(logType).."] ["..filename.."] "..data.."\n")
    myLog.close()
    if string.lower(logType) == "error" then
        table.insert(config.error,"["..logType.."] ["..filename.."] "..data)
    elseif string.lower(logType) == "warning" then
        table.insert(config.warning,"["..logType.."] ["..filename.."] "..data)
    end
    config_write()
end

function init_redstone()
    config_read()
    rs.setOutput(config.redstone.side,false)
end

function init_error_warning()
    config.warning = {}
    config.error = {}
    config_write()
end

function start()
    init_redstone()
    init_error_warning()
    main()
end

function main()
    while true do
        config_read()
        if #config.error > 0 then
            rs.setOutput(config.redstone.side,true)
            sleep(config.redstone.lamp_blink_speed)
            rs.setOutput(config.redstone.side,false)
            sleep(config.redstone.lamp_blink_speed)
        elseif #config.warning > 0 then
            rs.setOutput(config.redstone.side,true)
        else
            rs.setOutput(config.redstone.side,false)
        end
    sleep(.1)
    end
end
-- Main

start()