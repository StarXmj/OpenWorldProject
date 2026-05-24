--[ Gestionnaire de Survie et Moteur d'XP ]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local sprintEvent = ReplicatedStorage:FindFirstChild("SprintEvent") or Instance.new("RemoteEvent")
sprintEvent.Name = "SprintEvent"
sprintEvent.Parent = ReplicatedStorage
local sprintingPlayers = {}

local drinkEvent = ReplicatedStorage:FindFirstChild("DrinkEvent") or Instance.new("RemoteEvent")
drinkEvent.Name = "DrinkEvent"
drinkEvent.Parent = ReplicatedStorage

-- 🌟 LE MOTEUR D'XP GLOBAL (Accessible par tous les autres scripts)
local addXpEvent = ReplicatedStorage:FindFirstChild("AddXPEvent") or Instance.new("BindableEvent")
addXpEvent.Name = "AddXPEvent"
addXpEvent.Parent = ReplicatedStorage

addXpEvent.Event:Connect(function(entity, statName, xpAmount)
    if not entity or not entity.Parent then return end
    
    local currentXP = entity:GetAttribute(statName .. "_XP") or 0
    local currentLevel = entity:GetAttribute(statName .. "_Level") or 1
    
    if currentLevel >= 100 then return end -- Niveau Max
    
    currentXP += xpAmount
    local xpRequired = currentLevel * 50 -- Lv1 = 50xp, Lv2 = 100xp, Lv10 = 500xp...
    
    if currentXP >= xpRequired then
        currentXP -= xpRequired
        currentLevel += 1
        entity:SetAttribute(statName .. "_Level", currentLevel)
        
        -- Si c'est un joueur, on peut lui afficher un message
        local player = Players:GetPlayerFromCharacter(entity)
        if player then print("Niveau Supérieur ! " .. statName .. " est niveau " .. currentLevel) end
    end
    
    entity:SetAttribute(statName .. "_XP", currentXP)
end)

-- 🏃 Gestion de la Vitesse avec Bonus d'Athlétisme
local function updateSpeed(character, player)
    local athleticsLvl = character:GetAttribute("Athletics_Level") or 1
    local speedBonus = (athleticsLvl - 1) * 0.05 -- +0.05 de vitesse par niveau
    
    if sprintingPlayers[player] and character:GetAttribute("Stamina") > 0 then
        character.Humanoid.WalkSpeed = GameConfig.Entity.SprintSpeed + speedBonus
    else
        character.Humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed + speedBonus
    end
end

sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
    local char = player.Character
    if not char then return end
    sprintingPlayers[player] = isSprinting
    updateSpeed(char, player)
end)

drinkEvent.OnServerEvent:Connect(function(player)
    if player.Character and player.Character:GetAttribute("Thirst") then
        player.Character:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:SetAttribute("Hunger", GameConfig.Entity.MaxHunger)
        character:SetAttribute("Stamina", GameConfig.Entity.MaxStamina)
        character:SetAttribute("Thirst", GameConfig.Entity.MaxThirst)
        
        -- 🌟 Initialisation des 4 Stats (Niveau 1, XP 0)
        local stats = {"Athletics", "Strength", "Combat", "Resistance"}
        for _, stat in ipairs(stats) do
            character:SetAttribute(stat .. "_Level", 1)
            character:SetAttribute(stat .. "_XP", 0)
        end
    end)
end)

-- Boucle de Survie (Faim / Soif)
task.spawn(function()
    while task.wait(GameConfig.Survival.TickRate) do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                if char:GetAttribute("Hunger") then
                    local currentHunger = char:GetAttribute("Hunger")
                    if currentHunger > 0 then char:SetAttribute("Hunger", currentHunger - GameConfig.Survival.HungerDecay)
                    else char.Humanoid.Health -= GameConfig.Survival.StarvationDamage end
                end
                
                if char:GetAttribute("Thirst") then
                    local currentThirst = char:GetAttribute("Thirst")
                    if currentThirst > 0 then char:SetAttribute("Thirst", currentThirst - GameConfig.Survival.ThirstDecay)
                    else char.Humanoid.Health -= GameConfig.Survival.DehydrationDamage end
                end
            end
        end
    end
end)

-- Boucle d'Endurance et d'XP d'Athlétisme
task.spawn(function()
    while task.wait(0.1) do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char:GetAttribute("Stamina") then
                local currentStamina = char:GetAttribute("Stamina")
                local isMoving = char.Humanoid.MoveDirection.Magnitude > 0
                
                if sprintingPlayers[player] and isMoving then
                    -- 🌟 GAIN D'XP : Courir augmente l'Athlétisme !
                    addXpEvent:Fire(char, "Athletics", 0.5) 
                    
                    local newStamina = math.clamp(currentStamina - (GameConfig.Entity.StaminaDrain * 0.1), 0, GameConfig.Entity.MaxStamina)
                    char:SetAttribute("Stamina", newStamina)
                    if newStamina <= 0 then
                        sprintingPlayers[player] = false
                        updateSpeed(char, player)
                    end
                else
                    char:SetAttribute("Stamina", math.clamp(currentStamina + (GameConfig.Entity.StaminaRegen * 0.1), 0, GameConfig.Entity.MaxStamina))
                end
            end
        end
    end
end)