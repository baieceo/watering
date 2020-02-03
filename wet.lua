adc.force_init_mode(adc.INIT_ADC)
v = adc.read(0)

v = 1024 - v

print('adc = ' .. v)


gpio.mode(0, gpio.INPUT)
local val = gpio.read(0)

print('val = ' .. val)