
from microdot import Microdot
from src.config import Config
from src.networking import setup_wifi

config = Config()
setup_wifi(config)

app = Microdot()

@app.route('/')
def index(request):
    return 'Hello, world!'

app.run()