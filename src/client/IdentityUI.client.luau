--[ Interface d'Identité Avancée et Raccourcis ]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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

-- COULEURS THÉMATIQUES KENSHI (Brut, Sombre, Cuivré)
local BG_COLOR = Color3.fromRGB(20, 20, 20)
local ACCENT_COLOR = Color3.fromRGB(210, 160, 90)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local PANEL_COLOR = Color3.fromRGB(35, 35, 35)

------------------------------------------------------------------------
-- 1. LA COLONNE DE RAPPELLS DES TOUCHES (À GAUCHE DE L'ÉCRAN)
------------------------------------------------------------------------
local leftColumn = Instance.new("Frame")
leftColumn.Size = UDim2.new(0, 180, 0, 180)
leftColumn.Position = UDim2.new(0, 15, 0.5, -90)
leftColumn.BackgroundColor3 = BG_COLOR
leftColumn.BackgroundTransparency = 0.2
leftColumn.BorderSizePixel = 1
leftColumn.BorderColor3 = ACCENT_COLOR
leftColumn.Parent = screenGui

local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 6)
leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
leftLayout.Parent = leftColumn

local leftTitle = Instance.new("TextLabel")
leftTitle.Size = UDim2.new(1, 0, 0, 30)
leftTitle.BackgroundTransparency = 1
leftTitle.Text = "🎛️ COMMANDES"
leftTitle.TextColor3 = ACCENT_COLOR
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 14
leftTitle.Parent = leftColumn

local function createKeyReminder(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.9, 0, 0, 25)
    lbl.BackgroundColor3 = PANEL_COLOR
    lbl.TextColor3 = TEXT_COLOR
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 13
    lbl.Text = "  " .. text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = lbl
    lbl.Parent = leftColumn
end

createKeyReminder("[ C ] Fiche d'Identité")
createKeyReminder("[ I ] Sac à Dos")
createKeyReminder("[ Clic PNJ ] Inspecter (20m)")
createKeyReminder("[ Shift ] Courir / Sprint")

------------------------------------------------------------------------
-- STRUCTURATIONS DES FICHES DE STATS (Miroir Joueur / PNJ)
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

local function refreshCardData(cardFrame, model)
    if not model or not model:FindFirstChild("Humanoid") then return end
    local container = cardFrame:FindFirstChild("StatsContainer")
    if not container then return end

    -- Vie
    local hp = math.floor(model.Humanoid.Health)
    local maxHp = math.floor(model.Humanoid.MaxHealth)
    container.Health.Value.Text = hp .. " / " .. maxHp .. " HP "
    
    -- Faim / Soif
    local faim = math.floor(model:GetAttribute("Hunger") or 100)
    local soif = math.floor(model:GetAttribute("Thirst") or 100)
    container.Survival.Value.Text = "F:" .. faim .. " | S:" .. soif .. " "

    -- Les 4 compétences Kenshi
    local stats = {"Athletics", "Strength", "Combat", "Resistance"}
    for _, stat in ipairs(stats) do
        local lvl = model:GetAttribute(stat .. "_Level") or 1
        local xp = math.floor(model:GetAttribute(stat .. "_XP") or 0)
        container[stat].Value.Text = "Lv." .. lvl .. " (" .. xp .. "xp) "
    end
end

------------------------------------------------------------------------
-- 2. LE GRAND MENU CENTRAL DU JOUEUR (STATS + INVENTAIRE)
------------------------------------------------------------------------
local mainMenu = Instance.new("Frame")
mainMenu.Size = UDim2.new(0, 450, 0, 360)
mainMenu.Position = UDim2.new(0.5, -225, 0.5, -180) -- Plein centre
mainMenu.BackgroundColor3 = BG_COLOR
mainMenu.BackgroundTransparency = 0.1
mainMenu.BorderSizePixel = 2
mainMenu.BorderColor3 = ACCENT_COLOR
mainMenu.Visible = false
mainMenu.Parent = screenGui

-- Barre des Onglets
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

-- Panneau de Contenu des Onglets
local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(1, 0, 1, -40)
statsPanel.Position = UDim2.new(0, 0, 0, 40)
statsPanel.BackgroundTransparency = 1
statsPanel.Parent = mainMenu
populateStatsRows(statsPanel)

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

-- Logique des Onglets
btnStats.MouseButton1Click:Connect(function()
    statsPanel.Visible = true btnInventory.Visible = false
    btnStats.TextColor3 = ACCENT_COLOR btnInventory.TextColor3 = TEXT_COLOR
end)

btnInventory.MouseButton1Click:Connect(function()
    statsPanel.Visible = false inventoryPanel.Visible = true
    btnInventory.TextColor3 = ACCENT_COLOR btnStats.TextColor3 = TEXT_COLOR
end)

-- Raccourcis Clavier du Joueur (C et I)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.C then
        if mainMenu.Visible and statsPanel.Visible then mainMenu.Visible = false
        else mainMenu.Visible = true btnStats:Click() end
    elseif input.KeyCode == Enum.KeyCode.I then
        if mainMenu.Visible and inventoryPanel.Visible then mainMenu.Visible = false
        else mainMenu.Visible = true btnInventory:Click() end
    end
end)

-- Boucle de mise à jour de notre propre fiche d'identité
RunService.RenderStepped:Connect(function()
    if mainMenu.Visible and statsPanel.Visible and player.Character then
        refreshCardData(statsPanel, player.Character)
    end
end)

-- Actualisation de l'inventaire du joueur (liaison d'événements réseau)
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
targetMenu.Position = UDim2.new(1, -340, 0.5, -155) -- Positionné à droite de l'écran
targetMenu.BackgroundColor3 = BG_COLOR
targetMenu.BackgroundTransparency = 0.1
targetMenu.BorderSizePixel = 2
targetMenu.BorderColor3 = Color3.fromRGB(220, 100, 100) -- Rougeâtre/Alerte pour la cible
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

-- Liaison avec le TargetManager
local targetConnection = nil
targetEvent.Event:Connect(function(targetModel)
    if targetConnection then targetConnection:Disconnect() end
    
    if targetModel then
        targetMenu.Visible = true
        targetTitle.Text = "👤 " .. string.upper(targetModel.Name)
        
        -- Rafraîchissement initial
        refreshCardData(targetMenu, targetModel)
        
        -- Boucle d'écoute pour actualiser les stats du PNJ s'il prend des coups ou s'entraîne !
        targetConnection = targetModel.AttributeChanged:Connect(function()
            refreshCardData(targetMenu, targetModel)
        end)
    else
        targetMenu.Visible = false
    end
end)