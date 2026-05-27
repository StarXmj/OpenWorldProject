--[ Panel Admin Debug IA V5 - Segmentation & Capacités Dynamiques ]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local selectedEntity = nil
local gpsPart = nil 

-- 🎨 INTERFACE PRINCIPALE
local sg = Instance.new("ScreenGui")
sg.Name = "AdminDebugPanel"
sg.ResetOnSpawn = false
sg.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 380)
mainFrame.Position = UDim2.new(1, -540, 0, 40)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = sg
local uiCorner = Instance.new("UICorner") uiCorner.CornerRadius = UDim.new(0, 8) uiCorner.Parent = mainFrame

-- 🗂️ BOUTON RETRACTABLE (TUCK)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 30)
toggleBtn.Position = UDim2.new(0, -65, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
toggleBtn.Font = Enum.Font.GothamBold toggleBtn.TextSize = 12 toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "CLOSE" toggleBtn.Parent = mainFrame
local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 6) btnCorner.Parent = toggleBtn

local isTucked = false
toggleBtn.MouseButton1Click:Connect(function()
    isTucked = not isTucked
    local targetPos = isTucked and UDim2.new(1, -10, 0, 40) or UDim2.new(1, -540, 0, 40)
    toggleBtn.Text = isTucked and "OPEN" or "CLOSE"
    toggleBtn.BackgroundColor3 = isTucked and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 100, 50)
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end)

-- 📋 BARRE LATÉRALE (Liste Segmentée)
local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 160, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 4
sidebar.Parent = mainFrame
local sidebarLayout = Instance.new("UIListLayout") 
sidebarLayout.Padding = UDim.new(0, 2) 
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder -- ⚠️ IMPORTANT POUR LA SEGMENTATION
sidebarLayout.Parent = sidebar

-- En-têtes de catégorie
local function createHeader(text, layoutOrder)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    header.TextColor3 = Color3.fromRGB(150, 150, 150)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 10
    header.Text = text
    header.LayoutOrder = layoutOrder
    header.Parent = sidebar
    return header
end

local headerNPC = createHeader("--- 👤 ENTITÉS ---", 10)
local headerFlora = createHeader("--- 🌿 ÉCOLOGIE ---", 30)

-- Zone de Détails
local detailsFrame = Instance.new("Frame")
detailsFrame.Size = UDim2.new(1, -160, 1, 0) detailsFrame.Position = UDim2.new(0, 160, 0, 0)
detailsFrame.BackgroundTransparency = 1 detailsFrame.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40) title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 200, 50) title.Font = Enum.Font.GothamBold title.TextSize = 16
title.Text = "🧠 AI & ECOLOGY DASHBOARD" title.Parent = detailsFrame

local gpsBtn = Instance.new("TextButton")
gpsBtn.Size = UDim2.new(0, 100, 0, 25) gpsBtn.Position = UDim2.new(1, -120, 0, 10)
gpsBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255) gpsBtn.Font = Enum.Font.GothamBold
gpsBtn.TextSize = 11 gpsBtn.TextColor3 = Color3.fromRGB(255, 255, 255) gpsBtn.Text = "📍 GPS TRACK" gpsBtn.Parent = detailsFrame
local gpsCorner = Instance.new("UICorner") gpsCorner.CornerRadius = UDim.new(0, 4) gpsCorner.Parent = gpsBtn

local detailsList = Instance.new("UIListLayout") detailsList.Padding = UDim.new(0, 4) detailsList.Parent = detailsFrame
local padding = Instance.new("UIPadding") padding.PaddingLeft = UDim.new(0, 10) padding.PaddingTop = UDim.new(0, 45) padding.Parent = detailsFrame

local labels = {}
local function createRow(name, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20) lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(220, 220, 220) lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = detailsFrame
    labels[name] = lbl
end

createRow("Name", Color3.fromRGB(255, 255, 255))
createRow("DNA", Color3.fromRGB(180, 180, 180))
createRow("Stats", Color3.fromRGB(50, 255, 100))
createRow("State", Color3.fromRGB(255, 100, 100))
createRow("Priority", Color3.fromRGB(255, 150, 50))
createRow("Target", Color3.fromRGB(150, 200, 255))
createRow("Reason", Color3.fromRGB(255, 255, 100))
labels["Reason"].TextWrapped = true labels["Reason"].Size = UDim2.new(1, -20, 0, 60)

-- 🛰️ EXECUTION DE LA BALISE MAP
gpsBtn.MouseButton1Click:Connect(function()
    if not selectedEntity then return end
    local targetPos = selectedEntity:IsA("Model") and selectedEntity:GetPivot().Position or selectedEntity.Position
    if gpsPart then gpsPart:Destroy() end
    gpsPart = Instance.new("Part") gpsPart.Name = "NPC_GPS_Beacon" gpsPart.Anchored = true gpsPart.CanCollide = false
    gpsPart.Size = Vector3.new(2, 500, 2) gpsPart.Position = targetPos + Vector3.new(0, 250, 0)
    gpsPart.Material = Enum.Material.Neon gpsPart.Color = Color3.fromRGB(0, 255, 255) gpsPart.Transparency = 0.4 gpsPart.Parent = workspace
    local hl = Instance.new("Highlight") hl.Adornee = selectedEntity hl.FillColor = Color3.fromRGB(0, 255, 255) hl.FillTransparency = 0.5 hl.Parent = gpsPart
    task.delay(5, function() if gpsPart then gpsPart:Destroy() gpsPart = nil end end)
end)

