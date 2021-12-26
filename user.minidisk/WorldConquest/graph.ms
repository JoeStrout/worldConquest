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
	gfx.fillRect minx, miny, xspan, yspan, "#222222"
	maxTurn = history.len - 1
	maxCells = 0
	for playerData in history[0].values
		maxCells = maxCells + playerData.len
	end for
	for plNum in history[0].indexes
		g.color = teams[plNum].color
		for turn in history.indexes
			cells = history[turn][plNum].len
			x = minx + xspan * turn / maxTurn
			y = miny + yspan * cells / maxCells
			if turn > 0 then
				g.line lastx, lasty, x, y, g.color, 4
			end if
			lastx = x
			lasty = y
		end for
	end for
	gfx.drawRect minx, miny, xspan, yspan, color.white
end function


if locals == globals then
	clear
	drawGraph gfx
end function