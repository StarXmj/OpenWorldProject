--[ Interface d'Identité Avancée et Raccourcis Cliquables ]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local targetEvent = player:WaitForChild("PlayerScripts"):WaitForChild("TargetSelectedEvent")
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent")
local consumeEvent = ReplicatedStorage:WaitForChild("ConsumeEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedIdentityGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- COULEURS THÉMATIQUES
local BG_COLOR = Color3.fromRGB(20, 20, 20)
local ACCENT_COLOR = Color3.fromRGB(210, 160, 90)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local PANEL_COLOR = Color3.fromRGB(35, 35, 35)

------------------------------------------------------------------------
-- 1. TEXTES FLOTTANTS CLIQUABLES (À GAUCHE DE L'ÉCRAN)
------------------------------------------------------------------------
local leftColumn = Instance.new("Frame")
leftColumn.Size = UDim2.new(0, 200, 0, 180)
leftColumn.Position = UDim2.new(0, 15, 0.5, -90)
leftColumn.BackgroundTransparency = 1 -- 🛡️ CORRECTION : Fond 100% invisible
leftColumn.Parent = screenGui

local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 10)
leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
leftLayout.Parent = leftColumn

-- Fonction pour créer un texte flottant cliquable
local function createKeyReminder(text, clickAction)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundTransparency = 1 -- 🛡️ CORRECTION : Pas de fond de bouton
    btn.TextColor3 = TEXT_COLOR
    btn.TextStrokeTransparency = 0 -- Ajoute un contour noir pour être toujours lisible !
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = leftColumn

    -- Effet visuel au survol de la souris
    btn.MouseEnter:Connect(function() btn.TextColor3 = ACCENT_COLOR end)
    btn.MouseLeave:Connect(function() btn.TextColor3 = TEXT_COLOR end)

    if clickAction then
        btn.MouseButton1Click:Connect(clickAction)
    end
end

------------------------------------------------------------------------
-- 2. LE GRAND MENU CENTRAL DU JOUEUR (STATS + INVENTAIRE)
------------------------------------------------------------------------
local mainMenu = Instance.new("Frame")
mainMenu.Size = UDim2.new(0, 450, 0, 360)
mainMenu.Position = UDim2.new(0.5, -225, 0.5, -180) 
mainMenu.BackgroundColor3 = BG_COLOR
mainMenu.BackgroundTransparency = 0.1
mainMenu.BorderSizePixel = 2
mainMenu.BorderColor3 = ACCENT_COLOR
mainMenu.Visible = false
mainMenu.Parent = screenGui

local tabHeader = Instance.new("Frame")
tabHeader.Size = UDim2.new(1, 0, 0, 40)
tabHeader.BackgroundColor3 = PANEL_COLOR
tabHeader.BorderSizePixel = 0
tabHeader.Parent = mainMenu

local btnStats = Instance.new("TextButton")
btnStats.Size = UDim2.new(0.5, 0, 1, 0)
btnStats.BackgroundTransparency = 1
btnStats.Text = "🪪 FICHE PERSONNAGE"
btnStats.TextColor3 = ACCENT_COLOR
btnStats.Font = Enum.Font.GothamBold
btnStats.TextSize = 14
btnStats.Parent = tabHeader

local btnInventory = Instance.new("TextButton")
btnInventory.Size = UDim2.new(0.5, 0, 1, 0)
btnInventory.Position = UDim2.new(0.5, 0, 0, 0)
btnInventory.BackgroundTransparency = 1
btnInventory.Text = "🎒 SAC À DOS"
btnInventory.TextColor3 = TEXT_COLOR
btnInventory.Font = Enum.Font.GothamBold
btnInventory.TextSize = 14
btnInventory.Parent = tabHeader

local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(1, 0, 1, -40)
statsPanel.Position = UDim2.new(0, 0, 0, 40)
statsPanel.BackgroundTransparency = 1
statsPanel.Parent = mainMenu

local inventoryPanel = Instance.new("ScrollingFrame")
inventoryPanel.Size = UDim2.new(1, 0, 1, -50)
inventoryPanel.Position = UDim2.new(0, 0, 0, 45)
inventoryPanel.BackgroundTransparency = 1
inventoryPanel.CanvasSize = UDim2.new(0, 0, 2, 0)
inventoryPanel.Visible = false
inventoryPanel.Parent = mainMenu

local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = UDim2.new(0, 190, 0, 45)
invGrid.Padding = UDim2.new(0, 15, 0, 10)
invGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
invGrid.Parent = inventoryPanel

-- FONCTIONS D'OUVERTURE ET DE BASCULE DES MENUS
local function openStats()
    statsPanel.Visible = true 
    inventoryPanel.Visible = false
    btnStats.TextColor3 = ACCENT_COLOR 
    btnInventory.TextColor3 = TEXT_COLOR
end

local function openInventory()
    statsPanel.Visible = false 
    inventoryPanel.Visible = true
    btnInventory.TextColor3 = ACCENT_COLOR 
    btnStats.TextColor3 = TEXT_COLOR
end

local function toggleStats()
    if mainMenu.Visible and statsPanel.Visible then 
        mainMenu.Visible = false
    else 
        mainMenu.Visible = true 
        openStats() 
    end
end

local function toggleInventory()
    if mainMenu.Visible and inventoryPanel.Visible then 
        mainMenu.Visible = false
    else 
        mainMenu.Visible = true 
        openInventory() 
    end
end

-- Création des textes cliquables sur la gauche (Liés aux fonctions ci-dessus)
createKeyReminder("👤 [ C ] Personnage", toggleStats)
createKeyReminder("🎒 [ I ] Sac à Dos", toggleInventory)
createKeyReminder("🔍 [ Clic ] Inspecter PNJ", nil)
createKeyReminder("🏃 [ Shift ] Sprint", nil)

btnStats.MouseButton1Click:Connect(openStats)
btnInventory.MouseButton1Click:Connect(openInventory)

-- Raccourcis Clavier sécurisés
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.C then toggleStats()
    elseif input.KeyCode == Enum.KeyCode.I then toggleInventory() end
end)

------------------------------------------------------------------------
-- STRUCTURATIONS DES FICHES DE STATS (Communes au Joueur et PNJ)
------------------------------------------------------------------------
local function populateStatsRows(cardFrame)
    local container = Instance.new("Frame")
    container.Name = "StatsContainer"
    container.Size = UDim2.new(1, 0, 1, -50)
    container.Position = UDim2.new(0, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = cardFrame

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay.Parent = container

    local function createRow(name, id)
        local row = Instance.new("Frame")
        row.Name = id
        row.Size = UDim2.new(0.92, 0, 0, 32)
        row.BackgroundColor3 = PANEL_COLOR
        row.BorderSizePixel = 0
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = row

        local titleTxt = Instance.new("TextLabel")
        titleTxt.Name = "Title"
        titleTxt.Size = UDim2.new(0.5, 0, 1, 0)
        titleTxt.BackgroundTransparency = 1
        titleTxt.Text = "  " .. name
        titleTxt.TextColor3 = TEXT_COLOR
        titleTxt.Font = Enum.Font.SourceSansBold
        titleTxt.TextSize = 14
        titleTxt.TextXAlignment = Enum.TextXAlignment.Left
        titleTxt.Parent = row

        local valueTxt = Instance.new("TextLabel")
        valueTxt.Name = "Value"
        valueTxt.Size = UDim2.new(0.5, -5, 1, 0)
        valueTxt.Position = UDim2.new(0.5, 0, 0, 0)
        valueTxt.BackgroundTransparency = 1
        valueTxt.Text = "Lv.1"
        valueTxt.TextColor3 = ACCENT_COLOR
        valueTxt.Font = Enum.Font.Code
        valueTxt.TextSize = 14
        valueTxt.TextXAlignment = Enum.TextXAlignment.Right
        valueTxt.Parent = row

        row.Parent = container
    end

    createRow("❤️ Condition Physique", "Health")
    createRow("🍖 Énergie (Faim/Soif)", "Survival")
    createRow("🏃 Athlétisme", "Athletics")
    createRow("💪 Force Corporelle", "Strength")
    createRow("⚔️ Maîtrise du Combat", "Combat")
    createRow("🛡️ Résistance aux Chocs", "Resistance")
end

populateStatsRows(statsPanel)

local function refreshCardData(cardFrame, model)
    if not model or not model:FindFirstChild("Humanoid") then return end
    local container = cardFrame:FindFirstChild("StatsContainer")
    if not container then return end

    local hp = math.floor(model.Humanoid.Health)
    local maxHp = math.floor(model.Humanoid.MaxHealth)
    container.Health.Value.Text = hp .. " / " .. maxHp .. " HP "
    
    local faim = math.floor(model:GetAttribute("Hunger") or 100)
    local soif = math.floor(model:GetAttribute("Thirst") or 100)
    container.Survival.Value.Text = "F:" .. faim .. " | S:" .. soif .. " "

    local stats = {"Athletics", "Strength", "Combat", "Resistance"}
    for _, stat in ipairs(stats) do
        local lvl = model:GetAttribute(stat .. "_Level") or 1
        local xp = math.floor(model:GetAttribute(stat .. "_XP") or 0)
        container[stat].Value.Text = "Lv." .. lvl .. " (" .. xp .. "xp) "
    end
end

RunService.RenderStepped:Connect(function()
    if mainMenu.Visible and statsPanel.Visible and player.Character then
        refreshCardData(statsPanel, player.Character)
    end
end)

inventoryUpdateEvent.OnClientEvent:Connect(function(inventoryData)
    for _, child in ipairs(inventoryPanel:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    
    for itemID, amount in pairs(inventoryData) do
        local itemData = GameConfig.Items[itemID]
        if itemData then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 180, 0, 40)
            btn.BackgroundColor3 = PANEL_COLOR
            btn.TextColor3 = TEXT_COLOR
            btn.Font = Enum.Font.SourceSansBold
            btn.TextSize = 14
            btn.Text = " " .. itemData.Name .. " (x" .. amount .. ")"
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = btn
            btn.Parent = inventoryPanel
            
            btn.MouseButton1Click:Connect(function() consumeEvent:FireServer(itemID) end)
        end
    end
end)

------------------------------------------------------------------------
-- 3. LA FICHE DE LA CIBLE SÉLECTIONNÉE (À DROITE DE L'ÉCRAN)
------------------------------------------------------------------------
local targetMenu = Instance.new("Frame")
targetMenu.Size = UDim2.new(0, 320, 0, 310)
targetMenu.Position = UDim2.new(1, -340, 0.5, -155)
targetMenu.BackgroundColor3 = BG_COLOR
targetMenu.BackgroundTransparency = 0.1
targetMenu.BorderSizePixel = 2
targetMenu.BorderColor3 = Color3.fromRGB(220, 100, 100)
targetMenu.Visible = false
targetMenu.Parent = screenGui

local targetTitle = Instance.new("TextLabel")
targetTitle.Size = UDim2.new(1, 0, 0, 40)
targetTitle.BackgroundColor3 = PANEL_COLOR
targetTitle.Text = "INSPECTER CIBLE"
targetTitle.TextColor3 = Color3.fromRGB(220, 100, 100)
targetTitle.Font = Enum.Font.GothamBold
targetTitle.TextSize = 14
targetTitle.Parent = targetMenu

populateStatsRows(targetMenu)

local targetConnection = nil
targetEvent.Event:Connect(function(targetModel)
    if targetConnection then targetConnection:Disconnect() end
    
    if targetModel then
        targetMenu.Visible = true
        targetTitle.Text = "👤 " .. string.upper(targetModel.Name)
        refreshCardData(targetMenu, targetModel)
        targetConnection = targetModel.AttributeChanged:Connect(function()
            refreshCardData(targetMenu, targetModel)
        end)
    else
        targetMenu.Visible = false
    end
end)