clear
import "listUtil"

gfx.drawImage file.loadImage("pics/WORLDCONQUEST.png")
if globals.hasIndex("bgm") then
	bgm.adjust 0.5
else
	Sound.stopAll
	bgm = file.loadSound("music/title.ogg")
	bgm.loop = true
	bgm.play 0.5
end if

import "events"

hideInstructions = function
	gfx.drawImage file.loadImage("pics/WORLDCONQUEST.png")

	events.spriteDisplay.sprites.removeVal backBtn	
	instructionsBtn.start
	playBtn.start
end function

showInstructions = function
	gfx.drawImage file.loadImage("pics/instructions.png")
	
	events.spriteDisplay.sprites.removeVal instructionsBtn
	events.spriteDisplay.sprites.removeVal playBtn
		
	outer.backBtn = new events.EventSprite
	backBtn.image = file.loadImage("pics/backBtn.png")
	backBtn.onGoodClick = @hideInstructions
	backBtn.onKey = new events.KeyHandler
	backBtn.onKey["escape"] = @hideInstructions
	backBtn.onKey["b"] = @hideInstructions
	backBtn.x = 180
	backBtn.y = 100
	backBtn.start

end function

startGame = function
	load "setup"
	run
end function

events.EventSprite.isDown = false
events.EventSprite.onGoodClick = null

events.EventSprite.showDown = function()
	if self.isDown then return
	self.fullScale = self.scale
	self.scale = self.fullScale * 0.95
	self.y = self.y - 3
	self.isDown = true
end function

events.EventSprite.showUp = function()
	if not self.isDown then return
	self.scale = self.fullScale
	self.y = self.y + 3
	self.isDown = false	
end function

events.EventSprite.trackHit = function()
	while mouse.button
		if self.contains(mouse) then
			self.showDown
		else
			self.showUp
		end if
	end while
	if self.isDown then
		self.showUp
		self.onGoodClick
	end if
end function

events.EventSprite.onClick = @events.EventSprite.trackHit

instructionsBtn = new events.EventSprite
instructionsBtn.image = file.loadImage("pics/instructionsBtn.png")
instructionsBtn.onGoodClick = @showInstructions
instructionsBtn.onKey = new events.KeyHandler
instructionsBtn.onKey["h"] = @showInstructions
instructionsBtn.onKey["?"] = @showInstructions
instructionsBtn.onKey["slash"] = @showInstructions
instructionsBtn.x = 480-200
instructionsBtn.y = 100
instructionsBtn.start

playBtn = new events.EventSprite
playBtn.image = file.loadImage("pics/playBtn.png")
playBtn.onGoodClick = @startGame
playBtn.onKey = new events.KeyHandler
playBtn.onKey["return"] = @startGame
playBtn.onKey["enter"] = @startGame
playBtn.onKey["space"] = @startGame
playBtn.x = 480+200
playBtn.y = 100
playBtn.start

events.eventLoop.run

		