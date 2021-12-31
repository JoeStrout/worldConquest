// set up
import "listUtil"

setup =  function
	gfx.clear color.clear, 960/3, 640/3
	gfx.scale = 3 // (bigger pixels, easier to see!)
	display(1).mode = displayMode.pixel
	outer.flashGfx = display(1)
	flashGfx.clear color.clear, gfx.width, gfx.height
	flashGfx.scale = gfx.scale
	flashGfx.color = color.white

	outer.haveFlash = false
	outer.burstColors = [color.yellow, color.red, color.blue, 
	  color.aqua, color.pink, color.lime, color.fuchsia]
	outer.mouseWasDown = false
end function

// make a Particle class
Particle = {}
Particle.x = 0
Particle.y = 0
Particle.vx = 0
Particle.vy = 0
Particle.color = color.yellow
Particle.trail = null
Particle.maxTrails = 5
Particle.gravity = -15
Particle.dragFactor = 0.99
Particle.update = function(dt=0.1)
	// apply gravity and drag to velocity
	self.vy = (self.vy + self.gravity*dt) * self.dragFactor
	self.vx = self.vx * self.dragFactor
	
	// apply velocity to position
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt
	
	// draw, appending to the trail
	gfx.setPixel self.x, self.y, self.color
	if self.trail == null then self.trail = []
	self.trail.push [self.x, self.y]
	
	// erase when the trail is too long
	if self.trail.len > self.maxTrails then
		pos = self.trail.pull
		gfx.setPixel pos[0], pos[1], color.clear
	end if
end function

Particle.die = function
	// erase self
	gfx.setPixel self.x, self.y, color.clear
	// erase trail
	for pos in self.trail
		gfx.setPixel pos[0], pos[1], color.clear			
	end for
	// remove from global list
	particles.removeVal self  // (removeVal is from listUtil)
end function

// make a subclass of Particle that represents a rocket,
// before it bursts
Rocket = new Particle
Rocket.timeTillBurst = 2
Rocket.update = function(dt=0.1)
	// do standard particle update...
	super.update dt
	
	// then, update time till burst, and burst when it's time
	self.timeTillBurst = self.timeTillBurst - dt
	if self.timeTillBurst <= 0 then
		// remove the rocket particle and its trail
		self.die
		
		// create the burst particles
		c = burstColors.any  // (.any provided by listUtil)
		for i in range(1,40)
			p = new Ember
			p.startColor = c
			p.x = self.x
			p.y = self.y
			p.vx = 100 * rnd - 50
			p.vy = 100 * rnd - 50
			particles.push p
		end for
		
		// draw the flash
		flashGfx.fillEllipse self.x-10, self.y-10, 20, 20
		outer.haveFlash = true
	end if
end function

// make another Particle subclass that represents the
// embers that float down after the rocket bursts
Ember = new Particle
Ember.age = 0
Ember.gravity = -5
Ember.dragFactor = 0.90
Ember.startColor = color.pink
Ember.endColor = "#88000088"  // translucent red
Ember.update = function(dt=0.1)
	// age, adjust our color, and when it's time, die
	self.age = self.age + dt
	if self.age > 3 then
		self.die
	else
		// update our color
		self.color = color.lerp(self.startColor, 
		self.endColor, self.age/3)
		// and then do standard particle update
		super.update dt	
	end if
	
end function

// keep a list of all Particle instances
particles = []

// function to create and launch a new firework
launchAt = function(x)
	p = new Rocket
	p.x = x / gfx.scale
	p.y = 0
	p.vx = 30 * rnd - 15
	p.vy = 85
	p.timeTillBurst = 3 + 3 * rnd
	particles.push p
end function

nextRandomLaunchTime = 0
update = function
	if haveFlash then
		flashGfx.fillRect 0, 0, flashGfx.width, flashGfx.height, 
		color.clear
		outer.haveFlash = false
	end if
	mouseIsDown = mouse.button
	if mouseIsDown and not mouseWasDown then
		launchAt mouse.x
	end if
	outer.mouseWasDown = mouseIsDown
	for p in particles
		p.update
	end for
	if time > nextRandomLaunchTime then
		launchAt 60 + 840*rnd
		outer.nextRandomLaunchTime = time + 3 * rnd
	end if
end function

if globals == locals then
	setup
	while true
		update
		yield
	end while
end if
