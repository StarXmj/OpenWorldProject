--[ Système de Ciblage par Clic et Portée ]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local MAX_INSPECT_DISTANCE = 20 -- Distance max en studs pour inspecter

-- Effet visuel autour du PNJ sélectionné
local selectionHighlight = Instance.new("Highlight")
selectionHighlight.Name = "TargetHighlight"
selectionHighlight.FillTransparency = 1 -- Intérieur transparent
selectionHighlight.OutlineColor = Color3.fromRGB(220, 180, 120) -- Couleur bronze/Kenshi
selectionHighlight.OutlineTransparency = 0
selectionHighlight.Parent = script

local currentTarget = nil

-- Événement interne pour prévenir l'interface
local targetEvent = Instance.new("BindableEvent")
targetEvent.Name = "TargetSelectedEvent"
targetEvent.Parent = player:WaitForChild("PlayerScripts")

local function clearTarget()
    currentTarget = nil
    selectionHighlight.Parent = script
    targetEvent:Fire(nil)
end

-- Détection du clic de souris
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local targetPart = mouse.Target
        
        if targetPart and targetPart.Parent and targetPart.Parent:FindFirstChild("Humanoid") then
            local model = targetPart.Parent
            
            -- On vérifie s'il s'agit d'une entité vivante autre que nous-même
            if model:GetAttribute("Hunger") and model ~= player.Character then
                local char = player.Character
                if char and char.PrimaryPart and model.PrimaryPart then
                    local dist = (char.PrimaryPart.Position - model.PrimaryPart.Position).Magnitude
                    
                    if dist <= MAX_INSPECT_DISTANCE then
                        currentTarget = model
                        selectionHighlight.Parent = currentTarget
                        targetEvent:Fire(currentTarget) -- On envoie le PNJ à l'UI
                        return
                    end
                end
            end
        end
        
        -- Si clic dans le vide ou trop loin, on décible
        clearTarget()
    end
end)

-- Vérification de la distance en continu
RunService.RenderStepped:Connect(function()
    if currentTarget then
        if currentTarget.PrimaryPart and player.Character and player.Character.PrimaryPart then
            local dist = (player.Character.PrimaryPart.Position - currentTarget.PrimaryPart.Position).Magnitude
            if dist > MAX_INSPECT_DISTANCE then
                clearTarget() -- Trop loin, on ferme le menu
            end
        else
            clearTarget() -- Cible détruite ou morte
        end
    end
end)