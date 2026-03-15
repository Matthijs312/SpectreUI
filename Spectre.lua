local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local UserInput      = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local GuiService     = game:GetService("GuiService")

local Mouse  = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local guiInset = GuiService:GetGuiInset()

local sg = Instance.new("ScreenGui")
sg.Name              = "SpectreESP"
sg.ResetOnSpawn      = false
sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset    = false

local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not ok then
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ────────────────────────────────────────────────
-- Design System
-- ────────────────────────────────────────────────

local theme = {
    bg          = Color3.fromRGB(10, 10, 16),
    surface     = Color3.fromRGB(16, 16, 24),
    elevated    = Color3.fromRGB(22, 22, 34),
    border      = Color3.fromRGB(38, 38, 56),
    accent      = Color3.fromRGB(100, 180, 255),
    text        = Color3.fromRGB(230, 232, 240),
    textDim     = Color3.fromRGB(140, 145, 165),
    textMuted   = Color3.fromRGB(85, 88, 105),
    greenDim    = Color3.fromRGB(35, 80, 55),
    red         = Color3.fromRGB(220, 70, 70),
    redDim      = Color3.fromRGB(90, 30, 30),
    toggleOff   = Color3.fromRGB(50, 52, 65),
    toggleOn    = Color3.fromRGB(60, 170, 120),
    sliderTrack = Color3.fromRGB(32, 34, 48),
    sliderFill  = Color3.fromRGB(80, 160, 235),
}

local HttpService = game:GetService("HttpService")

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ────────────────────────────────────────────────
-- Notification System
-- ────────────────────────────────────────────────

local notifContainer = Instance.new("Frame")
notifContainer.Size = UDim2.new(0, 240, 1, 0)
notifContainer.Position = UDim2.new(1, -250, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 20
notifContainer.Parent = sg

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 6)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Parent = notifContainer

local notifOrder = 0

local function notify(text, color)
    notifOrder = notifOrder + 1
    color = color or theme.accent

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 38)
    toast.BackgroundColor3 = theme.surface
    toast.BorderSizePixel = 0
    toast.BackgroundTransparency = 1
    toast.ZIndex = 20
    toast.LayoutOrder = notifOrder
    toast.Parent = notifContainer
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)
    local ts = Instance.new("UIStroke", toast)
    ts.Color = color; ts.Thickness = 1; ts.Transparency = 0.4

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 0, 20)
    accentBar.Position = UDim2.new(0, 8, 0.5, -10)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0; accentBar.ZIndex = 21
    accentBar.Parent = toast
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text; lbl.TextColor3 = theme.text
    lbl.TextSize = 12; lbl.ZIndex = 21
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast

    -- Slide in
    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.08
    }):Play()

    -- Fade out after 2.5s
    task.delay(2.5, function()
        local tw = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        TweenService:Create(lbl, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
        TweenService:Create(ts, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
        tw:Play()
        tw.Completed:Wait()
        toast:Destroy()
    end)
end

-- ────────────────────────────────────────────────
-- Keybind System
-- ────────────────────────────────────────────────

local Keybinds = {
    ToggleMenu = Enum.KeyCode.Insert,
    AimLock = Enum.UserInputType.MouseButton2,
}

local function getKeyName(key)
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.KeyCode then
            return key.Name
        elseif key.EnumType == Enum.UserInputType then
            if key == Enum.UserInputType.MouseButton1 then return "Mouse1"
            elseif key == Enum.UserInputType.MouseButton2 then return "Mouse2"
            elseif key == Enum.UserInputType.MouseButton3 then return "Mouse3"
            else return key.Name end
        end
    end
    return tostring(key)
end

-- ────────────────────────────────────────────────
-- Config Save/Load
-- ────────────────────────────────────────────────

local CONFIG_DIR = "SpectreESP"
local CONFIG_FILE = CONFIG_DIR .. "/config.json"

local function saveConfig()
    local data = {
        -- ESP
        FillTransparency = ESP.FillTransparency,
        OutlineTransparency = ESP.OutlineTransparency,
        ShowNames = ESP.ShowNames,
        ShowHP = ESP.ShowHP,
        ShowDistance = ESP.ShowDistance,
        -- Aim Lock
        IgnoreTeam = ESP.IgnoreTeam,
        HoldToAim = ESP.HoldToAim,
        LockSmooth = ESP.LockSmooth,
        FOVRadius = ESP.FOVRadius,
        ShowFOVCircle = ESP.ShowFOVCircle,
        -- Crosshair
        CrosshairEnabled = ESP.CrosshairEnabled,
        CrosshairSize = ESP.CrosshairSize,
        CrosshairGap = ESP.CrosshairGap,
        CrosshairThickness = ESP.CrosshairThickness,
        CrosshairDot = ESP.CrosshairDot,
        CrosshairColorIndex = ESP.CrosshairColorIndex,
        -- Hitbox
        HitboxMultiplier = ESP.HitboxMultiplier,
        HitboxTransparency = ESP.HitboxTransparency,
        HitboxIgnoreTeam = ESP.HitboxIgnoreTeam,
        InfiniteJumpEnabled = ESP.InfiniteJumpEnabled,
        FullbrightEnabled = ESP.FullbrightEnabled,
        NoclipEnabled = ESP.NoclipEnabled,
        -- Keybinds
        ToggleMenuKey = getKeyName(Keybinds.ToggleMenu),
        AimLockKey = getKeyName(Keybinds.AimLock),
    }
    pcall(function()
        if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    local ok, raw = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false end

    -- ESP
    if data.FillTransparency ~= nil then ESP.FillTransparency = data.FillTransparency end
    if data.OutlineTransparency ~= nil then ESP.OutlineTransparency = data.OutlineTransparency end
    if data.ShowNames ~= nil then ESP.ShowNames = data.ShowNames end
    if data.ShowHP ~= nil then ESP.ShowHP = data.ShowHP end
    if data.ShowDistance ~= nil then ESP.ShowDistance = data.ShowDistance end
    -- Aim Lock
    if data.IgnoreTeam ~= nil then ESP.IgnoreTeam = data.IgnoreTeam end
    if data.HoldToAim ~= nil then ESP.HoldToAim = data.HoldToAim end
    if data.LockSmooth ~= nil then ESP.LockSmooth = data.LockSmooth end
    if data.FOVRadius ~= nil then ESP.FOVRadius = data.FOVRadius end
    if data.ShowFOVCircle ~= nil then ESP.ShowFOVCircle = data.ShowFOVCircle end
    -- Crosshair
    if data.CrosshairEnabled ~= nil then ESP.CrosshairEnabled = data.CrosshairEnabled end
    if data.CrosshairSize ~= nil then ESP.CrosshairSize = data.CrosshairSize end
    if data.CrosshairGap ~= nil then ESP.CrosshairGap = data.CrosshairGap end
    if data.CrosshairThickness ~= nil then ESP.CrosshairThickness = data.CrosshairThickness end
    if data.CrosshairDot ~= nil then ESP.CrosshairDot = data.CrosshairDot end
    if data.CrosshairColorIndex ~= nil then ESP.CrosshairColorIndex = data.CrosshairColorIndex end
    -- Hitbox
    if data.HitboxMultiplier ~= nil then ESP.HitboxMultiplier = data.HitboxMultiplier end
    if data.HitboxTransparency ~= nil then ESP.HitboxTransparency = data.HitboxTransparency end
    if data.HitboxIgnoreTeam ~= nil then ESP.HitboxIgnoreTeam = data.HitboxIgnoreTeam end
    if data.InfiniteJumpEnabled ~= nil then ESP.InfiniteJumpEnabled = data.InfiniteJumpEnabled end
    if data.FullbrightEnabled ~= nil then ESP.FullbrightEnabled = data.FullbrightEnabled end
    if data.NoclipEnabled ~= nil then ESP.NoclipEnabled = data.NoclipEnabled end
    -- Keybinds
    if data.ToggleMenuKey then
        local ok3, key = pcall(function() return Enum.KeyCode[data.ToggleMenuKey] end)
        if ok3 and key then Keybinds.ToggleMenu = key end
    end
    if data.AimLockKey then
        local ok3, key = pcall(function() return Enum.UserInputType[data.AimLockKey] end)
        if not ok3 then ok3, key = pcall(function() return Enum.KeyCode[data.AimLockKey] end) end
        if ok3 and key then Keybinds.AimLock = key end
    end

    return true
end

-- Check if executor supports file system
local filesystemSupported = pcall(function() return writefile and readfile and makefolder and isfolder end)
    and type(writefile) == "function"

-- Load config early so ESP state is ready before UI is built
local configLoaded = loadConfig()

-- Dual-connect helper: fires callback on both Activated and MouseButton1Click with debounce
local function dualConnect(btn, callback)
    local debounce = false
    local function wrapped()
        if debounce then return end
        debounce = true
        task.delay(0.1, function() debounce = false end)
        callback()
    end
    btn.Activated:Connect(wrapped)
    btn.MouseButton1Click:Connect(wrapped)
end

-- ────────────────────────────────────────────────
-- Floating toggle button
-- ────────────────────────────────────────────────

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size             = UDim2.new(0, 50, 0, 50)
toggleBtn.Position         = UDim2.new(1, -70, 1, -80)
toggleBtn.BackgroundColor3 = theme.surface
toggleBtn.Text             = "S"
toggleBtn.TextColor3       = theme.accent
toggleBtn.Font             = Enum.Font.GothamBlack
toggleBtn.TextSize         = 22
toggleBtn.AutoButtonColor  = false
toggleBtn.ZIndex           = 10
toggleBtn.Parent           = sg

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 16)

local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color     = theme.border
toggleStroke.Thickness = 1.5

local glowRing = Instance.new("Frame")
glowRing.Size                   = UDim2.new(1, 8, 1, 8)
glowRing.Position               = UDim2.new(0, -4, 0, -4)
glowRing.BackgroundTransparency = 1
glowRing.ZIndex                 = 9
glowRing.Parent                 = toggleBtn

Instance.new("UICorner", glowRing).CornerRadius = UDim.new(0, 18)

local glowStroke = Instance.new("UIStroke", glowRing)
glowStroke.Color        = theme.accent
glowStroke.Thickness    = 1.5
glowStroke.Transparency = 0.7

task.spawn(function()
    while task.wait(2.2) do
        if not toggleBtn.Parent then break end
        TweenService:Create(glowStroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.4}):Play()
        task.wait(1.1)
        TweenService:Create(glowStroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8}):Play()
    end
end)

