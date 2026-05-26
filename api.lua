-- ReplicatedStorage.Modules.StoreUI
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local guiName = "CustomStoreUI_v1"

local StoreUI = {}
StoreUI.__index = StoreUI

local registered = {}

local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do obj[k] = v end
    end
    return obj
end

local function createGui()
    local existing = player:FindFirstChildOfClass("PlayerGui"):FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local screenGui = new("ScreenGui", {Name = guiName, ResetOnSpawn = false})
    screenGui.Parent = player:FindFirstChildOfClass("PlayerGui")

    local main = new("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 700, 0, 420),
        Position = UDim2.new(0.5, -350, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        AnchorPoint = Vector2.new(0.5,0.5),
        Parent = screenGui
    })
    new("UICorner", {Parent = main, CornerRadius = UDim.new(0,8)})

    local title = new("TextLabel", {
        Name = "Title",
        Text = "Feature Store",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0,10,0,10),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(230,230,230),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        Parent = main
    })

    local closeBtn = new("TextButton", {
        Name = "Close",
        Text = "X",
        Size = UDim2.new(0,36,0,28),
        Position = UDim2.new(1, -46, 0, 8),
        BackgroundColor3 = Color3.fromRGB(200,60,60),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = main
    })
    new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,6)})

    local scroll = new("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, -20, 1, -70),
        Position = UDim2.new(0,10,0,50),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 8,
        Parent = main
    })
    local grid = new("UIGridLayout", {
        Parent = scroll,
        CellSize = UDim2.new(0, 220, 0, 100),
        CellPadding = UDim2.new(0, 12, 0, 12),
        FillDirectionMaxCells = 3
    })

    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    return {
        ScreenGui = screenGui,
        Main = main,
        Scroll = scroll,
        Grid = grid
    }
end

local guiState = nil

local function saveState(key, value)
    pcall(function()
        player:SetAttribute("StoreUI_" .. key, HttpService:JSONEncode(value))
    end)
end

local function loadState(key, default)
    local raw = player:GetAttribute("StoreUI_" .. key)
    if raw then
        local ok, val = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok then return val end
    end
    return default
end

local function buildCard(container, def)
    local card = new("Frame", {
        Name = "Card_" .. def.id,
        Size = UDim2.new(0, 220, 0, 100),
        BackgroundColor3 = Color3.fromRGB(40,40,40),
        Parent = container
    })
    new("UICorner", {Parent = card, CornerRadius = UDim.new(0,6)})

    local icon = new("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 64, 0, 64),
        Position = UDim2.new(0, 8, 0, 18),
        BackgroundTransparency = 1,
        Image = def.icon or "",
        Parent = card
    })

    local name = new("TextLabel", {
        Name = "Name",
        Text = def.name or "Unnamed",
        Size = UDim2.new(1, -84, 0, 24),
        Position = UDim2.new(0, 80, 0, 12),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(230,230,230),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local desc = new("TextLabel", {
        Name = "Desc",
        Text = def.description or "",
        Size = UDim2.new(1, -84, 0, 40),
        Position = UDim2.new(0, 80, 0, 34),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200,200,200),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local toggleBtn = new("TextButton", {
        Name = "Toggle",
        Text = "",
        Size = UDim2.new(0, 60, 0, 28),
        Position = UDim2.new(1, -68, 0, 36),
        BackgroundColor3 = Color3.fromRGB(70,70,70),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = card
    })
    new("UICorner", {Parent = toggleBtn, CornerRadius = UDim.new(0,6)})

    local state = loadState(def.id, false)
    local function updateVisual(on)
        if on then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60,150,80)
            toggleBtn.Text = "ON"
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            toggleBtn.Text = "OFF"
        end
    end
    updateVisual(state)

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        saveState(def.id, state)
        updateVisual(state)
        if state and type(def.onEnable) == "function" then
            pcall(def.onEnable)
        elseif not state and type(def.onDisable) == "function" then
            pcall(def.onDisable)
        end
    end)

    if state and type(def.onEnable) == "function" then
        pcall(def.onEnable)
    end

    return card
end

function StoreUI.RegisterFeature(def)
    assert(type(def.id) == "string", "id required")
    registered[def.id] = def
    if guiState and guiState.Scroll then
        buildCard(guiState.Scroll, def)
        -- adjust canvas
        local grid = guiState.Grid
        if grid then
            local count = 0
            for _,c in pairs(guiState.Scroll:GetChildren()) do
                if c:IsA("Frame") and c.Name:match("^Card_") then count = count + 1 end
            end
            local rows = math.ceil(count / 3)
            guiState.Scroll.CanvasSize = UDim2.new(0,0,0, rows * (grid.CellSize.Y.Offset + grid.CellPadding.Y.Offset))
        end
    end
end

function StoreUI.Open()
    if not guiState then
        guiState = createGui()
        for _, def in pairs(registered) do
            buildCard(guiState.Scroll, def)
        end
        local grid = guiState.Grid
        local count = 0
        for _,c in pairs(guiState.Scroll:GetChildren()) do
            if c:IsA("Frame") and c.Name:match("^Card_") then count = count + 1 end
        end
        local rows = math.ceil(count / 3)
        guiState.Scroll.CanvasSize = UDim2.new(0,0,0, rows * (grid.CellSize.Y.Offset + grid.CellPadding.Y.Offset))
    else
        guiState.ScreenGui.Enabled = true
    end
end

function StoreUI.Close()
    if guiState then
        guiState.ScreenGui.Enabled = false
    end
end

return StoreUI
