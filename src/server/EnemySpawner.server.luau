--[ Spawner d'Entités V2 (Sécurisé avec Logs) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))
local NPCBrain = require(script.Parent:WaitForChild("NPC"):WaitForChild("Brain"))

local MAX_NPCS = 10 

CoreLogger.info("Spawner", "⏳ En attente de la plantation de la flore et de l'eau...")

-- 🛡️ On attend que PropGenerator ait fini de poser les arbres et l'eau
repeat 
    task.wait(0.5) 
until workspace:GetAttribute("PropsGenerated") == true

CoreLogger.info("Spawner", "🚀 Le monde est prêt, déploiement des PNJ...")

-- (Le reste de ton script spawnNPC() reste identique)

-- 🌍 Scanner depuis le ciel pour trouver un sol sec
-- 🌍 Scanner depuis le ciel pour trouver un sol sec
local function getSafeSpawnPosition()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = {workspace.Terrain}

    for i = 1, 10 do
        -- 🛡️ CORRECTION : Large zone de spawn pour éviter les collisions mortelles !
        local rx = math.random(-300, 300) 
        local rz = math.random(-300, 300)
        local rayOrigin = Vector3.new(rx, 200, rz) 
        
        local ray = workspace:Raycast(rayOrigin, Vector3.new(0, -300, 0), raycastParams)
        
        if ray and ray.Material ~= Enum.Material.Water then
            -- On les fait tomber d'un peu plus haut (6 studs) en sécurité
            return ray.Position + Vector3.new(0, 6, 0)
        end
    end
    
    return Vector3.new(0, 80, 0) 
end

local function spawnNPC()
    -- On cherche le modèle dans ReplicatedStorage (ou ServerStorage)
    local npcTemplate = ReplicatedStorage:FindFirstChild("Vagabond") or ServerStorage:FindFirstChild("Vagabond")
    
    if not npcTemplate then
        warn("⚠️ Modèle 'Vagabond' introuvable dans ReplicatedStorage !")
        return
    end

    local clone = npcTemplate:Clone()
    local spawnPos = getSafeSpawnPosition()
    
    -- PivotTo est la méthode moderne (AAA) pour téléporter un modèle complexe avec ses accessoires
    clone:PivotTo(CFrame.new(spawnPos))
    clone.Parent = workspace
    
    -- 🧠 On branche le cerveau au corps !
    NPCBrain.Attach(clone)
    print("✅ Vagabond apparu en :", math.round(spawnPos.X), math.round(spawnPos.Z))
end

-- On attend 2 petites secondes au démarrage pour laisser le temps au moteur physique de se stabiliser
task.wait(2)

for i = 1, MAX_NPCS do
    spawnNPC()
    task.wait(0.1) -- On espace les spawns d'un dixième de seconde pour éviter un pic de lag (Lag Spike)
end

print("🌍 Tous les PNJ sont en place et vivent leur vie !")