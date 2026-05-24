--[ Inspecteur de PNJ (Survol de Souris) ]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- 1. CRÉATION DE L'ÉTIQUETTE (Cachée par défaut)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InspectorGUI"
screenGui.Parent = playerGui

local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 150, 0, 70)
tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tooltip.BackgroundTransparency = 0.1
tooltip.BorderSizePixel = 2
tooltip.BorderColor3 = Color3.fromRGB(150, 150, 150)
tooltip.Visible = false -- Caché au début
tooltip.Parent = screenGui

-- On arrondit les angles de l'étiquette
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = tooltip

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 25)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Doré
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.TextSize = 18
nameLabel.Parent = tooltip

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 0, 40)
statsLabel.Position = UDim2.new(0, 0, 0, 25)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 14
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = tooltip

-- 2. BOUCLE DE DÉTECTION (Se lance à chaque image du jeu)
RunService.RenderStepped:Connect(function()
    local target = mouse.Target
    
    -- Si la souris pointe sur un objet qui fait partie d'un modèle
    if target and target.Parent then
        local model = target.Parent
        
        -- On vérifie si ce modèle est un PNJ (S'il a une Faim et un nom de Vagabond)
        if model.Name == "Vagabond" and model:GetAttribute("Hunger") and model:GetAttribute("Stamina") then
            
            -- On affiche l'étiquette
            tooltip.Visible = true
            
            -- On décale légèrement l'étiquette pour qu'elle ne soit pas sous le curseur
            tooltip.Position = UDim2.new(0, mouse.X + 15, 0, mouse.Y + 15)
            
            -- On met à jour les textes avec les vraies valeurs du PNJ
            nameLabel.Text = model.Name
            
            local faim = math.floor(model:GetAttribute("Hunger"))
            local endurance = math.floor(model:GetAttribute("Stamina"))
            
            statsLabel.Text = "🍖 Faim : " .. faim .. " / 100\n⚡ Endu : " .. endurance .. " / 100"
            
        else
            -- Si on ne pointe pas sur un PNJ, on cache l'étiquette
            tooltip.Visible = false
        end
    else
        tooltip.Visible = false
    end
end)