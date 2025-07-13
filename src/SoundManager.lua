local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
    local self = setmetatable({}, SoundManager)
    self.currentLoopingAmbience = nil
    self.currentSFX = nil
    return self
end

function SoundManager:playAmbience()
	print("SoundManager.playAmbience")
	song = love.audio.newSource("assets/music/waterAmbience.mp3", "stream")
	song:setLooping(true)
	song:play()
	song:setVolume(0.2)
	self.currentLoopingAmbience = song
end

function SoundManager:stopAmbience()
	print("SoundManager.stopAmbience")
	self.currentLoopingAmbience:stop()
end

function SoundManager:playCollisionTone()
	print("SoundManager.playCollisionTone")
	if self.currentSFX ~= nil and self.currentSFX:isPlaying() == true then return end
	tone = love.audio.newSource("assets/sfx/collision.mp3", "static")
	tone:play()
	tone:setVolume(0.2)
	self.currentSFX = tone
end


return SoundManager