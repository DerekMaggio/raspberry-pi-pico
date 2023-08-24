
from firmware.microdot import Microdot
from firmware.config import Config
from firmware.networking import setup_wifi

config = Config()
setup_wifi(config)

app = Microdot()

@app.route('/')
def index(request):
    return 'Hello, world!'

@app.route('/led/on')
def led_on(request):
    return 'LED ON'

@app.route('/led/off')
def led_off(request):
    return 'LED OFF'

app.run()