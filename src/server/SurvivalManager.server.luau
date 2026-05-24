local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- 1. CRÉATION DU PONT DE COMMUNICATION (RemoteEvent)
local sprintEvent = Instance.new("RemoteEvent")
sprintEvent.Name = "SprintEvent"
sprintEvent.Parent = ReplicatedStorage

local sprintingPlayers = {} -- Dictionnaire pour savoir qui court

-- 2. ÉCOUTE DE LA TOUCHE SHIFT
sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    local currentStamina = char:GetAttribute("Stamina")
    
    if isSprinting and currentStamina > 0 then
        sprintingPlayers[player] = true
        humanoid.WalkSpeed = GameConfig.Entity.SprintSpeed
    else
        sprintingPlayers[player] = false
        humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed
    end
end)

-- 3. ATTRIBUTION DES STATS À L'APPARITION
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
        character:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
    end)
end)

-- 4. BOUCLE DE FAIM (Toutes les 5 secondes)
task.spawn(function()
    while task.wait(GameConfig.Survival.TickRate) do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:GetAttribute("Hunger") then
                local currentHunger = char:GetAttribute("Hunger")
                if currentHunger > 0 then
                    char:SetAttribute("Hunger", currentHunger - GameConfig.Survival.HungerDecay)
                else
                    char.Humanoid.Health -= GameConfig.Survival.StarvationDamage
                end
            end
        end
    end
end)

-- 5. BOUCLE D'ENDURANCE (Toutes les 0.1 secondes pour la fluidité)
task.spawn(function()
    while task.wait(0.1) do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char:GetAttribute("Stamina") then
                local currentStamina = char:GetAttribute("Stamina")
                local isMoving = char.Humanoid.MoveDirection.Magnitude > 0
                
                -- Si le joueur veut courir, qu'il a de l'endurance, et qu'il avance vraiment
                if sprintingPlayers[player] and isMoving then
                    local newStamina = math.clamp(currentStamina - (GameConfig.Entity.StaminaDrain * 0.1), 0, GameConfig.Entity.MaxStamina)
                    char:SetAttribute("Stamina", newStamina)
                    
                    -- S'il n'a plus d'endurance, on le force à marcher
                    if newStamina <= 0 then
                        sprintingPlayers[player] = false
                        char.Humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed
                    end
                else
                    -- Sinon, il récupère son endurance
                    local newStamina = math.clamp(currentStamina + (GameConfig.Entity.StaminaRegen * 0.1), 0, GameConfig.Entity.MaxStamina)
                    char:SetAttribute("Stamina", newStamina)
                end
            end
        end
    end
end)