--[ Moteur Central de Simulation (Master Tick AAA) ]--
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

local globalTickEvent = ReplicatedStorage:FindFirstChild("GlobalTickEvent") or Instance.new("BindableEvent")
globalTickEvent.Name = "GlobalTickEvent"
globalTickEvent.Parent = ReplicatedStorage

local BASE_DAY_SECONDS = 3600 
local TICK_RATE = 0.2 

Lighting.ClockTime = 8 

task.spawn(function()
    while true do
        task.wait(TICK_RATE)
        
        local dayLength = GameConfig.World.DayLengthSeconds or BASE_DAY_SECONDS
        local timeScale = BASE_DAY_SECONDS / dayLength
        
        -- 🌟 MATHS EXACTES : Fraction de jour in-game écoulée pendant ce Tick
        local inGameDaysPassed = TICK_RATE / dayLength
        
        -- Le soleil avance
        Lighting.ClockTime += (inGameDaysPassed * 24)
        
        -- On distribue : Le TickRate réel, la fraction de jour in-game, et le TimeScale (pour la vitesse physique)
        globalTickEvent:Fire(TICK_RATE, inGameDaysPassed, timeScale)
    end
end)