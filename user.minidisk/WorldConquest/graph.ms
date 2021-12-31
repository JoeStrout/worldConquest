// Module to generate a graph from the history data.
// History data is a list with one element per turn.
// Each element is a map from player number to a list
// of [col, row, armies] triplets describing cells
// owned by that player.

// Draw the graph into graphics context g
drawGraph = function(g)
	minx = 20
	maxx = g.width - 20
	xspan = maxx - minx
	miny = 20
	maxy = g.height - 20
	yspan = maxy - miny
	g.fillRect minx, miny, xspan, yspan, "#FFFFFFDD"
	g.drawRect minx, miny-1, xspan, yspan+2, color.white
	maxTurn = history.len - 1
	maxCells = 0
	for playerData in history[0].values
		maxCells = maxCells + playerData.len
	end for
	lastx = 0
	lasty = {}		// key: player number; value: last y
	for turn in history.indexes
		x = minx + xspan * turn / maxTurn
		for plNum in history[0].indexes
			g.color = teams[plNum].color
			turnCount = history.indexes.len
			cells = history[turn][plNum].len
			y = miny + yspan * cells / maxCells
			if turn > 0 then
				g.line lastx, lasty[plNum], x, y, g.color, 4
			end if
			lasty[plNum] = y
		end for
		g.drawRect minx, miny-1, xspan, yspan+2, color.white
		lastx = x - 1  // (creating a small amount of overlap to reduce gaps)
		wait 3 / turnCount
	end for
end function


if locals == globals then
	clear
	drawGraph gfx
end if