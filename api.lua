-- StoreUI ModuleScript
local StoreUI = {}
StoreUI.__index = StoreUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local guiName = "CustomStoreUI_v1"

-- Internal storage for registered features
local features = {}

-- Utility to create instances quickly
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

-- Create main ScreenGui and layout
local function createGui()
    local existing = player:FindFirstChildOfClass("PlayerGui"):FindFirstChild(guiName)
    if existing then
        existing:Destroy()
    end

    local screenGui = new("ScreenGui", {Name = guiName, ResetOnSpawn = false})
    screenGui.Parent = player:FindFirstChildOfClass("PlayerGui")

    local mainFrame = new("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 700, 0, 420),
        Position = UDim2.new(0.5, -350, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        AnchorPoint = Vector2.new(0.5,0.5),
        Parent = screenGui
    })

    local uiCorner = new("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0,8)})
    local title = new("TextLabel", {
        Name = "Title",
        Text = "Custom Feature Store",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0,10,0,10),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(230,230,230),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        Parent = mainFrame
    })

    local closeBtn = new("TextButton", {
        Name = "Close",
        Text = "X",
        Size = UDim2.new(0,36,0,28),
        Position = UDim2.new(1, -46, 0, 8),
        BackgroundColor3 = Color3.fromRGB(200,60,60),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = mainFrame
    })
    new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,6)})

    local scroll = new("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, -20, 1, -70),
        Position = UDim2.new(0,10,0,50),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 8,
        Parent = mainFrame
    })
    local grid = new("UIGridLayout", {
        Parent = scroll,
        CellSize = UDim2.new(0, 220, 0, 100),
        CellPadding = UDim2.new(0, 12, 0, 12),
        FillDirectionMaxCells = 3
    })

    -- Close behavior
    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Scroll = scroll,
        Grid = grid
    }
end

-- Save and load local state using Player attributes as a simple local store
local function saveState(key, value)
    local encoded = HttpService:JSONEncode(value)
    pcall(function()
        player:SetAttribute("StoreUI_" .. key, encoded)
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

-- Build an item card UI and return a toggle function
local function buildItemCard(container, feature)
    local card = new("Frame", {
        Name = "Card_" .. feature.id,
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
        Image = feature.icon or "",
        Parent = card
    })

    local name = new("TextLabel", {
        Name = "Name",
        Text = feature.name or "Unnamed",
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
        Text = feature.description or "",
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

    local state = loadState(feature.id, false)
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
        saveState(feature.id, state)
        updateVisual(state)
        if state and feature.onEnable then
            pcall(feature.onEnable)
        elseif not state and feature.onDisable then
            pcall(feature.onDisable)
        end
    end)

    -- If feature has an initial state callback, call it
    if state and feature.onEnable then
        pcall(feature.onEnable)
    end

    return card
end

-- Public API to register a feature
function StoreUI.RegisterFeature(featureDef)
    assert(type(featureDef.id) == "string", "feature must have id")
    features[featureDef.id] = featureDef

    -- If GUI already created, add immediately
    if StoreUI._gui and StoreUI._gui.Scroll then
        buildItemCard(StoreUI._gui.Scroll, featureDef)
        -- update canvas size
        local canvas = StoreUI._gui.Scroll
        local grid = canvas:FindFirstChildOfClass("UIGridLayout")
        if grid then
            local rows = math.ceil(#StoreUI._gui.Scroll:GetChildren() / 3)
            canvas.CanvasSize = UDim2.new(0,0,0, rows * (grid.CellSize.Y.Offset + grid.CellPadding.Y.Offset))
        end
    end
end

-- Public API to open the store UI
function StoreUI.Open()
    if not StoreUI._gui then
        StoreUI._gui = createGui()
        -- populate items
        for _,f in pairs(features) do
            buildItemCard(StoreUI._gui.Scroll, f)
        end
        -- adjust canvas size
        local grid = StoreUI._gui.Scroll:FindFirstChildOfClass("UIGridLayout")
        if grid then
            local count = 0
            for _,c in pairs(StoreUI._gui.Scroll:GetChildren()) do
                if c:IsA("Frame") and c.Name:match("^Card_") then count = count + 1 end
            end
            local rows = math.ceil(count / 3)
            StoreUI._gui.Scroll.CanvasSize = UDim2.new(0,0,0, rows * (grid.CellSize.Y.Offset + grid.CellPadding.Y.Offset))
        end
    else
        StoreUI._gui.ScreenGui.Enabled = true
    end
end

-- Public API to close the UI
function StoreUI.Close()
    if StoreUI._gui then
        StoreUI._gui.ScreenGui.Enabled = false
    end
end

-- Auto open for debugging; remove in production
-- StoreUI.Open()

return StoreUI
