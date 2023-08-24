import network
import time
from .config import Config
from machine import Pin
from time import sleep


def setup_wifi(config: Config, max_wait: int = 10) -> None:
    
    client = network.WLAN(network.STA_IF)  # Connect as client
    client.active(True)  # Set network to active
    client.connect(config.wifi_ssid, config.wifi_pass)

    while max_wait > 0:
        status = client.status
        
        if status == network.STAT_CONNECT_FAIL:
            pass

        if client.status() < 0 or client.status() >= 3:
            break
        max_wait -= 1
        print('waiting for connection...')
        time.sleep(1)
    if client.status() != 3:
        raise RuntimeError('network connection failed')
    else:
        print('connected')
        status = client.ifconfig()
        led = Pin("LED", Pin.OUT)
        for i in range(5):
            led.toggle()
            sleep(0.5)
        
        print( 'ip = ' + status[0] )

def get_ip():
    return network.WLAN(network.STA_IF).ifconfig()[0]