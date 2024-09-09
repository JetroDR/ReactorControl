function split(pString, pPattern)
    local split_data = {}
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(split_data,cap)
        end
        last_end = e+1
        s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= #pString then
        cap = pString:sub(last_end)
        table.insert(split_data, cap)
    end
    return split_data
end

function getActive()
    local state = true
    return state
end

return {
    split = split,
    getActive = getActive,
}
