-- Script written by ChrisFurry.
-- for all those people who miss the good-ol days where kart maker just squished the normal sprites i guess.
-- Tbh i just wish there were no insta-kill hazards in this game lol

--[[
		HEY YOU!! Want your skin to have a special flattened sprite?
		Well here's how you do it. Create a frame named "FLAT", and give it L/R frames only.
		Boom! Your skin will now have a proper flattened sprite unlike the base cast!
]]--

-- why are you adding me multiple times.
if(rawget(_G,"flattening_lua") ~= nil)then return end

-- FREESLOT!!!!!!!!
freeslot(
	"SPR2_FLAT", -- For custom animations
	"S_PLAY_FLAT")
spr2defaults[SPR2_FLAT] = SPR2_DEAD
-- namespace.
local _flat = {
	hooks = {},
	api = {}
}
-- Dunno why you would want to disable it if you're adding it, but ya never know the case.
local cvar_flattened_enabled = CV_RegisterVar({
	name = "flattening.enabled",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})
local cvar_flattened_time = CV_RegisterVar({
	name = "flattening.pancaketime",
	defaultvalue = tostring(TICRATE/2),
	flags = CV_NETVAR,
	PossibleValue = CV_Natural
})
local cvar_unflattened_jank = CV_RegisterVar({
	name = "flattening.recoverjanktime",
	defaultvalue = tostring(TICRATE*2),
	flags = CV_NETVAR,
	PossibleValue = CV_Natural
})
local cvar_mean_mode = CV_RegisterVar({
	name = "flattening.wombopain",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})
local cvar_explode_death = CV_RegisterVar({
	name = "flattening.explodeonstuck",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})
local cvar_grow_flattens = CV_RegisterVar({
	name = "flattening.growflattens",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})
local cvar_grow_stronger_inv = CV_RegisterVar({
	name = "flattening.growoverpowersinvincible",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})
local cvar_local_no_custom_sprites = CV_RegisterVar({
	name = "flattening.local.flatstyle",
	defaultvalue = "Auto",
	flags = 0,
	PossibleValue = {
		Auto = 0,
		Off = 1,
		On = 2
	}
})

local MF_CRUSHED = MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIP
local PF_CRUSHED = PF_STASIS

local sfx_squish = sfx_tppop
local sfx_unsquish = sfx_sprong

-- https://easings.net was referenced when making this function.
-- Simply returns a modified version of t
local function easeInElastic(t)
	local c4 = 120<<FRACBITS
	if(t==0 or t == FRACUNIT)then return t else 
		return FixedMul(
		-(2<<FRACBITS^(FixedMul(10<<FRACBITS,t)-10<<FRACBITS)),
		sin(FixedAngle(FixedMul(FixedMul(10<<FRACBITS,t) - 10<<FRACBITS,c4)))
		)
	end
	
end

local function mobj_being_crushed(self)
	return (self.ceilingz-self.floorz) >= FixedMul(self.height,self.scale)
end

local function mobj_flatten(self,inflictor,source,no_damage)
	-- Spew rings? Take away rings?? Kill???
	if(not self.flattened_timer)then
		if(not no_damage)then
			local dmg_flag = DMG_NORMAL
			if(cvar_mean_mode.value)then 
				dmg_flag = $|DMG_WOMBO 
				self.player.flashing = 0
			end
			P_DamageMobj(self,inflictor,source,1,dmg_flag)
			self.player.spinouttimer = 0
		end
		S_StartSound(self,sfx_squish)
	end
	-- Ensure we have been flattened.
	self.flattened_timer = cvar_flattened_time.value
	self.unflattened_jank = 0
	self.player.flashing = 0
	self.momx,self.momy,self.momz = 0,0,0
end

