local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local UserInput      = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")

local Mouse  = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

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

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Dual-connect helper: fires callback on both Activated and MouseButton1Click with debounce
local function dualConnect(btn, callback)
    local debounce = false
    local function wrapped()
        if debounce then return end
        debounce = true
        callback()
        task.delay(0.1, function() debounce = false end)
    end
    btn.Activated:Connect(wrapped)
    btn.MouseButton1Click:Connect(wrapped)
end

-- ────────────────────────────────────────────────
-- Floating toggle button
-- ────────────────────────────────────────────────

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size             = UDim2.new(0, 48, 0, 48)
toggleBtn.Position         = UDim2.new(1, -68, 1, -78)
toggleBtn.BackgroundColor3 = theme.surface
toggleBtn.Text             = "S"
toggleBtn.TextColor3       = theme.accent
toggleBtn.Font             = Enum.Font.GothamBlack
toggleBtn.TextSize         = 20
toggleBtn.AutoButtonColor  = false
toggleBtn.ZIndex           = 10
toggleBtn.Parent           = sg

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

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

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = theme.border; mainStroke.Thickness = 1; mainStroke.Transparency = 0.2

-- Top accent
local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1,0,0,2); topAccent.BackgroundColor3 = theme.accent
topAccent.BorderSizePixel = 0; topAccent.ZIndex = 5; topAccent.Parent = main

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,42); titleBar.Position = UDim2.new(0,0,0,2)
titleBar.BackgroundColor3 = theme.bg; titleBar.BorderSizePixel = 0; titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0,200,1,0); title.Position = UDim2.new(0,16,0,0)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack
title.Text = "SPECTRE"; title.TextColor3 = theme.text; title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = titleBar

local dot = Instance.new("TextLabel")
dot.Size = UDim2.new(0,20,1,0); dot.Position = UDim2.new(0,96,0,-1)
dot.BackgroundTransparency = 1; dot.Font = Enum.Font.GothamBlack
dot.Text = "•"; dot.TextColor3 = theme.accent; dot.TextSize = 18; dot.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0,200,1,0); subtitle.Position = UDim2.new(0,110,0,1)
subtitle.BackgroundTransparency = 1; subtitle.Font = Enum.Font.Gotham
subtitle.Text = "ESP"; subtitle.TextColor3 = theme.textDim; subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left; subtitle.Parent = titleBar

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(0,40,0,18); ver.Position = UDim2.new(0,138,0.5,-9)
ver.BackgroundColor3 = theme.elevated; ver.Font = Enum.Font.GothamSemibold
ver.Text = "v2.1"; ver.TextColor3 = theme.textMuted; ver.TextSize = 10; ver.Parent = titleBar
Instance.new("UICorner", ver).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30); closeBtn.Position = UDim2.new(1,-42,0,6)
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
div.Size = UDim2.new(1,-24,0,1); div.Position = UDim2.new(0,12,0,44)
div.BackgroundColor3 = theme.border; div.BorderSizePixel = 0
div.BackgroundTransparency = 0.4; div.Parent = main

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

local SIDEBAR_W, TAB_TOP = 130, 52

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,SIDEBAR_W,1,-TAB_TOP); sidebar.Position = UDim2.new(0,0,0,TAB_TOP)
sidebar.BackgroundColor3 = theme.surface; sidebar.BorderSizePixel = 0; sidebar.Parent = main

local sidebarEdge = Instance.new("Frame")
sidebarEdge.Size = UDim2.new(0,1,1,-TAB_TOP); sidebarEdge.Position = UDim2.new(0,SIDEBAR_W,0,TAB_TOP)
sidebarEdge.BackgroundColor3 = theme.border; sidebarEdge.BorderSizePixel = 0
sidebarEdge.BackgroundTransparency = 0.4; sidebarEdge.Parent = main

