--[ Générateur d'Objets au sol ]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local apple = Instance.new("Part")
apple.Name = "TestFood"
apple.Size = Vector3.new(1, 1, 1)
apple.Position = Vector3.new(0, 5, -10)
apple.Color = Color3.fromRGB(200, 30, 30)
apple.Shape = Enum.PartType.Ball
apple.Anchored = true
apple.Parent = workspace

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Ramasser"
prompt.ObjectText = "Pomme Rouge"
prompt.HoldDuration = 0.2
prompt.Parent = apple

prompt.Triggered:Connect(function(player)
    -- On utilise le BindableEvent créé dans InventoryManager
    local giveItemEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
    if giveItemEvent then
        giveItemEvent:Fire(player, "Apple", 1) -- On donne 1 Apple
        print(player.Name .. " a mis une pomme dans son sac !")
        apple:Destroy()
    end
end)