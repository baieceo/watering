JSON = {}

local function ToStringEx(value)
    if type(value)=='table' then
       return JSON.stringify(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
       return tostring(value)
    end
end

function JSON.stringify(t)
    if t == nil then return "" end
    local retstr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
          signal = ""
        end

        if key == i then
            retstr = retstr..signal..ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(value)
                end
            end
        end

        i = i+1
    end

     retstr = retstr.."}"
     return retstr
end

function JSON.parse(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    
    return loadstring("return " .. str)()
end
