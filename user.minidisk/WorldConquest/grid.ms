// Include module which handles the TileDisplay, including utilities
// for loading a map from a file, generating a random map, showing
// ownership via cell tint, etc.

import "qa"

// Prepare our army images
soldierPic = file.loadImage("/sys/pics/gamePieces/pieceWhite_border02.png")
flagPic = file.loadImage("/sys/pics/gamePieces/pieceWhite_border18.png")
drawSoldierAt = function(disp, x, y)
	disp.drawImage soldierPic, x - 8, y - 8, 16, 16
end function
drawSoldiers = function(disp, x, y, count, withFlag=false)
	disp.fillEllipse x-24, y-24, 48, 48, color.clear
	if withFlag then disp.drawImage flagPic, x - 8, y - 8, 16, 16
	if count < 1 then return
	pos = []
	if withFlag then
		if count == 1 then
			pos = [[-10,0]]
		else if count == 2 then
			pos = [[-10,0], [10,0]]
		else if count == 3 then
			pos = [[-10,-8], [10,-8], [0,12]]
		else if count == 4 then
			pos = [[-10,-10], [10,-10], [-10,10], [10,10]]
		else if count == 5 then
			pos = [[-15,-8], [0,-15], [15,-8], [-8,12], [8,12]]
		else if count == 6 then
			pos = [[-8,-12], [8,-12], [-15,0], [15,0], [-8,12], [8,12]]
		end if
	else
		if count == 1 then
			pos = [[0,0]]
		else if count == 2 then
			pos = [[-8,0], [8,0]]
		else if count == 3 then
			pos = [[-10,-8], [10,-8], [0,8]]
		else if count == 4 then
			pos = [[-8,-10], [8,-10], [-8,10], [8,10]]
		else if count == 5 then
			pos = [[-15,-10], [0,-10], [15,-10], [-8,10], [8,10]]
		else if count == 6 then
			pos = [[-15,-10], [0,-10], [15,-10], [-15,10], [0,10], [15,10]]
		end if
	end if
	for p in pos
		drawSoldierAt disp, x + p[0], y + p[1]
	end for
end function

// Prepare the hex td
columns = 15
rows = 12
tiles = file.loadImage("/sys/pics/TileShapes.png")
gfx.clear color.clear
display(6).mode = displayMode.tile
td = display(6)
td.tileSet = tiles
td.tileSetTileSize = 64
td.cellSize = 64
td.oddColOffset = 0
td.oddRowOffset = 0.5  // makes a hex td by rows!
td.overlap = [7,15]
td.extent = [columns, rows]
td.scrollX = -32
td.scrollY = -32
spacing = [td.cellSize - td.overlap[0], td.cellSize - td.overlap[1]]

colRange = range(0, columns-1)
rowRange = range(0, rows-1)

CellInfo = {}
CellInfo.isWater = false
CellInfo.owner = -1
CellInfo.selected = false
CellInfo.soldiers = 0
CellInfo.hasFlag = false
CellInfo.make = function(col, row)
	noob = new CellInfo
	noob.col = col
	noob.row = row
	return noob
end function
CellInfo.desc = function()
	n = "Unclaimed"
	if self.owner >= 0 then n = teams[self.owner].name
	return n + " cell at " + self.col + "," + self.row + " with " + self.soldiers + " soldiers"
end function
CellInfo.show = function()
	if self.isWater then
		tint = bgColor
	else if self.owner >= 0 then
		tint = teams[self.owner].color
	else
		tint = "#444444"
	end if
	if self.selected then tint = color.lerp(tint, color.white)
	td.setCellTint self.col, self.row, tint
end function
CellInfo.setWater = function(isWater=true)
	self.isWater = isWater
	self.show
end function
CellInfo.setOwner = function(owner)
	self.owner = owner
	self.show
end function
CellInfo.setSelected =  function(select=true)
	self.selected = select
	self.show
end function
CellInfo.setSoldiers = function(count)
	if count < 0 then count = 0
	self.soldiers = count
	drawSoldiers gfx, xForCell(self.col, self.row), yForCell(self.col, self.row), count, self.hasFlag
end function
CellInfo.setFlag = function(hasFlag)
	self.hasFlag = hasFlag
	self.setSoldiers self.soldiers // (forces a redraw)
end function

// Set up 2D array of info about each cell, accessed as cellInfo[col][row]
cellInfo = []
for c in colRange
	cellInfo.push []
	for r in rowRange
		cellInfo[c].push CellInfo.make(c, r)
	end for
