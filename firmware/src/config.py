
import json


class Config:
        WIFI_SSD_KEY = "WIFI_SSID"
        WIFI_PASSWORD_KEY = "WIFI_PASSWORD"
      
        def __init__(self) -> None:    
            with open("/config.json", "r") as file:
                content = file.read()
            
            configuration = json.loads(content)

            self.wifi_ssid = configuration[self.WIFI_SSD_KEY]
            self.wifi_pass = configuration[self.WIFI_PASSWORD_KEY]
