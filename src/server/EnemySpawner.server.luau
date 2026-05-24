--[ Générateur de PNJ sécurisé ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCBrain = require(script.Parent:WaitForChild("NPCBrain"))
local prefab = ReplicatedStorage:WaitForChild("EnemyPrefab")

-- 🛡️ SÉCURITÉ 1 : On attend impérativement que le monde soit fini
print("⏳ Les PNJ attendent la fin de la génération du monde...")
repeat 
    task.wait(0.5) 
until workspace:GetAttribute("WorldGenerated") == true
print("🚀 Le monde est prêt ! Scan des positions des PNJ...")

-- Le laser ne ciblera que le vrai Terrain
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {workspace.Terrain}

local function spawnNPC()
    -- 10 tentatives pour trouver un sol sec (hors de l'eau)
    for attempt = 1, 10 do
        local randomX = math.random(-250, 250)
        local randomZ = math.random(-250, 250)
        
        local origin = Vector3.new(randomX, 150, randomZ)
        local result = workspace:Raycast(origin, Vector3.new(0, -200, 0), raycastParams)
        
        if result and result.Material ~= Enum.Material.Water then
            local npc = prefab:Clone()
            npc.Name = "Vagabond"
            
            -- 🛡️ SÉCURITÉ 2 : On les spawn 10 studs AU-DESSUS du sol pour qu'ils tombent proprement
            npc:PivotTo(CFrame.new(result.Position + Vector3.new(0, 10, 0)))
            
            for _, part in ipairs(npc:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
            
            local root = npc:FindFirstChild("HumanoidRootPart")
            local humanoid = npc:FindFirstChild("Humanoid")
            if not root or not humanoid then return end

            npc.Parent = workspace
            root:SetNetworkOwner(nil) -- Garde le contrôle physique sur le serveur

            -- Interface Vie
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

            -- Interface Bulles de pensée
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

            -- Connexion de l'IA
            NPCBrain.Attach(npc)
            print("✅ Vagabond apparu avec succès aux coordonnées :", randomX, randomZ)
            return 
        end
    end
    
    -- Sécurité ultime : Si après 10 essais le laser n'a trouvé que de l'eau, on le force à spawn au centre de la map (0, 30, 0) pour ne pas perdre un PNJ
    warn("⚠️ Impossible de trouver un sol sec pour ce PNJ. Spawn de secours appliqué.")
    local fallbackNpc = prefab:Clone()
    fallbackNpc.Name = "Vagabond"
    fallbackNpc:PivotTo(CFrame.new(0, 30, 0))
    for _, part in ipairs(fallbackNpc:GetDescendants()) do if part:IsA("BasePart") then part.Anchored = false end end
    fallbackNpc.Parent = workspace
    fallbackNpc.HumanoidRootPart:SetNetworkOwner(nil)
    NPCBrain.Attach(fallbackNpc)
end

-- On lance l'apparition de nos 4 vagabonds
for i = 1, 4 do
    spawnNPC()
end