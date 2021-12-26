import "listUtil"
import "ai"

text.inverse = false
clear
display(7).mode = displayMode.solidColor
display(7).color = bgColor

grid.prepareDisplay

rows = grid.rows; columns = grid.columns
rowRange = grid.rowRange; colRange = grid.colRange
cellInfo = grid.cellInfo

hurry = false

// Keep a history of the state of the game on each turn
history = []

// Prepare sound effects
conquerSnd = new Sound
conquerSnd.init 0.5, 50, [1,0], Sound.noiseWave
failSnd = new Sound
failSnd.init 0.1, 400, [0,1,0], Sound.noiseWave
reinforceSnd = new Sound
reinforceSnd.init 0.05, 10, [1,1,1,0], Sound.noiseWave


countTeamStats = function(playerNum)
	team = teams[playerNum]
	team.territories = 0
	team.soldiers = 0
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.owner != playerNum or ci.isWater then continue
			team.territories = team.territories + 1
			team.soldiers = team.soldiers + ci.soldiers + 1  // (including implicit defender)
		end for
	end for
	team.eliminated = (team.territories == 0)
end function

isGameOver = function()
	count = 0
	for team in teams
		if not team.eliminated then count = count + 1
	end for
	return count < 2
end function

// Add a history entry recording the state of the game
recordHistory = function()
	entry = {}  // key: player number; value: list of cells owned
	// for each cell, it's [column, row, soldiers]
	for t in teams.indexes; entry[t] = []; end for
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.isWater or ci.owner < 0 then continue	
			entry[ci.owner].push [c,r, ci.soldiers]
		end for		
	end for
	history.push entry
end function

// Restore some point in history, for playback purposes.
showHistoryEntry = function(entry)
	// entry is as defined above
	for pl in teams.indexes
		for info in entry[pl]
			ci = cellInfo[info[0]][info[1]]
			ci.setOwner pl
			ci.setSoldiers info[2]
		end for
	end for
end function

// Replay all of history!
showHistoryReplay = function()
	for entry in history
		showHistoryEntry entry
		wait 0.25
	end for
end function

// findGroups: find all sets of connected cells of the given player.
// Return them as a list of sets (maps) of CellInfo objects.
findGroups = function(playerNum)
	result = []
	for c in colRange
		for r in rowRange
			// find a cell that belongs to this player
			ci = cellInfo[c][r]
			if ci.owner != playerNum or ci.isWater then continue
			// make sure it's not part of an existing group
			alreadyFound = false
			for set in result
				if set.hasIndex(ci) then
					alreadyFound = true
					break
				end if
			end for
			if alreadyFound then continue
			// start a group, then add all connected cells
			grp = {}
			grp.push ci
			toDo = grid.neighbors(ci.col, ci.row)
			while toDo
				p = toDo.pop
				n = cellInfo[p[0]][p[1]]
				if n.owner != playerNum or grp.hasIndex(n) then continue
				grp.push n
				toDo = toDo + grid.neighbors(n.col, n.row)
			end while
			result.push grp
		end for
	end for
	return result
end function

largestSet = function(sets)
	best = sets[0]
	if sets.len > 1 then
		for i in range(1, sets.len-1)
			if sets[i].len > best.len then best = sets[i]
		end for
	end if
	return best
end function

reinforcibleCells = function(cells, bordersOnly=true)
	result = []
	for cell in cells
		if cell.soldiers > 5 then continue	// already full
		if bordersOnly then
			ok = false
			for pos in grid.neighbors(cell.col, cell.row)
				if cellInfo[pos[0]][pos[1]].owner != cell.owner then
					ok = true
					break
				end if
			end for
			if not ok then continue	// not a border
		end if
		result.push cell
	end for
	result.shuffle
	return result
end function

findFlag = function(playerNum)
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.hasFlag and ci.owner == playerNum then return ci
		end for
	end for
end function

plantFlag = function(hexes)
	oldFlagCell = findFlag(curPlayer)
	if not hexes.hasIndex(oldFlagCell) then
		if oldFlagCell != null then oldFlagCell.setFlag false
		hexes.indexes.any.setFlag true
	end if
end function

