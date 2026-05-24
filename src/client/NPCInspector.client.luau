--[ Inspecteur de PNJ complet (Survol de Souris) ]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InspectorGUI"
screenGui.Parent = playerGui

local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 160, 0, 85) -- Légèrement agrandi pour accueillir la soif
tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tooltip.BackgroundTransparency = 0.1
tooltip.BorderSizePixel = 2
tooltip.BorderColor3 = Color3.fromRGB(150, 150, 150)
tooltip.Visible = false
tooltip.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = tooltip

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 25)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.TextSize = 18
nameLabel.Parent = tooltip

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 0, 55)
statsLabel.Position = UDim2.new(0, 0, 0, 25)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 14
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = tooltip

RunService.RenderStepped:Connect(function()
    local target = mouse.Target
    
    if target and target.Parent then
        local model = target.Parent
        
        -- AJOUT VÉRIFICATION DE LA SOIF DANS LES ATTRIBUTS
        if model.Name == "Vagabond" and model:GetAttribute("Hunger") and model:GetAttribute("Thirst") then
            tooltip.Visible = true
            tooltip.Position = UDim2.new(0, mouse.X + 15, 0, mouse.Y + 15)
            
            nameLabel.Text = model.Name
            
            local faim = math.floor(model:GetAttribute("Hunger"))
            local soif = math.floor(model:GetAttribute("Thirst"))
            local endurance = math.floor(model:GetAttribute("Stamina") or 100)
            
            -- TEXTE MIS À JOUR
            statsLabel.Text = "🍖 Faim : " .. faim .. " / 100\n💧 Soif : " .. soif .. " / 100\n⚡ Endu : " .. endurance .. " / 100"
        else
            tooltip.Visible = false
        end
    else
        tooltip.Visible = false
    end
end)