toggleBtn.MouseEnter:Connect(function()
    TweenService:Create(toggleBtn, TWEEN_FAST, {BackgroundColor3 = theme.elevated}):Play()
    TweenService:Create(toggleStroke, TWEEN_FAST, {Color = theme.accent}):Play()
end)

toggleBtn.MouseLeave:Connect(function()
    TweenService:Create(toggleBtn, TWEEN_FAST, {BackgroundColor3 = theme.surface}):Play()
    TweenService:Create(toggleStroke, TWEEN_FAST, {Color = theme.border}):Play()
end)

-- Status indicator dots (ESP, Aim, Hitbox, Jump)
local indicators = {}
for i = 1, 4 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 2 + (i - 1) * 12, 1, 4)
    dot.BackgroundColor3 = theme.toggleOff
    dot.BorderSizePixel = 0
    dot.ZIndex = 11
    dot.Parent = toggleBtn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    indicators[i] = dot
end

local function updateIndicators()
    local states = {ESP.Enabled, ESP.CursorLockEnabled, ESP.HitboxExpanderEnabled, ESP.InfiniteJumpEnabled}
    for i, dot in ipairs(indicators) do
        local on = states[i]
        TweenService:Create(dot, TWEEN_FAST, {
            BackgroundColor3 = on and theme.toggleOn or theme.toggleOff
        }):Play()
    end
end

-- Draggable toggle button
local tbDragging, tbDragStart, tbStartPos, tbDidDrag = false, nil, nil, false
local TB_DRAG_THRESHOLD = 5

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tbDragging = true; tbDidDrag = false
        tbDragStart = input.Position; tbStartPos = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then tbDragging = false end
        end)
    end
end)

UserInput.InputChanged:Connect(function(input)
    if tbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - tbDragStart
        if math.abs(d.X) > TB_DRAG_THRESHOLD or math.abs(d.Y) > TB_DRAG_THRESHOLD then
            tbDidDrag = true
            toggleBtn.Position = UDim2.new(tbStartPos.X.Scale, tbStartPos.X.Offset + d.X, tbStartPos.Y.Scale, tbStartPos.Y.Offset + d.Y)
        end
    end
end)

-- ────────────────────────────────────────────────
-- Main window
-- ────────────────────────────────────────────────

local WINDOW_W, WINDOW_H = 540, 440
local MIN_WIN_W, MIN_WIN_H = 380, 320
local MAX_WIN_W, MAX_WIN_H = 800, 600
local curW, curH = WINDOW_W, WINDOW_H

local main = Instance.new("Frame")
main.Size             = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
main.Position         = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
main.BackgroundColor3 = theme.bg
main.BorderSizePixel  = 0
main.ClipsDescendants = true
main.Visible          = false
main.Parent           = sg

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = theme.border; mainStroke.Thickness = 1; mainStroke.Transparency = 0.2

-- Drop shadow (subtle outer glow)
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 12, 1, 12); shadow.Position = UDim2.new(0, -6, 0, -6)
shadow.BackgroundTransparency = 1; shadow.ZIndex = -1; shadow.Parent = main
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 16)
local shadowStroke = Instance.new("UIStroke", shadow)
shadowStroke.Color = Color3.new(0, 0, 0); shadowStroke.Thickness = 4; shadowStroke.Transparency = 0.7

-- Top accent bar (gradient)
local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1,0,0,3); topAccent.BackgroundColor3 = theme.accent
topAccent.BorderSizePixel = 0; topAccent.ZIndex = 5; topAccent.Parent = main
Instance.new("UICorner", topAccent).CornerRadius = UDim.new(0, 12)
local topGrad = Instance.new("UIGradient", topAccent)
topGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, theme.accent),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 120, 255))
}

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,46); titleBar.Position = UDim2.new(0,0,0,3)
titleBar.BackgroundColor3 = theme.bg; titleBar.BorderSizePixel = 0; titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0,200,1,0); title.Position = UDim2.new(0,18,0,0)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack
title.Text = "SPECTRE"; title.TextColor3 = theme.text; title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = titleBar

local dot = Instance.new("TextLabel")
dot.Size = UDim2.new(0,16,1,0); dot.Position = UDim2.new(0,102,0,-1)
dot.BackgroundTransparency = 1; dot.Font = Enum.Font.GothamBlack
dot.Text = "//"; dot.TextColor3 = theme.accent; dot.TextSize = 14; dot.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0,200,1,0); subtitle.Position = UDim2.new(0,120,0,1)
subtitle.BackgroundTransparency = 1; subtitle.Font = Enum.Font.GothamSemibold
subtitle.Text = "ESP SUITE"; subtitle.TextColor3 = theme.textDim; subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left; subtitle.Parent = titleBar

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(0,42,0,20); ver.Position = UDim2.new(0,200,0.5,-10)
ver.BackgroundColor3 = theme.elevated; ver.Font = Enum.Font.GothamBold
ver.Text = "v3.1"; ver.TextColor3 = theme.accent; ver.TextSize = 10; ver.Parent = titleBar
Instance.new("UICorner", ver).CornerRadius = UDim.new(0, 6)
local verStroke = Instance.new("UIStroke", ver)
verStroke.Color = theme.border; verStroke.Thickness = 1; verStroke.Transparency = 0.5

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0,30,0,30); minimizeBtn.Position = UDim2.new(1,-76,0.5,-15)
minimizeBtn.BackgroundTransparency = 1; minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = theme.textMuted; minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20; minimizeBtn.Parent = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

minimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(minimizeBtn, TWEEN_FAST, {BackgroundTransparency=0, BackgroundColor3=theme.elevated, TextColor3=theme.accent}):Play()
end)
minimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(minimizeBtn, TWEEN_FAST, {BackgroundTransparency=1, TextColor3=theme.textMuted}):Play()
end)

local isMinimized = false
local preMinimizeH = nil

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30); closeBtn.Position = UDim2.new(1,-42,0.5,-15)
closeBtn.BackgroundTransparency = 1; closeBtn.Text = "X"
closeBtn.TextColor3 = theme.textMuted; closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16; closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TWEEN_FAST, {BackgroundTransparency=0, BackgroundColor3=theme.redDim, TextColor3=theme.red}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TWEEN_FAST, {BackgroundTransparency=1, TextColor3=theme.textMuted}):Play()
end)

-- Divider
local div = Instance.new("Frame")
div.Size = UDim2.new(1,0,0,1); div.Position = UDim2.new(0,0,0,49)
div.BackgroundColor3 = theme.border; div.BorderSizePixel = 0
div.BackgroundTransparency = 0.3; div.Parent = main
local divGrad = Instance.new("UIGradient", div)
divGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.8),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 0.8)
}

-- Draggable
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInput.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- ────────────────────────────────────────────────
-- Resize handle
-- ────────────────────────────────────────────────

local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, 22, 0, 22)
resizeHandle.Position = UDim2.new(1, -22, 1, -22)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = ""; resizeHandle.ZIndex = 6; resizeHandle.Parent = main

for i = 0, 2 do
    local grip = Instance.new("Frame")
    grip.Size = UDim2.new(0, 12 - i * 4, 0, 1)
    grip.AnchorPoint = Vector2.new(1, 1)
    grip.Position = UDim2.new(1, -3, 1, -(4 + i * 4))
    grip.BackgroundColor3 = theme.textMuted
    grip.BackgroundTransparency = 0.5
    grip.BorderSizePixel = 0; grip.ZIndex = 6
    grip.Parent = resizeHandle
end

