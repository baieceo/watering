fs = {}

function fs.readFile(name, opt, callback)
    freeMemory()
    
    local res = nil
    
    fr = file.open(name, opt or 'r')
    if fr then
        res = fr:read()
        fr:flush()
        fr:close()
    end
    
    fr = nil

    if callback ~= nil then
        callback(res)
    end

    res = nil
end

function fs.writeFile(name, data, opt)
    freeMemory()
    
    fw = file.open(name, opt or 'w')

    if fw then
        fw:write(data)
        fw:flush()
        fw:close()
    end

    fw:close()
    fw = nil
end
