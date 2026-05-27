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
                        
                        -- 🎲 1. PROBABILITÉS EXACTES
                        local capacityRoll = math.random()
                        local maxFruits = 1
                        if capacityRoll <= GameConfig.Generation.BerryQuantityChances.Four then maxFruits = 4
                        elseif capacityRoll <= GameConfig.Generation.BerryQuantityChances.Three then maxFruits = 3
                        elseif capacityRoll <= GameConfig.Generation.BerryQuantityChances.Two then maxFruits = 2
                        end
                        
                        -- 🧬 L'ADN du buisson
                        bush:SetAttribute("MaxFruits", maxFruits)
                        bush:SetAttribute("Fruits", maxFruits)
                        
                        -- 🍓 2. GÉNÉRATION ORGANIQUE DES BAIES INDIVIDUELLES
                        for i = 1, maxFruits do
                            local berry = Instance.new("Part")
                            berry.Name = "Berry_" .. i
                            berry.Size = Vector3.new(0.7, 0.7, 0.7)
                            berry.Color = Color3.fromRGB(180, 10, 50)
                            berry.Shape = Enum.PartType.Ball
                            berry.Anchored = true 
                            berry.CanCollide = false
                            
                            -- Placement naturel sans chevauchement (Cercle autour du buisson)
                            local angle = (i / maxFruits) * math.pi * 2 + math.random(-0.2, 0.2)
                            local radiusXZ = 1.6
                            local heightY = math.random(2, 12) / 10 -- Hauteur variable entre 0.2 et 1.2
                            local offsetX = math.cos(angle) * radiusXZ
                            local offsetZ = math.sin(angle) * radiusXZ
                            
                            berry.Position = bush.CFrame:PointToWorldSpace(Vector3.new(offsetX, heightY, offsetZ))
                            berry.Parent = bush
                            
                            -- Variables d'état individuelles
                            berry:SetAttribute("IsGrown", true)
                            berry:SetAttribute("RegrowthProgress", 0)
                            
                            local prompt = Instance.new("ProximityPrompt")
                            prompt.ActionText = "Cueillir"
                            prompt.ObjectText = "Baie Sauvage"
                            prompt.Parent = berry
                            
                            -- Interaction Joueur sur CETTE baie spécifique
                            prompt.Triggered:Connect(function(player)
                                if berry:GetAttribute("IsGrown") then
                                    berry:SetAttribute("IsGrown", false)
                                    berry:SetAttribute("RegrowthProgress", 0)
                                    berry.Size = Vector3.zero -- On la cache physiquement !
                                    prompt.Enabled = false
                                    
                                    -- Met à jour le compteur global du buisson
                                    local current = bush:GetAttribute("Fruits") or 1
                                    bush:SetAttribute("Fruits", math.max(0, current - 1))
                                    
                                    local giveItemEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
                                    if giveItemEvent then giveItemEvent:Fire(player, "Berry", 1) end
                                end
                            end)
                        end
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