resizeHandle.MouseEnter:Connect(function()
    for _, c in ipairs(resizeHandle:GetChildren()) do
        if c:IsA("Frame") then
            TweenService:Create(c, TWEEN_FAST, {BackgroundTransparency = 0, BackgroundColor3 = theme.accent}):Play()
        end
    end
end)
resizeHandle.MouseLeave:Connect(function()
    for _, c in ipairs(resizeHandle:GetChildren()) do
        if c:IsA("Frame") then
            TweenService:Create(c, TWEEN_FAST, {BackgroundTransparency = 0.5, BackgroundColor3 = theme.textMuted}):Play()
        end
    end
end)

local resizing, resizeStart, startSize
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = Vector2.new(curW, curH)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)

UserInput.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - resizeStart
        local newW = math.clamp(startSize.X + d.X, MIN_WIN_W, MAX_WIN_W)
        local newH = math.clamp(startSize.Y + d.Y, MIN_WIN_H, MAX_WIN_H)
        curW, curH = newW, newH
        main.Size = UDim2.new(0, newW, 0, newH)
    end
end)

-- ────────────────────────────────────────────────
-- Tab Sidebar
-- ────────────────────────────────────────────────

local SIDEBAR_W, TAB_TOP = 138, 54

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,SIDEBAR_W,1,-TAB_TOP); sidebar.Position = UDim2.new(0,0,0,TAB_TOP)
sidebar.BackgroundColor3 = theme.surface; sidebar.BorderSizePixel = 0; sidebar.Parent = main

local sidebarEdge = Instance.new("Frame")
sidebarEdge.Size = UDim2.new(0,1,1,-TAB_TOP); sidebarEdge.Position = UDim2.new(0,SIDEBAR_W,0,TAB_TOP)
sidebarEdge.BackgroundColor3 = theme.border; sidebarEdge.BorderSizePixel = 0
sidebarEdge.BackgroundTransparency = 0.5; sidebarEdge.Parent = main

local sidebarInner = Instance.new("Frame")
sidebarInner.Size = UDim2.new(1,-16,1,-8); sidebarInner.Position = UDim2.new(0,8,0,0)
sidebarInner.BackgroundTransparency = 1; sidebarInner.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0,3); sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebarInner
Instance.new("UIPadding", sidebarInner).PaddingTop = UDim.new(0, 10)

local tabContent = Instance.new("Frame")
tabContent.Size = UDim2.new(1,-(SIDEBAR_W+12),1,-(TAB_TOP+8))
tabContent.Position = UDim2.new(0,SIDEBAR_W+8,0,TAB_TOP+4)
tabContent.BackgroundTransparency = 1; tabContent.Parent = main

local currentTab, currentTabBtn = nil, nil
local allTabs = {}

local activeBar = Instance.new("Frame")
activeBar.Size = UDim2.new(0,3,0,24); activeBar.Position = UDim2.new(0,6,0,TAB_TOP+13)
activeBar.BackgroundColor3 = theme.accent; activeBar.BorderSizePixel = 0
activeBar.ZIndex = 5; activeBar.Parent = main
Instance.new("UICorner", activeBar).CornerRadius = UDim.new(1, 0)

local function selectTab(entry)
    -- Update state first
    if currentTab then currentTab.Visible = false end
    if currentTabBtn then
        TweenService:Create(currentTabBtn, TWEEN_FAST, {BackgroundTransparency=1, TextColor3=theme.textDim}):Play()
    end
    currentTab = entry.content
    currentTabBtn = entry.btn

    entry.content.Visible = true
    TweenService:Create(entry.btn, TWEEN_FAST, {BackgroundTransparency=0.85, BackgroundColor3=theme.accent, TextColor3=theme.text}):Play()

    pcall(function()
        local btnY = entry.btn.AbsolutePosition.Y - main.AbsolutePosition.Y
        TweenService:Create(activeBar, TWEEN_MED, {Position = UDim2.new(0,6,0,btnY+5)}):Play()
    end)
end

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36); btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold; btn.Text = (icon or "").."  "..name
    btn.TextColor3 = theme.textDim; btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false
    btn.Parent = sidebarInner
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 16)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1,0,1,0); content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3; content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0,0,0,0); content.Visible = false
    content.ScrollBarImageColor3 = theme.border; content.Parent = tabContent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = content
    local pad = Instance.new("UIPadding", content)
    pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,14)

    local entry = {btn = btn, content = content}
    table.insert(allTabs, entry)

    dualConnect(btn, function() selectTab(entry) end)

    btn.MouseEnter:Connect(function()
        if currentTabBtn ~= btn then
            TweenService:Create(btn, TWEEN_FAST, {TextColor3=theme.text, BackgroundTransparency=0.92}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTabBtn ~= btn then
            TweenService:Create(btn, TWEEN_FAST, {TextColor3=theme.textDim, BackgroundTransparency=1}):Play()
        end
    end)

    return content
end

-- ────────────────────────────────────────────────
-- UI Components
-- ────────────────────────────────────────────────

local function addSectionHeader(text, parent)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1,-8,0,30); c.BackgroundTransparency = 1; c.Parent = parent

    local accentDot = Instance.new("Frame")
    accentDot.Size = UDim2.new(0, 4, 0, 4)
    accentDot.Position = UDim2.new(0, 6, 0.5, -2)
    accentDot.BackgroundColor3 = theme.accent; accentDot.BorderSizePixel = 0
    accentDot.Parent = c
    Instance.new("UICorner", accentDot).CornerRadius = UDim.new(1, 0)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-18,1,0); l.Position = UDim2.new(0,16,0,0); l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold; l.Text = string.upper(text); l.TextColor3 = theme.textMuted
    l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1,-4,0,1); line.Position = UDim2.new(0,2,1,-1)
    line.BackgroundColor3 = theme.border; line.BorderSizePixel = 0
    line.BackgroundTransparency = 0.6; line.Parent = c
end

local function addLabel(text, parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-16,0,20); l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham
    l.Text = text; l.TextColor3 = theme.textDim; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = parent
    Instance.new("UIPadding", l).PaddingLeft = UDim.new(0, 6)
end

local function addSpacer(h, parent)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1,0,0,h); s.BackgroundTransparency = 1; s.Parent = parent
end

local function addToggle(text, parent)
    local state = false
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,42); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = theme.border; rowStroke.Thickness = 1; rowStroke.Transparency = 0.3

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-72,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text; lbl.TextColor3 = theme.text; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0,38,0,20); track.Position = UDim2.new(1,-52,0.5,-10)
    track.BackgroundColor3 = theme.toggleOff; track.BorderSizePixel = 0; track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16); knob.Position = UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3 = Color3.fromRGB(180,180,190); knob.BorderSizePixel = 0
    knob.ZIndex = 3; knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1,0,1,0); hitbox.BackgroundTransparency = 1
    hitbox.Text = ""; hitbox.ZIndex = 5; hitbox.Parent = row

    local function setVisual(on)
        if on then
            TweenService:Create(track, TWEEN_FAST, {BackgroundColor3=theme.toggleOn}):Play()
            TweenService:Create(knob, TWEEN_FAST, {Position=UDim2.new(0,20,0.5,-8), BackgroundColor3=Color3.new(1,1,1)}):Play()
            TweenService:Create(rowStroke, TWEEN_FAST, {Color=theme.greenDim, Transparency=0}):Play()
        else
            TweenService:Create(track, TWEEN_FAST, {BackgroundColor3=theme.toggleOff}):Play()
            TweenService:Create(knob, TWEEN_FAST, {Position=UDim2.new(0,2,0.5,-8), BackgroundColor3=Color3.fromRGB(180,180,190)}):Play()
            TweenService:Create(rowStroke, TWEEN_FAST, {Color=theme.border, Transparency=0.3}):Play()
        end
    end

    local callbacks = {}
    dualConnect(hitbox, function()
        state = not state; setVisual(state)
        for _, cb in ipairs(callbacks) do cb(state) end
    end)

    hitbox.MouseEnter:Connect(function()
        TweenService:Create(row, TWEEN_FAST, {BackgroundColor3=theme.elevated:Lerp(Color3.new(1,1,1),0.04)}):Play()
    end)
    hitbox.MouseLeave:Connect(function()
        TweenService:Create(row, TWEEN_FAST, {BackgroundColor3=theme.elevated}):Play()
    end)

    return {
        onChanged = function(_, cb) table.insert(callbacks, cb) end,
        setState  = function(_, val) state = val; setVisual(val) end,
        getState  = function(_) return state end,
    }
end

