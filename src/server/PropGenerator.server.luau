--[ Générateur d'Accessoires (Arbres, Buissons, Eau) sur Map Statique ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CoreLogger = require(Shared:WaitForChild("CoreLogger"))

CoreLogger.info("Génération", "Démarrage du scan écologique de la carte...")

local floraFolder = Instance.new("Folder")
floraFolder.Name = "Flora"
floraFolder.Parent = workspace

local waterWaypoints = Instance.new("Folder")
waterWaypoints.Name = "WaterWaypoints"
waterWaypoints.Parent = workspace

local mapSize = 1000 -- ⚠️ Modifie ceci si ta map statique est plus grande (ex: 2000)
local step = 15

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {workspace.Terrain}

-- On lance la génération dans un thread séparé pour ne pas figer le serveur
task.spawn(function()
    local countTrees, countBushes, countWater = 0, 0, 0
    
    for x = -mapSize/2, mapSize/2, step do
        for z = -mapSize/2, mapSize/2, step do
            local origin = Vector3.new(x, 200, z)
            local result = workspace:Raycast(origin, Vector3.new(0, -300, 0), rayParams)
            
            if result then
                if result.Material == Enum.Material.Water then
                    -- Générer des points d'eau invisibles (1 chance sur 10)
                    if math.random(1, 10) == 1 then
                        local wp = Instance.new("Part")
                        wp.Name = "WaterWaypoint"
                        wp.Position = result.Position
                        wp.Transparency = 1
                        wp.Anchored = true
                        wp.CanCollide = false
                        wp.Parent = waterWaypoints
                        countWater += 1
                    end
                elseif result.Material == Enum.Material.Grass then
                    local roll = math.random()
                    
                    if roll <= GameConfig.Generation.TreeChance then
                        local trunk = Instance.new("Part")
                        trunk.Name = "TreeTrunk"
                        trunk.Size = Vector3.new(3, 15, 3)
                        trunk.Position = result.Position + Vector3.new(0, 7.5, 0)
                        trunk.Color = Color3.fromRGB(102, 51, 0)
                        trunk.Material = Enum.Material.Wood
                        trunk.Anchored = true
                        trunk.Parent = floraFolder

                        local leaves = Instance.new("Part")
                        leaves.Size = Vector3.new(12, 12, 12)
                        leaves.Position = trunk.Position + Vector3.new(0, 10, 0)
                        leaves.Color = Color3.fromRGB(34, 139, 34)
                        leaves.Material = Enum.Material.Grass
                        leaves.Shape = Enum.PartType.Ball
                        leaves.Anchored = true
                        leaves.Parent = floraFolder
                        countTrees += 1
                        
                    elseif roll <= (GameConfig.Generation.TreeChance + GameConfig.Generation.BerryBushChance) then
                        local bush = Instance.new("Part")
                        bush.Name = "BerryBush"
                        bush.Size = Vector3.new(4, 3, 4)
                        bush.Position = result.Position + Vector3.new(0, 0.8, 0) 
                        bush.Color = Color3.fromRGB(20, 85, 20)
                        bush.Material = Enum.Material.Grass
                        bush.Shape = Enum.PartType.Ball
                        bush.Anchored = true
                        bush.Parent = floraFolder
                        
                        -- Initialisation pour l'EcologyManager
                        bush:SetAttribute("Fruits", 3)
                        
                        -- Création de la baie physique pour le joueur
                        local berry = Instance.new("Part")
                        berry.Name = "BerryDrop"
                        berry.Size = Vector3.new(0.7, 0.7, 0.7)
                        berry.Color = Color3.fromRGB(180, 10, 50)
                        berry.Shape = Enum.PartType.Ball
                        berry.Anchored = true 
                        berry.CanCollide = false
                        berry.Position = bush.Position + Vector3.new(0, 2, 0)
                        berry.Parent = bush
                        
                        local prompt = Instance.new("ProximityPrompt")
                        prompt.ActionText = "Cueillir"
                        prompt.ObjectText = "Baie Sauvage"
                        prompt.Parent = berry
                        
                        prompt.Triggered:Connect(function(player)
                            local giveItemEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
                            if giveItemEvent then 
                                giveItemEvent:Fire(player, "Berry", 1) 
                                berry.Transparency = 1
                                prompt.Enabled = false
                                CoreLogger.debug("Inventaire", player.Name .. " a cueilli une baie.")
                            end
                        end)
                        countBushes += 1
                    end
                end
            end
        end
        task.wait() -- Empêche le serveur de crash pendant la boucle
    end
    
    CoreLogger.info("Génération", string.format("Terminée ! Arbres: %d | Buissons: %d | Eau: %d", countTrees, countBushes, countWater))
    
    -- 🛡️ LE SIGNAL : On prévient les PNJ et l'écologie que le monde est prêt !
    workspace:SetAttribute("PropsGenerated", true)
end)