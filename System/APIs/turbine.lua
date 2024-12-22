function getActive()
    local state = true
    return state
end

function getRotorSpeed()
    local speed = 1817.8
    return speed
end

function getInductorEngaged()
    local inductor = true
    return inductor
end

function getEnergyProducedLastTick()
    local energy = 5760.2
    return energy
end

function getFluidFlowRate()
    local fluid = 2000
    return fluid
end

return {
    {
        getActive = getActive,
        getRotorSpeed = getRotorSpeed,
        getInductorEngaged = getInductorEngaged,
        getEnergyProducedLastTick = getEnergyProducedLastTick,
        getFluidFlowRate = getFluidFlowRate,
    }
}