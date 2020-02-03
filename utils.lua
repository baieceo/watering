function split(str, reps)
    local resultStrList = {}

    if type(str) == 'string' then
        string.gsub(str, '[^' .. reps .. ']+', function (w)
            table.insert(resultStrList,w)
        end)
    end
    
    return resultStrList
end