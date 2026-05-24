--[ Générateur de PNJ (Adapté au Terrain Procédural) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCBrain = require(script.Parent:WaitForChild("NPCBrain"))
local prefab = ReplicatedStorage:WaitForChild("EnemyPrefab")

-- On attend que le terrain ET la nature soient générés
task.wait(5)

-- On paramètre notre laser pour qu'il détecte bien l'eau (pour éviter de les faire spawn sous l'eau)
local raycastParams = RaycastParams.new()
raycastParams.IgnoreWater = false

local function spawnNPC()
    -- Le script va faire jusqu'à 10 tentatives pour trouver un sol valide
    for attempt = 1, 10 do
        local randomX = math.random(-200, 200)
        local randomZ = math.random(-200, 200)
        
        local origin = Vector3.new(randomX, 150, randomZ)
        local result = workspace:Raycast(origin, Vector3.new(0, -200, 0), raycastParams)
        
        -- Si on a touché le sol ET que ce n'est PAS de l'eau
        if result and result.Material ~= Enum.Material.Water then
            
            local npc = prefab:Clone()
            npc.Name = "Vagabond"
            
            -- On le place exactement à la position touchée par le laser, + 3 en hauteur pour ses jambes
            npc:PivotTo(CFrame.new(result.Position + Vector3.new(0, 3, 0)))
            
            for _, part in ipairs(npc:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
            
            local root = npc:FindFirstChild("HumanoidRootPart")
            local humanoid = npc:FindFirstChild("Humanoid")
            if not root or not humanoid then return end

            npc.Parent = workspace
            root:SetNetworkOwner(nil)

            -- Interface
            local healthGui = Instance.new("BillboardGui")
            healthGui.Size = UDim2.new(0, 100, 0, 20)
            healthGui.StudsOffset = Vector3.new(0, 3, 0)
            healthGui.AlwaysOnTop = true
            healthGui.Parent = root

            local healthText = Instance.new("TextLabel")
            healthText.Size = UDim2.new(1, 0, 1, 0)
            healthText.BackgroundTransparency = 1
            healthText.TextColor3 = Color3.fromRGB(255, 50, 50)
            healthText.Font = Enum.Font.SourceSansBold
            healthText.TextScaled = true
            healthText.Parent = healthGui
            healthText.Text = humanoid.Health .. " / " .. humanoid.MaxHealth

            humanoid.HealthChanged:Connect(function(health)
                healthText.Text = math.floor(health) .. " / " .. humanoid.MaxHealth
                if health <= 0 then npc:Destroy() end
            end)

            local thoughtGui = Instance.new("BillboardGui")
            thoughtGui.Name = "ThoughtGui"
            thoughtGui.Size = UDim2.new(0, 120, 0, 30)
            thoughtGui.StudsOffset = Vector3.new(0, 4.5, 0)
            thoughtGui.AlwaysOnTop = true
            thoughtGui.Parent = root

            local thoughtText = Instance.new("TextLabel")
            thoughtText.Name = "ThoughtText"
            thoughtText.Size = UDim2.new(1, 0, 1, 0)
            thoughtText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            thoughtText.BackgroundTransparency = 0.2
            thoughtText.TextColor3 = Color3.fromRGB(30, 30, 30)
            thoughtText.Font = Enum.Font.GothamBold
            thoughtText.TextScaled = true
            thoughtText.Text = "..."
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.3, 0)
            corner.Parent = thoughtText
            thoughtText.Parent = thoughtGui

            NPCBrain.Attach(npc)
            
            -- Dès qu'un vagabond a bien été placé, on stoppe les tentatives de cette boucle
            return 
        end
    end
end

-- On génère nos 4 vagabonds
for i = 1, 4 do
    spawnNPC()
end