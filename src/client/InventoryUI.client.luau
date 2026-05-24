--[ Interface de l'Inventaire ]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local updateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent")
local consumeEvent = ReplicatedStorage:WaitForChild("ConsumeEvent")

-- 1. CRÉATION DU MENU SUR LE COTÉ DROIT
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 200, 0, 300)
container.Position = UDim2.new(1, -220, 0.5, -150) -- À droite au milieu
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BackgroundTransparency = 0.2
container.BorderSizePixel = 2
container.Parent = screenGui

-- Un Layout pour ranger les boutons automatiquement en liste
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = container

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "INVENTAIRE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.Parent = container

-- 2. METTRE À JOUR LA LISTE QUAND LE SERVEUR L'ORDONNE
updateEvent.OnClientEvent:Connect(function(inventoryData)
    
    -- On nettoie les anciens boutons
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- On crée un bouton pour chaque objet possédé
    for itemID, amount in pairs(inventoryData) do
        local itemData = GameConfig.Items[itemID]
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSans
        btn.Text = itemData.Name .. " (x" .. amount .. ")"
        btn.Parent = container
        
        -- Quand le joueur clique sur le bouton
        btn.MouseButton1Click:Connect(function()
            consumeEvent:FireServer(itemID)
        end)
    end
end)