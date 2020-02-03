local function taskReg(str)
    freeMemory('Task Reg: ' .. str)
    
    str = string.gsub(str, '\n', '')
    
    local param = queryParse(str)

    local TMR_TASK = tmr.create()

    local function scheduleHandler()
        freeMemory('Task Start')
        gpio.mode(param.pin, gpio.OUTPUT)
        gpio.write(param.pin, gpio.LOW)
    
        tmr.alarm(TMR_TASK, tonumber(param.duration), tmr.ALARM_SINGLE, function () 
            freeMemory('Task End')
            
            gpio.write(param.pin, gpio.HIGH)
    
            tmr.stop(TMR_TASK)
    
            TMR_TASK = nil
            param = nil
        end)
    end

    if param.open ~= nil then
        local ok, info = pcall(cron.schedule, param.schedule, scheduleHandler)
    end
end

function taskRegAll()
    freeMemory('Task Reg All Start')
    
    cron.reset()

    ok, queue = pcall(database, 'query', nil, nil, 'table')
    
    if ok then
        for i, v in ipairs(queue) do
            taskReg(v)
        end
    end

    freeMemory('Task Reg All End')
end
