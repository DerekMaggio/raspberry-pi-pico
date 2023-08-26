from machine import Pin

def get_led() -> Pin:
    return Pin("LED", Pin.OUT)