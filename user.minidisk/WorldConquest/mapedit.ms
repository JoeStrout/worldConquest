import "stringUtil"

clear
bgColor = "#000044FF"
display(7).mode = displayMode.solidColor
display(7).color = bgColor

columns = 15
rows = 12
tiles = file.loadImage("/sys/pics/TileShapes.png")
gfx.clear color.clear
display(6).mode = displayMode.tile
grid = display(6)
grid.tileSet = tiles
grid.tileSetTileSize = 64
grid.cellSize = 64
grid.oddColOffset = 0
grid.oddRowOffset = 0.5  // makes a hex grid by rows!
grid.overlap = [7,15]
grid.extent = [columns, rows]
grid.scrollX = -32
grid.scrollY = -32
spacing = [grid.cellSize - grid.overlap[0], grid.cellSize - grid.overlap[1]]

colRange = range(0, columns-1)
rowRange = range(0, rows-1)

landColor = "#BBFFBB"
filename = ""

isWater = function(col, row)
	return grid.cellTint(col, row) == bgColor
end function

isLand = function(col, row)
	return not isWater(col, row)
end function

toggle = function(col, row)
	if isWater(col, row) then
		grid.setCellTint col, row, landColor
	else
		grid.setCellTint col, row, bgColor
	end if
end function

colForXY = function(x, y)
	row = rowForXY(x, y)
	col = (x + grid.scrollX - grid.cellSize*0.5 - (row%2)*grid.oddRowOffset*spacing[0]) / spacing[0]
	return round(col)
end function

rowForXY = function(x, y)
	row = (y + grid.scrollY - grid.cellSize*0.5) / spacing[1]
	return round(row)
end function

inBounds = function(col, row)
	return col >= 0 and col < columns and row >= 0 and row < rows
end function

mapToLines = function()
	lines = []
	for row in range(rows-1)
		data = []
		for col in range(0, columns-1)
			if isLand(col,row) then data.push "@" else data.push "."
		end for
		lines.push data.join(" ")
	end for
	return lines
end function

linesToMap = function(lines)
	grid.clear
	grid.setCell colRange, rowRange, 32 // solid white hex
	grid.setCellTint colRange, rowRange, bgColor
	i = 0
	for row in range(rows-1)
		if i >= lines.len then break
		data = lines[i].split(" ")
		for col in range(0, columns-1)
			if col < data.len and data[col] == "@" then
				grid.setCellTint col, row, landColor
			end if
		end for
		i = i + 1
	end for
end function

save = function(filename)
	path = "maps/" + filename + ".txt"
	file.writeLines path, mapToLines
	print "Map saved as: " + path
	wait
end function

// Setup
grid.clear

newMap = function()
	grid.setCell colRange, rowRange, 32 // solid white hex
	grid.setCellTint colRange, rowRange, bgColor
	for r in rowRange
		for c in colRange
			d = sqrt((r - rows/2)^2 + (c - columns/2)^2)
			if d < 6 then toggle c, r
		end for
	end for
end function

loadMap = function(filename)
	path = "maps/" + filename + ".txt"
	lines = file.readLines(path)
	if not lines then
		print "File not found: " + path
	else
		linesToMap lines
		print "Map loaded: " + path
	end if
	wait
end function

editMap = function()
	text.clear
	text.row = 0; text.delimiter = ""
	print "Click and drag to edit map.  Press Return when done."
	text.delimiter = char(13)

	// Main editing loop
	mouseWasDown = false
	makingLand = true
	while true
		yield
		col = colForXY(mouse.x, mouse.y)
		row = rowForXY(mouse.x, mouse.y)
		if not inBounds(col, row) then continue
		if mouse.button then
			if not mouseWasDown then
				makingLand = isWater(col, row)
				mouseWasDown = true
			end if
			if makingLand and isWater(col, row) then
				toggle col, row
			else if not makingLand and isLand(col, row) then
				toggle col, row
			end if
		else
			mouseWasDown = false
		end if
		if key.available and key.get == char(10) then
			mapMenu
			return
		end if
	end while
end function

mainMenu = function()
	while true
		text.clear; text.row = 7; print
		print "  [N]ew Map"
		print "  [L]oad Map"
		print
		print "==>"
		choice = key.get.lower
		if choice == char(27) or choice == "q" then exit
		if choice == "n" then
			newMap
			break
		else if choice == "l" then
			prompt = "Map name"
			if filename then prompt = prompt + " [" + filename + "]"
			inp = input(prompt + ": ").trim
			if inp then globals.filename = inp - ".txt"			
			loadMap filename
			break
		end if
	end while
	while true
		editMap
	end while
end function

mapMenu = function()
	while true
		text.clear; text.row = 6; print
		print "  [S]ave Map"
		print "  [Q]uit"
		print
		print "==>"
		choice = key.get.lower
		if choice == char(27) then return
		if choice == "q" then exit
		if choice == "s" then
			prompt = "Save as"
			if filename then prompt = prompt + " [" + filename + "]"
			inp = input(prompt + ": ").trim
			if inp then globals.filename = inp - ".txt"
			if filename then save filename
			return
		end if
	end while
end function
		
mainMenu
