--[ Système Centralisé de Logs V2 (Avec Module IA) ]--
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
    print(string.format("⚪ [%s] [%s] : %s", IS_SERVER and "SERVER" or "CLIENT", string.upper(system), message))
end

-- 🧠 NOUVEAU : Log dédié à l'IA (Format AAA)
function CoreLogger.ai(npcName, message)
    if IS_SERVER then
        print(string.format("🧠 [AI - %s] %s", npcName, message))
    end
end

return CoreLogger