local function mobj_handle_flatten(self)
	if(not cvar_flattened_enabled.value)then return end
	if(self.player.playerstate ~= PST_LIVE)then
		self.flattened_timer = nil
		self.get_unstuck_please = nil
		self.unflattened_jank = nil
		return
	end
	if(self.unflattened_jank)then 
		-- Getting unflattened gets special jank!
		self.unflattened_jank = $-1
		self.player.defenselockout = 2
		-- Prevent the player from spindashing and drifting while unflattening.
		self.player.cmd.buttons = $&~(BT_DRIFT)

		if(not self.unflattened_jank)then
			-- Play funny sound
			S_StartSound(self,sfx_unsquish)
			self.spritexscale = FU/3*2
			self.spriteyscale = FU/3*4
		end
	end
	if(not self.flattened_timer)then return end
	-- Purely visual shit
	self.flags = $|MF_CRUSHED
	self.player.pflags = $|PF_CRUSHED
	-- Stop momentum and other actions
	self.momx = 0
	self.momy = 0
	self.z = self.floorz
	-- Prevent the player from doing much of anything.
	self.player.cmd.buttons = $&(BT_LOOKBACK|BT_VOTE) -- HEY GUYS GUESS WHA- (respawn replaced with ring bail)
	-- Countdown
	if(mobj_being_crushed(self))then
		self.flattened_timer = $-1
	else
		-- You're still being flattened!
		self.flattened_timer = cvar_flattened_time.value
		if(not self.get_unstuck_please)then self.get_unstuck_please = 0 end
		self.get_unstuck_please = $+1
		-- Make sure we aren't stuck forever by FUCKING KILLING YOU LOL
		if(self.get_unstuck_please > (TICRATE*2))then
			self.state = S_KART_STILL
			if(cvar_explode_death.value)then
				P_KillMobj(self,nil,nil,DMG_INSTAKILL)
			else
				P_DamageMobj(self,nil,nil,1,DMG_DEATHPIT)
			end
			self.flattened_timer = nil
			self.get_unstuck_please = nil
			self.flags = $&~MF_CRUSHED
			self.player.pflags = $&~PF_CRUSHED
			return
		end
	end
	self.player.stunned = cvar_unflattened_jank.value
	-- End
	if(self.flattened_timer <= 0)then
		self.flattened_timer = nil
		self.get_unstuck_please = nil
		self.state = S_KART_STILL

		self.flags = $&~MF_CRUSHED
		self.player.pflags = $&~PF_CRUSHED
		self.player.flashing = cvar_unflattened_jank.value
		self.unflattened_jank = cvar_unflattened_jank.value
		-- Set scale
		self.spritexscale = 2<<FRACBITS
		self.spriteyscale = FU/4
	end
end

local function mobj_handle_visual(self)
	if(not cvar_flattened_enabled.value)then return end
	if(self.flattened_timer)then
		-- Check if we even have this custom sprite for this skin.
		local ani_valid = skins[self.player.skin].sprites[SPR2_FLAT].numframes
		if((ani_valid and cvar_local_no_custom_sprites.value == 0) or cvar_local_no_custom_sprites.value == 2)then
			self.state = S_PLAY_FLAT
			self.spritexscale,self.spriteyscale = FU+FU/2,FU+FU/2
			self.renderflags = $|RF_NOSPLATBILLBOARD
		else
			self.spritexscale,self.spriteyscale = FU+FU/2,FU/4
		end
		return
	end
	if(not self.unflattened_jank)then return end
	-- Get a number from 0 to Fracunit for the easing functions
	local true_t = FU-((self.unflattened_jank<<FRACBITS)/cvar_unflattened_jank.value)
	-- Ease true_t for silly
	local bounce_t = ease.inexpo(true_t,0,FU)
	self.spritexscale = ease.linear(bounce_t,FU+FU/2 + (FixedMul(FU+cos(FixedAngle(true_t*360)),FU/2)/2),$)
	self.spriteyscale = ease.linear(bounce_t,FU/4 + (FixedMul(FU+sin(FixedAngle(true_t*720)),FU/2)/2),$)
end
-- The state that allows your skin to have a custom splat animation.
states[S_PLAY_FLAT] = {
	sprite = SPR_PLAY,
	frame = 0|SPR2_FLAT|FF_ANIMATE|FF_FLOORSPRITE,
	tics = 1,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_PLAY_FLAT
}
-- hey stop don't do that naughty >:(
function _flat.hooks.ShouldDamage(self,inflictor,source,damage,type)
	if(not cvar_flattened_enabled.value)then return end
	if(not self.player or 
		self.player.playerstate ~= PST_LIVE or
		self.player.respawn.state ~= 0x00)then return end
	if((type&(DMG_DEATHMASK|DMG_TYPEMASK)) ~= DMG_CRUSHED)then return end
	mobj_flatten(self)
	return false
