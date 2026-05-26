-- StoreUI_Pastebin (ModuleScript)
-- Place in ReplicatedStorage.Modules.StoreUI_Pastebin

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local guiName = "StoreUI_Pastebin_v1"

local StoreUI = {}
StoreUI.__index = StoreUI

-- ASSETS: replace with "rbxassetid://<id>" if you want explicit rbxassetid format
local ASSETS = {
    Header = "rbxassetid://100447503406361",
    Exit = "rbxassetid://88014724426057",
    Icon = "rbxassetid://103248461436758",
    BannerTop = "rbxassetid://132456408835496",
    BannerMid = "rbxassetid://103921755022681",
    BannerBottom = "rbxassetid://930796081464987",
    -- ServerLuck / packs
    ServerRays = "rbxassetid://76286590540512",
    ServerBuyBtn = "rbxassetid://72422011031204",
    IconGreen = "rbxassetid://12889918158462",
    IconPink = "rbxassetid://139279956463359",
    IconGold = "rbxassetid://139644418501560",
    PinkPack = "rbxassetid://120320260006008",
    GreenPack = "rbxassetid://78156677168288",
    GoldPack = "rbxassetid://129807599810361",
    -- Starter pack icons
    Starter1 = "rbxassetid://91338713917812",
    Starter2 = "rbxassetid://89348733379073",
    Starter3 = "rbxassetid://814546283083027",
    Starter4 = "rbxassetid://86964499984867",
    -- placeholders (others from your list)
    Placeholder1 = "rbxassetid://111624955089486",
    Placeholder2 = "rbxassetid://120965422656755",
    -- ... add more as needed
}

-- Internal state
local guiState = nil
local countdownSeconds = 3600 -- default server luck timer (1 hour)
local serverLuckActive = false

-- Utility
local function new(class, props)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k] = v end end
    return obj
end

local function formatTime(sec)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = sec%60
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Build GUI matching pastebin layout
local function createGui()
    local existing = player:FindFirstChildOfClass("PlayerGui"):FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local screenGui = new("ScreenGui", {Name = guiName, ResetOnSpawn = false})
    screenGui.Parent = player:FindFirstChildOfClass("PlayerGui")

    local main = new("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 980, 0, 560),
        Position = UDim2.new(0.5, -490, 0.5, -280),
        BackgroundColor3 = Color3.fromRGB(18,18,20),
        AnchorPoint = Vector2.new(0.5,0.5),
        Parent = screenGui
    })
    new("UICorner", {Parent = main, CornerRadius = UDim.new(0,12)})

    -- Left banner area
    local left = new("Frame", {
        Name = "Left",
        Size = UDim2.new(0, 520, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = main
    })

    -- Banner images stacked (top/mid/bottom)
    local bannerTop = new("ImageLabel", {Name="BannerTop", Size=UDim2.new(1,0,0,160), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Image=ASSETS.BannerTop, Parent=left})
    local bannerMid = new("ImageLabel", {Name="BannerMid", Size=UDim2.new(1,0,0,160), Position=UDim2.new(0,0,0,160), BackgroundTransparency=1, Image=ASSETS.BannerMid, Parent=left})
    local bannerBottom = new("ImageLabel", {Name="BannerBottom", Size=UDim2.new(1,0,0,160), Position=UDim2.new(0,0,0,320), BackgroundTransparency=1, Image=ASSETS.BannerBottom, Parent=left})

    -- Rarity tiles overlay (example three tiles with percentages)
    local rarityHolder = new("Frame", {Name="RarityHolder", Size=UDim2.new(0, 360, 0, 120), Position=UDim2.new(0, 24, 0, 200), BackgroundTransparency=1, Parent=left})
    new("UICorner", {Parent = rarityHolder, CornerRadius = UDim.new(0,8)})

    local function makeRarity(x, title, percent, color)
        local f = new("Frame", {Size=UDim2.new(0, 110, 0, 100), Position=UDim2.new(0, x, 0, 0), BackgroundColor3 = Color3.fromRGB(30,30,32), Parent = rarityHolder})
        new("UICorner", {Parent = f, CornerRadius = UDim.new(0,8)})
        new("TextLabel", {Parent=f, Text=title, Size=UDim2.new(1, -12, 0, 28), Position=UDim2.new(0, 6, 0, 6), BackgroundTransparency=1, TextColor3=Color3.fromRGB(230,230,230), Font=Enum.Font.GothamBold, TextSize=14})
        new("TextLabel", {Parent=f, Text=percent, Size=UDim2.new(1, -12, 0, 28), Position=UDim2.new(0, 6, 0, 36), BackgroundTransparency=1, TextColor3=color, Font=Enum.Font.GothamBold, TextSize=18})
        return f
    end

    makeRarity(0, "Common", "70%", Color3.fromRGB(180,180,180))
    makeRarity(0.33, "Rare", "25%", Color3.fromRGB(120,180,255))
    makeRarity(0.66, "Legendary", "5%", Color3.fromRGB(255,200,80))

    -- Buy buttons area (three buy buttons under banners)
    local buyHolder = new("Frame", {Name="BuyHolder", Size=UDim2.new(1, -48, 0, 80), Position=UDim2.new(0, 24, 0, 340), BackgroundTransparency=1, Parent=left})
    local function makeBuyButton(posX, label, price, asset)
        local btn = new("TextButton", {Name = "Buy_"..label, Text = label.." - "..price, Size = UDim2.new(0, 160, 0, 48), Position = UDim2.new(posX, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(70,70,70), TextColor3 = Color3.fromRGB(255,255,255), Parent = buyHolder})
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
        if asset and asset ~= "" then
            local img = new("ImageLabel", {Parent = btn, Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 8, 0.5, -18), BackgroundTransparency = 1, Image = asset})
        end
        return btn
    end

    local buy1 = makeBuyButton(0, "Buy Pink", "$2.99", ASSETS.PinkPack)
    local buy2 = makeBuyButton(0.33, "Buy Green", "$4.99", ASSETS.GreenPack)
    local buy3 = makeBuyButton(0.66, "Buy Gold", "$9.99", ASSETS.GoldPack)

    -- Right panel (Server Luck + timer + buy)
    local right = new("Frame", {Name="Right", Size=UDim2.new(0, 420, 1, 0), Position=UDim2.new(1, -420, 0, 0), BackgroundTransparency=1, Parent=main})
    local serverPanel = new("Frame", {Name="ServerLuck", Size=UDim2.new(1, -24, 0, 220), Position=UDim2.new(0, 12, 0, 24), BackgroundColor3 = Color3.fromRGB(26,26,28), Parent = right})
    new("UICorner", {Parent = serverPanel, CornerRadius = UDim.new(0,10)})
    new("ImageLabel", {Parent = serverPanel, Name = "Rays", Size = UDim2.new(1,0,0,120), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Image = ASSETS.ServerRays})
    new("TextLabel", {Parent = serverPanel, Name = "Title", Text = "Server Luck", Size = UDim2.new(1, -24, 0, 28), Position = UDim2.new(0, 12, 0, 128), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamBold, TextSize = 16})
    local timerLabel = new("TextLabel", {Parent = serverPanel, Name = "Timer", Text = formatTime(countdownSeconds), Size = UDim2.new(1, -24, 0, 28), Position = UDim2.new(0, 12, 0, 156), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200,255,200), Font = Enum.Font.GothamBold, TextSize = 14})

    local serverBuy = new("TextButton", {Parent = serverPanel, Name = "ServerBuy", Text = "Buy Server Luck", Size = UDim2.new(0, 160, 0, 36), Position = UDim2.new(1, -176, 0, 156), BackgroundColor3 = Color3.fromRGB(80,160,80), TextColor3 = Color3.fromRGB(255,255,255)})
    new("UICorner", {Parent = serverBuy, CornerRadius = UDim.new(0,8)})

    -- Starter pack strip at bottom
    local starterStrip = new("Frame", {Name="StarterStrip", Size=UDim2.new(1, -24, 0, 72), Position=UDim2.new(0, 12, 1, -84), BackgroundColor3 = Color3.fromRGB(24,24,26), Parent = right})
    new("UICorner", {Parent = starterStrip, CornerRadius = UDim.new(0,8)})
    new("TextLabel", {Parent = starterStrip, Text = "Starter Pack", Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamBold, TextSize = 16})
    local function makeStarterIcon(x, asset, label)
        local holder = new("Frame", {Parent = starterStrip, Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(x, 0, 0.5, -32), BackgroundTransparency = 1})
        local img = new("ImageLabel", {Parent = holder, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Image = asset})
        return holder
    end
    makeStarterIcon(0.35, ASSETS.Starter1, "s1")
    makeStarterIcon(0.55, ASSETS.Starter2, "s2")
    makeStarterIcon(0.75, ASSETS.Starter3, "s3")

    -- Return references for runtime hooks
    return {
        ScreenGui = screenGui,
        Main = main,
        Left = left,
        Right = right,
        TimerLabel = timerLabel,
        ServerBuy = serverBuy,
        BuyButtons = {buy1, buy2, buy3},
        StarterStrip = starterStrip
    }
