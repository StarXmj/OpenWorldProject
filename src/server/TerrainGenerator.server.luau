--[ Générateur d'Open World (Performant) ]--

local Terrain = workspace.Terrain

-- 1. PARAMÈTRES DU MONDE (Tu peux les modifier à l'infini !)
local mapSize = 600       -- Taille totale de la carte (600x600 studs)
local blockSize = 4       -- Résolution (4 est la taille standard d'un voxel Roblox)
local noiseScale = 80     -- "L'étirement" des collines (Plus c'est grand, plus c'est plat et vaste)
local amplitude = 40      -- La hauteur maximale des montagnes
local waterLevel = 15     -- Le niveau de la mer

-- On génère une "graine" aléatoire pour que la carte soit unique à chaque partie
local seed = math.random(1, 100000)

local function generateWorld()
    print("🌍 Début de la génération du monde...")
    
    -- On nettoie le terrain existant pour repartir à zéro
    Terrain:Clear()
    
    local blocksProcessed = 0
    
    -- On boucle sur l'axe X (Gauche/Droite) et Z (Avant/Arrière)
    for x = -mapSize/2, mapSize/2, blockSize do
        for z = -mapSize/2, mapSize/2, blockSize do
            
            -- Le Bruit de Perlin calcule la hauteur (Y) pour cette coordonnée X et Z
            local noiseValue = math.noise(x / noiseScale, seed, z / noiseScale)
            
            -- On transforme le bruit (qui va de -0.5 à 0.5) en véritable hauteur
            local height = (noiseValue + 0.5) * amplitude
            
            -- Choix du biome/matériau selon l'altitude
            local material = Enum.Material.Grass
            if height < waterLevel + 2 then
                material = Enum.Material.Sand -- Plages près de l'eau
            elseif height > amplitude * 0.8 then
                material = Enum.Material.Rock -- Roches sur les sommets
            end
            
            -- Création de la colonne de terre (qui part de -20 en profondeur jusqu'à la hauteur)
            local depth = 20
            local sizeY = height + depth
            local cframe = CFrame.new(x, (height - depth) / 2, z)
            local size = Vector3.new(blockSize, sizeY, blockSize)
            
            -- On sculpte la terre
            Terrain:FillBlock(cframe, size, material)
            
            -- Si la terre est sous le niveau de la mer, on remplit le vide avec de l'eau
            if height < waterLevel then
                local waterDepth = waterLevel - height
                local waterCFrame = CFrame.new(x, height + (waterDepth / 2), z)
                Terrain:FillBlock(waterCFrame, Vector3.new(blockSize, waterDepth, blockSize), Enum.Material.Water)
            end
            
            -- 🛡️ LE BOUCLIER ANTI-CRASH (Performance)
            blocksProcessed += 1
            if blocksProcessed % 400 == 0 then
                task.wait() -- Laisse le serveur respirer toutes les 400 colonnes
            end
        end
    end
    
    print("✅ Génération du monde terminée !")
end

-- On lance la création dès le démarrage
generateWorld()