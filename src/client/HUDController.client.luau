--[ Contrôleur du HUD Ajustable ]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Fonction utilitaire modifiée pour accepter une position personnalisée
local function createBar(name, customPosition, color, parent)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 200, 0, 20)
    bg.Position = customPosition -- APPLIQUE LA POSITION DE LA CONFIG
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BorderSizePixel = 2
    bg.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = bg

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = name
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.SourceSansBold
    txt.Parent = bg

    return fill
end

-- Création des barres via les positions du GameConfig
local thirstBar = createBar("Soif", GameConfig.UI.ThirstPosition, Color3.fromRGB(0, 200, 255), screenGui)
local hungerBar = createBar("Faim", GameConfig.UI.HungerPosition, Color3.fromRGB(220, 120, 30), screenGui)
local staminaBar = createBar("Endurance", GameConfig.UI.StaminaPosition, Color3.fromRGB(30, 144, 255), screenGui)

-- CADRAN SOLAIRE PERSONNALISABLE
local sundialFrame = Instance.new("Frame")
sundialFrame.Size = UDim2.new(0, 80, 0, 80)
sundialFrame.Position = GameConfig.UI.SundialPosition -- APPLIQUE LA POSITION DE LA CONFIG
sundialFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sundialFrame.BackgroundTransparency = 0.2
sundialFrame.BorderSizePixel = 2
sundialFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = sundialFrame

local timeIcon = Instance.new("TextLabel")
timeIcon.Size = UDim2.new(1, 0, 0.6, 0)
timeIcon.BackgroundTransparency = 1
timeIcon.TextScaled = true
timeIcon.Parent = sundialFrame

local timeText = Instance.new("TextLabel")
timeText.Size = UDim2.new(1, 0, 0.4, 0)
timeText.Position = UDim2.new(0, 0, 0.6, 0)
timeText.BackgroundTransparency = 1
timeText.TextColor3 = Color3.fromRGB(255, 255, 255)
timeText.Font = Enum.Font.Code
timeText.TextScaled = true
timeText.Parent = sundialFrame

RunService.RenderStepped:Connect(function()
    local hours = math.floor(Lighting.ClockTime)
    local minutes = math.floor((Lighting.ClockTime - hours) * 60)
    timeText.Text = string.format("%02d:%02d", hours, minutes)

    if Lighting.ClockTime >= 6 and Lighting.ClockTime <= 18 then
        timeIcon.Text = "☀️"
    else
        timeIcon.Text = "🌙"
    end
end)

local function setupUIConnections(character)
    local function refreshBars()
        local h = character:GetAttribute("Hunger") or 100
        local s = character:GetAttribute("Stamina") or 100
        local t = character:GetAttribute("Thirst") or 100
        
        hungerBar:TweenSize(UDim2.new(math.clamp(h/100,0,1), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.2, true)
        staminaBar:TweenSize(UDim2.new(math.clamp(s/100,0,1), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.1, true)
        thirstBar:TweenSize(UDim2.new(math.clamp(t/100,0,1), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.2, true)
    end

    refreshBars()
    character:GetAttributeChangedSignal("Hunger"):Connect(refreshBars)
    character:GetAttributeChangedSignal("Stamina"):Connect(refreshBars)
    character:GetAttributeChangedSignal("Thirst"):Connect(refreshBars)
end

if player.Character then setupUIConnections(player.Character) end
player.CharacterAdded:Connect(setupUIConnections)