// Assign random starting positions.
genStart = function()
	for teamNum in teams.indexes
		// gather all the hexes that belong to this team
		hexes = []
		for ciList in cellInfo
			for ci in ciList
				if not ci.isWater and ci.owner == teamNum then hexes.push ci
			end for
		end for
		// Now, distribute soldiers among those hexes
		soldiersLeft = 25 + 5 * teams[teamNum].human
		while soldiersLeft > 0 and hexes
			hex = hexes[rnd * hexes.len]
			if hex.soldiers >= 6 then continue
			hex.setSoldiers hex.soldiers + 1
			soldiersLeft = soldiersLeft - 1
		end while
	end for
end function

drawStatus = function(s)
	s = s + " " * (60 - s.len)
	text.delimiter = ""
	text.row = 0; text.column = 0
	print s
	text.delimiter = char(13)
end function

drawPrompt = function()
	text.color = teams[curPlayer].color
	prompt = teams[curPlayer].name + "'s turn.  "
	if state == kStateSelectingAttacker then
		prompt = prompt + "Select attacking territory."
	else if state == kStateSelectingTarget then
		prompt = prompt + "Select target."
	else if state == kStateDoingBattle then
		prompt = teams[curPlayer].name + " attacks " + teams[defendingCell.owner].name + "!"
	else
		prompt = ""
	end if
	drawStatus prompt
end function

drawDoneButton = function(drawIt=true)
	s = char(57856) + "DONE" + char(57857)
	foreColor = text.backColor
	backColor = text.color
	if not drawIt then
		s = " " * s.len
		foreColor = text.color
		backColor = text.backColor
	end if
	for i in s.indexes
		x = 68 - s.len + i
		text.setCell x, 0, s[i]
		text.setCellColor x, 0, foreColor
		text.setCellBackColor x, 0, backColor
	end for
end function

doneButtonClicked = function()
	if mouse.x > 875 and mouse.y < 30 then	// "DONE" button
		// ToDo: we really should do proper button highlighting & tracking here.
		// But for now we'll just react to the mouse-down.
		return true
	end if
	return false
end function

roll = function(dice, sides=6)
	sum = 0
	for i in range(1, dice)
		sum = sum + floor(rnd * sides) + 1
	end for
	return sum
end function

doBattle = function()
	drawDoneButton false
	text.row = 0; text.column = 0; text.delimiter = ""
	print " " * 66
	
	attack = roll(attackingCell.soldiers + 1)
	defense = roll(defendingCell.soldiers + 1)
	
	s = "Attack: " + (attackingCell.soldiers + 1) + "d6 = " + attack + "   "
	if attack > defense then s = s + ">" else s = s + "<="
	s = s + "   Defense: " + (defendingCell.soldiers + 1) + "d6 = " + defense
	text.column = 34 - s.len/2; print s
	text.delimiter = char(13)
	
	if attack > defense then
		// attacker won
		conquerSnd.freq = 40 + 20 * rnd
		conquerSnd.play
		defender = defendingCell.owner
		defendingCell.setOwner curPlayer
		lost = round((attackingCell.soldiers + 1) * defense/attack)
		survivors = attackingCell.soldiers + 1 - lost
		if survivors < 2 then survivors = 2
		if defendingCell.hasFlag then defendingCell.setFlag false
		defendingCell.setSoldiers survivors - 2
		attackingCell.setSoldiers 0
		countTeamStats defender
		if teams[defender].eliminated then
			drawStatus teams[defender].name + " is eliminated!"
			wait 1
		end if
	else
		// defender won
		failSnd.play
		lost = round((defendingCell.soldiers + 1) * attack/defense)
		survivors = defendingCell.soldiers + 1 - lost
		attackingCell.setSoldiers 0
		defendingCell.setSoldiers survivors - 1
	end if
	enterState kStateDidBattle
end function

doReinforcements = function()
	drawDoneButton false
	groups = findGroups(curPlayer)
	if groups then
		best = largestSet(groups)
		// OK, we've found the best group, and its size.
		// Make sure it contains the flag.
		plantFlag best
		// Distribute reinforcements!
		reinforcements = best.len
		drawStatus teams[curPlayer].name + " gets " + reinforcements +
		" reinforcement" + "s" * (reinforcements != 1)
		delay = 0.4
		options = reinforcibleCells(best.indexes)
		for i in range(1, best.len)
			if not options then
				options = reinforcibleCells(best.indexes, false)
				if not options then break
			end if
			choice = options[i % options.len]
			choice.setSoldiers choice.soldiers + 1
			if choice.soldiers > 5 then options.remove options.indexOf(choice)
			reinforceSnd.freq = 9 + 2 * rnd
			reinforceSnd.play
			if key.available and key.get == char(10) then globals.hurry = true
			if not hurry then wait delay
			delay = delay * 0.9
		end for
	else
		// eliminated!
	end if
