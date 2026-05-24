--[ Gestionnaire Central des Inventaires ]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- 1. CRÉATION DES PONTS DE COMMUNICATION
-- Pour mettre à jour l'écran du joueur
local updateEvent = Instance.new("RemoteEvent")
updateEvent.Name = "InventoryUpdateEvent"
updateEvent.Parent = ReplicatedStorage

-- Pour que le joueur dise "Je veux manger ça"
local consumeEvent = Instance.new("RemoteEvent")
consumeEvent.Name = "ConsumeEvent"
consumeEvent.Parent = ReplicatedStorage

-- Pour que les autres scripts du serveur puissent donner des objets
local giveItemEvent = Instance.new("BindableEvent")
giveItemEvent.Name = "GiveItemEvent"
giveItemEvent.Parent = ReplicatedStorage

-- 2. LA MÉMOIRE DES INVENTAIRES
local playerInventories = {} -- Format: { [Player] = { Apple = 2, Sword = 1 } }

Players.PlayerAdded:Connect(function(player)
    playerInventories[player] = {} -- Inventaire vide au début
end)

Players.PlayerRemoving:Connect(function(player)
    playerInventories[player] = nil -- On nettoie la mémoire quand il quitte
end)

-- 3. AJOUTER UN OBJET (Appelé par le monde)
giveItemEvent.Event:Connect(function(player, itemID, amount)
    local inv = playerInventories[player]
    if inv then
        inv[itemID] = (inv[itemID] or 0) + amount
        -- On prévient le client que son inventaire a changé
        updateEvent:FireClient(player, inv)
    end
end)

-- 4. UTILISER UN OBJET (Appelé par le joueur via un clic)
consumeEvent.OnServerEvent:Connect(function(player, itemID)
    local inv = playerInventories[player]
    
    -- Si le joueur a bien l'objet
    if inv and inv[itemID] and inv[itemID] > 0 then
        local itemData = GameConfig.Items[itemID]
        
        -- Si c'est un objet qui se mange
        if itemData and itemData.Type == "Consumable" then
            
            -- 1. On le retire de l'inventaire
            inv[itemID] -= 1
            if inv[itemID] <= 0 then inv[itemID] = nil end
            
            -- 2. On applique l'effet (Faim)
            local char = player.Character
            if char and char:GetAttribute("Hunger") then
                local newHunger = math.clamp(char:GetAttribute("Hunger") + itemData.RestoreValue, 0, GameConfig.Entity.MaxHunger)
                char:SetAttribute("Hunger", newHunger)
            end
            
            -- 3. On met à jour l'écran
            updateEvent:FireClient(player, inv)
        end
    end
end)