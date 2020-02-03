function queryParse(s)
    local t = split(s, '&')
    local r = {}

    for i, v in ipairs(t) do
        local item = split(v, '=')

        r[item[1]] = item[2]
    end

    return r
end

function queryString(o)
    local r = ''

    for k, v in pairs(o) do  
        r = r .. k .. '=' .. v .. '&' 
    end

    return string.sub(r, 1, #r - 1)
end
