local GameConfig = {
    World = { 
        DayLengthSeconds = 180, -- 1 heure réelle = 1 jour de jeu
        Gravity = 196.2 
    },

    Entity = {
        MaxHealth = 100, WalkSpeed = 14, SprintSpeed = 22,
        MaxHunger = 100, MaxStamina = 100, MaxThirst = 100,
        StaminaDrain = 15, StaminaRegen = 10,MaxFatigue = 100
    },

    Survival = { 
       DaysToStarve = 0.5,    -- 🍖 Vide la jauge de faim en 1/2 journée
        DaysToDehydrate = 0.4, -- 💧 Vide la soif un peu plus vite
        StarveDamagePerDay = 150, -- Dégâts s'il a 0 faim (Meurt en 0.6 jour de famine)
        DehydDamagePerDay = 200,
    },
    Ecology = {
        DaysToRegrow = 0.1, -- 🫐 Les buissons repoussent en 1/10ème de jour
    },

    Items = {
        ["Berry"] = { Name = "Baie Sauvage", Type = "Consumable", RestoreValue = 20 }
    },

 Combat = {
        BaseDamage = 15, 
        AttackRange = 6,     -- 🛡️ CORRECTION : Le paramètre manquant !
        Cooldown = 0.8, 
        WindUpTime = 0.25, 
        HitboxSize = Vector3.new(5, 5, 5), 
        HitboxOffset = CFrame.new(0, 0, -3), 
        PunchAnimId = "rbxassetid://119824661728215", 
    },

    NPC = {
        WalkAnimId = "rbxassetid://507777826", 
        GrabAnimId = "rbxassetid://97106070783144", 
    },

    -- CONFIGURATION DE LA GÉNÉRATION (Réglages de 0 à 1)
    Generation = {
        TreeChance = 0.05,       -- 5% de chance d'avoir un arbre par case
        BerryBushChance = 0.08,  -- 8% de chance d'avoir un buisson
        
        -- TES RARETÉS EXACTES POUR LES BAIES PAR BUISSON (0 à 1)
        BerryQuantityChances = {
            Four = 0.00001,      -- Très rare (0.001%)
            Three = 0.001,       -- Rare (0.1%)
            Two = 0.1,           -- Peu commun (10%)
            One = 1.0,           -- Commun (Le reste / 100%)
        }
    },

    UI = {
        ThirstPosition = UDim2.new(0.5, -100, 1, -120),
        HungerPosition = UDim2.new(0.5, -100, 1, -90),
        StaminaPosition = UDim2.new(0.5, -100, 1, -60),
        SundialPosition = UDim2.new(1, -100, 1, -100),
    }
}

return GameConfig