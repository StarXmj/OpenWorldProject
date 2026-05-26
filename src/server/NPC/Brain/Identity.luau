--[ IA Component : Génétique et Identité (ADN) ]--
local Identity = {}

-- Banques de noms
local MALE_NAMES = {"Kael", "Torn", "Jax", "Bane", "Rin", "Kenshi", "Gorin", "Dax"}
local FEMALE_NAMES = {"Lyra", "Sia", "Kira", "Mina", "Elara", "Tess", "Ruka", "Aya"}
local LAST_NAMES = {"Stone", "Iron", "Sand", "Dust", "Ash", "Bone", "Drifter"}

-- Traits de caractère qui vont influencer le Cerveau
local PERSONALITIES = {
    "Aggressive", -- Se bat plus vite, fuit très tard
    "Coward",     -- Fuit très tôt, évite le combat
    "Friendly",   -- Cherche à sociabiliser, aide les autres
    "Neutral"     -- Comportement standard
}

function Identity.Generate(npc)
    -- 1. Sexe (50/50)
    local isMale = math.random() > 0.5
    local gender = isMale and "Male" or "Female"
    
    -- 2. Nom
    local firstName = isMale and MALE_NAMES[math.random(1, #MALE_NAMES)] or FEMALE_NAMES[math.random(1, #FEMALE_NAMES)]
    local lastName = LAST_NAMES[math.random(1, #LAST_NAMES)]
    local fullName = firstName .. " " .. lastName
    
    -- 3. Âge (Génération de 8 ans à 65 ans)
    -- L'âge influencera la vitesse et la taille plus tard
    local age = math.random(8, 65) 
    
    -- 4. Personnalité
    local trait = PERSONALITIES[math.random(1, #PERSONALITIES)]
    
    -- 5. Application au PNJ
    npc.Name = fullName
    npc:SetAttribute("Gender", gender)
    npc:SetAttribute("Age", age)
    npc:SetAttribute("Personality", trait)
    
    -- On log la création pour le debug
    return string.format("%s (%s, %d ans) - Trait: %s", fullName, gender, age, trait)
end

-- ⏳ Fonction pour faire vieillir le PNJ (Appelée une fois par jour In-Game)
function Identity.AgeUp(npc)
    local currentAge = npc:GetAttribute("Age") or 0
    npc:SetAttribute("Age", currentAge + 1)
    
    if currentAge + 1 >= 70 then
        -- Mort de vieillesse possible !
    end
end

return Identity