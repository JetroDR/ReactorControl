function getActive()
    local state = true
    return state
end

function getRotorSpeed()
    local speed = 1767
    return speed
end

function getInductorEngaged()
    local inductor = true
    return inductor
end

function getEnergyProducedLastTick()
    local energy = 5760
    return energy
end

return {
    {
        getActive = getActive,
        getRotorSpeed = getRotorSpeed,
        getInductorEngaged = getInductorEngaged,
        getEnergyProducedLastTick = getEnergyProducedLastTick
    }
}