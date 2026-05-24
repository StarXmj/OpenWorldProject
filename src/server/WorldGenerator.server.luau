--[ Générateur Unique de l'Open World (Performant) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Terrain = workspace.Terrain

local SEED = math.random(1, 1000000)
local mapSize = 600
local blockSize = 4
local noiseScale = 80
local amplitude = 40
local waterLevel = 15

local waterWaypoints = Instance.new("Folder")
waterWaypoints.Name = "WaterWaypoints"
waterWaypoints.Parent = workspace

print("🌍 Génération du monde en cours... Seed : " .. SEED)

-- PARTIE A : LOGIQUE DU TERRAIN
Terrain:Clear()
local blocksProcessed = 0

for x = -mapSize/2, mapSize/2, blockSize do
    for z = -mapSize/2, mapSize/2, blockSize do
        local noiseValue = math.noise(x / noiseScale, SEED, z / noiseScale)
        local height = (noiseValue + 0.5) * amplitude
        
        local material = Enum.Material.Grass
        if height < waterLevel + 2 then material = Enum.Material.Sand
        elseif height > amplitude * 0.8 then material = Enum.Material.Rock end
        
        Terrain:FillBlock(CFrame.new(x, (height - 20) / 2, z), Vector3.new(blockSize, height + 20, blockSize), material)
        
        if height < waterLevel then
            Terrain:FillBlock(CFrame.new(x, height + ((waterLevel - height) / 2), z), Vector3.new(blockSize, waterLevel - height, blockSize), Enum.Material.Water)
            
            -- Points d'eau invisibles pour guider les PNJ sans alourdir le serveur
            if math.random(1, 40) == 1 then
                local wp = Instance.new("Part")
                wp.Name = "WaterWaypoint"
                wp.Position = Vector3.new(x, waterLevel, z)
                wp.Transparency = 1
                wp.Anchored = true
                wp.CanCollide = false
                wp.Parent = waterWaypoints
            end
        end
        
        blocksProcessed += 1
        if blocksProcessed % 500 == 0 then task.wait() end
    end
end

-- Fonction pour savoir combien de baies poser sur un buisson selon tes probabilités
local function rollBerryQuantity()
    local roll = math.random() -- Entre 0 et 1
    local chances = GameConfig.Generation.BerryQuantityChances
    
    if roll <= chances.Four then return 4
    elseif roll <= chances.Three then return 3
    elseif roll <= chances.Two then return 2
    else return 1 end
end

-- PARTIE B : ARBRES ET BUISSONS AVEC BAIES VISIBLES
task.wait(1)
local rayParams = RaycastParams.new()
rayParams.IgnoreWater = false

for x = -mapSize/2, mapSize/2, 15 do
    for z = -mapSize/2, mapSize/2, 15 do
        local result = workspace:Raycast(Vector3.new(x, 150, z), Vector3.new(0, -200, 0), rayParams)
        
        if result and result.Material == Enum.Material.Grass then
            local roll = math.random()
            
            if roll <= GameConfig.Generation.TreeChance then
                -- Création Arbre
                local trunk = Instance.new("Part")
                trunk.Name = "TreeTrunk"
                trunk.Size = Vector3.new(3, 15, 3)
                trunk.Position = result.Position + Vector3.new(0, 7.5, 0)
                trunk.Color = Color3.fromRGB(102, 51, 0)
                trunk.Material = Enum.Material.Wood
                trunk.Anchored = true
                trunk.Parent = workspace

                local leaves = Instance.new("Part")
                leaves.Size = Vector3.new(12, 12, 12)
                leaves.Position = trunk.Position + Vector3.new(0, 10, 0)
                leaves.Color = Color3.fromRGB(34, 139, 34)
                leaves.Material = Enum.Material.Grass
                leaves.Shape = Enum.PartType.Ball
                leaves.Anchored = true
                leaves.Parent = workspace
                
            elseif roll <= (GameConfig.Generation.TreeChance + GameConfig.Generation.BerryBushChance) then
                -- Création Buisson
                local bush = Instance.new("Part")
                bush.Name = "BerryBush"
                bush.Size = Vector3.new(4, 3, 4)
                bush.Position = result.Position + Vector3.new(0, 1.5, 0)
                bush.Color = Color3.fromRGB(20, 85, 20)
                bush.Material = Enum.Material.Grass
                bush.Shape = Enum.PartType.Ball
                bush.Anchored = true
                bush.Parent = workspace
                
                -- GÉNÉRATION DES BAIES VISIBLES SUR LE BUISSON
                local berryCount = rollBerryQuantity()
                for i = 1, berryCount do
                    local berry = Instance.new("Part")
                    berry.Name = "BerryDrop"
                    berry.Size = Vector3.new(0.7, 0.7, 0.7)
                    berry.Color = Color3.fromRGB(180, 10, 50) -- Rouge Baie
                    berry.Shape = Enum.PartType.Ball
                    berry.Anchored = true -- Fixées sur le buisson
                    berry.CanCollide = false
                    
                    -- On les éparpille légèrement autour du centre du buisson pour qu'elles soient visibles
                    berry.Position = bush.Position + Vector3.new(math.random(-15, 15)/10, math.random(0, 10)/10, math.random(-15, 15)/10)
                    berry.Parent = workspace
                    
                    local prompt = Instance.new("ProximityPrompt")
                    prompt.ActionText = "Cueillir"
                    prompt.ObjectText = "Baie Sauvage"
                    prompt.Parent = berry
                    
                    prompt.Triggered:Connect(function(player)
                        local giveItemEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
                        if giveItemEvent then 
                            giveItemEvent:Fire(player, "Berry", 1) 
                            berry:Destroy() 
                        end
                    end)
                end
            end
        end
    end
    blocksProcessed += 1
    if blocksProcessed % 20 == 0 then task.wait() end
end

print("✅ Monde et flore générés avec succès !")