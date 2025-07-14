local SoundManager = {}
SoundManager.__index = SoundManager

-- Constants ------------------------------------------------------------------------------
local DEFAULT_MUSIC_VOLUME = 0.7
local DEFAULT_JINGLE_VOLUME = 0.7
local DEFAULT_AMBIENCE_VOLUME = 0.5
local DEFAULT_SFX_VOLUME = 0.5

function SoundManager.new()
	local self = setmetatable({}, SoundManager)
	self.currentLoopingAmbience = nil
	self.currentLoopingMusic = nil
	self.currentSFX = nil

	-- Pre-load frequently used SFX sources to avoid runtime loading latency
	self._collisionToneSource = love.audio.newSource("assets/sfx/collision.mp3", "static")
	self._collisionToneSource:setVolume(DEFAULT_SFX_VOLUME)

	return self
end

local function _stopSource(source)
	if source ~= nil and source:isPlaying() then
		source:stop()
	end
end

-- Stop currently playing looping music (if any)
function SoundManager:stopMusic()
	_stopSource(self.currentLoopingMusic)
	self.currentLoopingMusic = nil
end

-- Stop currently playing ambience (if any)
function SoundManager:stopAmbience()
	_stopSource(self.currentLoopingAmbience)
	self.currentLoopingAmbience = nil
end

-- Play looping background music, replacing any previous looping music
function SoundManager:playMusic()
	-- Stop previous music to prevent overlap
	self:stopMusic()

	local song = love.audio.newSource("assets/music/sketch2.mp3", "stream")
	song:setLooping(true)
	song:setVolume(DEFAULT_MUSIC_VOLUME)
	song:play()

	self.currentLoopingMusic = song
end

-- Play looping ambience, replacing any previous ambience track
function SoundManager:playAmbience()
	-- Stop previous ambience to prevent overlap
	self:stopAmbience()

	local ambience = love.audio.newSource("assets/music/waterAmbience.mp3", "stream")
	ambience:setLooping(true)
	ambience:setVolume(DEFAULT_AMBIENCE_VOLUME)
	ambience:play()

	self.currentLoopingAmbience = ambience
end

-- Play short collision SFX
function SoundManager:playCollisionTone()
	-- If another collision tone is currently playing, restart it quickly
	if self._collisionToneSource:isPlaying() then
		self._collisionToneSource:stop()
	end

	self._collisionToneSource:seek(0)
	self._collisionToneSource:play()

	self.currentSFX = self._collisionToneSource
end

-- Play celebratory high-score jingle, stopping all background loops first
function SoundManager:playHighScoreJingle()
	-- Stop any current SFX
	if self.currentSFX ~= nil and self.currentSFX:isPlaying() then
		self.currentSFX:stop()
	end

	local jingle = love.audio.newSource("assets/sfx/high-score-jingle.mp3", "static")
	jingle:setVolume(DEFAULT_JINGLE_VOLUME)
	jingle:play()

	self.currentSFX = jingle
end

function SoundManager:playDidntGetHighScore()
	-- Stop any current SFX so the jingle can be clearly heard
	if self.currentSFX ~= nil and self.currentSFX:isPlaying() then
		self.currentSFX:stop()
	end

	local jingle = love.audio.newSource("assets/sfx/no.mp3", "static")
	jingle:setVolume(DEFAULT_JINGLE_VOLUME)
	jingle:play()

	self.currentSFX = jingle
end

return SoundManager