end

-- Timer loop for server luck display (UI only)
local function startTimer(gui)
    spawn(function()
        while gui and gui.TimerLabel and countdownSeconds > 0 do
            gui.TimerLabel.Text = formatTime(countdownSeconds)
            task.wait(1)
            countdownSeconds = countdownSeconds - 1
        end
        if gui and gui.TimerLabel then
            gui.TimerLabel.Text = "00:00:00"
        end
    end)
end

-- Public API
function StoreUI.Open()
    if not guiState then
        guiState = createGui()
        -- wire buy buttons to callbacks (no purchase logic here)
        guiState.ServerBuy.MouseButton1Click:Connect(function()
            if type(StoreUI.OnServerBuy) == "function" then
                pcall(StoreUI.OnServerBuy)
            else
                warn("ServerBuy clicked - no handler assigned")
            end
        end)
        for i, btn in ipairs(guiState.BuyButtons) do
            btn.MouseButton1Click:Connect(function()
                if type(StoreUI.OnBuy) == "function" then
                    pcall(StoreUI.OnBuy, i)
                else
                    warn("Buy button "..i.." clicked - no handler assigned")
                end
            end)
        end
        -- starter strip click (example: open starter buy)
        guiState.StarterStrip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if type(StoreUI.OnStarterBuy) == "function" then
                    pcall(StoreUI.OnStarterBuy)
                else
                    warn("Starter strip clicked - no handler assigned")
                end
            end
        end)
        startTimer(guiState)
    else
        guiState.ScreenGui.Enabled = true
    end
end

function StoreUI.Close()
    if guiState then guiState.ScreenGui.Enabled = false end
end

-- Callbacks you can assign from your bootstrap script:
-- StoreUI.OnBuy = function(index) end
-- StoreUI.OnServerBuy = function() end
-- StoreUI.OnStarterBuy = function() end

-- Helper to set countdown (seconds)
function StoreUI.SetServerCountdown(seconds)
    countdownSeconds = math.max(0, math.floor(seconds))
    if guiState and guiState.TimerLabel then
        guiState.TimerLabel.Text = formatTime(countdownSeconds)
    end
end

return StoreUI
