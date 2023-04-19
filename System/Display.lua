--[[

    Name = Diplay.lua
    Version = 0.1.2.8
    Author = Jetro

]]

-- Variables

local name = "ReactorControl"
local filename = name.."/System/Display.lua"

local apipath = "OS/APIs/"
local apis = {
    "screen",
}
local reactor = {}
local turbine = {}
local battery = {}
local mon = {}

local last_program_state

local file = {
    config = "ReactorControl/System/Config.cfg",
    symbols = {
        radioactive = "ReactorControl/Symbols/Radioactive.nfp",
        start = "ReactorControl/Symbols/Start.nfp",
        stop = "ReactorControl/Symbols/Stop.nfp",
        battery = "ReactorControl/Symbols/Battery.nfp",
    },
    log = "ReactorControl/System/log.log"
}

local peripheral_limit = {
    reactor = 1,
    turbine = 4,
    battery = 1,
    monitor = 1,
}

local mW, mH

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

function init_log()
    if fs.exists(file.log) then
        fs.delete(file.log)
    end
    myLog = fs.open(file.log,"w")
    myLog.close()
end

function init_peripheral()
    log("info","looking for peripherals...")
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

    if #reactor ~= 0 then
        log("debug","Found "..#reactor..((#reactor == 1 and " Reactor") or (#reactor > 1 and " Reactors")))
    end
    if #turbine ~= 0 then
        log("debug","Found "..#turbine..((#turbine == 1 and " Turbine") or (#turbine > 1 and " Turbines")))
    end
    if #battery ~= 0 then
        log("debug","Found "..#battery..((#battery == 1 and " Battery") or (#battery > 1 and " Batteries")))
    end
    if #mon ~= 0 then
        log("debug","Found "..#mon..((#mon == 1 and " Monitor") or (#mon > 1 and " Monitors")))
    end

    if #reactor > peripheral_limit.reactor then
        log("error","this version only support up to "..peripheral_limit.reactor.." Reactor")
        error()
    end
    if #turbine > peripheral_limit.turbine then
        log("error","this version only support up to "..peripheral_limit.turbine.." Turbines")
        error()
    end
    if #battery > peripheral_limit.battery then
        log("error","this version only support up to "..peripheral_limit.battery.." Batteries")
        error()
    end
    if #mon > peripheral_limit.monitor then
        log("error","this version only support up to "..peripheral_limit.monitor.." Monitors")
        error()
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

    if #config.reactor.locked == 0 then
        for i = 1, #reactor do
            config.reactor.locked[i] = true
        end
    end
    if #config.turbine.locked == 0 then
        for i = 1, #turbine do
            config.turbine.locked[i] = true
        end
    end
    
    config.peripheral.reactor = #reactor
    config.peripheral.turbine = #turbine
    config.peripheral.battery = #battery
    config.peripheral.mon = #mon
    config_write()
    log("info","completed")
end

function init_apis()
    log("info","loading APIs --")
    for i = 1, #apis do
        if fs.exists(apipath..apis[i]..".api") then
            Succes = os.loadAPI(apipath..apis[i]..".api")
            if Succes then
                _G[apis[i]] = _G[apis[i]..".api"]
                log("debug","API succesfully loaded: "..apis[i]..".api")
            else
                log("error","Unable to load API: "..apis[i]..".api")
                error()
            end
        else
            log("error","API not found: "..apis[i]..".api")
            error()
        end
    end
    log("info","completed")
end

function init_monitor()
    mon[1].setTextScale(0.5)
    mW, mH = mon[1].getSize()
    draw_menu_m()
end

function draw_menu_m()
    screen.clearM(colors.blue,colors.black)
    screen.clearLineM(1,colors.lightBlue)
    screen.drawTextM(1,1,"   HOME    ",(config.page.mon == "home" and colors.blue) or (config.page.mon ~= "home" and colors.lightBlue))
    screen.drawTextM(11,1,"  REACTOR  ",(config.page.mon == "reactor" and colors.blue) or (config.page.mon ~= "reactor" and colors.lightBlue))
    screen.drawTextM(21,1,"  TURBINE  ",(config.page.mon == "turbine" and colors.blue) or (config.page.mon ~= "turbine" and colors.lightBlue))
    screen.drawTextM(31,1,"  BATTERY  ",(config.page.mon == "battery" and colors.blue) or (config.page.mon ~= "battery" and colors.lightBlue))

    BatPercent = battery[1].getEnergyStored()/battery[1].getMaxEnergyStored()*100
    if BatPercent >= 100 then
        x = 0
    elseif BatPercent >= 10 then
        x = 1
    elseif BatPercent < 10 then
        x = 2
    end
    BatPercent = math.floor(BatPercent*(10^x))/(10^x)

    if config.page.mon == "home" then
        draw_image("start",mW-3-23,4)
        draw_image("stop",mW-3-23,14)
        screen.drawTextM(2,3,"AUTOMODE: ",colors.blue)
        draw_button(12,3,config.button.automode)
        screen.drawTextM(2,5,"REACTOR: ",colors.blue,colors.black)
        screen.drawTextM(11,5,((not(reactor[1].getActive()) and "offline") or (reactor[1].getActive() and "online")),colors.blue,((not(reactor[1].getActive()) and colors.red) or (reactor[1].getActive() and colors.lime)))
        for i = 1,#turbine do
            screen.drawTextM(2,6+i,tostring(i),(config.turbine.locked[i] and colors.blue) or colors.red,colors.black)
            screen.drawTextM(5,6+i,": TURBINE:",colors.blue,colors.black)
            screen.drawTextM(16,6+i,((not(turbine[i].getActive()) and "offline") or (turbine[i].getActive() and "online")),colors.blue,((not(turbine[i].getActive()) and colors.red) or (turbine[i].getActive() and colors.lime)))
            screen.drawTextM(26,6+i,"COILS: ",colors.blue,colors.black)
            screen.drawTextM(33,6+i,((not(turbine[i].getInductorEngaged()) and "disengaged") or (turbine[i].getInductorEngaged() and "engaged")),colors.blue,((not(turbine[i].getInductorEngaged()) and colors.red) or (turbine[i].getInductorEngaged() and colors.lime)))
            screen.drawTextM(45,6+i,"SPEED: "..math.floor(turbine[i].getRotorSpeed()),colors.blue,colors.black)
            screen.drawTextM(58,6+i,"RPM")
            screen.drawTextM(65,6+i,"ENERGY: "..math.floor(turbine[i].getEnergyProducedLastTick()),colors.blue,colors.black)
            screen.drawTextM(80,6+i,"RF/t")
            screen.drawTextM(85,6+i,(not(config.turbine.locked[i]) and "LOCKED") or "",colors.red,colors.black)
        end
        screen.drawRectM(mW-11,mH-3-20,10,20,colors.gray,true,colors.gray)
        screen.drawRectM(mW-10,mH-3-19+(18-math.floor(BatPercent/100*18)),8,math.floor(BatPercent/100*18),colors.lime,true,colors.lime)
        screen.drawTextM(mW-11,mH-3,string.rep(" ",10),colors.blue,colors.black)
        screen.drawTextM(mW-9,mH-3,BatPercent.." %",colors.blue,colors.black)
        screen.drawTextM(mW-11,mH-2,string.rep(" ",10),colors.blue,colors.black)
        screen.drawTextM(mW-11,mH-2,((battery[1].getAverageChangePerTick() > 0 and "Charging") or (battery[1].getAverageChangePerTick() < 0 and "Discharging") or (battery[1].getAverageChangePerTick() == 0 and "Stable")),colors.blue,colors.black)
    elseif config.page.mon == "reactor" then
        --draw_image("radioactive",mW-3-22,4)
    elseif config.page == "turbine" then

    elseif config.page.mon == "battery" then
        draw_image("battery",2,4)
        screen.drawRectM(4,5,math.floor(BatPercent/100*20),4,((BatPercent > 75 and colors.lime) or (BatPercent > 50 and colors.yellow) or (BatPercent > 20 and colors.orange) or colors.red),true,((BatPercent > 75 and colors.lime) or (BatPercent > 50 and colors.yellow) or (BatPercent > 20 and colors.orange) or colors.red))
        screen.drawTextM(5,11,"CHARGE: "..BatPercent.." %",colors.blue,colors.black)
        screen.drawTextM(5,12,"STATE: "..((battery[1].getAverageChangePerTick() > 0 and "Charging") or (battery[1].getAverageChangePerTick() < 0 and "Discharging") or (battery[1].getAverageChangePerTick() == 0 and "Stable")),colors.blue,colors.black)
        screen.drawTextM(32,6,"DELTA: ",colors.blue,colors.black)
        screen.drawTextM(39,6,(math.floor(battery[1].getAverageChangePerTick()*100)/100).." RF/t",colors.blue,(battery[1].getAverageChangePerTick() > 0 and colors.lime) or (battery[1].getAverageChangePerTick() < 0 and colors.red) or (battery[1].getAverageChangePerTick() == 0 and colors.black))
        screen.drawTextM(32,4,"Input: "..(math.floor(battery[1].getAverageInputPerTick()*100)/100).." RF/t",colors.blue,colors.black)
        screen.drawTextM(32,8,"Output: "..(math.floor(battery[1].getAverageOutputPerTick()*100)/100).." RF/t")
        if battery[1].getAverageChangePerTick() >= 0 then
            ChargeType = "Full: "
            ChargeTime = (math.floor(10*math.abs((battery[1].getMaxEnergyStored()-battery[1].getEnergyStored())/battery[1].getAverageChangePerTick()/20)))/10
            
        else
            ChargeType = "Empty: "
            ChargeTime = (math.floor(10*math.abs(battery[1].getEnergyStored()/battery[1].getAverageChangePerTick()/20)))/10
        end
        ChargeHours = math.floor(ChargeTime/3600)
        ChargeMinutes = math.floor((ChargeTime-ChargeHours*3600)/60)
        ChargeSeconds = math.floor((ChargeTime-ChargeHours*3600-ChargeMinutes*60))
        screen.drawTextM(5,13,"Time until "..ChargeType..ChargeHours.." h "..ChargeMinutes.." m "..ChargeSeconds.." s")
    end
end

function draw_image(request_image,x,y)
    term_old = term.current()
    term.redirect(mon[1])
    temp_image = paintutils.loadImage(file.symbols[request_image])
    paintutils.drawImage(temp_image,x,y)
    term.redirect(term_old)
end

function draw_button(x,y, boolean)
    if not(boolean) then
        mon[1].setCursorPos(x+1,y)
        mon[1].setBackgroundColor(colors.red)
        mon[1].write("OFF")
        mon[1].setCursorPos(x,y)
        mon[1].setBackgroundColor(colors.gray)
        mon[1].write(" ")
    elseif boolean then
        mon[1].setCursorPos(x,y)
        mon[1].setBackgroundColor(colors.lime)
        mon[1].write("ON ")
        mon[1].setCursorPos(x+3,y)
        mon[1].setBackgroundColor(colors.gray)
        mon[1].write(" ")

    end
end

function control()
    for i = 1, #reactor do
        if not(config.reactor.locked[i]) then
            reactor[i].setActive(false)
        else
            if false then -- Reactor locked rules
            else
                if config.button.automode then
                    if BatPercent > config.setting.battery_high then
                        if reactor[i].getActive() then
                            reactor[i].setActive(false)
                        end
                    elseif BatPercent < config.setting.battery_low then
                        if not(reactor[i].getActive()) then
                            reactor[i].setActive(true)
                        end
                    end
                    if reactor[i].getCoolantAmount() < 21800*0.25 then
                        if not(rs.getOutput(config.reactor.coolant_side)) then
                            log("warning","reactor "..i..": coolant level low")
                            rs.setOutput(config.reactor.coolant_side,true)                            
                        end
                    elseif reactor[i].getCoolantAmount() > 21800*0.5 then
                        if rs.getOutput(config.reactor.coolant_side) then
                            rs.setOutput(config.reactor.coolant_side,false)
                        end
                    end
                else
                    if reactor[i].getCoolantAmount() < 21800*0.25 then
                        if not(rs.getOutput(config.reactor.coolant_side)) then
                            log("warning","reactor "..i..": coolant level low")
                            rs.setOutput(config.reactor.coolant_side,true)                            
                        end
                    elseif reactor[i].getCoolantAmount() > 21800*0.5 then
                        if rs.getOutput(config.reactor.coolant_side) then
                            rs.setOutput(config.reactor.coolant_side,false)
                        end
                    end
                end
            end
        end
    end

    for i = 1, #turbine do
        if not(config.turbine.locked[i]) then
            turbine[i].setActive(false)
            turbine[i].setInductorEngaged(true)
        else
            if turbine[i].getRotorSpeed() > config.setting.overspeed then
               config.turbine.locked[i] = false
               config_write()
               log("error","turbine "..i..": locked - overspeed") 
            else
                if config.button.automode then
                    if BatPercent > config.setting.battery_high then
                        if turbine[i].getActive() then
                            turbine[i].setActive(false)
                        end
                    elseif BatPercent < config.setting.battery_low then
                        if not(turbine[i].getActive()) then
                            turbine[i].setActive(true)
                        end
                    end

                    if turbine[i].getActive() and turbine[i].getRotorSpeed() > config.setting.inductor_engage_high then
                        turbine[i].setInductorEngaged(true)
                    elseif not(turbine[i].getActive()) and turbine[i].getRotorSpeed() > config.setting.inductor_engage_low then
                        turbine[i].setInductorEngaged(true)
                    else
                        turbine[i].setInductorEngaged(false)
                    end
                else
                    if turbine[i].getRotorSpeed() > config.setting.inductor_emergency_high then
                        if not(turbine[i].getInductorEngaged()) then
                            --turbine[i].setInductorEngaged(true)
                            log("warning","turbine "..i..": inductor engaged - exceeded emergency speed")
                        end
                    end
                end
            end
        end
    end
end

function update_program_state()
    if #config.error > 0 then
        config.program_state = "error"
    elseif #config.warning > 0 then
        config.program_state = "warning"
    elseif not(config.button.automode) then
        config.program_state = "manual mode"
    elseif BatPercent > config.setting.battery_high and battery[1].getAverageChangePerTick() > 0 then
        config.program_state = "battery full - spooling down"
    elseif BatPercent < config.setting.battery_high and battery[1].getAverageChangePerTick() > 0 then
        config.program_state = "generating"
    elseif BatPercent < config.setting.battery_low then
        config.program_state = "battery empty - spooling up"  
    elseif BatPercent > config.setting.battery_low and not(reactor[1].getActive()) then
        config.program_state = "battery sufficient - shutdown - standby"
    else
        config.program_state = "unknown"
    end
    if last_program_state ~= config.program_state then
        config_write()
    end
    last_program_state = config.program_state
end

function start()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    init_log()
    config_read()
    init_apis()
    init_peripheral()
    init_monitor()
    sleep(1)
    main()
end

function main()
    while true do
        config_read()
        draw_menu_m()
        control()
        update_program_state()
        sleep(.1)
    end
end

-- Main

start()