end for

td.clear
td.setCell colRange, rowRange, 32 // solid white hex

// Make a couple of functions to convert between hex cell
// coordinates, and pixel coordinates.
xForCell = function(col, row)
	x = td.cellSize*0.5 + col * spacing[0] - td.scrollX
	x = x + (row%2) * td.oddRowOffset * spacing[0]
	return x
end function

yForCell = function(col, row)
	y = td.cellSize*0.5 + row * spacing[1] - td.scrollY
	return y
end function

colForXY = function(x, y)
	row = rowForXY(x, y)
	col = (x + td.scrollX - td.cellSize*0.5 - (row%2)*td.oddRowOffset*spacing[0]) / spacing[0]
	return round(col)
end function

rowForXY = function(x, y)
	row = (y + td.scrollY - td.cellSize*0.5) / spacing[1]
	return round(row)
end function

inBounds = function(col, row)
	return col >= 0 and col < columns and row >= 0 and row < rows
end function

cellAt = function(xy)
	c = colForXY(xy.x, xy.y)
	r = rowForXY(xy.x, xy.y)
	if not inBounds(c, r) then return null
	return cellInfo[c][r]
end function

// Get the neighbors of any given hex cell.
// Slightly tricky since it depends on which row you're on.
neighbors = function(col, row, allowWater = false)
	result = [[col-1,row], [col+1,row]]
	if row%2 then
		result = result + [[col,row-1], [col+1,row-1]]
		result = result + [[col,row+1], [col+1,row+1]]
	else
		result = result + [[col-1,row-1], [col,row-1]]
		result = result + [[col-1,row+1], [col,row+1]]
	end if
	// Remove any neighbors which are out of bounds or (optionally) water.
	for i in range(result.len-1, 0)
		c = result[i][0]
		r = result[i][1]
		if not inBounds(c,r) or (not allowWater and cellInfo[c][r].isWater) then
			result.remove i
		end if
	end for
	return result
end function

isNeighboring = function(cell1, cell2)
	return neighbors(cell1.col, cell1.row).indexOf([cell2.col, cell2.row]) != null
end function


// helper function for map generation: adds a new hex of the given color,
// but if it touches some other color, then changes all of that other color
// to this color.
addLandHex = function(col, row, newColor="#888888")
	cellInfo[col][row].setWater false
	td.setCellTint col, row, newColor
	converts = 0
	for n in neighbors(col, row)
		prevColor = td.cellTint(n[0], n[1])
		if prevColor != c then		
			// Recolor all hexes of prevColor to new color.
			for r in rowRange
				for c in colRange
					if td.cellTint(c,r) == prevColor then td.setCellTint c,r, newColor
				end for
			end for
		end if
	end for
end function

randRow = function()
	return round(rnd * rows/2 + rnd * rows/2)
end function
randCol = function()
	return round(rnd * columns/2 + rnd * columns/2)
end function

// Generate a random map.
genMap = function()	
	// land high points:
	landPoints = []
	for i in range(1 + ceil(rnd*3))
		landPoints.push {"row":randRow, "col":randRow, "dist":3 + rnd*3, "lake": rnd*2.5}
		//print landPoints[-1]
	end for
	
	for c in colRange
		for r in rowRange
			cellInfo[c][r].setSoldiers 0
			// check if we're within range of any land high point
			isWater = true
			for lp in landPoints
				dsqr = (r - lp.row)^2 + (c - lp.col)^2
				if dsqr < lp.dist^2 then isWater = false
				if dsqr < lp.lake^2 then isWater = true
			end for
			cellInfo[c][r].setWater isWater
			if not isWater then cellInfo[c][r].setOwner floor(rnd * teams.len) 
		end for
	end for
end function

loadMap = function(mapName, assignPlayers=true)
	lines = file.readLines("maps/" + (mapName - ".txt") + ".txt")
	if not lines then return false
	td.setCell colRange, rowRange, 32 // solid white hex
	td.setCellTint colRange, rowRange, bgColor
	landColor = "#BBFFBB"
	i = 0
	for row in range(rows-1)
		if i >= lines.len then break
		data = lines[i].split(" ")
		for col in range(0, columns-1)
			if col < data.len and data[col] == "@" then
				cellInfo[col][row].setWater false
				td.setCellTint col, row, landColor
				if assignPlayers then cellInfo[col][row].setOwner floor(rnd * teams.len)
			else
				cellInfo[col][row].setWater true
			end if
		end for
		i = i + 1
	end for
	return true
end function
