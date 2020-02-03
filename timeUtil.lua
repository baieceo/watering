local NTP_IP = '5.103.139.163'

function timeSync(succ, fail)
    rtctime.set(rtctime.get())
            
    sntp.sync(NTP_IP, 
        function ()
            if succ ~= nil then
                succ()
            end
        end,
        function (index)
            if fail ~= nil then
                fail(index)
            end
        end
    )
end
