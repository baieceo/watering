function freeMemory(msg)
    collectgarbage()

    print('Memory: ' .. node.heap() / 1000 .. 'kb -> ' .. (msg or ''))
end

require('httpServer')
require('utils')
require('querystring')
require('database')
require('timeUtil')
require('taskUtil')

freeMemory('Require All End')

taskQueue = {}

local TMR_WIFI, TMR_WIFI_INIT, TMR_WIFI_CONFIG, WIFI_INIT_CONNECT_MAX, WIFI_INIT_CONNECT_COUNT = 1, 2, 3, 30, 0


gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.LOW)
wifi.setmode(wifi.STATIONAP)

wifi.ap.config({
    ssid = 'Dream Water',
    pwd = '88888888'
})

wifi.ap.setip({
    ip = '192.168.100.100',
    netmask = '255.255.255.0',
    gateway = '192.168.100.100'
})

wifi.sta.autoconnect(1)

tmr.alarm(TMR_WIFI_INIT, 1000, tmr.ALARM_AUTO, function()
    WIFI_INIT_CONNECT_COUNT = WIFI_INIT_CONNECT_COUNT + 1

    if WIFI_INIT_CONNECT_COUNT >= WIFI_INIT_CONNECT_MAX then
        print('Connect WiFi Timeout')
        
        tmr.stop(TMR_WIFI_INIT)
    elseif wifi.sta.getip() == nil then
        print('Waiting IP...')
    else
        freeMemory('IP: ' .. wifi.sta.getip())

        timeSync(taskRegAll)
        
        tmr.stop(TMR_WIFI_INIT)
    end
end)

httpServer:use('/', function(req, res)
    freeMemory('/')
    
    print(wifi.sta.getip())
    
    if wifi.sta.getip() ~= nil then
        res:sendFile('task.html')
    else
        res:sendFile('wifi.html')
    end
end)

httpServer:use('/test*', function(req, res)
    freeMemory('/test')
    
    res:sendFile('test.html')
end)

httpServer:use('/wifi', function (req, res)
    freeMemory('/wifi')
  
    res:sendFile('wifi.html')
end)

httpServer:use('/task', function (req, res)
    freeMemory('/task')
    
    res:sendFile('task.html')
end)

httpServer:use('/task/start', function (req, res)
    freeMemory('/task/start')

    local pin = 0

    if req.query.pin ~= nil then
        pin = tonumber(req.query.pin)
    end

    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, gpio.LOW)

    pin = nil
    
    res:type('application/json')
    
    res:send(sjson.encode({ success = true }))
end)

httpServer:use('/task/stop', function (req, res)
    freeMemory('/task/stop')

    local pin = 0

    if req.query.pin ~= nil then
        pin = tonumber(req.query.pin)
    end

    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, gpio.HIGH)

    pin = nil

    res:type('application/json')
    
    res:send(sjson.encode({ success = true }))
end)

httpServer:use('/wifi/result', function (req, res)
    freeMemory('/wifi/result')
    
    if req.query.ssid ~= nil and req.query.pwd ~= nil then
        wifiConfig = {
            ssid = req.query.ssid,
            pwd = req.query.pwd
        }

        wifi.sta.config(wifiConfig)
        wifi.sta.connect()

        WIFI_INIT_CONNECT_COUNT = 0

        tmr.alarm(TMR_WIFI_CONFIG, 1000, tmr.ALARM_AUTO, function ()
            WIFI_INIT_CONNECT_COUNT = WIFI_INIT_CONNECT_COUNT + 1

            if WIFI_INIT_CONNECT_COUNT >= WIFI_INIT_CONNECT_MAX then
                res:redirect('/wifi?error=timeout')
  
                tmr.stop(TMR_WIFI_CONFIG)
            elseif wifi.sta.getip() == nil then
                print('Waiting IP...')
            else
                tmr.stop(TMR_WIFI_CONFIG)

                res:redirect('/wifi/result?ssid=' .. req.query.ssid .. '&ip=' .. wifi.sta.getip())
            end
        end)
    elseif req.query.ssid ~= nil and req.query.ip ~= nil then
        res:sendFile('wifi_result.html')
    else
        res:redirect('/wifi?error=timeout')
    end
end)

httpServer:use('/task/add', function (req, res)
    freeMemory('/task/add')

    local result = {}
    local params = queryString(req.query)
    local limit = 5

    if database('count') <= limit then
        local ok, buffer = pcall(database, 'add', params)
    
        if ok then
            result.success = true
        else
            result.success = false
        end
    else
        result.success = false
    end

    taskRegAll()

    res:type('application/json')
    res:send(sjson.encode(result))

    ok, buffer, result, params, limit = nil
end)

httpServer:use('/task/remove', function (req, res)
    freeMemory('/task/remove')

    local result = {}
    local id = tonumber(req.query.id)

    if id > database('count') - 1 or id < 0 then
        result.success = false
    else
        local ok, buffer = pcall(database, 'remove', tonumber(req.query.id) + 1)
    
        if ok then
            result.success = true
        else
            result.success = false
        end
    end

    taskRegAll()

    res:type('application/json')
    res:send(sjson.encode(result))

    id, ok, buffer, result = nil
end)

httpServer:use('/task/update', function (req, res)
    freeMemory('/task/update')

    local result = {}

    local id = tonumber(req.query.id)

    if id > database('count') - 1 or id < 0 then
        result.success = false
    else
        local ok, buffer = pcall(database, 'update', tonumber(req.query.id) + 1, queryString(req.query))
    
        if ok then
            result.success = true
        else
            result.success = false
        end
    end

    taskRegAll()

    res:type('application/json')
    res:send(sjson.encode(result))

    id, ok, buffer, result = nil
end)

httpServer:use('/task/query', function (req, res)
    freeMemory('/task/query')

    local result = nil
    local limit = req.query.limit or 5

    local ok, buffer = pcall(database, 'query', 1, limit)

    if ok then
        result = buffer
    else
        result = ''
    end
    
    res:send(result)

    ok, limit, buffer, result = nil
end)

httpServer:use('/restart', function (req, res)
    freeMemory('/restart')
    
    res:type('application/json')
    
    res:send(sjson.encode({ success = true }))

    local TMR_RESTART = tmr.create()

    tmr.alarm(TMR_RESTART, 1000, tmr.ALARM_SINGLE, function () 
        node.restart()
        
        tmr.stop(TMR_RESTART)

        TMR_RESTART = nil
    end)
end)

httpServer:use('/rtctime', function (req, res)
    freeMemory('/rtctime')
    
    res:send(rtctime.get())
end)

httpServer:listen(80) 
