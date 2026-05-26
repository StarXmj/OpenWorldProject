--[ Moteur Central de Simulation (Master Tick) ]--

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

-- 🌟 LE BATTEMENT DE COEUR DU JEU
local globalTickEvent = Instance.new("BindableEvent")
globalTickEvent.Name = "GlobalTickEvent"
globalTickEvent.Parent = ReplicatedStorage

local BASE_DAY_SECONDS = 3600 -- Une journée "normale" fait 1 heure réelle
Lighting.ClockTime = 8 

-- Le serveur émet un Tick toutes les 0.2 secondes (optimisé pour 5 calculs par seconde)
local TICK_RATE = 0.2 

CoreLogger.info("CoreClock", "Moteur de simulation démarré. TickRate: " .. TICK_RATE .. "s")

task.spawn(function()
    while task.wait(TICK_RATE) do
        -- 1. Calcul de l'échelle du temps (TimeScale)
        -- Si DayLengthSeconds = 1800, le TimeScale est de 2 (le jeu va 2 fois plus vite)
        local currentDayLength = GameConfig.World.DayLengthSeconds or BASE_DAY_SECONDS
        local timeScale = BASE_DAY_SECONDS / currentDayLength

        -- 2. Mise à jour du soleil (Le temps in-game)
        -- En 0.2s réelles, combien d'heures in-game se sont écoulées ?
        local hoursPerTick = (TICK_RATE * 24 * timeScale) / BASE_DAY_SECONDS
        Lighting.ClockTime += hoursPerTick

        -- 3. PROPAGATION DU TICK À TOUT LE JEU
        -- Tous les PNJ, la nature et le joueur vont écouter cet événement !
        globalTickEvent:Fire(TICK_RATE, timeScale)
    end
end)