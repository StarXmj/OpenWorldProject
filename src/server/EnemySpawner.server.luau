--[ Générateur de PNJ (Correction de l'ordre d'apparition) ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCBrain = require(script.Parent:WaitForChild("NPCBrain"))
local prefab = ReplicatedStorage:WaitForChild("EnemyPrefab")

local function spawnNPC(position)
    local npc = prefab:Clone()
    npc.Name = "Vagabond"
    npc:PivotTo(CFrame.new(position))
    
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored = false end
    end
    
    local root = npc:FindFirstChild("HumanoidRootPart")
    local humanoid = npc:FindFirstChild("Humanoid")
    if not root or not humanoid then return end

    -- LA CORRECTION EST ICI : 
    -- 1. On place d'abord le PNJ dans le monde
    npc.Parent = workspace
    
    -- 2. ENSUITE on force le contrôle par le serveur (plus de bug !)
    root:SetNetworkOwner(nil)

    -- La Barre de Vie
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

    -- La Bulle de Pensée
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

    -- 3. On connecte le cerveau
    NPCBrain.Attach(npc)
end

-- Génération de la meute
for i = 1, 4 do
    local randomX = math.random(-30, 30)
    local randomZ = math.random(-30, 30)
    spawnNPC(Vector3.new(randomX, 5, randomZ))
end