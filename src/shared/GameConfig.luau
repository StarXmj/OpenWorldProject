local GameConfig = {
    World = { DayNightCycleSpeed = 10, Gravity = 196.2 },

    Entity = {
        MaxHealth = 100, WalkSpeed = 14, SprintSpeed = 22,
        MaxHunger = 100, MaxStamina = 100,
        StaminaDrain = 15, StaminaRegen = 10,
    },

    Survival = { TickRate = 5, HungerDecay = 2, StarvationDamage = 5 },

    Items = {
        ["Apple"] = { Name = "Pomme Rouge", Type = "Consumable", RestoreValue = 25 }
    },

    Combat = {
        BaseDamage = 15, AttackRange = 6, Cooldown = 0.6,     
        PunchAnimId = "rbxassetid://507771019", 
    },

    -- NOUVEAU : Animations des PNJ
    NPC = {
        WalkAnimId = "rbxassetid://121435095284865", -- Animation de marche basique
        GrabAnimId = "rbxassetid://97106070783144", -- Animation de ramassage (coucou de la main)
    }
}

return GameConfig