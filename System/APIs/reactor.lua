function getActive()
    local state = true
    return state
end

function getHotFluidProducedLastTick()
    local HotFluid = 2000.7
    return HotFluid
end

function getFuelTemperature()
    local temp = 1214.4
    return temp
end

function getCasingTemperature()
    local temp = 1467.2
    return temp
end

function getControlRodLevel()
    local rod = 100
    return rod
end

function getCoolantAmount()
    local coolant = 11000
    return coolant
end

return {
    getActive = getActive,
    getHotFluidProducedLastTick = getHotFluidProducedLastTick,
    getFuelTemperature = getFuelTemperature,
    getCasingTemperature = getCasingTemperature,
    getControlRodLevel = getControlRodLevel,
    getCoolantAmount = getCoolantAmount,
}