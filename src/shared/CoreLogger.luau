--[ Système Centralisé de Logs ]--
local RunService = game:GetService("RunService")
local CoreLogger = {}

local IS_SERVER = RunService:IsServer()

function CoreLogger.info(system, message)
    print(string.format("🟢 [%s] [%s] : %s", IS_SERVER and "SERVER" or "CLIENT", string.upper(system), message))
end

function CoreLogger.warn(system, message)
    warn(string.format("🟠 [%s] [%s] : %s", IS_SERVER and "SERVER" or "CLIENT", string.upper(system), message))
end

function CoreLogger.error(system, message)
    error(string.format("🔴 [%s] [%s] : %s", IS_SERVER and "SERVER" or "CLIENT", string.upper(system), message))
end

function CoreLogger.debug(system, message)
    -- Pratique pour des infos spam (ex: déplacements), qu'on peut désactiver facilement
    print(string.format("⚪ [%s] [%s] : %s", IS_SERVER and "SERVER" or "CLIENT", string.upper(system), message))
end

return CoreLogger