local function addModeSelector(text, options, defaultIndex, parent, callback)
    local selected = defaultIndex or 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,42); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", row).Color = theme.border

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45,0,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text; lbl.TextColor3 = theme.text; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local segW = #options * 68 + (#options-1)*2 + 4
    local seg = Instance.new("Frame")
    seg.Size = UDim2.new(0,segW,0,26); seg.Position = UDim2.new(1,-(segW+10),0.5,-13)
    seg.BackgroundColor3 = theme.bg; seg.BorderSizePixel = 0; seg.Parent = row
    Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 6)
    local sl = Instance.new("UIListLayout"); sl.FillDirection = Enum.FillDirection.Horizontal
    sl.Padding = UDim.new(0,2); sl.SortOrder = Enum.SortOrder.LayoutOrder
    sl.VerticalAlignment = Enum.VerticalAlignment.Center; sl.Parent = seg
    Instance.new("UIPadding", seg).PaddingLeft = UDim.new(0, 2)

    local btns = {}
    local function updateSelection(idx)
        selected = idx
        for i, b in ipairs(btns) do
            if i == idx then
                TweenService:Create(b, TWEEN_FAST, {BackgroundColor3=theme.accent, BackgroundTransparency=0.15, TextColor3=theme.text}):Play()
            else
                TweenService:Create(b, TWEEN_FAST, {BackgroundColor3=theme.bg, BackgroundTransparency=1, TextColor3=theme.textMuted}):Play()
            end
        end
        if callback then callback(idx, options[idx]) end
    end

    for i, opt in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,68,0,22); b.BackgroundTransparency = 1; b.BackgroundColor3 = theme.bg
        b.BorderSizePixel = 0; b.Font = Enum.Font.GothamSemibold; b.Text = opt
        b.TextColor3 = theme.textMuted; b.TextSize = 11; b.AutoButtonColor = false
        b.LayoutOrder = i; b.Parent = seg
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        table.insert(btns, b)
        dualConnect(b, function() updateSelection(i) end)
    end
    updateSelection(selected)
    return { getSelected = function() return selected end, setSelected = function(_,idx) updateSelection(idx) end }
end

-- Shared slider input: one global listener instead of one per slider
local activeSliders = {}

UserInput.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        for _, s in ipairs(activeSliders) do
            if s.sliding then s.upd(i.Position.X) end
        end
    end
end)

local function addSlider(text, min, max, default, parent, callback, formatFn)
    local value = default
    local fmtFn = formatFn or function(v) return string.format("%.0f%%", v*100) end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,54); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rs = Instance.new("UIStroke", row); rs.Color = theme.border; rs.Thickness = 1; rs.Transparency = 0.3

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-60,0,18); lbl.Position = UDim2.new(0,14,0,5)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text; lbl.TextColor3 = theme.text; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0,44,0,18); valLbl.Position = UDim2.new(1,-54,0,5)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold
    valLbl.Text = fmtFn(default); valLbl.TextColor3 = theme.accent; valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = row

    local tf = Instance.new("Frame")
    tf.Size = UDim2.new(1,-28,0,6); tf.Position = UDim2.new(0,14,0,32)
    tf.BackgroundColor3 = theme.sliderTrack; tf.BorderSizePixel = 0; tf.Parent = row
    Instance.new("UICorner", tf).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0); fill.BackgroundColor3 = theme.sliderFill
    fill.BorderSizePixel = 0; fill.Parent = tf
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local sk = Instance.new("Frame")
    sk.Size = UDim2.new(0,14,0,14); sk.AnchorPoint = Vector2.new(0.5,0.5)
    sk.Position = UDim2.new((default-min)/(max-min),0,0.5,0); sk.BackgroundColor3 = Color3.new(1,1,1)
    sk.BorderSizePixel = 0; sk.ZIndex = 3; sk.Parent = tf
    Instance.new("UICorner", sk).CornerRadius = UDim.new(1, 0)
    local kg = Instance.new("UIStroke", sk); kg.Color = theme.sliderFill; kg.Thickness = 2; kg.Transparency = 0.4

    local da = Instance.new("TextButton")
    da.Size = UDim2.new(1,0,0,28); da.Position = UDim2.new(0,0,0,22)
    da.BackgroundTransparency = 1; da.Text = ""; da.ZIndex = 5; da.Parent = row

    local entry = {sliding = false}
    function entry.upd(inputX)
        local ap, as = tf.AbsolutePosition.X, tf.AbsoluteSize.X
        if as < 1 then return end
        local rel = math.clamp((inputX-ap)/as, 0, 1)
        value = min+(max-min)*rel
        fill.Size = UDim2.new(rel,0,1,0); sk.Position = UDim2.new(rel,0,0.5,0)
        valLbl.Text = fmtFn(value)
        if callback then callback(value) end
    end
    table.insert(activeSliders, entry)

    da.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then entry.sliding=true; entry.upd(i.Position.X) end end)
    da.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then entry.sliding=false end end)

    return {
        setValue = function(_, v)
            value = math.clamp(v, min, max)
            local rel = (value - min) / (max - min)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            sk.Position = UDim2.new(rel, 0, 0.5, 0)
            valLbl.Text = fmtFn(value)
        end,
    }
end

-- ────────────────────────────────────────────────
-- ESP State
-- ────────────────────────────────────────────────

local ESP = {
    Enabled = false, objects = {},
    CursorLockEnabled = false, CursorLockedTarget = nil,
    IgnoreTeam = true, HoldToAim = false,
    FillTransparency = 0.38, OutlineTransparency = 0.15,
    ShowNames = true, ShowHP = true, ShowDistance = true,
    HitboxExpanderEnabled = false, HitboxMultiplier = 4.0,
    HitboxTransparency = 0.6, HitboxIgnoreTeam = true,
    FOVRadius = 200, ShowFOVCircle = false,
    LockSmooth = 0.7,
    InfiniteJumpEnabled = false, FullbrightEnabled = false, NoclipEnabled = false,
    CrosshairEnabled = false, CrosshairSize = 12, CrosshairThickness = 2,
    CrosshairColor = theme.accent, CrosshairGap = 4, CrosshairDot = false,
    CrosshairColorIndex = 5,
}

local function getTeamColor(p)
    if p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end
    return theme.accent
end

-- ────────────────────────────────────────────────
-- ESP Highlights
-- ────────────────────────────────────────────────

local function createHighlight(player)
    if ESP.objects[player] then
        pcall(function() ESP.objects[player].highlight:Destroy() end)
        pcall(function() ESP.objects[player].billboard:Destroy() end)
    end
    if not player.Character then return end
    local char = player.Character
    local head = char:FindFirstChild("Head")
    if not head then return end
    local tc = getTeamColor(player)

    local hl = Instance.new("Highlight")
    hl.Name = "SpectreESP"; hl.FillColor = tc; hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = ESP.FillTransparency; hl.OutlineTransparency = ESP.OutlineTransparency
    hl.Adornee = char; hl.Parent = sg

    local bb = Instance.new("BillboardGui")
    bb.Name = "SpectreESPInfo"; bb.Adornee = head; bb.Size = UDim2.new(0,180,0,52)
    bb.StudsOffset = Vector3.new(0,2.8,0); bb.AlwaysOnTop = true
    bb.LightInfluence = 0; bb.MaxDistance = math.huge; bb.Parent = sg

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1,0,0,18); nl.BackgroundTransparency = 1; nl.Font = Enum.Font.GothamBold
    nl.Text = player.DisplayName; nl.TextColor3 = tc; nl.TextSize = 14
    nl.TextStrokeColor3 = Color3.new(0,0,0); nl.TextStrokeTransparency = 0.3; nl.Parent = bb

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(0.85,0,0,5); hpBg.Position = UDim2.new(0.075,0,0,21)
    hpBg.BackgroundColor3 = Color3.fromRGB(30,30,30); hpBg.BorderSizePixel = 0; hpBg.Parent = bb
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1,0,1,0); hpFill.BackgroundColor3 = Color3.fromRGB(100,255,130)
    hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

    local hpLbl = Instance.new("TextLabel")
    hpLbl.Size = UDim2.new(1,0,0,14); hpLbl.Position = UDim2.new(0,0,0,28)
    hpLbl.BackgroundTransparency = 1; hpLbl.Font = Enum.Font.GothamSemibold
    hpLbl.Text = "100 HP  •  0m"; hpLbl.TextColor3 = Color3.fromRGB(200,200,210)
    hpLbl.TextSize = 11; hpLbl.TextStrokeColor3 = Color3.new(0,0,0)
    hpLbl.TextStrokeTransparency = 0.4; hpLbl.Parent = bb

    ESP.objects[player] = {highlight=hl, billboard=bb, hpFill=hpFill, hpBg=hpBg, hpLabel=hpLbl, nameLabel=nl}
end

local function removeAllHighlights()
    for _, d in pairs(ESP.objects) do
        if type(d)=="table" then
            pcall(function() d.highlight:Destroy() end)
            pcall(function() d.billboard:Destroy() end)
        end
    end
    ESP.objects = {}
end

