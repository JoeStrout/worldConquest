import "stringUtil"
import "textUtil"
import "mathUtil"

clear
import "grid"

// turn down the background music
if globals.hasIndex("bgm") then bgm.adjust 0.25

grid.td.cellSize = 32
grid.td.overlap = [4,8]
grid.td.scrollX = -420; grid.td.scrollY = -175

text.color = "#FFFC79"
bgColor = "#000044FF"

display(7).mode = displayMode.pixel
display(7).drawImage file.loadImage("pics/selectScreen.png")

Player = {}
newPlayer = function(name, human=true, color=null)
	noob = new Player
	noob.name = name
	noob.human = human
	noob.territories = 0
	noob.soldiers = 0
	noob.eliminated = false
	if color == null then
		noob.color = globals.color[name.lower]
	else
		noob.color = color
	end if
	return noob
end function

teams = []
teams.push newPlayer("Blue", true, "#4444FF")
teams.push newPlayer("Purple", false)
teams.push newPlayer("Red", false)
teams.push newPlayer("Orange", false)
teams.push newPlayer("Green", false)
teams.push newPlayer("Brown", false)

hexFrame = file.loadImage("pics/hexOutline.png")
hexFill = file.loadImage("pics/hexFill.png")
humanIcon = file.loadImage("pics/humanIcon.png")
robotIcon = file.loadImage("pics/robotIcon.png")
noIcon = file.loadImage("pics/noIcon.png")

drawImageCentered = function(g, image, x, y, tint="#FFFFFF")
	w = image.width; h = image.height
	g.drawImage image, round(x-w/2), round(y-h/2), w, h, 0, 0, w, h, tint
end function

composingGfx = new PixelDisplay
makePlayerButtonImage = function(team)
	// compose an image for the player icon
	if team.eliminated then
		icon = noIcon
	else if team.human then
		icon = humanIcon
	else
		icon = robotIcon
	end if
	cx = 32
	cy = 40
	composingGfx.clear color.clear, cx*2, cy*2
	drawImageCentered composingGfx, hexFill, cx, cy, team.color
	drawImageCentered composingGfx, icon, cx, cy
	drawImageCentered composingGfx, hexFrame, cx, cy
	return composingGfx.getImage
end function

changePlayer = function()
	redrawMap = true
	if self.team.eliminated then
		self.team.eliminated = false
		self.team.human = true
	else if self.team.human then
		self.team.human = false
		redrawMap = false
	else
		self.team.eliminated = true
	end if
	self.image = makePlayerButtonImage(self.team)
	if redrawMap then grid.randomizePlayerCells
end function

makeTeamButton = function(teamNum)
	btn = new events.EventSprite
	btn.image = makePlayerButtonImage(teams[i])
	btn.teamNum = i
	btn.team = teams[i]
	btn.onGoodClick = @changePlayer
	btn.x = 467 + 72*i
	btn.y = 572
	btn.start
end function
for i in teams.indexes
	makeTeamButton i
end for

string.padCenter = function(width=20)
	if self.len >= width then return self[:width]
	extra = width - self.len
	leftPad = floor(extra/2)
	rightPad = extra - leftPad
	return " " * leftPad + self + " " * rightPad
end function

mapFiles = file.children("maps")
for i in range(mapFiles.len - 1)
	if not mapFiles[i].endsWith(".txt") then mapFiles.remove i
end for
mapFiles.insert 0, "<Random>"

mapListTop = 18
mapListLeft = 6
mapListWidth = 18
mapListRows = 12

mapListScroll = 0
maxScroll = mapFiles.len - mapListRows

drawMapList = function()
	for i in range(0, mapListRows-1)
		row = mapListTop - i
		idx = mapListScroll + i
		if idx >= mapFiles.len then label = "" else label = mapFiles[idx] - ".txt"
		if idx == selMapIndex then text.inverse = true
		textUtil.printAt mapListLeft, row, label.padCenter(mapListWidth)
		text.inverse = false
	end for	
end function

selectMap = function(idx)
	globals.selMapIndex = idx
	if idx - mapListScroll < 3 then
		globals.mapListScroll = mathUtil.clamp(idx - 3, 0, maxScroll)
	else if idx - mapListScroll > mapListRows - 4 then
		globals.mapListScroll = mathUtil.clamp(idx - mapListRows + 4, 0, maxScroll)
	end if
	drawMapList
	if mapFiles[selMapIndex] == "<Random>" then
		grid.genMap
	else
		grid.loadMap mapFiles[selMapIndex]
	end if
end function
selectMap 0

events.eventLoop.onGotKey = function(keyChar)
	k = keyChar.code
	if k == 19 then  // up
		selectMap (selMapIndex + mapFiles.len - 1) % mapFiles.len
	else if k == 20 then  // down
		selectMap (selMapIndex + 1) % mapFiles.len
	else if k == 27 then
		exit		// for now!
	end if
end function

events.eventLoop.onClick = function()
	col = textUtil.textCol(mouse.x)
	row = textUtil.textRow(mouse.y)
	if col < mapListLeft or col > mapListLeft + mapListWidth then return
	if row > mapListTop or row < mapListTop - mapListRows then return
	hit = mapListTop - row - mapListScroll
	if hit >= mapFiles.len then return
	selectMap hit
end function

returnToTitle = function()
	load "title"
	run
end function

startGame = function()
	for i in range(60)
		bgm.adjust 0.25 * i/60
		yield
	end for
	bgm.stop
	load "game"; run
end function

backBtn = new events.EventSprite
backBtn.image = file.loadImage("pics/backBtn.png")
backBtn.onGoodClick = @returnToTitle
backBtn.onKey = new events.KeyHandler
backBtn.onKey["escape"] = @returnToTitle
backBtn.onKey["b"] = @returnToTitle
backBtn.x = 480-200
backBtn.y = 100
backBtn.start

continueBtn = new events.EventSprite
continueBtn.image = file.loadImage("pics/continueBtn.png")
continueBtn.onGoodClick = @startGame
continueBtn.onKey = new events.KeyHandler
continueBtn.onKey["return"] = @startGame
continueBtn.onKey["enter"] = @startGame
continueBtn.onKey["space"] = @startGame
continueBtn.x = 480+200
continueBtn.y = 100
continueBtn.start

events.eventLoop.run

