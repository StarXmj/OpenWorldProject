--[ Système de Ciblage Fixé (Ignore accessoires et PrimaryPart) ]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local MAX_INSPECT_DISTANCE = 20 -- Distance max en studs pour inspecter

-- Effet visuel autour du PNJ sélectionné
local selectionHighlight = Instance.new("Highlight")
selectionHighlight.Name = "TargetHighlight"
selectionHighlight.FillTransparency = 1 
selectionHighlight.OutlineColor = Color3.fromRGB(220, 180, 120) 
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

-- 🛡️ CORRECTION : Détection intelligente du clic
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local targetPart = mouse.Target
        
        if targetPart then
            -- FindFirstAncestorOfClass permet de remonter tout l'arbre !
            -- (Même si on clique sur un chapeau, on trouvera le Vagabond)
            local model = targetPart:FindFirstAncestorOfClass("Model")
            
            if model and model:FindFirstChild("Humanoid") and model:GetAttribute("Hunger") and model ~= player.Character then
                
                local char = player.Character
                -- On cherche explicitement le torse sans se fier au "PrimaryPart" de Studio
                local targetRoot = model:FindFirstChild("HumanoidRootPart")
                local charRoot = char and char:FindFirstChild("HumanoidRootPart")
                
                if charRoot and targetRoot then
                    local dist = (charRoot.Position - targetRoot.Position).Magnitude
                    
                    if dist <= MAX_INSPECT_DISTANCE then
                        currentTarget = model
                        selectionHighlight.Parent = currentTarget
                        targetEvent:Fire(currentTarget) -- On envoie le PNJ à l'UI
                        return
                    end
                end
            end
        end
        
        -- Si clic dans le vide, trop loin, ou non-vivant
        clearTarget()
    end
end)

-- Vérification de la distance en continu
RunService.RenderStepped:Connect(function()
    if currentTarget then
        local char = player.Character
        local charRoot = char and char:FindFirstChild("HumanoidRootPart")
        local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")
        
        if charRoot and targetRoot then
            local dist = (charRoot.Position - targetRoot.Position).Magnitude
            if dist > MAX_INSPECT_DISTANCE then
                clearTarget() -- Trop loin, on ferme le menu
            end
        else
            clearTarget() -- Cible détruite ou morte
        end
    end
end)