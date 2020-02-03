function database(command, ...)
    freeMemory('Database: ' .. command)
    
    local fr, fw, id, ok, info, chunk, offset, buffer, payload, filename, resType, DATABASE_NAME, DATABASE_TEMP = nil
    local index = 0
    local DEFAULT_NAME = 'database'

    if command == 'add' then
        payload, filename = ...
    elseif command == 'remove' then
        id, offset, filename = ...
    elseif command == 'update' then
        id, payload, filename = ...
    elseif command == 'query' then
        id, offset, resType, filename = ...

        if resType == 'table' then
            buffer = {}
        else
            buffer = ''
        end
    end

    DEFAULT_NAME = filename or DEFAULT_NAME
    DATABASE_NAME = DEFAULT_NAME .. '.db'
    DATABASE_TEMP = DEFAULT_NAME .. '.temp'

    freeMemory()

    if command == 'count' then
        if file.open(DATABASE_NAME, 'r') then
            repeat
                chunk = file.readline()
    
                if chunk ~= nil then
                    index = index + 1
                end
            until chunk == nil
    
            buffer = index
    
            file.flush()
            file.close()
        else
            buffer = index
        end
    elseif command == 'add' then
        file.open(DATABASE_NAME, 'a+')
        file.writeline(payload)
        file.flush()
        file.close()
    elseif command == 'remove' or command == 'update' then
        fr = file.open(DATABASE_NAME, 'r')
        fw = file.open(DATABASE_TEMP, 'w')

        repeat
            index = index + 1
            chunk = fr:readline()

            if chunk ~= nil then
                if command == 'remove' then
                    offset = offset or 1
                    
                    if index < id or index >= id + offset then
                        chunk = string.gsub(chunk, '\n', '')
                        
                        fw:writeline(chunk)
                    end
                elseif command == 'update' then
                    if index == id then
                        chunk = payload
                    else
                        chunk = string.gsub(chunk, '\n', '')
                    end
                    
                    fw:writeline(chunk)
                end
            end
        until chunk == nil
        
        fr:flush()
        fr:close()
        fr = nil
        
        fw:flush()
        fw:close()
        fw = nil
        
        fr = file.open(DATABASE_TEMP, 'r')
        fw = file.open(DATABASE_NAME, 'w+')

        chunk = fr:read()

        if chunk ~= nil then
            fw:write(chunk)
        end
        
        fr:flush()
        fr:close()
        fr = nil

        fw:flush()
        fw:close()
        fw = nil

        file.remove(DATABASE_TEMP)
    elseif command == 'query' then
        local ok, info = pcall(file.open, DATABASE_NAME, 'r')

        if ok then
            if id == nil and offset == nil then
                repeat
                    chunk = file.readline()
    
                    if chunk ~= nil then
                        if resType == 'table' then
                            table.insert(buffer, chunk)
                        else
                            buffer = buffer .. chunk
                        end
                    end
                until index == id or chunk == nil
            else
                if offset == nil then
                    offset = 1
                end
    
                repeat
                    index = index + 1
                    chunk = file.readline()
    
                    if chunk ~= nil then
                        if index >= id and index < id + offset then
                            if resType == 'table' then
                                table.insert(buffer, chunk)
                            else
                                buffer = buffer .. chunk
                            end
                        end
                    end
                until index >= id + offset or chunk == nil
            end
        end
        
        
    end

    if fr ~= nil then
        fr:flush()
        fr:close()
    end

    if fw ~= nil then
        fw:flush()
        fw:close()
    end
    
    id, fr, fw, ok, info, resType, index, chunk, offset, payload, filename, DEFAULT_NAME, DATABASE_NAME, DATABASE_TEMP = nil

    return buffer
end
