--[ Contrôleur du HUD (Heads-Up Display) ]--
-- Ce script crée l'interface visuelle et la met à jour en temps réel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Récupération de la configuration globale
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. CRÉATION DE L'INTERFACE VISUELLE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Barre de Faim (Fond Gris)
local hungerBackground = Instance.new("Frame")
hungerBackground.Size = UDim2.new(0, 200, 0, 20)
hungerBackground.Position = UDim2.new(0.5, -100, 1, -90) -- En bas au centre
hungerBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hungerBackground.BorderSizePixel = 2
hungerBackground.Parent = screenGui

-- Barre de Faim (Remplissage Orange)
local hungerBar = Instance.new("Frame")
hungerBar.Size = UDim2.new(1, 0, 1, 0)
hungerBar.BackgroundColor3 = Color3.fromRGB(220, 120, 30)
hungerBar.BorderSizePixel = 0
hungerBar.Parent = hungerBackground

local hungerText = Instance.new("TextLabel")
hungerText.Size = UDim2.new(1, 0, 1, 0)
hungerText.BackgroundTransparency = 1
hungerText.Text = "Faim"
hungerText.TextColor3 = Color3.fromRGB(255, 255, 255)
hungerText.Font = Enum.Font.SourceSansBold
hungerText.Parent = hungerBackground

-- Barre d'Endurance (Fond Gris)
local staminaBackground = Instance.new("Frame")
staminaBackground.Size = UDim2.new(0, 200, 0, 20)
staminaBackground.Position = UDim2.new(0.5, -100, 1, -60)
staminaBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
staminaBackground.BorderSizePixel = 2
staminaBackground.Parent = screenGui

-- Barre d'Endurance (Remplissage Bleu)
local staminaBar = Instance.new("Frame")
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = staminaBackground

local staminaText = Instance.new("TextLabel")
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = "Endurance"
staminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaText.Font = Enum.Font.SourceSansBold
staminaText.Parent = staminaBackground

-- 2. MISE À JOUR DES BARRES
local function setupUIConnections(character)
    
    -- Fonction interne pour recalculer la taille des barres
    local function refreshBars()
        local currentHunger = character:GetAttribute("Hunger") or GameConfig.Entity.MaxHunger
        local currentStamina = character:GetAttribute("Stamina") or GameConfig.Entity.MaxStamina
        
        -- Calcul du pourcentage (ex: 50 / 100 = 0.5)
        local hungerScale = math.clamp(currentHunger / GameConfig.Entity.MaxHunger, 0, 1)
        local staminaScale = math.clamp(currentStamina / GameConfig.Entity.MaxStamina, 0, 1)
        
        -- TweenSize permet d'animer la barre pour que ça fasse un mouvement fluide
        hungerBar:TweenSize(UDim2.new(hungerScale, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.2, true)
        staminaBar:TweenSize(UDim2.new(staminaScale, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.1, true)
    end

    -- On met à jour une première fois à l'apparition
    refreshBars()

    -- On écoute les changements envoyés par le serveur
    character:GetAttributeChangedSignal("Hunger"):Connect(refreshBars)
    character:GetAttributeChangedSignal("Stamina"):Connect(refreshBars)
end

-- Connexion au personnage actuel
if player.Character then
    setupUIConnections(player.Character)
end

-- Connexion en cas de mort / réapparition
player.CharacterAdded:Connect(setupUIConnections)