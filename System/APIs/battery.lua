function getEnergyStored()
    local energy = 2475213
    return energy
end

function getMaxEnergyStored()
    local energy = 5000000
    return energy
end

function getAverageChangePerTick()
    local change = 487
    return change
end

function getAverageInputPerTick()
    local input = 569
    return input
end

function getAverageOutputPerTick()
    local output = 82
    return output
end

return {
    getEnergyStored = getEnergyStored,
    getAverageChangePerTick = getAverageChangePerTick,
    getAverageInputPerTick = getAverageInputPerTick,
    getAverageOutputPerTick = getAverageOutputPerTick,
}