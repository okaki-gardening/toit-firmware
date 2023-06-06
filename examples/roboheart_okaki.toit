import gpio
import gpio.adc show Adc
import encoding.json as json

//jag pkg install github.com/toitware/http
import http
import net
import certificate_roots
import esp32
import http.headers

CERTIFICATE ::= certificate_roots.ISRG_ROOT_X1
network := net.open
client := http.Client.tls network --root_certificates=[CERTIFICATE]

URL ::= "appwrite.okaki.org"
PORT ::= 8079
PATH ::= "/measurements"

DEVICE_ID ::= "device2"
KEY ::= "my-secret"

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

  
  (Duration --s=60).periodic:
    soil := adc_soil.get
    battery := adc_battery.get
    json_str := {"deviceID":"$DEVICE_ID","key":"$KEY","measurements":[{"sensorID":"647f3cf0e1c62af05311","sensorTypeID":"soilmoisture","value":"$soil"},{"sensorID":"647f3d06599e879074f8","sensorTypeID":"battery","value":"$battery"}]}

    print "sending POST REQUEST TO $URL:$PORT$PATH"
    print json_str
    response := client.post_json --host=URL --port=PORT --path=PATH json_str
  
    print response.status_code
    print response.status_message
    data := response.body.stringify
    //data := json.decode_stream response.body
    client.close
    print data
  




    
    