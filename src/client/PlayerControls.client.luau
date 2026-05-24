local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- On attend que le serveur ait créé notre pont de communication
local sprintEvent = ReplicatedStorage:WaitForChild("SprintEvent")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        -- On envoie un signal au serveur : VRAI (je veux courir)
        sprintEvent:FireServer(true)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        -- On envoie un signal au serveur : FAUX (j'arrête de courir)
        sprintEvent:FireServer(false)
    end
end)