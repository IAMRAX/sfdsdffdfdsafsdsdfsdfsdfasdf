-- StoreUIStyled ModuleScript
-- Place in ReplicatedStorage.Modules.StoreUIStyled

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local guiName = "StoreUI_Styled_v1"

local StoreUI = {}
StoreUI.__index = StoreUI

local registered = {}
local categories = { "All" }

-- Utility
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do obj[k] = v end
    end
    return obj
end

local function safeEncode(v)
    local ok, s = pcall(function() return HttpService:JSONEncode(v) end)
    return ok and s or "{}"
end

local function saveState(key, value)
    pcall(function() player:SetAttribute("StoreUI_"..key, safeEncode(value)) end)
end

local function loadState(key, default)
    local raw = player:GetAttribute("StoreUI_"..key)
    if raw then
        local ok, val = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok then return val end
    end
    return default
end

-- Create GUI
local function createGui()
    local existing = player:FindFirstChildOfClass("PlayerGui"):FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local screenGui = new("ScreenGui", {Name = guiName, ResetOnSpawn = false})
    screenGui.Parent = player:FindFirstChildOfClass("PlayerGui")

    -- Main container
    local main = new("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 980, 0, 560),
        Position = UDim2.new(0.5, -490, 0.5, -280),
        BackgroundColor3 = Color3.fromRGB(22,22,24),
        AnchorPoint = Vector2.new(0.5,0.5),
        Parent = screenGui
    })
    new("UICorner", {Parent = main, CornerRadius = UDim.new(0,12)})

    -- Left sidebar
    local sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(18,18,20),
        Parent = main
    })
    new("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0,12)})

    local logo = new("TextLabel", {
        Name = "Logo",
        Text = "STORE",
        Size = UDim2.new(1, -24, 0, 48),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(240,240,240),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar
    })

    local catHolder = new("ScrollingFrame", {
        Name = "Categories",
        Size = UDim2.new(1, -24, 1, -84),
        Position = UDim2.new(0, 12, 0, 72),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        Parent = sidebar
    })
    local catLayout = new("UIListLayout", {Parent = catHolder, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})

    -- Right content area
    local content = new("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -240, 1, 0),
        Position = UDim2.new(0, 240, 0, 0),
        BackgroundTransparency = 1,
        Parent = main
    })

    -- Header: search + close
    local header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 64),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = content
    })

    local searchBox = new("Frame", {
        Name = "SearchBox",
        Size = UDim2.new(0.6, -12, 0, 36),
        Position = UDim2.new(0, 12, 0, 14),
        BackgroundColor3 = Color3.fromRGB(28,28,30),
        Parent = header
    })
    new("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0,8)})
    local searchIcon = new("TextLabel", {
        Name = "SearchIcon",
        Text = "🔍",
        Size = UDim2.new(0, 36, 1, 0),
        BackgroundTransparency = 1,
        Parent = searchBox
    })
    local searchInput = new("TextBox", {
        Name = "SearchInput",
        Text = "",
        PlaceholderText = "Search features...",
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.new(0, 44, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(230,230,230),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        Parent = searchBox
    })

    local closeBtn = new("TextButton", {
        Name = "Close",
        Text = "X",
        Size = UDim2.new(0, 44, 0, 36),
        Position = UDim2.new(1, -56, 0, 14),
        BackgroundColor3 = Color3.fromRGB(200,60,60),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = header
    })
    new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,8)})

    -- Grid area
    local gridFrame = new("Frame", {
        Name = "GridFrame",
        Size = UDim2.new(1, -24, 1, -96),
        Position = UDim2.new(0, 12, 0, 84),
        BackgroundTransparency = 1,
        Parent = content
    })

    local scroll = new("ScrollingFrame", {
        Name = "GridScroll",
        Size = UDim2.new(1, 0, 1, -12),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 8,
        Parent = gridFrame
    })
    local grid = new("UIGridLayout", {
        Parent = scroll,
        CellSize = UDim2.new(0, 300, 0, 120),
        CellPadding = UDim2.new(0, 12, 0, 12),
        FillDirectionMaxCells = 2
    })

    -- Pagination bar
    local pageBar = new("Frame", {
        Name = "PageBar",
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.new(0, 12, 1, -44),
        BackgroundTransparency = 1,
        Parent = content
    })
    local prevBtn = new("TextButton", {Name = "Prev", Text = "<", Size = UDim2.new(0,36,1,0), BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.fromRGB(255,255,255), Parent = pageBar})
    new("UICorner", {Parent = prevBtn, CornerRadius = UDim.new(0,6)})
    local pageLabel = new("TextLabel", {Name = "PageLabel", Text = "1 / 1", Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(0, 44, 0, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 14, Parent = pageBar})
    local nextBtn = new("TextButton", {Name = "Next", Text = ">", Size = UDim2.new(0,36,1,0), Position = UDim2.new(0, 176, 0, 0), BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.fromRGB(255,255,255), Parent = pageBar})
    new("UICorner", {Parent = nextBtn, CornerRadius = UDim.new(0,6)})

    -- Return references
    return {
        ScreenGui = screenGui,
        Main = main,
        Sidebar = sidebar,
        Categories = catHolder,
        Content = content,
        SearchInput = searchInput,
        CloseBtn = closeBtn,
        GridScroll = scroll,
        GridLayout = grid,
        PageBar = pageBar,
        PrevBtn = prevBtn,
        NextBtn = nextBtn,
        PageLabel = pageLabel
    }
end

-- Build category button (styled)
local function buildCategory(gui, name, onSelect)
    local btn = new("TextButton", {
        Name = "Cat_"..name,
        Text = name,
        Size = UDim2.new(1, -12, 0, 36),
        BackgroundColor3 = Color3.fromRGB(30,30,32),
        TextColor3 = Color3.fromRGB(220,220,220),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        Parent = gui.Categories
    })
    new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
    btn.MouseButton1Click:Connect(function()
        onSelect(name)
    end)
    return btn
end

-- Build product card
local function buildCard(def)
    local card = new("Frame", {
        Name = "Card_"..def.id,
        Size = UDim2.new(0, 300, 0, 120),
        BackgroundColor3 = Color3.fromRGB(28,28,30)
    })
    new("UICorner", {Parent = card, CornerRadius = UDim.new(0,8)})

    local icon = new("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 96, 0, 96),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Image = def.icon or "",
        Parent = card
    })
    local title = new("TextLabel", {
        Name = "Title",
        Text = def.name or "Unnamed",
        Size = UDim2.new(1, -132, 0, 24),
        Position = UDim2.new(0, 120, 0, 12),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(240,240,240),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })
    local desc = new("TextLabel", {
        Name = "Desc",
        Text = def.description or "",
        Size = UDim2.new(1, -132, 0, 48),
        Position = UDim2.new(0, 120, 0, 36),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200,200,200),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local action = new("TextButton", {
        Name = "Action",
        Text = def.buttonText or "Toggle",
        Size = UDim2.new(0, 92, 0, 32),
        Position = UDim2.new(1, -108, 0, 44),
        BackgroundColor3 = Color3.fromRGB(70,70,70),
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = card
    })
    new("UICorner", {Parent = action, CornerRadius = UDim.new(0,8)})

    -- Hover effect
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(34,34,36)}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28,28,30)}):Play()
    end)

    -- Action handling
    action.MouseButton1Click:Connect(function()
        if type(def.onAction) == "function" then
            pcall(def.onAction)
        end
    end)

    return card