-- 🔄 Génération de la liste segmentée
local entityButtons = {}
RunService.Heartbeat:Connect(function()
    -- 1. Scan des PNJ (LayoutOrder = 20)
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:GetAttribute("Personality") and not entityButtons[obj] then
            local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40) btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.Gotham btn.TextSize = 11 btn.Text = "👤 " .. obj.Name 
            btn.LayoutOrder = 20 -- Sous l'en-tête NPC
            btn.Parent = sidebar
            btn.MouseButton1Click:Connect(function()
                selectedEntity = obj
                for bObj, b in pairs(entityButtons) do 
                    b.BackgroundColor3 = bObj:GetAttribute("Personality") and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(20, 40, 20)
                end
                btn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            end)
            entityButtons[obj] = btn
        end
    end
    -- 2. Scan de la Flore (LayoutOrder = 40)
    local flora = workspace:FindFirstChild("Flora")
    if flora then
        for _, obj in ipairs(flora:GetChildren()) do
            if obj.Name == "BerryBush" and not entityButtons[obj] then
                local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 28)
                btn.BackgroundColor3 = Color3.fromRGB(20, 40, 20) btn.TextColor3 = Color3.fromRGB(150, 255, 150)
                btn.Font = Enum.Font.Gotham btn.TextSize = 11 btn.Text = "🌿 Buisson" 
                btn.LayoutOrder = 40 -- Sous l'en-tête Écologie
                btn.Parent = sidebar
                btn.MouseButton1Click:Connect(function()
                    selectedEntity = obj
                    for bObj, b in pairs(entityButtons) do 
                        b.BackgroundColor3 = bObj:GetAttribute("Personality") and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(20, 40, 20)
                    end
                    btn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                end)
                entityButtons[obj] = btn
            end
        end
    end
end)

-- 🔄 Boucle de synchronisation du Dashboard
RunService.RenderStepped:Connect(function()
    if selectedEntity and selectedEntity.Parent then
        
        -- SI C'EST UN BUISSON 🌿
       -- SI C'EST UN BUISSON 🌿
        if selectedEntity.Name == "BerryBush" then
            labels["Name"].Text = "📌 Plant: Berry Bush"
            labels["DNA"].Text = "🧬 Type: Natural Resource (Flora)"
            
            -- L'affichage PUR demandé : 1, 2, 3 ou 4.
            local fruits = selectedEntity:GetAttribute("Fruits") or 0
            labels["Stats"].Text = string.format("🍓 Baies prêtes : %d", fruits)
            
            -- Analyse des baies individuelles en cours de pousse
            local growingStats = ""
            local daysToRegrow = GameConfig.Ecology.DaysToRegrow or 0.1
            
            for _, child in ipairs(selectedEntity:GetChildren()) do
                if string.sub(child.Name, 1, 6) == "Berry_" and child:GetAttribute("IsGrown") == false then
                    local progress = child:GetAttribute("RegrowthProgress") or 0
                    local progressPct = math.min(100, (progress / daysToRegrow) * 100)
                    growingStats = growingStats .. string.format("[%d%%] ", math.floor(progressPct))
                end
            end
            
            if growingStats == "" then
                labels["State"].Text = "⚙️ Status : Plein"
            else
                labels["State"].Text = "⚙️ Pousse : " .. growingStats
            end
            
            labels["Priority"].Text = ""
            labels["Target"].Text = ""
            labels["Reason"].Text = "💬 Chaque baie possède son propre cycle de vie organique et grandit indépendamment."
            
        -- SI C'EST UN PNJ 👤
            
        -- SI C'EST UN PNJ 👤
        elseif selectedEntity:GetAttribute("Personality") then
            labels["Name"].Text = "📌 Name: " .. selectedEntity.Name
            labels["DNA"].Text = string.format("🧬 Age: %d | Personality: %s", selectedEntity:GetAttribute("Age") or 0, selectedEntity:GetAttribute("Personality") or "N/A")
            
            local hg = selectedEntity:GetAttribute("Hunger") or 0
            local th = selectedEntity:GetAttribute("Thirst") or 0
            local ft = selectedEntity:GetAttribute("Fatigue") or 0
            labels["Stats"].Text = string.format("📊 Vitals -> 🍖 Faim: %d%% | 💧 Soif: %d%% | 💤 Fatigue: %d%%", math.floor(hg), math.floor(th), math.floor(ft))
            
            labels["State"].Text = "⚙️ Machine State: " .. (selectedEntity:GetAttribute("Debug_State") or "WANDER")
            labels["Priority"].Text = "⚠️ Weight Priority: " .. (selectedEntity:GetAttribute("Debug_Priority") or "LOW")
            labels["Target"].Text = "🎯 Focus Target: " .. (selectedEntity:GetAttribute("Debug_Target") or "None")
            labels["Reason"].Text = "💬 Reason Log:\n" .. (selectedEntity:GetAttribute("Debug_Reason") or "N/A")
        end
    else
        labels["Name"].Text = "Select an entity from the sidebar..."
        labels["DNA"].Text = "" labels["Stats"].Text = "" labels["State"].Text = ""
        labels["Priority"].Text = "" labels["Target"].Text = "" labels["Reason"].Text = ""
    end
end)