-- ESP update loop
RunService.Heartbeat:Connect(function()
    if not ESP.Enabled then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for player, d in pairs(ESP.objects) do
        if type(d)~="table" then continue end
        if not player.Character or not player.Character.Parent then continue end
        local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
        if not hum then continue end
        d.highlight.FillTransparency = ESP.FillTransparency
        d.highlight.OutlineTransparency = ESP.OutlineTransparency
        d.nameLabel.Visible = ESP.ShowNames
        d.hpBg.Visible = ESP.ShowHP
        local hp, maxHp = hum.Health, hum.MaxHealth
        local ratio = math.clamp(hp/math.max(maxHp,1), 0, 1)
        d.hpFill.Size = UDim2.new(ratio,0,1,0)
        d.hpFill.BackgroundColor3 = ratio>0.5
            and Color3.fromRGB(100,255,130):Lerp(Color3.fromRGB(255,255,80),(1-ratio)*2)
            or  Color3.fromRGB(255,255,80):Lerp(Color3.fromRGB(255,60,60),(1-ratio*2))
        local dist = 0
        local tr = player.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tr then dist = math.floor((myRoot.Position-tr.Position).Magnitude+0.5) end
        local p = {}
        if ESP.ShowHP then table.insert(p, string.format("%d / %d HP", math.floor(hp), math.floor(maxHp))) end
        if ESP.ShowDistance then table.insert(p, string.format("%dm", dist)) end
        d.hpLabel.Text = table.concat(p, "  •  "); d.hpLabel.Visible = (#p>0)
        local tc = getTeamColor(player)
        d.highlight.FillColor = tc; d.nameLabel.TextColor3 = tc
    end
end)

local function enableESP()
    if ESP.Enabled then return end; ESP.Enabled = true; removeAllHighlights()
    for _, p in Players:GetPlayers() do if p~=LocalPlayer and p.Character then createHighlight(p) end end
end
local function disableESP()
    if not ESP.Enabled then return end; ESP.Enabled = false; removeAllHighlights()
end

-- ────────────────────────────────────────────────
-- Head Expander (apply once per character, not every frame)
-- ────────────────────────────────────────────────

local origHeadSizes   = {}  -- [userId string] = original Vector3
local origHeadCollide = {}  -- [userId string] = original CanCollide
local appliedTo       = {}  -- [userId string] = true if already expanded

local function expandHead(player)
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end
    local key = tostring(player.UserId)
    if not origHeadSizes[key] then
        origHeadSizes[key]   = head.Size
        origHeadCollide[key] = head.CanCollide
    end
    head.Size         = origHeadSizes[key] * ESP.HitboxMultiplier
    head.Transparency = ESP.HitboxTransparency
    head.CanCollide   = false
    head.Massless     = true
    appliedTo[key]    = true
end

local function restoreHead(player)
    local key = tostring(player.UserId)
    if origHeadSizes[key] and player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            head.Size         = origHeadSizes[key]
            head.Transparency = 0
            head.CanCollide   = origHeadCollide[key] or true
            head.Massless     = false
        end
    end
    origHeadSizes[key]   = nil
    origHeadCollide[key] = nil
    appliedTo[key]       = nil
end

local function expandAllHeads()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        if ESP.HitboxIgnoreTeam and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
        expandHead(player)
    end
end

local function restoreAllHeads()
    for _, player in ipairs(Players:GetPlayers()) do
        restoreHead(player)
    end
    origHeadSizes   = {}
    origHeadCollide = {}
    appliedTo       = {}
end

-- Slow re-check every 2 seconds (handles late joins, respawns game resets)
-- NOT every frame - that was causing the freeze
task.spawn(function()
    while task.wait(2) do
        if not ESP.HitboxExpanderEnabled then continue end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not player.Character then continue end
            if ESP.HitboxIgnoreTeam and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
            expandHead(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    origHeadSizes[tostring(p.UserId)]   = nil
    origHeadCollide[tostring(p.UserId)] = nil
    appliedTo[tostring(p.UserId)]       = nil
    if playerConnections[p] then
        for _, conn in ipairs(playerConnections[p]) do conn:Disconnect() end
        playerConnections[p] = nil
    end
    if ESP.objects[p] then
        pcall(function() ESP.objects[p].highlight:Destroy() end)
        pcall(function() ESP.objects[p].billboard:Destroy() end)
        ESP.objects[p] = nil
    end
    if ESP.CursorLockedTarget and ESP.CursorLockedTarget.model and p.Character
        and ESP.CursorLockedTarget.model == p.Character then
        ESP.CursorLockedTarget = nil
    end
end)

-- ────────────────────────────────────────────────
-- FOV Circle
-- ────────────────────────────────────────────────

local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, ESP.FOVRadius * 2, 0, ESP.FOVRadius * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 8
fovCircle.Parent = sg

Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = theme.accent
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3

local function updateFOVCircle()
    local diameter = ESP.FOVRadius * 2
    fovCircle.Size = UDim2.new(0, diameter, 0, diameter)
    fovCircle.Visible = ESP.ShowFOVCircle and ESP.CursorLockEnabled
end

-- ────────────────────────────────────────────────
-- Crosshair Overlay
-- ────────────────────────────────────────────────

local crosshairColors = {
    {name = "White",  color = Color3.fromRGB(255, 255, 255)},
    {name = "Red",    color = Color3.fromRGB(255, 60, 60)},
    {name = "Green",  color = Color3.fromRGB(60, 255, 100)},
    {name = "Cyan",   color = Color3.fromRGB(60, 220, 255)},
    {name = "Accent", color = theme.accent},
}

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Size = UDim2.new(0, 0, 0, 0)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.Visible = false
crosshairContainer.ZIndex = 9
crosshairContainer.Parent = sg

local crossLines = {}
for i = 1, 4 do
    local line = Instance.new("Frame")
    line.BackgroundColor3 = ESP.CrosshairColor
    line.BorderSizePixel = 0
    line.ZIndex = 9
    line.Parent = crosshairContainer
    crossLines[i] = line
end

local crossDot = Instance.new("Frame")
crossDot.AnchorPoint = Vector2.new(0.5, 0.5)
crossDot.Position = UDim2.new(0.5, 0, 0.5, 0)
crossDot.BackgroundColor3 = ESP.CrosshairColor
crossDot.BorderSizePixel = 0
crossDot.ZIndex = 10
crossDot.Visible = false
crossDot.Parent = crosshairContainer
Instance.new("UICorner", crossDot).CornerRadius = UDim.new(1, 0)

local function updateCrosshair()
    local s = ESP.CrosshairSize
    local t = ESP.CrosshairThickness
    local g = ESP.CrosshairGap
    local c = ESP.CrosshairColor
    -- Top
    crossLines[1].Size = UDim2.new(0, t, 0, s)
    crossLines[1].Position = UDim2.new(0.5, -t/2, 0.5, -(g + s))
    -- Bottom
    crossLines[2].Size = UDim2.new(0, t, 0, s)
    crossLines[2].Position = UDim2.new(0.5, -t/2, 0.5, g)
    -- Left
    crossLines[3].Size = UDim2.new(0, s, 0, t)
    crossLines[3].Position = UDim2.new(0.5, -(g + s), 0.5, -t/2)
    -- Right
    crossLines[4].Size = UDim2.new(0, s, 0, t)
    crossLines[4].Position = UDim2.new(0.5, g, 0.5, -t/2)

    for _, l in ipairs(crossLines) do
        l.BackgroundColor3 = c
    end

    -- Center dot
    local dotSize = math.max(t + 2, 4)
    crossDot.Size = UDim2.new(0, dotSize, 0, dotSize)
    crossDot.BackgroundColor3 = c
    crossDot.Visible = ESP.CrosshairDot

    crosshairContainer.Visible = ESP.CrosshairEnabled
end

-- ────────────────────────────────────────────────
-- Aim Lock
-- ────────────────────────────────────────────────

local function trackTarget(part)
    if not part or not part.Parent then return end
    local cf, pos = Camera.CFrame, Camera.CFrame.Position
    local dir = (part.Position - pos)
    if dir.Magnitude < 0.1 then return end
    Camera.CFrame = cf:Lerp(CFrame.lookAt(pos, part.Position), ESP.LockSmooth)
end

local function findNearestPlayer()
    local vp = Camera.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local best, bestD = nil, ESP.FOVRadius
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and p.Character then
            if ESP.IgnoreTeam and LocalPlayer.Team and p.Team == LocalPlayer.Team then continue end
            local root = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local hum = p.Character:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    local sp = Camera:WorldToViewportPoint(root.Position)
                    if sp.Z > 0 then
                        local d = math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2)
                        if d < bestD then bestD = d; best = p end
                    end
                end
            end
        end
    end
    if not best then return nil end
    local m = best.Character
    return {model=m, getTarget=function()
        if not m or not m.Parent then return nil end
        return m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
    end}
end

local function isAimLockInput(input)
    local bind = Keybinds.AimLock
    if bind.EnumType == Enum.UserInputType then
        return input.UserInputType == bind
    else
        return input.KeyCode == bind
    end
end

UserInput.InputBegan:Connect(function(input, gp)
    if gp and input.UserInputType == Enum.UserInputType.MouseButton1 then return end
    if not ESP.CursorLockEnabled then return end
    if not isAimLockInput(input) then return end
    if ESP.HoldToAim then
        ESP.CursorLockedTarget = findNearestPlayer()
    else
        if ESP.CursorLockedTarget then ESP.CursorLockedTarget = nil
        else ESP.CursorLockedTarget = findNearestPlayer() end
    end
end)

UserInput.InputEnded:Connect(function(input)
    if not ESP.CursorLockEnabled or not ESP.HoldToAim then return end
    if isAimLockInput(input) then ESP.CursorLockedTarget = nil end
end)

RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2 - guiInset.Y
    fovCircle.Position = UDim2.new(0, cx, 0, cy)
    fovCircle.Visible = ESP.ShowFOVCircle and ESP.CursorLockEnabled
    crosshairContainer.Position = UDim2.new(0, cx, 0, cy)
    if not ESP.CursorLockEnabled then ESP.CursorLockedTarget = nil; return end
    if ESP.CursorLockedTarget then
        local m = ESP.CursorLockedTarget.model
        if not m or not m.Parent then ESP.CursorLockedTarget = nil; return end
        local hum = m:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then ESP.CursorLockedTarget = nil; return end
        local part = ESP.CursorLockedTarget.getTarget()
        if part and part.Parent then trackTarget(part) else ESP.CursorLockedTarget = nil end
    end
end)

