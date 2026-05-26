-- StoreUI ModuleScript
-- Place this in ReplicatedStorage.Modules.StoreUI (or ClientLoader.Components.StoreUI)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local guiName = "CustomStoreUI_v2"

local StoreUI = {}
StoreUI.__index = StoreUI

local registered = {}
local categories = { "All" }

-- Utility to create instances quickly
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do obj[k] = v end
    end
    return obj
end

-- Persistent state helpers (local only)
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

-- Build main GUI
local function createGui()
    local existing = player:FindFirstChildOfClass("PlayerGui"):FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local screenGui = new("ScreenGui", { Name = guiName, ResetOnSpawn = false })
    screenGui.Parent = player:FindFirstChildOfClass("PlayerGui")

    local main = new("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 760, 0, 480),
        Position = UDim2.new(0.5, -380, 0.5, -240),
        BackgroundColor3 = Color3.fromRGB(28,28,28),
        AnchorPoint = Vector2.new(0.5,0.5),
        Parent = screenGui
    })
    new("UICorner", { Parent = main, CornerRadius = UDim.new(0,10) })

    local header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1,0,0,56),
        BackgroundTransparency = 1,
        Parent = main
    })
    local title = new("TextLabel", {
        Name = "Title",
        Text = "Custom Store",
        Size = UDim2.new(0.6, -12, 1, 0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(240,240,240),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    local closeBtn = new("TextButton", {
        Name = "Close",
        Text = "X",
        Size = UDim2.new(0,36,0,28),
        Position = UDim2.new(1, -48, 0, 14),
        BackgroundColor3 = Color3.fromRGB(200,60,60),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = header
    })
    new("UICorner", { Parent = closeBtn, CornerRadius = UDim.new(0,6) })

    -- Category bar
    local catBar = new("Frame", {
        Name = "CategoryBar",
        Size = UDim2.new(1, -24, 0, 40),
        Position = UDim2.new(0,12,0,56),
        BackgroundTransparency = 1,
        Parent = main
    })
    local catLayout = new("UIListLayout", { Parent = catBar, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8) })

    -- Scroll area for items
    local scroll = new("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, -24, 1, -120),
        Position = UDim2.new(0,12,0,110),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 8,
        Parent = main
    })
    local grid = new("UIGridLayout", {
        Parent = scroll,
        CellSize = UDim2.new(0, 240, 0, 110),
        CellPadding = UDim2.new(0, 12, 0, 12),
        FillDirectionMaxCells = 3
    })

    -- Close behavior
    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    return {
        ScreenGui = screenGui,
        Main = main,
        Header = header,
        CategoryBar = catBar,
        Scroll = scroll,
        Grid = grid
    }
end

-- Build a category button
local function buildCategoryButton(container, name, onSelect)
    local btn = new("TextButton", {
        Name = "Cat_" .. name,
        Text = name,
        Size = UDim2.new(0, 120, 0, 32),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.fromRGB(230,230,230),
        Parent = container
    })
    new("UICorner", { Parent = btn, CornerRadius = UDim.new(0,6) })
    btn.MouseButton1Click:Connect(function()
        onSelect(name)
    end)
    return btn
end

-- Build an item card
local function buildItemCard(container, def)
    local card = new("Frame", {
        Name = "Card_" .. def.id,
        Size = UDim2.new(0, 240, 0, 110),
        BackgroundColor3 = Color3.fromRGB(40,40,40),
        Parent = container
    })
    new("UICorner", { Parent = card, CornerRadius = UDim.new(0,6) })

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
        Size = UDim2.new(1, -96, 0, 24),
        Position = UDim2.new(0, 80, 0, 12),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(230,230,230),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local desc = new("TextLabel", {
        Name = "Desc",
        Text = def.description or "",
        Size = UDim2.new(1, -96, 0, 40),
        Position = UDim2.new(0, 80, 0, 34),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200,200,200),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local actionBtn = new("TextButton", {
        Name = "Action",
        Text = def.buttonText or "Toggle",
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -92, 0, 40),
        BackgroundColor3 = Color3.fromRGB(70,70,70),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = card
    })
    new("UICorner", { Parent = actionBtn, CornerRadius = UDim.new(0,6) })

    -- Toggle visual state if requested
    local state = loadState(def.id, false)
    local function updateVisual(on)
        if on then
            actionBtn.BackgroundColor3 = Color3.fromRGB(60,150,80)
            actionBtn.Text = def.onText or "ON"
        else
            actionBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            actionBtn.Text = def.offText or "OFF"
        end
    end
    updateVisual(state)

    actionBtn.MouseButton1Click:Connect(function()
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

-- Filter and rebuild visible cards by category
local function rebuildCards(gui, selectedCategory)
    -- clear existing cards
    for _, child in pairs(gui.Scroll:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Card_") then
            child:Destroy()
        end
    end

    local count = 0
    for _, def in pairs(registered) do
        if selectedCategory == "All" or def.category == selectedCategory then
            buildItemCard(gui.Scroll, def)
            count = count + 1
        end
    end

    local grid = gui.Grid
    local rows = math.ceil(math.max(1, count) / 3)
    gui.Scroll.CanvasSize = UDim2.new(0,0,0, rows * (grid.CellSize.Y.Offset + grid.CellPadding.Y.Offset))
end

-- Public API
function StoreUI.RegisterFeature(def)
    assert(type(def.id) == "string", "id required")
    registered[def.id] = def
    if StoreUI._gui then
        -- ensure category exists
        if def.category and not table.find(categories, def.category) then
            table.insert(categories, def.category)
            buildCategoryButton(StoreUI._gui.CategoryBar, def.category, function(cat)
                rebuildCards(StoreUI._gui, cat)
            end)
        end
        rebuildCards(StoreUI._gui, "All")
    end
end

function StoreUI.RegisterCategory(name)
    if not table.find(categories, name) then
        table.insert(categories, name)
        if StoreUI._gui then
            buildCategoryButton(StoreUI._gui.CategoryBar, name, function(cat)
                rebuildCards(StoreUI._gui, cat)
            end)
        end
    end
end

function StoreUI.Open()
    if not StoreUI._gui then
        StoreUI._gui = createGui()
        -- build default category buttons
        for _, cat in ipairs(categories) do
            buildCategoryButton(StoreUI._gui.CategoryBar, cat, function(c)
                rebuildCards(StoreUI._gui, c)
            end)
        end
        rebuildCards(StoreUI._gui, "All")
    else
        StoreUI._gui.ScreenGui.Enabled = true
    end
end

function StoreUI.Close()
    if StoreUI._gui then
        StoreUI._gui.ScreenGui.Enabled = false
    end
end

return StoreUI
