local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
    local self = setmetatable({}, SoundManager)
    self.currentMusic = nil
    self.currentSFXQueue = nil
    return self
end

function SoundManager.playMusic()
	print("SoundManager.playMusic")
	song = love.audio.newSource("assets/music/song.ogg", "stream")
	song:setLooping(true)
	song:play()
	song:setVolume(0)
	currentMusic = song
end

function SoundManager.stopMusic()
	print("SoundManager.stopMusic")
	currentMusic:stop()
end

function SoundManager.playTone()

end


return SoundManager