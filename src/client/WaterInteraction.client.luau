--[ Interaction d'Eau Optimisée Globale (Client) ]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- On crée une cible d'interaction invisible unique pour le joueur
local waterTarget = Instance.new("Part")
waterTarget.Size = Vector3.new(2, 2, 2)
waterTarget.Transparency = 1
waterTarget.CanCollide = false
waterTarget.Anchored = true
waterTarget.Parent = workspace

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Boire"
prompt.ObjectText = "Eau naturelle"
prompt.HoldDuration = 0.5
prompt.Enabled = false
prompt.Parent = waterTarget

RunService.RenderStepped:Connect(function()
    local char = player.Character
    if char and char.PrimaryPart then
        -- Laser à 3 mètres devant les pieds du joueur
        local origin = char.PrimaryPart.Position + (char.PrimaryPart.CFrame.LookVector * 3)
        
        local rayParams = RaycastParams.new()
        rayParams.IgnoreWater = false
        rayParams.FilterDescendantsInstances = {char, waterTarget}
        
        local result = workspace:Raycast(origin, Vector3.new(0, -6, 0), rayParams)
        
        -- Si c'est de l'eau, on déplace le bouton et on l'allume !
        if result and result.Material == Enum.Material.Water then
            waterTarget.Position = result.Position
            prompt.Enabled = true
        else
            prompt.Enabled = false
        end
    end
end)

prompt.Triggered:Connect(function()
    local drinkEvent = ReplicatedStorage:FindFirstChild("DrinkEvent")
    if drinkEvent then drinkEvent:FireServer() end
end)