-- ────────────────────────────────────────────────
-- Infinite Jump
-- ────────────────────────────────────────────────

UserInput.JumpRequest:Connect(function()
    if not ESP.InfiniteJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ────────────────────────────────────────────────
-- Noclip
-- ────────────────────────────────────────────────

RunService.Stepped:Connect(function()
    if not ESP.NoclipEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- ────────────────────────────────────────────────
-- Player hooks
-- ────────────────────────────────────────────────

local playerConnections = {} -- [Player] = {connection, ...}

local function hookPlayer(plr)
    if plr == LocalPlayer then return end
    local conn = plr.CharacterAdded:Connect(function(char)
        origHeadSizes[tostring(plr.UserId)]   = nil
        origHeadCollide[tostring(plr.UserId)] = nil
        appliedTo[tostring(plr.UserId)]       = nil
        if ESP.Enabled then task.wait(0.15); createHighlight(plr) end
        -- Watch for Head streaming in (for StreamingEnabled games)
        if ESP.HitboxExpanderEnabled then
            local head = char:FindFirstChild("Head")
            if head then
                expandHead(plr)
            end
        end
        local descConn
        descConn = char.DescendantAdded:Connect(function(desc)
            if desc.Name == "Head" and desc:IsA("BasePart") and ESP.HitboxExpanderEnabled then
                local key = tostring(plr.UserId)
                if not appliedTo[key] then
                    if ESP.HitboxIgnoreTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return end
                    expandHead(plr)
                end
            end
        end)
        -- Store so we can disconnect later
        table.insert(playerConnections[plr], descConn)
    end)
    playerConnections[plr] = {conn}
    -- Also hook existing character if already loaded
    if plr.Character then
        local char = plr.Character
        local descConn = char.DescendantAdded:Connect(function(desc)
            if desc.Name == "Head" and desc:IsA("BasePart") and ESP.HitboxExpanderEnabled then
                local key = tostring(plr.UserId)
                if not appliedTo[key] then
                    if ESP.HitboxIgnoreTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return end
                    expandHead(plr)
                end
            end
        end)
        table.insert(playerConnections[plr], descConn)
    end
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in Players:GetPlayers() do hookPlayer(p) end

-- ────────────────────────────────────────────────
-- Tab: Home
-- ────────────────────────────────────────────────

local homeTab = createTab("Home", ">>")
addSpacer(6, homeTab)

local lf = Instance.new("Frame")
lf.Size = UDim2.new(1,-8,0,90); lf.BackgroundColor3 = theme.elevated; lf.BorderSizePixel = 0; lf.Parent = homeTab
Instance.new("UICorner", lf).CornerRadius = UDim.new(0, 10)
local ls = Instance.new("UIStroke", lf); ls.Color = theme.border; ls.Thickness = 1; ls.Transparency = 0.3

-- Hero accent bar
local heroBar = Instance.new("Frame")
heroBar.Size = UDim2.new(1,0,0,3); heroBar.BackgroundColor3 = theme.accent
heroBar.BorderSizePixel = 0; heroBar.Parent = lf
Instance.new("UICorner", heroBar).CornerRadius = UDim.new(0, 10)
local heroGrad = Instance.new("UIGradient", heroBar)
heroGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, theme.accent),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 120, 255))
}

local lt = Instance.new("TextLabel")
lt.Size = UDim2.new(1,0,0,32); lt.Position = UDim2.new(0,0,0,18); lt.BackgroundTransparency = 1
lt.Font = Enum.Font.GothamBlack; lt.Text = "SPECTRE"; lt.TextColor3 = theme.text; lt.TextSize = 26; lt.Parent = lf

local ls2 = Instance.new("TextLabel")
ls2.Size = UDim2.new(1,0,0,16); ls2.Position = UDim2.new(0,0,0,52); ls2.BackgroundTransparency = 1
ls2.Font = Enum.Font.GothamSemibold; ls2.Text = "ESP  //  Educational Tool  //  v3.1"
ls2.TextColor3 = theme.textMuted; ls2.TextSize = 11; ls2.Parent = lf

addSpacer(4, homeTab)
addSectionHeader("Quick Start", homeTab)
addLabel("Press INSERT or click S to toggle menu", homeTab)
addLabel("Each feature has its own tab", homeTab)
addSpacer(4, homeTab)
addSectionHeader("Keybinds", homeTab)
addLabel("INSERT — Toggle menu", homeTab)
addLabel("Right-Click — Aim lock (toggle or hold)", homeTab)

-- ────────────────────────────────────────────────
-- Tab: ESP
-- ────────────────────────────────────────────────

local espTab = createTab("ESP", "[]")
addSectionHeader("Enable", espTab)

local espToggle = addToggle("ESP Highlights", espTab)
espToggle:onChanged(function(on)
    if on then enableESP() else disableESP() end
    updateIndicators()
    notify(on and "ESP Enabled" or "ESP Disabled", on and theme.toggleOn or theme.red)
end)

addSpacer(2, espTab)
addSectionHeader("Info Display", espTab)

local nameToggle = addToggle("Show Names", espTab)
nameToggle:setState(true); nameToggle:onChanged(function(on) ESP.ShowNames = on end)

local hpToggle = addToggle("Show Health Bar", espTab)
hpToggle:setState(true); hpToggle:onChanged(function(on) ESP.ShowHP = on end)

local distToggle = addToggle("Show Distance", espTab)
distToggle:setState(true); distToggle:onChanged(function(on) ESP.ShowDistance = on end)

addSpacer(2, espTab)
addSectionHeader("Appearance", espTab)
local fillSlider = addSlider("Fill Opacity", 0, 1, 0.38, espTab, function(v) ESP.FillTransparency = v end)
local outlineSlider = addSlider("Outline Opacity", 0, 1, 0.15, espTab, function(v) ESP.OutlineTransparency = v end)
addSpacer(2, espTab)
addLabel("Uses team colors automatically", espTab)

-- ────────────────────────────────────────────────
-- Tab: Aim Lock
-- ────────────────────────────────────────────────

local aimTab = createTab("Aim Lock", "+")
addSectionHeader("Enable", aimTab)

local aimToggle = addToggle("Aim Lock", aimTab)
aimToggle:onChanged(function(on)
    ESP.CursorLockEnabled = on
    if not on then ESP.CursorLockedTarget = nil end
    updateFOVCircle()
    updateIndicators()
    notify(on and "Aim Lock Enabled" or "Aim Lock Disabled", on and theme.toggleOn or theme.red)
end)

addSpacer(2, aimTab)
addSectionHeader("Behavior", aimTab)

local aimModeSelector = addModeSelector("Lock Mode", {"Toggle", "Hold"}, 1, aimTab, function(idx)
    ESP.HoldToAim = (idx == 2)
    if ESP.HoldToAim then ESP.CursorLockedTarget = nil end
end)

local teamToggle = addToggle("Ignore Teammates", aimTab)
teamToggle:setState(true); teamToggle:onChanged(function(on) ESP.IgnoreTeam = on end)

local smoothSlider = addSlider("Smoothness", 0.05, 1, 0.7, aimTab, function(v)
    ESP.LockSmooth = v
end, function(v) return string.format("%.0f%%", v * 100) end)
addLabel("Low = smooth tracking, High = snappy lock", aimTab)

addSpacer(2, aimTab)
addSectionHeader("FOV Circle", aimTab)

local fovToggle = addToggle("Show FOV Circle", aimTab)
fovToggle:onChanged(function(on) ESP.ShowFOVCircle = on; updateFOVCircle() end)

local fovSlider = addSlider("FOV Radius", 50, 500, 200, aimTab, function(v)
    ESP.FOVRadius = v; updateFOVCircle()
end, function(v) return string.format("%.0fpx", v) end)

addSpacer(2, aimTab)
addSectionHeader("How It Works", aimTab)
addLabel("Toggle: right-click to lock, again to release", aimTab)
addLabel("Hold: hold right-click to aim, release to stop", aimTab)
addLabel("Locks onto nearest player inside FOV circle", aimTab)
addLabel("Works through walls at any distance", aimTab)

-- ────────────────────────────────────────────────
-- Tab: Hitbox
-- ────────────────────────────────────────────────

local hitboxTab = createTab("Hitbox", "#")
addSectionHeader("Head Expander", hitboxTab)

local hbToggle = addToggle("Enable Head Expander", hitboxTab)
hbToggle:onChanged(function(on)
    ESP.HitboxExpanderEnabled = on
    if on then expandAllHeads() else restoreAllHeads() end
    updateIndicators()
    notify(on and "Hitbox Expander Enabled" or "Hitbox Expander Disabled", on and theme.toggleOn or theme.red)
end)

