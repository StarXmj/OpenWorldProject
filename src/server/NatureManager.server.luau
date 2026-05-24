--[ Générateur de Nature et de Ressources ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local trees = {}

-- 1. CRÉER LA FORÊT (5 Arbres)
for i = 1, 5 do
    -- Le Tronc
    local trunk = Instance.new("Part")
    trunk.Name = "TreeTrunk"
    trunk.Size = Vector3.new(3, 15, 3)
    trunk.Position = Vector3.new(math.random(-60, 60), 7.5, math.random(-60, 60))
    trunk.Color = Color3.fromRGB(102, 51, 0) -- Marron
    trunk.Material = Enum.Material.Wood
    trunk.Anchored = true
    trunk.Parent = workspace
    
    -- Le Feuillage
    local leaves = Instance.new("Part")
    leaves.Name = "TreeLeaves"
    leaves.Size = Vector3.new(12, 12, 12)
    leaves.Position = trunk.Position + Vector3.new(0, 10, 0)
    leaves.Color = Color3.fromRGB(34, 139, 34) -- Vert
    leaves.Material = Enum.Material.Grass
    leaves.Shape = Enum.PartType.Ball
    leaves.Anchored = true
    leaves.Parent = workspace
    
    -- On garde le tronc en mémoire pour savoir où faire tomber les pommes
    table.insert(trees, trunk)
end

-- 2. LE CYCLE DES POMMES (Une pomme tombe toutes les 15 secondes)
task.spawn(function()
    while task.wait(15) do
        -- On choisit un arbre au hasard
        local randomTree = trees[math.random(1, #trees)]
        
        -- On crée la pomme
        local apple = Instance.new("Part")
        apple.Name = "TestFood" -- Le nom exact que le cerveau du PNJ cherche !
        apple.Size = Vector3.new(1, 1, 1)
        -- Elle tombe juste à côté du tronc
        apple.Position = randomTree.Position + Vector3.new(math.random(-4, 4), -5, math.random(-4, 4))
        apple.Color = Color3.fromRGB(200, 30, 30)
        apple.Shape = Enum.PartType.Ball
        apple.Anchored = true 
        apple.Parent = workspace
        
        -- On lui ajoute le bouton pour que TU puisses la ramasser (le PNJ s'en fiche du bouton)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Ramasser"
        prompt.ObjectText = "Pomme Rouge"
        prompt.HoldDuration = 0.2
        prompt.Parent = apple
        
        prompt.Triggered:Connect(function(player)
            local giveItemEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
            if giveItemEvent then
                giveItemEvent:Fire(player, "Apple", 1)
                apple:Destroy()
            end
        end)
        
        print("Une pomme est tombée d'un arbre !")
    end
end)