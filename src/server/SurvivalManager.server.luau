local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local sprintEvent = ReplicatedStorage:FindFirstChild("SprintEvent") or Instance.new("RemoteEvent")
sprintEvent.Name = "SprintEvent"
sprintEvent.Parent = ReplicatedStorage
local sprintingPlayers = {}

-- Événement réseau pour boire n'importe où
local drinkEvent = Instance.new("RemoteEvent")
drinkEvent.Name = "DrinkEvent"
drinkEvent.Parent = ReplicatedStorage

sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
    local char = player.Character
    if not char then return end
    if isSprinting and char:GetAttribute("Stamina") > 0 then
        sprintingPlayers[player] = true
        char.Humanoid.WalkSpeed = GameConfig.Entity.SprintSpeed
    else
        sprintingPlayers[player] = false
        char.Humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed
    end
end)

drinkEvent.OnServerEvent:Connect(function(player)
    local char = player.Character
    if char and char:GetAttribute("Thirst") then
        char:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
        character:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
        character:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    end)
end)

-- Boucle de Survie Joueur (Toutes les 5 secondes)
task.spawn(function()
    while task.wait(GameConfig.Survival.TickRate) do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                
                -- FAIM
                if char:GetAttribute("Hunger") then
                    local currentHunger = char:GetAttribute("Hunger")
                    if currentHunger > 0 then 
                        char:SetAttribute("Hunger", currentHunger - GameConfig.Survival.HungerDecay)
                    else 
                        -- Subit les dégâts de faim exacts configurés
                        char.Humanoid.Health -= GameConfig.Survival.StarvationDamage 
                    end
                end
                
                -- SOIF
                if char:GetAttribute("Thirst") then
                    local currentThirst = char:GetAttribute("Thirst")
                    if currentThirst > 0 then 
                        char:SetAttribute("Thirst", currentThirst - GameConfig.Survival.ThirstDecay)
                    else 
                        -- Subit les dégâts de soif exacts configurés
                        char.Humanoid.Health -= GameConfig.Survival.DehydrationDamage 
                    end
                end

            end
        end
    end
end)

-- Boucle d'Endurance
task.spawn(function()
    while task.wait(0.1) do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char:GetAttribute("Stamina") then
                local currentStamina = char:GetAttribute("Stamina")
                local isMoving = char.Humanoid.MoveDirection.Magnitude > 0
                
                if sprintingPlayers[player] and isMoving then
                    local newStamina = math.clamp(currentStamina - (GameConfig.Entity.StaminaDrain * 0.1), 0, GameConfig.Entity.MaxStamina)
                    char:SetAttribute("Stamina", newStamina)
                    if newStamina <= 0 then
                        sprintingPlayers[player] = false
                        char.Humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed
                    end
                else
                    char:SetAttribute("Stamina", math.clamp(currentStamina + (GameConfig.Entity.StaminaRegen * 0.1), 0, GameConfig.Entity.MaxStamina))
                end
            end
        end
    end
end)