addSpacer(2, hitboxTab)
addSectionHeader("Settings", hitboxTab)

local multiplierSlider = addSlider("Size Multiplier", 1, 12, 4, hitboxTab, function(v)
    ESP.HitboxMultiplier = v
    if ESP.HitboxExpanderEnabled then restoreAllHeads(); task.wait(); expandAllHeads() end
end, function(v) return string.format("%.1fx", v) end)

local transparencySlider = addSlider("Hitbox Transparency", 0, 1, 0.6, hitboxTab, function(v)
    ESP.HitboxTransparency = v
    if ESP.HitboxExpanderEnabled then restoreAllHeads(); task.wait(); expandAllHeads() end
end, function(v) return string.format("%.0f%%", v * 100) end)

local hbTeamToggle = addToggle("Skip Teammates", hitboxTab)
hbTeamToggle:setState(true)
hbTeamToggle:onChanged(function(on)
    ESP.HitboxIgnoreTeam = on
    if ESP.HitboxExpanderEnabled then restoreAllHeads(); task.wait(); expandAllHeads() end
end)

addSpacer(2, hitboxTab)
addSectionHeader("Info", hitboxTab)
addLabel("Only expands head hitbox", hitboxTab)
addLabel("Body stays completely normal", hitboxTab)
addLabel("Re-checks every 2 seconds for new players", hitboxTab)
addLabel("Some games may detect this", hitboxTab)

-- ────────────────────────────────────────────────
-- Tab: Movement
-- ────────────────────────────────────────────────

local moveTab = createTab("Movement", "^")
addSectionHeader("Movement", moveTab)

local infJumpToggle = addToggle("Infinite Jump", moveTab)
infJumpToggle:onChanged(function(on)
    ESP.InfiniteJumpEnabled = on
    updateIndicators()
    notify(on and "Infinite Jump Enabled" or "Infinite Jump Disabled", on and theme.toggleOn or theme.red)
end)

addLabel("Press jump while mid-air to jump again", moveTab)

addSpacer(2, moveTab)

local noclipToggle = addToggle("Noclip", moveTab)
noclipToggle:onChanged(function(on)
    ESP.NoclipEnabled = on
    notify(on and "Noclip Enabled" or "Noclip Disabled", on and theme.toggleOn or theme.red)
end)

addLabel("Walk through walls and objects", moveTab)

addSpacer(4, moveTab)
addSectionHeader("Visuals", moveTab)

local Lighting = game:GetService("Lighting")
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local function setFullbright(on)
    if on then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
end

local fullbrightToggle = addToggle("Fullbright", moveTab)
fullbrightToggle:onChanged(function(on)
    ESP.FullbrightEnabled = on
    setFullbright(on)
    notify(on and "Fullbright Enabled" or "Fullbright Disabled", on and theme.toggleOn or theme.red)
end)

addLabel("Removes all darkness and shadows", moveTab)

addSpacer(4, moveTab)
addSectionHeader("Info", moveTab)
addLabel("Noclip disables collision every frame", moveTab)
addLabel("Some games may detect these features", moveTab)

-- ────────────────────────────────────────────────
-- Tab: Crosshair
-- ────────────────────────────────────────────────

local crossTab = createTab("Crosshair", "x")
addSectionHeader("Enable", crossTab)

local crossToggle = addToggle("Show Crosshair", crossTab)
crossToggle:onChanged(function(on)
    ESP.CrosshairEnabled = on
    updateCrosshair()
    notify(on and "Crosshair Enabled" or "Crosshair Disabled", on and theme.toggleOn or theme.red)
end)

addSpacer(2, crossTab)
addSectionHeader("Customize", crossTab)

local crossSizeSlider = addSlider("Size", 4, 30, 12, crossTab, function(v)
    ESP.CrosshairSize = v; updateCrosshair()
end, function(v) return string.format("%.0fpx", v) end)

local crossGapSlider = addSlider("Gap", 0, 20, 4, crossTab, function(v)
    ESP.CrosshairGap = v; updateCrosshair()
end, function(v) return string.format("%.0fpx", v) end)

local crossThickSlider = addSlider("Thickness", 1, 6, 2, crossTab, function(v)
    ESP.CrosshairThickness = v; updateCrosshair()
end, function(v) return string.format("%.0fpx", v) end)

local crossDotToggle = addToggle("Center Dot", crossTab)
crossDotToggle:onChanged(function(on)
    ESP.CrosshairDot = on; updateCrosshair()
end)

addSpacer(2, crossTab)
addSectionHeader("Color", crossTab)

local colorNames = {}
for _, c in ipairs(crosshairColors) do table.insert(colorNames, c.name) end
local crossColorSelector = addModeSelector("Color", colorNames, ESP.CrosshairColorIndex, crossTab, function(idx)
    ESP.CrosshairColorIndex = idx
    ESP.CrosshairColor = crosshairColors[idx].color
    updateCrosshair()
end)

addSpacer(2, crossTab)
addSectionHeader("Info", crossTab)
addLabel("Crosshair is drawn at screen center", crossTab)
addLabel("Stays visible even when menu is closed", crossTab)
addLabel("Settings are saved with your config", crossTab)

-- ────────────────────────────────────────────────
-- Tab: Settings
-- ────────────────────────────────────────────────

local settingsTab = createTab("Settings", "=")
addSectionHeader("About", settingsTab)
addLabel("SPECTRE ESP v3.1", settingsTab)

addSpacer(4, settingsTab)
addSectionHeader("Keybinds", settingsTab)
addLabel("Click a keybind button, then press a key", settingsTab)
addSpacer(2, settingsTab)

-- Keybind button component
local function addKeybindButton(text, bindName, parent)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,40); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rowStroke = Instance.new("UIStroke", row); rowStroke.Color = theme.border; rowStroke.Thickness = 1; rowStroke.Transparency = 0.3

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-110,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = text; lbl.TextColor3 = theme.text; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0,88,0,26); keyBtn.Position = UDim2.new(1,-98,0.5,-13)
    keyBtn.BackgroundColor3 = theme.bg; keyBtn.BorderSizePixel = 0
    keyBtn.Font = Enum.Font.GothamSemibold; keyBtn.TextSize = 12
    keyBtn.Text = getKeyName(Keybinds[bindName])
    keyBtn.TextColor3 = theme.accent; keyBtn.AutoButtonColor = false
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

    local listening = false
    local listenConn = nil

    dualConnect(keyBtn, function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = theme.red

        task.defer(function() listenConn = UserInput.InputBegan:Connect(function(input, gp)
            if input.KeyCode == Enum.KeyCode.Escape then
                listening = false
                keyBtn.Text = getKeyName(Keybinds[bindName])
                keyBtn.TextColor3 = theme.accent
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keybinds[bindName] = input.KeyCode
                keyBtn.Text = getKeyName(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                Keybinds[bindName] = input.UserInputType
                keyBtn.Text = getKeyName(input.UserInputType)
            else
                listening = false
                keyBtn.Text = getKeyName(Keybinds[bindName])
                keyBtn.TextColor3 = theme.accent
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                return
            end
            listening = false
            keyBtn.TextColor3 = theme.accent
            if listenConn then listenConn:Disconnect(); listenConn = nil end
            saveConfig()
            notify(text .. " set to " .. getKeyName(Keybinds[bindName]), theme.accent)
        end) end)
    end)

    return keyBtn
end

local toggleMenuKeyBtn = addKeybindButton("Toggle Menu", "ToggleMenu", settingsTab)
local aimLockKeyBtn = addKeybindButton("Aim Lock", "AimLock", settingsTab)

local function syncUI()
    nameToggle:setState(ESP.ShowNames)
    hpToggle:setState(ESP.ShowHP)
    distToggle:setState(ESP.ShowDistance)
    teamToggle:setState(ESP.IgnoreTeam)
    fovToggle:setState(ESP.ShowFOVCircle)
    crossToggle:setState(ESP.CrosshairEnabled)
    crossDotToggle:setState(ESP.CrosshairDot)
    hbTeamToggle:setState(ESP.HitboxIgnoreTeam)
    infJumpToggle:setState(ESP.InfiniteJumpEnabled)
    fullbrightToggle:setState(ESP.FullbrightEnabled)
    noclipToggle:setState(ESP.NoclipEnabled)
    setFullbright(ESP.FullbrightEnabled)
    fillSlider:setValue(ESP.FillTransparency)
    outlineSlider:setValue(ESP.OutlineTransparency)
    smoothSlider:setValue(ESP.LockSmooth)
    fovSlider:setValue(ESP.FOVRadius)
    crossSizeSlider:setValue(ESP.CrosshairSize)
    crossGapSlider:setValue(ESP.CrosshairGap)
    crossThickSlider:setValue(ESP.CrosshairThickness)
    multiplierSlider:setValue(ESP.HitboxMultiplier)
    transparencySlider:setValue(ESP.HitboxTransparency)
    aimModeSelector:setSelected(ESP.HoldToAim and 2 or 1)
    if crosshairColors[ESP.CrosshairColorIndex] then
        ESP.CrosshairColor = crosshairColors[ESP.CrosshairColorIndex].color
    end
    crossColorSelector:setSelected(ESP.CrosshairColorIndex)
    toggleMenuKeyBtn.Text = getKeyName(Keybinds.ToggleMenu)
    aimLockKeyBtn.Text = getKeyName(Keybinds.AimLock)
    updateFOVCircle()
    updateCrosshair()
    updateIndicators()
end

addSpacer(4, settingsTab)
addSectionHeader("Config", settingsTab)

-- Save button
local saveRow = Instance.new("Frame")
saveRow.Size = UDim2.new(1,-8,0,40); saveRow.BackgroundColor3 = theme.elevated; saveRow.BorderSizePixel = 0; saveRow.Parent = settingsTab
Instance.new("UICorner", saveRow).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", saveRow).Color = theme.border

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1,0,1,0); saveBtn.BackgroundTransparency = 1
saveBtn.Font = Enum.Font.GothamSemibold; saveBtn.Text = "Save Config"
saveBtn.TextColor3 = theme.toggleOn; saveBtn.TextSize = 13
saveBtn.AutoButtonColor = false; saveBtn.Parent = saveRow

