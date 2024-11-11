Name = "Display.lua"
Version = "0.2.0"
Author = "Jetro"

local Path = "ReactorControl"
local files = {
    config = Path.."/System/Files/config.cfg",
    log = Path.."/System/Files/ReactorControl.log",
    symbols = {
        radioactive = Path.."/Symbols/Radioactive.nfp",
        start = Path.."/Symbols/Start.nfp",
        stop = Path.."/Symbols/Stop.nfp",
        battery = Path.."/Symbols/Battery.nfp",
    },
}

local config = {
    warnings = {},
    errors = {},
}

local page = {
    term = {
        {name="home", x=1, y=1},
        {name="settings", x=0, y=1},
        {name="warnings", x=0, y=1, count = 0},
        {name="errors", x=0, y=1, count = 0},
        active = "home",
    },
    mon = {
        {name="home", x=1, y=1},
        {name="reactor", x=0, y=1},
        {name="turbine", x=0, y=1},
        {name="battery", x=0, y=1},
        active = "home",
    },
    turbine = 1,
}

--[[ TEMP PERIPHERAL FIX
local reactor = {}
local turbine = {}
local battery = {}
]]

function log(type, text)
    if (type == "debug" and config.debug) or type ~= "debug" then
        myLog = fs.open(files.log, "a")
        myLog.write("["..Name.."] ["..string.upper(type).."] ["..os.date("%d-%m-%Y %X").."] "..text.."\n")
        myLog.close()
        if type == "warning" then
            table.insert(config.warnings, text)
            write_config()
        elseif type == "error" and config.debug then 
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

function init_apis()
    for APIname, APIpath in pairs(config.files.apis) do
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

