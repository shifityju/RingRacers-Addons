//Original script by Zeverous, edited and optimized by Snu
//Ported to Ring Racers by PlatterTheFinch
//but then again it is pretty different from the Kart version...

local debugFLM = 0 //set this to 1 if you like console spam

local j = 1

local useFLM = 1
//0 or 1, enable or disable entire script until further spec
//2 should not be set by player; set this to 2 if the map has its own FL music setup (it disables the script until next map load

//the thing that lets me disable this
local function toggleFLM(player, ...)
    useFLM = arg1
end

//stolem (sawy)
local function getattrib(name,default,allowstring)
	local attrib = mapheaderinfo[gamemap][name]
	if attrib == nil
		return default
	end
	if attrib:lower() == "true"
		return true
	elseif attrib:lower() == "false"
		return false
	elseif allowstring
		return attrib
	end
	return default
end

COM_AddCommand ("toggleFLM", toggleFLM)

//Consoleplayer + Displayplayer
local cp, dp
hud.add(function(v, p, c)
    dp = p
    if not cp or not cp.valid
        cp = p
    end
end)

//if the stage has its own FLmusic association, turn off this script until that map passes
//this should be specified in a table because i suck

local dontplay = {
"765 Stadium",
"Regal", //zonetitle is disregarded
"Las Vegas",
"Joypolis",
"Daytona Speedway",
"Angel Arrow",
"Tetromino",
"Simple Circuit", //this and the rest are just Pro Pack X which have inbuilt FLMusic
"Robotnik Raceway",
"Lonely Isle",
"Twinkle Village",
"Roundabout",
"Coconut Mall",
"Great Galleon",
"Blitz Beach",
"Banshee Boardwalk",
"Azure Garden",
"Festival Night",
"Rampart Ruins",
"Sea Stadium",
"Port Aurora",
"Angel\'s Gate",
}

//player, useFLM, debugFLM
local function checkList ()
	if debugFLM == 2
		CONS_Printf (players[0], "BL check function is called")
	end
	useFLM = getattrib("flm_restrict", 1, true)
	if debugFLM >= 2
		CONS_Printf (players[0], "Header check returned "..getattrib("flm_restrict", "nothing", true))
	end
	j = 1 //this is the part where i lost all sanity
	if true //useFLM == 1
		repeat
			if debugFLM == 3
				CONS_Printf (players[0], "iterating on line"..j)
				CONS_Printf (players[0], "such a map is "..dontplay[j])
			end
			if mapheaderinfo[gamemap].lvlttl == dontplay[j]
				useFLM = 2
				if debugFLM >= 2
					CONS_Printf (players[0], "BLCF RESPONSE!")
				end
			end
			j = j + 1
		until j >= #dontplay //cuz a for loop is too much for me wee little brayn
	end
end

//The Thinkframe
addHook("ThinkFrame", do
	for p in players.iterate
		if p.laps == mapheaderinfo[gamemap].numlaps //the amount of laps FINISHED (so the total amount of laps, not -1 like it was in kart)
		and p.invincibilitytimer <= 0 //check for invincibility, in theory these should both delay the music change while theyre active
		and p.growshrinktimer <= 0 //check for growth
			if not p.mq 
				p.mq = 1 
			end
			p.mq = min(50, $+1)
			
			if not p.mqd //check to see if music changed already
			and useFLM == 1 //wait should we be doing this at all
				if debugFLM >= 1
					CONS_Printf (p, "Met requirements for FLM")
					if useFLM == 2
						CONS_Printf (p, "wait a minute, i hate FLM")
					end
				end
				if p.mq == 49
					COM_BufInsertText(p, "tunes "..mapheaderinfo[gamemap].musname[1].." 1.1")
				end
				if p.mq <= 48
					COM_BufInsertText(p, "tunes -none")
					
				end
			end
		end
		if p.laps == mapheaderinfo[gamemap].numlaps + 1 //check that the race has concluded and will make the music normal again
		and useFLM == 1
			COM_BufInsertText(p, "tunes -default")
			if debugFLM >= 1
				CONS_Printf (p, "Finished the stage, music is returned")
			end
		end
		if (p.pflags & PF_ELIMINATED) then //don't keep the music going, im dead
			if useFLM == 1
				COM_BufInsertText(p, "tunes -default")
				if debugFLM >= 1
					CONS_Printf (p, "You lost the game, music is returned")
				end
			end
		end
		if useFLM == 2
		and debugFLM >= 1
			CONS_Printf (p, "Course is blacklisted; script execution halted")
		end
		useFLM = 1 //i shouldnt have to use this line but this script keeps acting up
		checkList()
	end
end)
//reset variables on mapload
addHook("MapLoad", function()
	for p in players.iterate
		p.mq = nil
		p.mqd = nil
		if useFLM == 1
			COM_BufInsertText(p, "tunes -default")
		end
		if debugFLM >= 1
			CONS_Printf (p, "The script should be running now")
			CONS_Printf (p, mapheaderinfo[gamemap].lvlttl)
		end
	end
end)

//make it so music doesnt continue if we're not in a game
addHook("GameQuit", function()
	for p in players.iterate
		p.mq = nil
		p.mqd = nil
		if useFLM == 1
			COM_BufInsertText(p, "tunes -default")
		end
		if debugFLM >= 1
			CONS_Printf (p, "Cease running because the game was exit")
		end
	end
end)

//shouldn't need this but you never know
addHook("IntermissionThinker", function()
	for p in players.iterate
		p.mq = nil
		p.mqd = nil
		if useFLM == 1
			COM_BufInsertText(p, "tunes -default")
		end
		if debugFLM >= 1
			CONS_Printf (p, "Cease running because the round was finished")
		end
	end
end)