dualConnect(saveBtn, function()
    if not filesystemSupported then
        notify("Executor doesn't support saving", theme.red)
        return
    end
    saveConfig()
    notify("Config saved", theme.toggleOn)
end)

saveBtn.MouseEnter:Connect(function()
    TweenService:Create(saveRow, TWEEN_FAST, {BackgroundColor3 = theme.elevated:Lerp(Color3.new(1,1,1), 0.04)}):Play()
end)
saveBtn.MouseLeave:Connect(function()
    TweenService:Create(saveRow, TWEEN_FAST, {BackgroundColor3 = theme.elevated}):Play()
end)

-- Load button
local loadRow = Instance.new("Frame")
loadRow.Size = UDim2.new(1,-8,0,40); loadRow.BackgroundColor3 = theme.elevated; loadRow.BorderSizePixel = 0; loadRow.Parent = settingsTab
Instance.new("UICorner", loadRow).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", loadRow).Color = theme.border

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(1,0,1,0); loadBtn.BackgroundTransparency = 1
loadBtn.Font = Enum.Font.GothamSemibold; loadBtn.Text = "Load Config"
loadBtn.TextColor3 = theme.accent; loadBtn.TextSize = 13
loadBtn.AutoButtonColor = false; loadBtn.Parent = loadRow

dualConnect(loadBtn, function()
    if loadConfig() then
        syncUI()
        notify("Config loaded", theme.toggleOn)
    else
        notify("No saved config found", theme.red)
    end
end)

loadBtn.MouseEnter:Connect(function()
    TweenService:Create(loadRow, TWEEN_FAST, {BackgroundColor3 = theme.elevated:Lerp(Color3.new(1,1,1), 0.04)}):Play()
end)
loadBtn.MouseLeave:Connect(function()
    TweenService:Create(loadRow, TWEEN_FAST, {BackgroundColor3 = theme.elevated}):Play()
end)

-- Reset to defaults button
local resetRow = Instance.new("Frame")
resetRow.Size = UDim2.new(1,-8,0,40); resetRow.BackgroundColor3 = theme.elevated; resetRow.BorderSizePixel = 0; resetRow.Parent = settingsTab
Instance.new("UICorner", resetRow).CornerRadius = UDim.new(0, 8)
local resetStroke = Instance.new("UIStroke", resetRow); resetStroke.Color = theme.border

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1,0,1,0); resetBtn.BackgroundTransparency = 1
resetBtn.Font = Enum.Font.GothamSemibold; resetBtn.Text = "Reset to Defaults"
resetBtn.TextColor3 = theme.red; resetBtn.TextSize = 13
resetBtn.AutoButtonColor = false; resetBtn.Parent = resetRow

dualConnect(resetBtn, function()
    -- Reset ESP state
    ESP.FillTransparency = 0.38; ESP.OutlineTransparency = 0.15
    ESP.ShowNames = true; ESP.ShowHP = true; ESP.ShowDistance = true
    ESP.IgnoreTeam = true; ESP.HoldToAim = false
    ESP.LockSmooth = 0.7; ESP.FOVRadius = 200; ESP.ShowFOVCircle = false
    ESP.HitboxMultiplier = 4.0; ESP.HitboxTransparency = 0.6; ESP.HitboxIgnoreTeam = true; ESP.InfiniteJumpEnabled = false
    ESP.FullbrightEnabled = false; ESP.NoclipEnabled = false
    ESP.CrosshairEnabled = false; ESP.CrosshairSize = 12; ESP.CrosshairGap = 4; ESP.CrosshairThickness = 2
    ESP.CrosshairDot = false; ESP.CrosshairColorIndex = 5; ESP.CrosshairColor = theme.accent
    -- Reset keybinds
    Keybinds.ToggleMenu = Enum.KeyCode.Insert
    Keybinds.AimLock = Enum.UserInputType.MouseButton2
    -- Sync UI to match reset state
    syncUI()
    -- Save defaults
    if filesystemSupported then saveConfig() end
    notify("All settings reset to defaults", theme.accent)
end)

resetBtn.MouseEnter:Connect(function()
    TweenService:Create(resetRow, TWEEN_FAST, {BackgroundColor3 = theme.redDim}):Play()
end)
resetBtn.MouseLeave:Connect(function()
    TweenService:Create(resetRow, TWEEN_FAST, {BackgroundColor3 = theme.elevated}):Play()
end)

addSpacer(4, settingsTab)
addSectionHeader("Info", settingsTab)
addLabel("Config saves to executor's workspace folder", settingsTab)
addLabel("Keybinds are saved with config", settingsTab)

-- ────────────────────────────────────────────────
-- Auto-select first tab
-- ────────────────────────────────────────────────

if #allTabs > 0 then
    currentTab = allTabs[1].content; currentTabBtn = allTabs[1].btn
    allTabs[1].content.Visible = true
    allTabs[1].btn.BackgroundTransparency = 0.85
    allTabs[1].btn.BackgroundColor3 = theme.accent
    allTabs[1].btn.TextColor3 = theme.text
    task.defer(function()
        task.wait()
        pcall(function()
            activeBar.Position = UDim2.new(0, 6, 0, allTabs[1].btn.AbsolutePosition.Y - main.AbsolutePosition.Y + 5)
        end)
    end)
end

-- Sync UI with config loaded at startup
if configLoaded then syncUI() end

-- ────────────────────────────────────────────────
-- Open / Close
-- ────────────────────────────────────────────────

local isOpen = false

local function openMenu()
    if isOpen then return end; isOpen = true; isMinimized = false
    minimizeBtn.Text = "-"; main.Visible = true
    main.BackgroundTransparency = 1
    main.Size = UDim2.new(0, curW*0.95, 0, curH*0.95)
    main.Position = UDim2.new(0.5, -curW*0.475, 0.5, -curH*0.475)
    TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,curW,0,curH),
        Position = UDim2.new(0.5,-curW/2,0.5,-curH/2),
        BackgroundTransparency = 0
    }):Play()
end

local function closeMenu()
    if not isOpen then return end; isOpen = false
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, curW*0.95, 0, curH*0.95),
        Position = UDim2.new(0.5, -curW*0.475, 0.5, -curH*0.475),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.25, function() if not isOpen then main.Visible = false end end)
end

local TITLE_BAR_H = 52

local function minimizeMenu()
    if not isOpen or isMinimized then return end
    isMinimized = true
    preMinimizeH = curH
    minimizeBtn.Text = "+"
    TweenService:Create(main, TWEEN_MED, {
        Size = UDim2.new(0, curW, 0, TITLE_BAR_H)
    }):Play()
end

local function restoreMenu()
    if not isMinimized then return end
    isMinimized = false
    curH = preMinimizeH or WINDOW_H
    minimizeBtn.Text = "-"
    TweenService:Create(main, TWEEN_MED, {
        Size = UDim2.new(0, curW, 0, curH)
    }):Play()
end

dualConnect(minimizeBtn, function()
    if isMinimized then restoreMenu() else minimizeMenu() end
end)

dualConnect(toggleBtn, function()
    if tbDidDrag then return end
    if isOpen then closeMenu() else openMenu() end
end)
dualConnect(closeBtn, closeMenu)

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Keybinds.ToggleMenu then
        if isOpen then closeMenu() else openMenu() end
    end
end)

print("SPECTRE ESP v3.1 loaded")
print("→ Open with " .. getKeyName(Keybinds.ToggleMenu) .. " or S button")

task.defer(function()
    task.wait(0.5)
    notify("SPECTRE v3.1 loaded", theme.accent)
    if configLoaded then
        task.wait(0.3)
        notify("Config loaded", theme.toggleOn)
    elseif filesystemSupported then
        task.wait(0.3)
        notify("No config found — using defaults", theme.textDim)
    else
        task.wait(0.3)
        notify("Executor doesn't support saving configs", theme.red)
    end
end)