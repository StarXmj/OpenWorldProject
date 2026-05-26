--[ Spawner d'Entités V2 (Map Statique & StreamingEnabled) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local NPCBrain = require(script.Parent:WaitForChild("NPC"):WaitForChild("Brain"))
local MAX_NPCS = 10 -- ⚙️ Nombre de PNJ à générer sur la carte

print("🚀 Démarrage du Spawner de PNJ...")

-- 🌍 Scanner depuis le ciel pour trouver un sol sec
local function getSafeSpawnPosition()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = {workspace.Terrain} -- On ne scanne que le Terrain

    for i = 1, 10 do -- On tente 10 fois maximum pour trouver un bon point
        -- Modifie ces valeurs (-400, 400) en fonction de la taille de ta map !
        local rx = math.random(-25, 25) 
        local rz = math.random(-25, 25)
        local rayOrigin = Vector3.new(rx, 200, rz) -- On part de 200 mètres d'altitude
        
        local ray = workspace:Raycast(rayOrigin, Vector3.new(0, -300, 0), raycastParams)
        
        -- Si on touche le sol et que ce n'est PAS de l'eau
        if ray and ray.Material ~= Enum.Material.Water then
            return ray.Position + Vector3.new(0, 4, 0) -- On le lâche 4 studs au-dessus du sol
        end
    end
    
    return Vector3.new(0, 50, 0) -- Position de secours au centre de la map
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