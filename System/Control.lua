Name = "Control.lua"
Version = "0.2.2"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    config = Path.."/System/Files/config.cfg",
    log = Path.."/System/Files/ReactorControl.log",
}

standalone_peripheral = true
if not(standalone_peripheral) then
    local reactor = {}
    local turbine = {}
    local battery = {}
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

function init_apis()
    for APIname, APIpath in pairs(config.files.apis) do
        -- TEMP peripheral fix
        loadAPI = true
        if APIname == "reactor" or APIname == "turbine" or APIname == "battery" then
            loadAPI = standalone_peripheral
        end

        if loadAPI then
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
end

function init_peripherals()
    local PList = peripheral.getNames()
    log("info","Found "..#PList.." Peripheral"..(#PList > 1 and "s"))
    for i = 1, #PList do
        log("debug","name: "..PList[i].."; type: "..peripheral.getType(PList[i]))
        if peripheral.getType(PList[i]) == "monitor" then
            mon = peripheral.wrap(PList[i])
        elseif peripheral.getType(PList[i]) == "modem" then
            rednet.open(PList[i])
        elseif peripheral.getType(PList[i]) == "BigReactors-Reactor" then
            table.insert(reactor,peripheral.wrap(PList[i]))
        elseif peripheral.getType(PList[i]) == "BigReactors-Turbine" then
            table.insert(turbine,peripheral.wrap(PList[i]))
        elseif peripheral.getType(PList[i]) == "capacitor_bank" then
            table.insert(battery,peripheral.wrap(PList[i]))
        end
    end

    if standalone_peripheral then
        -- TEMP PERIPHERAL FIX
        local temp = reactor
        reactor = {}
        table.insert(reactor, temp)

        local temp = turbine
        turbine = {}
        table.insert(turbine, temp)

        local temp = battery
        battery = {}
        table.insert(battery, temp)
    end
end

function control()
    local totalBattery = {
        getEnergyStored = 0,
        getMaxEnergyStored = 0,
        getAverageChangePerTick = 0,
        getAverageInputPerTick = 0,
        getAverageOutputPerTick = 0,
    }

    for i = 1, #battery do
        totalBattery.getEnergyStored = totalBattery.getEnergyStored + battery[i].getEnergyStored()
        totalBattery.getMaxEnergyStored = totalBattery.getMaxEnergyStored + battery[i].getMaxEnergyStored()
        totalBattery.getAverageChangePerTick = totalBattery.getAverageChangePerTick + battery[i].getAverageChangePerTick()
        totalBattery.getAverageInputPerTick = totalBattery.getAverageInputPerTick + battery[i].getAverageInputPerTick()
        totalBattery.getAverageOutputPerTick = totalBattery.getAverageOutputPerTick + battery[i].getAverageOutputPerTick()
    end

    BatPercent = totalBattery.getEnergyStored/totalBattery.getMaxEnergyStored*100
    if BatPercent >= 100 then
        x = 0
    elseif BatPercent >= 10 then
        x = 1
    elseif BatPercent < 10 then
        x = 2
    end
    BatPercent = math.floor(BatPercent*(10^x))/(10^x)

    if totalBattery.getAverageChangePerTick >= 0 then
        ChargeTime = (math.floor(10*math.abs((totalBattery.getMaxEnergyStored-totalBattery.getEnergyStored)/totalBattery.getAverageChangePerTick/20)))/10
    else
        ChargeTime = (math.floor(10*math.abs(totalBattery.getEnergyStored/totalBattery.getAverageChangePerTick/20)))/10
    end

    for i = 1, #reactor do
        if config.button.automode then
            if not(config.button.adaptive_battery) then
                if BatPercent > config.settings.battery_high.value then
                    if reactor[i].getActive() then
                        reactor[i].setActive(false)
                    end
                elseif BatPercent < config.settings.battery_low.value then
                    if not(reactor[i].getActive()) then
                        reactor[i].setActive(true)
                    end
                end
            else
                if ChargeTime/60 < config.settings.battery_high_adaptive.value and totalBattery.getAverageChangePerTick > 0 then
                    if reactor[i].getActive() then
                        reactor[i].setActive(false)
                    end
                elseif ChargeTime/60 < config.settings.battery_low_adaptive.value and totalBattery.getAverageChangePerTick < 0 then
                    if not(reactor[i].getActive()) then
                        reactor[i].setActive(true)
                    end
                end
            end

            if turbine[i].getActive() and turbine[i].getRotorSpeed() > config.settings.inductor_engage_high.value then
                if not(turbine[i].getInductorEngaged()) then
                    turbine[i].setInductorEngaged(true)
                end
            elseif not(turbine[i].getActive()) and turbine[i].getRotorSpeed() > config.settings.inductor_engage_low.value then
                if not(turbine[i].getInductorEngaged()) then
                    turbine[i].setInductorEngaged(true)
                end
            else
                if turbine[i].getInductorEngaged() then
                    turbine[i].setInductorEngaged(false)
                end
            end
        end

        if reactor[i].getCoolantAmount() < 21800*0.25 then
            if not(rs.getOutput(config.settings.reactor_coolant_side.value)) then
                log("warning","reactor "..i..": coolant level low")
                rs.setOutput(config.settings.reactor_coolant_side.value,true)                            
            end
        elseif reactor[i].getCoolantAmount() > 21800*0.5 then
            if rs.getOutput(config.settings.reactor_coolant_side.value) then
                rs.setOutput(config.settings.reactor_coolant_side.value,false)   
            end
        end
    end

    for i = 1, #turbine do
        if config.button.automode then
            if not(config.button.adaptive_battery) then
                if BatPercent > config.settings.battery_high.value then
                    if turbine[i].getActive() then
                        turbine[i].setActive(false)
                    end
                elseif BatPercent < config.settings.battery_low.value then
                    if not(turbine[i].getActive()) then
                        turbine[i].setActive(true)
                    end
                end
            else
                if ChargeTime/60 < config.settings.battery_high_adaptive.value and totalBattery.getAverageChangePerTick > 0 then
                    if turbine[i].getActive() then
                        turbine[i].setActive(false)
                    end
                elseif ChargeTime/60 < config.settings.battery_low_adaptive.value and totalBattery.getAverageChangePerTick < 0 then
                    if not(turbine[i].getActive()) then
                        turbine[i].setActive(true)
                    end
                end
            end
        end
    end

    for i = 1, #battery do
    
    end

    if #config.warnings > 0 or #config.errors > 0 then
        if not(rs.getOutput(config.settings.redstone_warning_side.value)) then
            rs.setOutput(config.settings.redstone_warning_side.value, true)
            log("debug", "redstone on")
        end
    else
        if rs.getOutput(config.settings.redstone_warning_side.value) then
            rs.setOutput(config.settings.redstone_warning_side.value, false)
            log("debug", "redstone off")
        end
    end
end

function main()
    read_config()
    init_apis()
    init_peripherals()
    log("debug", Name)

    while true do
        read_config()
        control()
        sleep(1)
    end
end

main()