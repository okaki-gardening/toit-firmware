import gpio
import gpio.adc show Adc
import encoding.json as json


import net
//jag pkg install github.com/toitware/mqtt
import mqtt

OKAKI_DEVICE_ID ::= "device2"
CLIENT_ID ::= "okaki32-$(OKAKI_DEVICE_ID)"
HOST      ::= "192.168.100.110"

TOPIC_SOIL ::= "okaki/$(OKAKI_DEVICE_ID)/soil"
TOPIC_BATTERY ::= "okaki/$(OKAKI_DEVICE_ID)/battery"
TOPIC_LED ::= "okaki/$(OKAKI_DEVICE_ID)/led"
TOPIC_VALVE ::= "okaki/$(OKAKI_DEVICE_ID)/valve"

pinnumber_led ::= 14
pinnumber_soil ::= 34
pinnumber_battery ::= 36

GPIO_MA_PH_IN1 ::= 25  //  PHASE/IN1  //DAC1
GPIO_MA_EN_IN2 ::= 26  //  ENABLE/IN2  //DAC2
GPIO_MA_MODE ::= 2  //  MODE        
GPIO_MA_SLEEP ::= 0  //  nSLEEP

pin_ma_ph_in1 := gpio.Pin GPIO_MA_PH_IN1 --output
pin_ma_en_in2 := gpio.Pin GPIO_MA_EN_IN2 --output
pin_ma_mode := gpio.Pin GPIO_MA_MODE --output
pin_ma_sleep := gpio.Pin GPIO_MA_SLEEP --output

valve_init:  
  pin_ma_ph_in1.set 0
  pin_ma_en_in2.set 0
  pin_ma_mode.set 0
  pin_ma_sleep.set 1

valve_sleep:
  //coast mode
  pin_ma_ph_in1.set 0
  pin_ma_en_in2.set 0
  pin_ma_sleep.set 0

valve_close:
  pin_ma_sleep.set 1
  pin_ma_ph_in1.set 1
  pin_ma_en_in2.set 0
  sleep --ms=100
  valve_sleep

valve_open:
  pin_ma_sleep.set 1
  pin_ma_ph_in1.set 0
  pin_ma_en_in2.set 1  
  sleep --ms=100
  valve_sleep

main:
  pin_soil := gpio.Pin pinnumber_soil
  pin_battery := gpio.Pin pinnumber_battery
  pin_led := gpio.Pin pinnumber_led --output

  adc_soil := Adc (pin_soil)
  adc_battery := Adc (pin_battery)

  valve_init

  network := net.open
  transport := mqtt.TcpTransport network --host=HOST
  client := mqtt.Client --transport=transport
  client.start --client_id=CLIENT_ID

  // MQTT broker is now connected.

  client.subscribe TOPIC_LED:: | topic payload |
    print "Received: $topic: $payload.to_string_non_throwing"
    if payload.to_string_non_throwing == "1": 
      print "LED ON"
      pin_led.set 1
    else:
      print "LED OFF"
      pin_led.set 0 

  client.subscribe TOPIC_VALVE:: | topic payload |
    print "Received: $topic: $payload.to_string_non_throwing"
    if payload.to_string_non_throwing == "1": 
      print "VALVE ON"
      valve_open
    else:
      print "VALVE OFF"
      valve_close
  

  (Duration --s=10).periodic:
    soil := adc_soil.get
    battery := adc_battery.get

    json_str := "{'soil':'$soil','battery':'$battery'}"
    print json_str

    client.publish TOPIC_SOIL "$soil".to_byte_array
    client.publish TOPIC_BATTERY "$battery".to_byte_array




    
    