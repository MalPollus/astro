import os
from math import cos, sin, pi
import datetime
from time import strftime
from PIL import Image, ImageDraw, ImageFont

BASE_COLOR = (0,2,23)
PLANET_COLOR = (235,67,30)
ORBIT_COLOR = (153,153,171)

ORBIT_SCALING = 1.4
SUN_RADIUS = 80

SCALING = 2
SCREEN_RES = [1920 * SCALING,1080 * SCALING]
REF_YEAR = 2025
THIS_DAY = (
    datetime.datetime.now().hour * 0.0416 +
    datetime.datetime.now().day +
    datetime.datetime.now().month * 30.417 +
    datetime.datetime.now().year * 365.256
)

#image creation
img = Image.new("RGBA", SCREEN_RES, BASE_COLOR)
draw = ImageDraw.Draw(img)

draw.ellipse(xy=(
    SCREEN_RES[0]/2-SUN_RADIUS,
    SCREEN_RES[1]/2-SUN_RADIUS,
    SCREEN_RES[0]/2+SUN_RADIUS,
    SCREEN_RES[1]/2+SUN_RADIUS
), fill=PLANET_COLOR, width=1)


def calculateCirclePos(pos, radius):
    return (
        pos[0]-radius,
        pos[1]-radius,
        pos[0]+radius,
        pos[1]+radius
    )

class Planet:
    def __init__(self, init_angle, velocity, radius, orbit_size) -> None:
        self.init_angle = init_angle
        self.velocity = velocity
        self.radius = radius
        self.orbit_size = orbit_size

    def calculatePlanetPosition(self):
        angle = self.calculateNewAngle()
        return [
            cos(-angle)*self.orbit_size + SCREEN_RES[0]/2,
            sin(-angle)*self.orbit_size + SCREEN_RES[1]/2]

    def calculateNewAngle(self):
        time_elapsed = THIS_DAY - REF_YEAR * 365.256
        new_angle = self.init_angle + self.velocity * time_elapsed
        return new_angle

    def drawPlanet(self):
        #orbit
        draw.ellipse(
            calculateCirclePos([SCREEN_RES[0]/2, SCREEN_RES[1]/2], self.orbit_size),
            outline=ORBIT_COLOR, width=2
        )
        #planet
        draw.ellipse(
            calculateCirclePos(self.calculatePlanetPosition(), self.radius),
            fill=PLANET_COLOR, width=2
        )

# velocity : 2PI / earth days to make a full rotation around the sun
mercury = Planet(3.2812, pi * 2 / 87.969, 10, 100 * ORBIT_SCALING)
venus = Planet(0.8378, pi * 2 / 224.701, 20, 150 * ORBIT_SCALING)
earth = Planet(1.6755, pi * 2 / 365.256, 25, 200 * ORBIT_SCALING)
mars = Planet(1.7628, pi * 2 / 686.980, 15, 250 * ORBIT_SCALING)
jupiter = Planet(1.2217, pi * 2 / 4332.589, 60, 350 * ORBIT_SCALING)
saturn = Planet(6.0388, pi * 2 / 10759.22, 50, 450 * ORBIT_SCALING)
uranus = Planet(0.8901, pi * 2 / 30688.5, 35, 550 * ORBIT_SCALING)
neptune = Planet(6.161, pi * 2 / 60182, 35, 650 * ORBIT_SCALING)

mercury.drawPlanet()
venus.drawPlanet()
earth.drawPlanet()
mars.drawPlanet()
jupiter.drawPlanet()
saturn.drawPlanet()
uranus.drawPlanet()
neptune.drawPlanet()

# bottom-left text
font = ImageFont.truetype("Chillax-Semibold.otf", 32)
draw.text((SCREEN_RES[0] - 200, SCREEN_RES[1] - 180),"astro",ORBIT_COLOR,font=font)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
img_path = os.path.join(BASE_DIR, "output/img.png") #ricorda di controllare se output/ esiste
img.save(img_path)