end
-- Main handling.
function _flat.hooks.PreThink()
	for self in players.iterate() do
		if(self.mo)then
			mobj_handle_flatten(self.mo)
		end
	end
end
-- Visuals are done in post due to lots of things messing with it.
function _flat.hooks.PostThink()
	for self in players.iterate() do
		if(self.mo)then
			mobj_handle_visual(self.mo)
		end
	end
end

function _flat.hooks.MobjCollide(self,collidee)
	-- We don't need to do this.
	if(not cvar_grow_flattens.value)then return end
	-- Not who we need.
	if(not self.player)then return end
	if(not collidee.player)then return end
	-- Respawn states
	if(self.player.playerstate ~= PST_LIVE or
		self.player.respawn.state ~= 0x00)then return end
	if(collidee.player.playerstate ~= PST_LIVE or
		collidee.player.respawn.state ~= 0x00)then return end
	-- Overhead
	if(collidee.z > self.z + self.height)then return end
	-- Underneath
	if(collidee.z + collidee.height < self.z)then return end
	-- Ghosted
	if(self.player.hyudorotimer or collidee.player.hyudorotimer)then return end
	-- If they're flashing, don't.
	if(collidee.player.flashing)then return end
	-- If they're invincible, check. (optional, if you like grow being stronger then you can change that :)
	if(not cvar_grow_stronger_inv.value)then
		if(collidee.player.invincibilitytimer > 0)then return end
	end
	-- Are we larger?
	local required_diff = (mapobjectscale/4)
	if(self.scale <= collidee.scale + required_diff)then return end
	-- Using current abilities (fling instead of squash)
	if(self.player.invincibilitytimer > 0)then return end
	if(self.player.flamedash > 0 and self.player.curshield == KSHIELD_FLAME)then return end
	if(self.player.curshield == KSHIELD_TOP and (self.player.cmd.buttons & BT_DRIFT) ~= BT_DRIFT)then return end
	if(self.player.bubbleblowup > 0)then return end
	-- We'll just call that good.
	mobj_flatten(collidee,self,self,(gametyperules&GTR_BUMPERS) ~= GTR_BUMPERS)
	return false
end

addHook("ShouldDamage",_flat.hooks.ShouldDamage,MT_PLAYER)
addHook("PreThinkFrame",_flat.hooks.PreThink)
addHook("PostThinkFrame",_flat.hooks.PostThink)
addHook("MobjCollide",_flat.hooks.MobjCollide,MT_PLAYER)
addHook("MobjMoveCollide",_flat.hooks.MobjCollide,MT_PLAYER)

-- API
---@function Allows the flatten, and restored sounds to be replaced by different sounds. The only reason this is provided is because this is a lua script only, and I want to avoid making this a wad. Allows you to make a sound mod for this mod.
---@param name Either "flattened" or "restored", otherwise will throw an error.
---@param sfxid The sfx_ constant to play when squished.
---@return namespace, for chaining functions.
function _flat.api.changeSound(name,sfxid)
	if(name:lower() == "flattened")then
		sfx_squish = sfxid
		return _flat
	elseif(name:lower() == "restored")then
		sfx_unsquish = sfxid
		return _flat
	end
	print("[flattened.lua][ERROR][changeSound]: Sound name '"..name.."' not recognised! Name can only be 'flattened' or 'restored'!")
	return _flat
end

---@function Flatten a mobj. Only works on MT_PLAYER.
---@param mobj The object to flatten. Should only be type MT_PLAYER.
---@param no_damage If true, will not deal damage to the object.
---@param inflictor What did it? Can be nil.
---@param source Who did it? Can be nil.
---@return namespace, for chaining functions.
function _flat.api.mobjFlatten(mobj,inflictor,source,no_damage)
	if(userdataType(mobj) ~= "mobj_t")then
		print("[flattened.lua][ERROR][mobjFlatten]: mobj is not a mobj_t!")
		return _flat
	end
	mobj_flatten(mobj,inflictor,source,no_damage)
	return _flat
end

-- dont mind me im just clogging up globalspace lol
rawset(_G,"flattening_lua",_flat)
