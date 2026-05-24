--[ Gestionnaire du Cycle Jour/Nuit Réaliste ]--

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

Lighting.ClockTime = 8 -- Départ à 8h du matin

task.spawn(function()
    while task.wait(0.1) do
        -- Mathématiques pour caler le temps :
        -- Une journée Roblox fait 24 heures. La boucle s'exécute toutes les 0.1s.
        local hoursPerTick = (0.1 * 24) / GameConfig.World.DayLengthSeconds
        Lighting.ClockTime += hoursPerTick
    end
end)