end

-- Filtering, pagination
local function filterList(query, category)
    local out = {}
    local q = (query or ""):lower()
    for _, def in pairs(registered) do
        if (category == "All" or def.category == category) then
            if q == "" or (def.name and def.name:lower():find(q)) or (def.description and def.description:lower():find(q)) then
                table.insert(out, def)
            end
        end
    end
    return out
end

-- GUI state
StoreUI._gui = nil
StoreUI._page = 1
StoreUI._perPage = 6
StoreUI._currentCategory = "All"
StoreUI._currentQuery = ""

local function rebuildGrid()
    local gui = StoreUI._gui
    if not gui then return end

    local list = filterList(StoreUI._currentQuery, StoreUI._currentCategory)
    local total = #list
    local pages = math.max(1, math.ceil(total / StoreUI._perPage))
    StoreUI._page = math.clamp(StoreUI._page, 1, pages)

    -- clear
    for _, child in pairs(gui.GridScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Card_") then child:Destroy() end
    end

    -- add current page items
    local startIdx = (StoreUI._page - 1) * StoreUI._perPage + 1
    local endIdx = math.min(total, startIdx + StoreUI._perPage - 1)
    for i = startIdx, endIdx do
        local def = list[i]
        if def then
            local card = buildCard(def)
            card.Parent = gui.GridScroll
        end
    end

    -- update canvas size
    local grid = gui.GridLayout
    local count = 0
    for _, c in pairs(gui.GridScroll:GetChildren()) do if c:IsA("Frame") and c.Name:match("^Card_") then count = count + 1 end end
    local rows = math.ceil(math.max(1, count) / (grid.FillDirectionMaxCells or 2))
    gui.GridScroll.CanvasSize = UDim2.new(0,0,0, rows * (grid.CellSize.Y.Offset + grid.CellPadding.Y.Offset))

    -- update page label
    gui.PageLabel.Text = string.format("%d / %d", StoreUI._page, pages)
end

-- Public API
function StoreUI.RegisterFeature(def)
    assert(type(def.id) == "string", "id required")
    registered[def.id] = def
    if def.category and not table.find(categories, def.category) then
        table.insert(categories, def.category)
    end
    if StoreUI._gui then
        -- rebuild categories and grid
        -- clear categories
        for _, child in pairs(StoreUI._gui.Categories:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        -- rebuild
        for _, cat in ipairs(categories) do
            buildCategory(StoreUI._gui, cat, function(c)
                StoreUI._currentCategory = c
                StoreUI._page = 1
                rebuildGrid()
            end)
        end
        rebuildGrid()
    end
end

function StoreUI.Open()
    if not StoreUI._gui then
        StoreUI._gui = createGui()

        -- build categories
        for _, cat in ipairs(categories) do
            buildCategory(StoreUI._gui, cat, function(c)
                StoreUI._currentCategory = c
                StoreUI._page = 1
                rebuildGrid()
            end)
        end

        -- search handling
        StoreUI._gui.SearchInput.FocusLost:Connect(function(enter)
            StoreUI._currentQuery = StoreUI._gui.SearchInput.Text
            StoreUI._page = 1
            rebuildGrid()
        end)

        -- close
        StoreUI._gui.CloseBtn.MouseButton1Click:Connect(function()
            StoreUI._gui.ScreenGui.Enabled = false
        end)

        -- pagination
        StoreUI._gui.PrevBtn.MouseButton1Click:Connect(function()
            StoreUI._page = math.max(1, StoreUI._page - 1)
            rebuildGrid()
        end)
        StoreUI._gui.NextBtn.MouseButton1Click:Connect(function()
            StoreUI._page = StoreUI._page + 1
            rebuildGrid()
        end)

        -- initial populate
        rebuildGrid()
    else
        StoreUI._gui.ScreenGui.Enabled = true
    end
end

function StoreUI.Close()
    if StoreUI._gui then StoreUI._gui.ScreenGui.Enabled = false end
end

-- Convenience: register multiple features at once
function StoreUI.RegisterFeatures(list)
    for _, def in ipairs(list) do
        StoreUI.RegisterFeature(def)
    end
end

return StoreUI
