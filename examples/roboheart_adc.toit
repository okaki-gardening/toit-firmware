import gpio
import gpio.adc show Adc
import encoding.json as json

pinnumber_led ::= 14
pinnumber_soil ::= 34
pinnumber_battery ::= 36

main:
    pin_soil := gpio.Pin pinnumber_soil
    pin_battery := gpio.Pin pinnumber_battery
    pin_led := gpio.Pin pinnumber_led --output

    adc_soil := Adc (pin_soil)
    adc_battery := Adc (pin_battery)

    (Duration --s=1).periodic:
        soil := adc_soil.get
        battery := adc_battery.get

        json_str := "{'soil':'$soil','battery':'$battery'}"
        print json_str