local sidebarInner = Instance.new("Frame")
sidebarInner.Size = UDim2.new(1,-12,1,0); sidebarInner.Position = UDim2.new(0,6,0,0)
sidebarInner.BackgroundTransparency = 1; sidebarInner.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0,2); sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebarInner
Instance.new("UIPadding", sidebarInner).PaddingTop = UDim.new(0, 8)

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
    btn.Size = UDim2.new(1,0,0,34); btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold; btn.Text = (icon or "").."  "..name
    btn.TextColor3 = theme.textDim; btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false
    btn.Parent = sidebarInner
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 14)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1,0,1,0); content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3; content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0,0,0,0); content.Visible = false
    content.ScrollBarImageColor3 = theme.border; content.Parent = tabContent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,6); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = content
    local pad = Instance.new("UIPadding", content)
    pad.PaddingTop = UDim.new(0,4); pad.PaddingBottom = UDim.new(0,12)

    local entry = {btn = btn, content = content}
    table.insert(allTabs, entry)

    dualConnect(btn, function() selectTab(entry) end)

    btn.MouseEnter:Connect(function()
        if currentTabBtn ~= btn then TweenService:Create(btn, TWEEN_FAST, {TextColor3=theme.text}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if currentTabBtn ~= btn then TweenService:Create(btn, TWEEN_FAST, {TextColor3=theme.textDim}):Play() end
    end)

    return content
end

-- ────────────────────────────────────────────────
-- UI Components
-- ────────────────────────────────────────────────

local function addSectionHeader(text, parent)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1,-8,0,28); c.BackgroundTransparency = 1; c.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,1,0); l.Position = UDim2.new(0,4,0,0); l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold; l.Text = string.upper(text); l.TextColor3 = theme.textMuted
    l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1,-4,0,1); line.Position = UDim2.new(0,2,1,-1)
    line.BackgroundColor3 = theme.border; line.BorderSizePixel = 0
    line.BackgroundTransparency = 0.5; line.Parent = c
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
    row.Size = UDim2.new(1,-8,0,40); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
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
    row.Size = UDim2.new(1,-8,0,40); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
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

local function addSlider(text, min, max, default, parent, callback, formatFn)
    local value = default
    local fmtFn = formatFn or function(v) return string.format("%.0f%%", v*100) end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = theme.elevated; row.BorderSizePixel = 0; row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
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

    local sliding = false
    local function upd(inputX)
        local ap, as = tf.AbsolutePosition.X, tf.AbsoluteSize.X
        if as < 1 then return end
        local rel = math.clamp((inputX-ap)/as, 0, 1)
        value = min+(max-min)*rel
        fill.Size = UDim2.new(rel,0,1,0); sk.Position = UDim2.new(rel,0,0.5,0)
        valLbl.Text = fmtFn(value)
        if callback then callback(value) end
    end
    da.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true; upd(i.Position.X) end end)
    da.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
    UserInput.InputChanged:Connect(function(i) if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end)
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
    HitboxIgnoreTeam = true,
    FOVRadius = 200, ShowFOVCircle = false,
    LockSmooth = 0.7,
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
    head.Size       = origHeadSizes[key] * ESP.HitboxMultiplier
    head.CanCollide = false
    head.Massless   = true
    appliedTo[key]  = true
end

local function restoreHead(player)
    local key = tostring(player.UserId)
    if origHeadSizes[key] and player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            head.Size       = origHeadSizes[key]
            head.CanCollide = origHeadCollide[key] or true
            head.Massless   = false
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
            local key = tostring(player.UserId)
            if not appliedTo[key] then
                expandHead(player)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    origHeadSizes[tostring(p.UserId)]   = nil
    origHeadCollide[tostring(p.UserId)] = nil
    appliedTo[tostring(p.UserId)]       = nil
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
    return {model=m, getTarget=function() return m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart end}
end

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not ESP.CursorLockEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if ESP.HoldToAim then
        ESP.CursorLockedTarget = findNearestPlayer()
    else
        if ESP.CursorLockedTarget then ESP.CursorLockedTarget = nil
        else ESP.CursorLockedTarget = findNearestPlayer() end
    end
end)

UserInput.InputEnded:Connect(function(input)
    if not ESP.CursorLockEnabled or not ESP.HoldToAim then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then ESP.CursorLockedTarget = nil end
end)

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = ESP.ShowFOVCircle and ESP.CursorLockEnabled
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
-- Player hooks
-- ────────────────────────────────────────────────

