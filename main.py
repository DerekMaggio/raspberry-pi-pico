
from firmware.microdot import Microdot
from firmware.config import Config
from firmware.networking import setup_wifi
from firmware.util import get_led

config = Config()
setup_wifi(config)

app = Microdot()

@app.route('/')
def index(request):
    return 'Hello, world!\n'

@app.route('/led/on')
def led_on(request):
    get_led().on()
    return 'LED ON\n'

@app.route('/led/off')
def led_off(request):
    get_led().off()
    return 'LED OFF\n'

app.run()