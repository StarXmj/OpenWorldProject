--[ Gestionnaire Principal des Joueurs ]--
-- Ce script se lance côté serveur. Il gère les connexions et l'apparition des personnages.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- On charge notre module de configuration globale (placé dans ReplicatedStorage par Rojo)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- Fonction appelée chaque fois que le personnage (l'avatar) d'un joueur apparaît
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    -- On applique nos propres règles définies dans GameConfig.luau
    humanoid.MaxHealth = GameConfig.Entity.MaxHealth
    humanoid.Health = GameConfig.Entity.MaxHealth
    humanoid.WalkSpeed = GameConfig.Entity.WalkSpeed
    
    print("Personnage configuré avec succès pour :", character.Name)
end

-- Fonction appelée quand un joueur se connecte au serveur
local function onPlayerAdded(player)
    print("Nouvelle connexion :", player.Name)
    
    -- On écoute l'apparition de son personnage
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- On connecte l'événement PlayerAdded à notre fonction
Players.PlayerAdded:Connect(onPlayerAdded)