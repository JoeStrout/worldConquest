import "graph"

events.spriteDisplay.clear
text.clear

if not globals.hasIndex("endMusic") then
	endMusic = file.loadSound("music/postgame.ogg")
	endMusic.loop = true
	endMusic.play 0.5
end if


instantReplay = function
	events.spriteDisplay.clear
	showHistoryReplay
	run
end function

powerGraph = function
	spriteDispIdx = events.spriteDisplay.index
	display(spriteDispIdx).mode = displayMode.off
	display(1).mode = displayMode.pixel
	g = display(1)
	g.clear color.clear
	graph.drawGraph g
	while not mouse.button and not key.available
		yield
	end while
	key.clear
	g.mode = displayMode.off
	while mouse.button; end while
	while key.pressed("return") or key.pressed("enter") or key.pressed("space")
		yield
	end while
	key.clear
	display(spriteDispIdx).mode = displayMode.sprite
end function

returnToTitle = function
	for i in range(60)
		endMusic.adjust 0.5 * i/60
		yield
	end for
	endMusic.stop

	reset; load "title"; run
end function

background = new Sprite
background.image = file.loadImage("pics/gameOverBkgnd.png")
background.x = 480
background.y = 350
events.spriteDisplay.sprites.push background

banner = new Sprite
banner.image = file.loadImage("pics/win_" + winner.name.lower + ".png")
banner.x = 480
banner.y = 496
events.spriteDisplay.sprites.push banner

replayBtn = new events.EventSprite
replayBtn.image = file.loadImage("pics/replayBtn.png")
replayBtn.x = 480
replayBtn.y = 380
replayBtn.onGoodClick = @instantReplay
replayBtn.onKey["i"] = @instantReplay
replayBtn.onKey["r"] = @instantReplay
replayBtn.start

graphBtn = new events.EventSprite
graphBtn.image = file.loadImage("pics/graphBtn.png")
graphBtn.x = 480
graphBtn.y = replayBtn.y - 84
graphBtn.onGoodClick = @powerGraph
replayBtn.onKey["p"] = @powerGraph
replayBtn.onKey["g"] = @powerGraph
graphBtn.start

doneBtn = new events.EventSprite
doneBtn.image = file.loadImage("pics/doneBtn.png")
doneBtn.x = 480
doneBtn.y = graphBtn.y - 84
doneBtn.onGoodClick = @returnToTitle
replayBtn.onKey["d"] = @returnToTitle
replayBtn.onKey["return"] = @returnToTitle
replayBtn.onKey["enter"] = @returnToTitle
replayBtn.onKey["space"] = @returnToTitle
doneBtn.start

events.eventLoop.run