local function hookPlayer(plr)
    if plr == LocalPlayer then return end
    plr.CharacterAdded:Connect(function()
        origHeadSizes[tostring(plr.UserId)]   = nil
        origHeadCollide[tostring(plr.UserId)] = nil
        appliedTo[tostring(plr.UserId)]       = nil
        if ESP.Enabled then task.wait(0.15); createHighlight(plr) end
    end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in Players:GetPlayers() do hookPlayer(p) end

-- ────────────────────────────────────────────────
-- Tab: Home
-- ────────────────────────────────────────────────

local homeTab = createTab("Home", ">>")
addSpacer(8, homeTab)

local lf = Instance.new("Frame")
lf.Size = UDim2.new(1,-8,0,80); lf.BackgroundColor3 = theme.elevated; lf.BorderSizePixel = 0; lf.Parent = homeTab
Instance.new("UICorner", lf).CornerRadius = UDim.new(0, 8)
local ls = Instance.new("UIStroke", lf); ls.Color = theme.border; ls.Thickness = 1

local lt = Instance.new("TextLabel")
lt.Size = UDim2.new(1,0,0,32); lt.Position = UDim2.new(0,0,0,14); lt.BackgroundTransparency = 1
lt.Font = Enum.Font.GothamBlack; lt.Text = "SPECTRE"; lt.TextColor3 = theme.text; lt.TextSize = 24; lt.Parent = lf

local ls2 = Instance.new("TextLabel")
ls2.Size = UDim2.new(1,0,0,16); ls2.Position = UDim2.new(0,0,0,48); ls2.BackgroundTransparency = 1
ls2.Font = Enum.Font.Gotham; ls2.Text = "ESP  •  Educational Tool  •  v2.1"
ls2.TextColor3 = theme.textMuted; ls2.TextSize = 12; ls2.Parent = lf

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
espToggle:onChanged(function(on) if on then enableESP() else disableESP() end end)

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
addSlider("Fill Opacity", 0, 1, 0.38, espTab, function(v) ESP.FillTransparency = v end)
addSlider("Outline Opacity", 0, 1, 0.15, espTab, function(v) ESP.OutlineTransparency = v end)
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
end)

addSpacer(2, aimTab)
addSectionHeader("Behavior", aimTab)

addModeSelector("Lock Mode", {"Toggle", "Hold"}, 1, aimTab, function(idx)
    ESP.HoldToAim = (idx == 2)
    if ESP.HoldToAim then ESP.CursorLockedTarget = nil end
end)

local teamToggle = addToggle("Ignore Teammates", aimTab)
teamToggle:setState(true); teamToggle:onChanged(function(on) ESP.IgnoreTeam = on end)

addSlider("Smoothness", 0.05, 1, 0.7, aimTab, function(v)
    ESP.LockSmooth = v
end, function(v) return string.format("%.0f%%", v * 100) end)
addLabel("Low = smooth tracking, High = snappy lock", aimTab)

addSpacer(2, aimTab)
addSectionHeader("FOV Circle", aimTab)

local fovToggle = addToggle("Show FOV Circle", aimTab)
fovToggle:onChanged(function(on) ESP.ShowFOVCircle = on; updateFOVCircle() end)

addSlider("FOV Radius", 50, 500, 200, aimTab, function(v)
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
end)

addSpacer(2, hitboxTab)
addSectionHeader("Settings", hitboxTab)

addSlider("Size Multiplier", 1, 12, 4, hitboxTab, function(v)
    ESP.HitboxMultiplier = v
    if ESP.HitboxExpanderEnabled then restoreAllHeads(); task.wait(); expandAllHeads() end
end, function(v) return string.format("%.1fx", v) end)

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
-- Tab: Settings
-- ────────────────────────────────────────────────

local settingsTab = createTab("Settings", "=")
addSectionHeader("About", settingsTab)
addLabel("SPECTRE ESP v2.1", settingsTab)
addSpacer(4, settingsTab)
addSectionHeader("Keybinds", settingsTab)
addLabel("INSERT — Toggle menu", settingsTab)
addLabel("Right-Click — Aim lock (toggle or hold)", settingsTab)
addSpacer(4, settingsTab)
addSectionHeader("Features", settingsTab)
addLabel("ESP — Player highlights with info", settingsTab)
addLabel("Aim Lock — Camera lock to players", settingsTab)
addLabel("Hitbox — Expand head for easier hits", settingsTab)

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

-- ────────────────────────────────────────────────
-- Open / Close
-- ────────────────────────────────────────────────

local isOpen = false

local function openMenu()
    if isOpen then return end; isOpen = true; main.Visible = true
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

dualConnect(toggleBtn, function()
    if tbDidDrag then return end
    if isOpen then closeMenu() else openMenu() end
end)
dualConnect(closeBtn, closeMenu)

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if isOpen then closeMenu() else openMenu() end
    end
end)

print("SPECTRE ESP v2.1 loaded")
print("→ Open with INSERT or S button")