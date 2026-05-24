local GameConfig = {
    World = { 
        DayLengthSeconds = 3600, -- 1 heure réelle = 1 jour de jeu
        Gravity = 196.2 
    },

    Entity = {
        MaxHealth = 100, WalkSpeed = 14, SprintSpeed = 22,
        MaxHunger = 100, MaxStamina = 100, MaxThirst = 100,
        StaminaDrain = 15, StaminaRegen = 10,
    },

    Survival = { 
        TickRate = 5, 
        HungerDecay = 2, 
        ThirstDecay = 3, 
        -- CORRECTION : 4.17 dégâts toutes les 5s = Mort en exactement 2 minutes (120s)
        StarvationDamage = 4.17, 
        DehydrationDamage = 4.17, 
    },

    Items = {
        ["Berry"] = { Name = "Baie Sauvage", Type = "Consumable", RestoreValue = 20 }
    },

    Combat = {
        BaseDamage = 15, AttackRange = 6, Cooldown = 0.6,     
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