end function

endTurn = function()
	if attackingCell != null then
		attackingCell.setSelected false
		globals.attackingCell = null
	end if
	
	doReinforcements
	recordHistory
	
	while true
		globals.curPlayer = (curPlayer + 1) % teams.len
		if not teams[curPlayer].eliminated then break
	end while
	enterState kStateSelectingAttacker
end function


kStateSelectingAttacker = "Selecting Attacker"
kStateSelectingTarget = "Selecting Target"
kStateDoingBattle = "Doing Battle"
kStateDidBattle = "Did Battle"
kStateGameOver = "Game Over"

enterState = function(state)
	globals.state = state
	text.color = teams[curPlayer].color
	
	if state == kStateSelectingAttacker then
		//globals.hurry = false
		if attackingCell != null then
			attackingCell.setSelected false
			globals.attackingCell = null
		end if
		if defendingCell != null then
			defendingCell.setSelected false
			globals.defendingCell = null
		end if
		if teams[curPlayer].human then drawDoneButton
		drawPrompt
	else if state == kStateSelectingTarget then
		if defendingCell != null then
			defendingCell.setSelected false
			globals.defendingCell = null
		end if
		if teams[curPlayer].human then drawDoneButton
		drawPrompt
	else if state == kStateDoingBattle then
		drawDoneButton false
		drawPrompt
	else if state == kStateDidBattle then
		if attackingCell != null then
			attackingCell.setSelected false
			globals.attackingCell = null
		end if
		if defendingCell != null then
			defendingCell.setSelected false
			globals.defendingCell = null
		end if
		if teams[curPlayer].human then drawDoneButton
		if isGameOver then enterState kStateGameOver
	else if state == kStateGameOver then
		recordHistory
		
		print "OK, now check history"
		print "and maybe make a graph!"
		exit
		
		drawDoneButton false
		drawStatus "GAME OVER!  (Click for Replay.)"
		while mouse.button; end while
		while not mouse.button; end while
		showHistoryReplay
		drawStatus "GAME OVER!"
		while mouse.button; end while
		while not mouse.button; end while		
		reset; load "title"; run  // start over!
	end if
	
end function

genStart
lastMouseButton = mouse.button
attackingCell = null
defendingCell = null
update = function()
	mouseDown = mouse.button and not lastMouseButton
	if mouseDown then clicked = grid.cellAt(mouse) else clicked = null
	globals.lastMouseButton = mouse.button
	
	if state == kStateSelectingAttacker or state == kStateDidBattle then
		if not teams[curPlayer].human then
			globals.attackingCell = ai.selectAttacker
			if attackingCell == null then
				endTurn
			else
				attackingCell.setSelected
				enterState kStateSelectingTarget
			end if
			return
		end if
		if mouseDown and doneButtonClicked then endTurn
		if clicked != null and clicked.owner == curPlayer and clicked.soldiers > 0 then
			clicked.setSelected
			globals.attackingCell = clicked
			enterState kStateSelectingTarget
		end if
	else if state == kStateSelectingTarget then
		if not teams[curPlayer].human then
			globals.defendingCell = ai.selectTarget
			defendingCell.setSelected
			if not hurry then wait 0.3
			enterState kStateDoingBattle
			return
		end if
		if mouseDown and doneButtonClicked then endTurn
		if clicked == null then return
		if clicked == attackingCell then
			// clicked the original selection again; undo it
			enterState kStateSelectingAttacker
		else if clicked.owner == curPlayer then
			if clicked.soldiers > 0 then
				// clicked a different cell of the current player; select that instead
				attackingCell.setSelected false
				clicked.setSelected
				globals.attackingCell = clicked
			end if
		else if grid.isNeighboring(attackingCell, clicked) then
			// attack!
			globals.defendingCell = clicked
			clicked.setSelected
			enterState kStateDoingBattle
		end if
	else if state == kStateDoingBattle then
		doBattle
	end if
end function

// Start the first turn
state = null
curPlayer = 0
enterState kStateSelectingAttacker

// Main loop
while true
	update
	if key.available and key.get == char(10) then globals.hurry = not hurry
	yield
end while
key.clear
