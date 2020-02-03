gpio.mode(0, gpio.INPUT)
local val = gpio.read(0)

print()

for i = 0, 12, 1 do 
    gpio.mode(i, gpio.OUTPUT)
    
    print('GPIO ' .. i .. ' = ' .. gpio.read(i)) 
end