function init_peripherals()
    local PList = peripheral.getNames()
    log("info","Found "..#PList.." Peripheral"..(#PList > 1 and "s"))
    for i = 1, #PList do
        log("debug","name: "..PList[i].."; type: "..peripheral.getType(PList[i]))
        if peripheral.getType(PList[i]) == "monitor" then
            mon = peripheral.wrap(PList[i])
        elseif peripheral.getType(PList[i]) == "modem" then
            rednet.open(PList[i])
        end
    end
end

function init_data()
    for PageName, PageData in pairs(page) do
        if PageName == "term" or PageName == "mon" then
            for i = 1, #PageData do
                if PageData[i].x == 0 then
                    PageData[i].x = PageData[i-1].x + (string.len(PageData[i-1].name) + 2 + ((PageData[i-1].count and 4) or 2))
                end
            end
        end
    end
end

function draw_menu()
    
    -- draw term
    w, h  = term.getSize()

    screen.clear(colors.blue)
    screen.clearLine(1, colors.lightBlue)
    for i = 1, #page.term do
        screen.drawText(page.term[i].x, page.term[i].y, "  "..string.upper(page.term[i].name)..((page.term[i].count and " ("..page.term[i].count..")") or "  "), ((page.term[i].count and page.term[i].count > 0) and colors.red) or (page.term[i].name == page.term.active and colors.blue) or colors.lightBlue)
    end
    if page.term.active == "home" then
        screen.drawText(1,3,"STATE:", colors.blue)
        --screen.drawText(11,3,config.program_state,colors.blue,(string.lower(config.program_state) == "unknown" and colors.red) or colors.white)
    elseif page.term.active == "settings" then
        screen.drawText(1,5,"SETTINGS", colors.blue)
        screen.drawText(1,6,"click on the command textbox to enter a command")
        screen.drawText(1,7,"type 'return' to go back to exit the textbox", colors.blue)
        screen.drawText(4,h-9,"COMMAND",colors.blue)
        screen.drawRect(4,h-8,w-6,1,colors.gray)
        screen.drawText(4,h-5,"FEEDBACK",colors.blue)
        screen.drawRect(4,h-4,w-6,1,colors.gray)
    elseif page.term.active == "warnings" then

    elseif page.term.active == "errors" then

    end

    -- switch to monitor 1
    old_term = term.current()
    term.redirect(mon)

    -- draw monitor 1
    w, h = term.getSize()
    
    screen.clear(colors.blue)
    screen.clearLine(1, colors.lightBlue)
    for i = 1, #page.mon do
        screen.drawText(page.mon[i].x, page.mon[i].y, "  "..string.upper(page.mon[i].name).."  ", (page.mon[i].name == page.mon.active and colors.blue) or colors.lightBlue)
    end

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
    
    if page.mon.active == "home" then
        --draw_image("start", w-3-23, 4)
        --draw_image("stop", w-3-23, 14)
        screen.drawText(2,3, "AUTOMODE: ", colors.blue)
        draw_button(12,3, config.button.automode)
        screen.drawText(2,5, "\131\131", (reactor.getActive() and colors.lime) or colors.red, colors.blue)
        screen.drawText(5,5, "REACTOR", colors.blue, colors.white)
        screen.drawText(18,5, "\131\131", ((reactor.getHotFluidProducedLastTick() >= #turbine*2000) and colors.lightBlue) or colors.red, colors.blue)
        screen.drawText(21,5, "STEAM", colors.blue, colors.white)
        for i = 1, #turbine do
            screen.drawText(2,6+i, "\131\131", (turbine[i].getActive() and colors.lime) or colors.red, colors.blue)
            screen.drawText(5,6+i, "TURBINE #"..tostring(i), colors.blue,colors.white)
            screen.drawText(18,6+i, "\131\131", ((turbine[i].getRotorSpeed() >= 1700 and turbine[i].getRotorSpeed() <= 1850) and colors.lime) or colors.red, colors.blue)
            screen.drawText(21,6+i, "SPEED", colors.blue, colors.white)
            screen.drawText(30,6+i, "\131\131", (turbine[i].getInductorEngaged() and colors.yellow) or colors.red, colors.blue)
            screen.drawText(33,6+i, "COILS", colors.blue, colors.white)
        end
        x,y = term.getCursorPos()
        screen.drawText(2,y+2, "\131\131", ((BatPercent > 75 and colors.lime) or (BatPercent > 50 and colors.yellow) or (BatPercent > 20 and colors.orange) or colors.red), colors.blue)
        screen.drawText(5,y+2, "BATTERY "..math.floor(BatPercent).."%", colors.blue, colors.white)
        screen.drawText(18,y+2, "\131\131", (totalBattery.getAverageChangePerTick > 0 and colors.lime) or (totalBattery.getAverageChangePerTick < 0 and colors.red) or colors.yellow, colors.blue)
        screen.drawText(21,y+2, (totalBattery.getAverageChangePerTick > 0 and "Charging") or (totalBattery.getAverageChangePerTick < 0 and "Discharging") or "Steady", colors.blue, colors.white)
    elseif page.mon.active == "reactor" then
        screen.drawText(2,3, "\131\131", (reactor.getActive() and colors.lime) or colors.red, colors.blue)
        screen.drawText(5,3, "REACTOR", colors.blue, colors.white)
        screen.drawText(2,5, "\131\131", ((reactor.getHotFluidProducedLastTick() >= #turbine*2000) and colors.lightBlue) or colors.red, colors.blue)
        screen.drawText(5,5, "STEAM"..string.rep(" ", 11).." mb/t", colors.blue, colors.white)
        screen.drawText(15,5, (math.floor(reactor.getHotFluidProducedLastTick()*10)/10), colors.blue, colors.white)
        screen.drawText(2,6, "\131\131", ((reactor.getFuelTemperature() <= 2000) and colors.lime) or colors.red, colors.blue)
        screen.drawText(5,6, "T Fuel"..string.rep(" ", 10).." C", colors.blue, colors.white)
        screen.drawText(15,6, (math.floor(reactor.getFuelTemperature()*10)/10), colors.blue, colors.white)
        screen.drawText(2,7, "\131\131", ((reactor.getCasingTemperature() <= 2000) and colors.lime) or colors.red, colors.blue)
        screen.drawText(5,7, "T Casing"..string.rep(" ", 8).." C", colors.blue, colors.white)
        screen.drawText(15,7, (math.floor(reactor.getCasingTemperature()*10)/10), colors.blue, colors.white)
    elseif page.mon.active == "turbine" then
        screen.drawText(2,3, "\131\131", (turbine[page.turbine].getActive() and colors.lime) or colors.red, colors.blue)
        screen.drawText(5,3, "TURBINE \17"..((page.turbine < 10 and "0"..page.turbine) or page.turbine).."\16", colors.blue, colors.white)
        screen.drawText(2,5, "\131\131", (turbine[page.turbine].getInductorEngaged() and colors.yellow) or colors.red, colors.blue)
        screen.drawText(5,5, "COILS", colors.blue, colors.white)
        screen.drawText(2,6, "\131\131", (turbine[page.turbine].getEnergyProducedLastTick() > 10 and colors.yellow) or colors.red, colors.blue)
        screen.drawText(5,6, "ENERGY"..string.rep(" ", 10).." RF/t", colors.blue, colors.white)
        screen.drawText(15,6, (math.floor(turbine[page.turbine].getEnergyProducedLastTick()*10)/10), colors.blue, colors.white)
        screen.drawText(2,7, "\131\131", ((turbine[page.turbine].getRotorSpeed() >= 1700 and turbine[page.turbine].getRotorSpeed() <= 1850) and colors.lime) or colors.red, colors.blue)
        screen.drawText(5,7, "SPEED"..string.rep(" ", 11).." RPM", colors.blue, colors.white)
        screen.drawText(15,7, (math.floor(turbine[page.turbine].getRotorSpeed()*10)/10), colors.blue, colors.white)
    elseif page.mon.active == "battery" then
        draw_image("battery",2,4)
        screen.drawRect(4,5,math.floor(BatPercent/100*20),4,((BatPercent > 75 and colors.lime) or (BatPercent > 50 and colors.yellow) or (BatPercent > 20 and colors.orange) or colors.red),true,((BatPercent > 75 and colors.lime) or (BatPercent > 50 and colors.yellow) or (BatPercent > 20 and colors.orange) or colors.red))
        screen.drawText(5,11,"CHARGE: "..BatPercent.." %",colors.blue,colors.white)
        screen.drawText(5,12,"STATE: "..((totalBattery.getAverageChangePerTick > 0 and "Charging") or (totalBattery.getAverageChangePerTick < 0 and "Discharging") or (totalBattery.getAverageChangePerTick == 0 and "Stable")),colors.blue,colors.white)
        screen.drawText(32,6,"DELTA: ",colors.blue)
        screen.drawText(39,6,(math.floor(totalBattery.getAverageChangePerTick*100)/100).." RF/t",colors.blue,(totalBattery.getAverageChangePerTick > 0 and colors.lime) or (totalBattery.getAverageChangePerTick < 0 and colors.red) or (totalBattery.getAverageChangePerTick == 0 and colors.white))
        screen.drawText(32,4,"Input: "..(math.floor(totalBattery.getAverageInputPerTick*100)/100).." RF/t",colors.blue,colors.white)
        screen.drawText(32,8,"Output: "..(math.floor(totalBattery.getAverageOutputPerTick*100)/100).." RF/t")
        if totalBattery.getAverageChangePerTick >= 0 then
            ChargeType = "Full: "
            ChargeTime = (math.floor(10*math.abs((totalBattery.getMaxEnergyStored-totalBattery.getEnergyStored)/totalBattery.getAverageChangePerTick/20)))/10
        else
            ChargeType = "Empty: "
            ChargeTime = (math.floor(10*math.abs(totalBattery.getEnergyStored/totalBattery.getAverageChangePerTick/20)))/10
        end
        ChargeHours = math.floor(ChargeTime/3600)
        ChargeMinutes = math.floor((ChargeTime-ChargeHours*3600)/60)
        ChargeSeconds = math.floor((ChargeTime-ChargeHours*3600-ChargeMinutes*60))
        screen.drawText(5,13,"Time until "..ChargeType..ChargeHours.." h "..ChargeMinutes.." m "..ChargeSeconds.." s")
        screen.drawText(5,15,"Adaptive Battery: ",colors.blue)
        draw_button(23,15,config.button.adaptive_battery)
    end

    -- switch back to term
    term.redirect(old_term)
end

function draw_image(request_image,x,y)
    temp_image = paintutils.loadImage(files.symbols[request_image])
    paintutils.drawImage(temp_image,x,y)
end

function draw_button(x,y, boolean)
    if not(boolean) then
        term.setCursorPos(x+1,y)
        term.setBackgroundColor(colors.red)
        term.write("OFF")
        term.setCursorPos(x,y)
        term.setBackgroundColor(colors.gray)
        term.write(" ")
    elseif boolean then
        term.setCursorPos(x,y)
        term.setBackgroundColor(colors.lime)
        term.write("ON ")
        term.setCursorPos(x+3,y)
        term.setBackgroundColor(colors.gray)
        term.write(" ")
    end
end

function touch()
    --event, a, b, c = os.pullEvent()

    parallel.waitForAny(
        function()
            event, a, b, c = os.pullEvent()
        end,
        function()
            sleep(config.error_refresh)
        end
    )

    if event == "monitor_touch" then
        side = a
        x = b
        y = c

        for i = 1, #page.mon do
            if x >= page.mon[i].x and x <= page.mon[i].x + 3 + string.len(page.mon[i].name) and y == page.mon[i].y then
                page.mon.active = page.mon[i].name
            end
        end
        
        if page.mon.active == "home" then
            if x>= 12 and x <= 15 and y == 3 then    
                if config.button.automode then
                    config.button.automode = false
                else
                    config.button.automode = true
                end
                write_config()
            end
        elseif page.mon.active == "reactor" then

        elseif page.mon.active == "turbine" then
            if x == 13 and y == 3 then
                if page.turbine > 1 then
                    page.turbine = page.turbine - 1
                end
            elseif x == 16 and y == 3 then
                if page.turbine < #turbine then
                    page.turbine = page.turbine + 1
                end
            end
        elseif page.mon.active == "battery" then
            if x>= 23 and x <= 26 and y == 15 then 
                if config.button.adaptive_battery then
                    config.button.adaptive_battery = false
                else
                    config.button.adaptive_battery = true
                end
                write_config()
            end
        end
    elseif event == "mouse_click" then
        x = b
        y = c

        for i = 1, #page.term do
            if x >= page.term[i].x and x <= page.term[i].x + ((page.term[i].count and 5) or 3) + string.len(page.term[i].name) and y == page.term[i].y then
                page.term.active = page.term[i].name
            end
        end

        if page.term.active == "home" then
        
        elseif page.term.active == "settings" then
            if x >= 4 and x <= w-3 and y == h-9 then
                term.setCursorPos(4,h-8)
                input = {""}
                while input[1] ~= "return" and not(input[2]) do
                    draw_menu()
                    term.setCursorPos(4,h-9)
                    input = read()
                    input = split.split(input," ")

                    for i = 1, #input do
                        if tonumber(input[i]) then
                            input[i] = tonumber(input[i])
                        elseif string.lower(input[i]) == "true" then
                            input[i] = true
                        elseif string.lower(input[i]) == "false" then
                            input[i] = false
                        else
                            input[i] = string.lower(input[i])
                        end
                    end

                    if input[1] == "return" then
                        feedback = ""
                        break
                    elseif input[1] == "reactor_coolant_side" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.reactor.coolant_side.."%"
                            elseif input[2] and type(input[2]) ~= "number" then
                                for _, side in pairs({"left", "right", "front", "back", "top", "bottom"}) do
                                    if input[2] == side then
                                        input_side = input[2]
                                    end
                                    if input_side then
                                        config.reactor.coolant_side = input[2]
                                        feedback = "Changed "..input[1].." to "..input[2]
                                        write_config()
                                    else
                                        feedback = "Incorrect side"
                                    end
                                end
                            end
                        else
                            feedback = "Usage: reactor_coolant_side <side>"
                        end
                    elseif input[1] == "battery_high" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.settings.battery_high.."%"
                            elseif input[2] then
                                if input[2] and type(input[2]) == "number" then
                                    if input[2] >= 0 and input[2] <= 100 then
                                        if input[2] > config.settings.battery_low then
                                            config.settings.battery_high = input[2]
                                            feedback = "Changed "..input[1].." to "..input[2]
                                            write_config()
                                        else
                                            feedback = "parameter must be higher then battery_low"
                                        end
                                    else
                                        feedback = "parameter must be a number between 0 and 100"
                                    end
                                else
                                    feedback = "parameter must be a number"
                                end
                            end
                        else
                            feedback = "Usage: battery_high <0-100>"
                        end
                    elseif input[1] == "battery_high_adaptive" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.settings.battery_high_adaptive.."%"
                            elseif input[2] then
                                if input[2] and type(input[2]) == "number" then
                                    if input[2] >= 0 and input[2] <= 120 then
                                        config.settings.battery_high_adaptive = input[2]
                                        feedback = "Changed "..input[1].." to "..input[2]
                                        write_config()
                                    else
                                        feedback = "parameter must be a number between 0 and 100"
                                    end
                                else
                                    feedback = "parameter must be a number"
                                end
                            end
                        else
                            feedback = "Usage: battery_high_adaptive <0-100> [in minutes]"
                        end
                    elseif input[1] == "battery_low" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.settings.battery_low.."%"
                            else
                                if input[2] and type(input[2]) == "number" then
                                    if input[2] >= 0 and input[2] <= 100 then
                                        if input[2] < config.settings.battery_high then
                                            config.settings.battery_low = input[2]
                                            feedback = "Changed "..input[1].." to "..input[2]
                                            write_config()
                                        else
                                            feedback = "parameter must be lower then battery_high"
                                        end
                                    else
                                        feedback = "parameter must be a number between 0 and 100"
                                    end
                                else
                                    feedback = "parameter must be a number"
                                end
                            end
                        else
                            feedback = "Usage: battery_low <0-100>"
                        end
                    elseif input[1] == "battery_low_adaptive" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.settings.battery_low_adaptive.."%"
                            else
                                if input[2] and type(input[2]) == "number" then
                                    if input[2] >= 0 and input[2] <= 100 then
                                        config.settings.battery_low_adaptive = input[2]
                                        feedback = "Changed "..input[1].." to "..input[2]
                                        write_config()
                                    else
                                        feedback = "parameter must be a number between 0 and 100"
                                    end
                                else
                                    feedback = "parameter must be a number"
                                end
                            end
                        else
                            feedback = "Usage: battery_low_adaptive <0-100> [in minutes]"
                        end
                    elseif input[1] == "inductor_engage_high" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.settings.inductor_engage_high.."%"
                            elseif input[2] then
                                if input[2] and type(input[2]) == "number" then
                                    if input[2] >= 0 and input[2] <= 1800 then
                                        if input[2] > config.settings.inductor_engage_low then
                                            config.settings.inductor_engage_high = input[2]
                                            feedback = "Changed "..input[1].." to "..input[2]
                                            write_config()
                                        else
                                            feedback = "parameter must be higher then inductor_engage_low"
                                        end
                                    else
                                        feedback = "parameter must be a number between 0 and 1800"
                                    end
                                else
                                    feedback = "parameter must be a number"
                                end
                            end
                        else
                            feedback = "Usage: inductor_engage_high <0-1800>"
                        end
                    elseif input[1] == "inductor_engage_low" then
                        if input[2] then
                            if input[2] == "get" then
                                feedback = "Value at "..config.settings.inductor_engage_low.."%"
                            elseif input[2] then
                                if input[2] and type(input[2]) == "number" then
                                    if input[2] >= 0 and input[2] <= 1800 then
                                        if input[2] < config.settings.inductor_engage_high then
                                            config.settings.inductor_engage_low = input[2]
                                            feedback = "Changed "..input[1].." to "..input[2]
                                            write_config()
                                        else
                                            feedback = "parameter must be higher then inductor_engage_high"
                                        end
                                    else
                                        feedback = "parameter must be a number between 0 and 1800"
                                    end
                                else
                                    feedback = "parameter must be a number"
                                end
                            end
                        else
                            feedback = "Usage: inductor_engage_low <0-1800>"
                        end
                    elseif input[1] == "check_for_updates" then
                        if input[2] ~= nil then
                            if input[2] == "get" then
                                feedback = "Checking for updates "..((config.settings.check_for_updates and "enabled") or "disabled")
                            else
                                if input[2] ~= nil and type(input[2]) == "boolean" then
                                    config.settings.check_for_updates = input[2]
                                    feedback = "Changed "..input[1].." to "..tostring(input[2])
                                    write_config()
                                else
                                    feedback = "parameter must be a boolean"
                                end
                            end
                        else
                            feedback = "Usage: check_for_updates <true-false>"
                        end
                    else
                        feedback = "Unknown command "..input[1]
                    end
                    screen.drawText(4,h-5, feedback)
                    if feedback ~= "" then
                        sleep(2)
                    end
                end
            end
        elseif page.term.active == "warnings" then
        
        elseif page.term.active == "errors" then

        end
    end
end

function main()
    read_config()
    init_apis()
    init_peripherals()
    init_data()
    -- TEMP PERIPHERAL FIX
    local temp = turbine
    turbine = {}
    table.insert(turbine, temp)

    local temp = battery
    battery = {}
    table.insert(battery, temp)
    
    while true do
        read_config()
        page.term[3].count = #config.warnings
        page.term[4].count = #config.errors
        draw_menu()
        touch()
    end
end

main()