--[[

    Name = Datalogger.lua
    Version = 0.1.0
    Author = Jetro

]]

-- Variables

local name = "ReactorControl"
local filename = name.."/System/Datalogger.lua"
local version = "0.1.0"

local file = {
    config = "ReactorControl/System/Config.cfg",
    log = "ReactorControl/System/log.log",
    data = {
        reactor = "time;casing_temp;core_temp;hot_fluid_produced_last_tick",
        turbine = "time;energy_produced_last_tick;rotor_speed",
        battery = "time;energy_stored;max_energy_capacity;percentage",
    }
}

local reactor = {}
local turbine = {}
local battery = {}
local mon = {}

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

function datawriter(datafile, data)
    myData = fs.open(datafile, "a")
    myData.write("\n"..os.date("%a %d %B %Y %T")..";"..data)
    myData.close()
end

function init_peripheral()
    PList = peripheral.getNames()
    for i = 1, #PList do
        if peripheral.getType(PList[i]) == "BigReactors-Reactor" then
            table.insert(reactor,PList[i])
        elseif peripheral.getType(PList[i]) == "BigReactors-Turbine" then
            table.insert(turbine,PList[i])
        elseif peripheral.getType(PList[i]) == "capacitor_bank" then
            table.insert(battery,PList[i])
        elseif peripheral.getType(PList[i]) == "monitor" then
            table.insert(mon,PList[i])
        end
        table.sort(reactor)
        table.sort(turbine)
        table.sort(battery)
        table.sort(mon)
    end

    for i = 1, #reactor do
        reactor[i] = peripheral.wrap(reactor[i])
    end
    for i = 1, #turbine do
        turbine[i] = peripheral.wrap(turbine[i])
    end
    for i = 1, #battery do
        battery[i] = peripheral.wrap(battery[i])
    end
    for i = 1, #mon do
        mon[i] = peripheral.wrap(mon[i])
    end
end

function init_datafiles()
    for file, intro in pairs(file.data) do
        if file == "turbine" then
            for i = 1,  #turbine do
                if fs.exists("ReactorControl/Data/"..file..i..".csv") then
                    fs.delete("ReactorControl/Data/"..file..i..".csv")
                end
                myData = fs.open("ReactorControl/Data/"..file..i..".csv", "w")
                myData.write(intro)
                myData.close()
            end
        else
            if fs.exists("ReactorControl/Data/"..file..".csv") then
                fs.delete("ReactorControl/Data/"..file..".csv")
            end
            myData = fs.open("ReactorControl/Data/"..file..".csv", "w")
            myData.write(intro)
            myData.close()
        end
    end
end

function Datalogger()
    config_read()
    init_peripheral()
    init_datafiles()

    while true do
        config_read()
        datawriter("ReactorControl/Data/reactor.csv",reactor[1].getCasingTemperature()..";"..reactor[1].getFuelTemperature()..";"..reactor[1].getHotFluidProducedLastTick())
        for i = 1, #turbine do
            datawriter("ReactorControl/Data/turbine"..i..".csv",turbine[i].getEnergyProducedLastTick()..";"..turbine[i].getRotorSpeed())
        end
        datawriter("ReactorControl/Data/battery.csv",battery[1].getEnergyStored()..";"..battery[1].getMaxEnergyStored()..";"..(battery[1].getEnergyStored()/battery[1].getMaxEnergyStored()))
        sleep(5)
    end
end

-- Main

Datalogger()