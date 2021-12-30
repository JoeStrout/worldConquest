// AI (artificial intelligence, i.e. computer player) for Speed Conquest.
//
// The main entry points here are selectAttacker and selectTarget.  These should
// return the CellInfo of the chosen attacker and defender for curPlayer.

selectAttacker = function()
	//drawStatus teams[curPlayer].name + " is thinking..."
	if not hurry then niceWait
	
	// Find our largest group -- this is the one we mostly want to expand.
	myGroups = findGroups(curPlayer)
	//drawStatus teams[curPlayer].name + " has " + myGroups.len + " groups..."; wait

	if not myGroups then return null
	mainGrp = largestSet(myGroups)
	//drawStatus teams[curPlayer].name + "'s home territory has " + mainGrp.len + " cells"; wait
	
	// Find all the enemy territories adjacent to this one.
	// These are potential targets.
	targets = []
	for c in colRange
		for r in rowRange
			ci = cellInfo[c][r]
			if ci.isWater or ci.owner == curPlayer then continue
			for n in grid.neighbors(ci.col, ci.row)
				if mainGrp.hasIndex(cellInfo[n[0]][n[1]]) then
					//drawStatus teams[curPlayer].name + " considers " + ci.desc
					targets.push ci
					break
				end if
			end for
		end for
	end for
	//drawStatus teams[curPlayer].name + " has " + targets.len + " possible targets"; wait

	while targets
		// select a potential target
		t = targets.pop
		// make sure we will be able to attack it
		for n in grid.neighbors(t.col, t.row)
			nc = cellInfo[n[0]][n[1]]
			if nc.owner == curPlayer and nc.soldiers > 0 then
				// yep, this is a valid target; return the attacker
				outer.target = t
				return nc
			end if
		end for
		// nope, try again
	end while

	return null
end function

selectTarget = function()	
	// target was actually set in selectAttacker.
	return target
end function
