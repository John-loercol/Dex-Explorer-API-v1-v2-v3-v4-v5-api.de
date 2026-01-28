-- ===================================================
-- local Services...
local CoreGui = game:GetService("CoreGui")

local UserInputService = game:GetService("UserInputService")

local UIS = game:GetService("UserInputService")

local uis = game:GetService("UserInputService")

local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")

local players = game:GetService("Players")

local RunService = game:GetService("RunService")

local runService = game:GetService("RunService")

local Lighting = game:GetService("Lighting")

local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local VirtualInputManager = game:GetService("VirtualInputManager")

local HttpService = game:GetService("HttpService")

local SoundService = game:GetService("SoundService")

local MarketplaceService = game:GetService("MarketplaceService")

local TeleportService = game:GetService("TeleportService")

local HttpService = game:GetService("HttpService")

local PlaceId = game.PlaceId
local JobId = game.JobId
local LocalPlayer = Players.LocalPlayer
local Player = game.Players.LocalPlayer
local player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local camera = workspace.CurrentCamera

-- ===================================================
-- ตรวจสอบการสร้าง CoreGui, Humanoid
repeat task.wait() until game:IsLoaded()

-- CoreGui Loading...
repeat task.wait() until game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

-- ===================================================
local ERCMainTitleimg = "rbxassetid://138560507380517"

-- UICorner สำหรับมุมโค้ง
local function createUICorner(parent, radius)
    local corner = Instance.new("UICorner")

    if typeof(radius) == "UDim" then
        corner.CornerRadius = radius
    elseif typeof(radius) == "number" then
        corner.CornerRadius = UDim.new(0, radius)
    else
        corner.CornerRadius = UDim.new(0, 4) -- default
    end

    corner.Parent = parent
    return corner
end

-- ฟังก์ชันสร้าง UIStroke สำหรับเส้นขอบ (รองรับหลายรูปแบบ)
local function createUIStroke(parent, thickness, color, transparency)
    local stroke = Instance.new("UIStroke")

    -- Thickness
    if typeof(thickness) == "number" then
        stroke.Thickness = thickness
    else
        stroke.Thickness = 1.5 -- default
    end

    -- Color
    if typeof(color) == "Color3" then
        stroke.Color = color
    else
        stroke.Color = Color3.fromRGB(50, 50, 50)
    end

    -- Transparency
    if typeof(transparency) == "number" then
        stroke.Transparency = math.clamp(transparency, 0, 1)
    else
        stroke.Transparency = 0
    end

    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round

    stroke.Parent = parent
    return stroke
end

-- Layout / Padding
local function createListLayout(parent, paddingBetween, paddingTopBottom)
    -- UIListLayout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, paddingBetween or 10)
    layout.Parent = parent

    -- UIPadding
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, paddingTopBottom or 5)
    pad.PaddingBottom = UDim.new(0, paddingTopBottom or 5)
    pad.Parent = parent

    return layout, pad
end

-- Center Frame (Universal / Safe)
local function CenterFrame(Frame, XP, YP)
	local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1280, 720)

	Frame.Position = UDim2.new(
		0, (viewportSize.X - Frame.AbsoluteSize.X) / (XP or 2),
		0, (viewportSize.Y - Frame.AbsoluteSize.Y) / (YP or 2)
	)
end

-- ฟังก์ชันสร้าง UITextSizeConstraint
local function createTextSizeConstraint(parent, minSize, maxSize)
    if not parent then return end

    local constraint = Instance.new("UITextSizeConstraint")

    -- ค่าเริ่มต้น (default)
    constraint.MinTextSize = typeof(minSize) == "number" and minSize or 12
    constraint.MaxTextSize = typeof(maxSize) == "number" and maxSize or 18

    constraint.Parent = parent
    return constraint
end

-- ==========================
-- Function: RobloxGUI
-- ทำให้ ScreenGui แสดงผลอยู่เหนือ Executor
-- ==========================
local function RobloxGUI(gui)
	assert(typeof(gui) == "Instance" and gui:IsA("ScreenGui"),
		"[RobloxGUI] Argument must be ScreenGui")

	-- ป้องกัน Parent ซ้ำ
	pcall(function()
		if gui.Parent then
			gui.Parent = nil
		end
	end)

	-- ป้องกัน GUI หายตอนตัวละครตาย
	gui.ResetOnSpawn = false

	-- Executor Layer Priority

	-- gethui (Delta / Fluxus / Hydrogen)
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and typeof(hui) == "Instance" then
			gui.Parent = hui
			return gui
		end
	end

	-- Synapse X
	if syn and typeof(syn.protect_gui) == "function" then
		pcall(function()
			syn.protect_gui(gui)
		end)
		gui.Parent = CoreGui
		return gui
	end

	-- Roblox Internal GUI Layer
	local robloxGui = CoreGui:FindFirstChild("RobloxGui")
	if robloxGui then
		gui.Parent = robloxGui
		return gui
	end

	-- Fallback
	gui.Parent = CoreGui
	return gui
end

-- erc Notification
local ScreenGuiNotification = Instance.new("ScreenGui")
ScreenGuiNotification.Name = "Roblox.API.Notification.ARS"
ScreenGuiNotification.ResetOnSpawn = false
ScreenGuiNotification.DisplayOrder = 9e9
RobloxGUI(ScreenGuiNotification)

-- ANCHOR FRAME
local AnchorFrame = Instance.new("Frame")
AnchorFrame.Name = "NotificationAnchor"
AnchorFrame.Size = UDim2.new(1, 0, 0, 1)
AnchorFrame.Position = UDim2.new(0, 0, 0, 0)
AnchorFrame.BackgroundTransparency = 1
AnchorFrame.ZIndex = 10000
AnchorFrame.Parent = ScreenGuiNotification

-- CONTAINER
local Container = Instance.new("Frame")
Container.Name = "NotificationContainer"
Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.ZIndex = 10001
Container.Parent = ScreenGuiNotification

-- NOTIFICATION CONFIG
local NOTIF_WIDTH   = 270
local NOTIF_HEIGHT  = 75
local NOTIF_SPACING = 10
local SLIDE_OFFSET  = 450

local LOADING_FRAMES = { "|", "/", "—", "\\", "|", "/", "—", "\\" }
local LOADING_INTERVAL = 0.5

local TWEEN_INFO = TweenInfo.new(
	0.6,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)

-- BASE Y 
local BASE_Y = 0
local activeNotifications = {}

local function syncBaseY()
	BASE_Y = math.floor(AnchorFrame.AbsolutePosition.Y)
end

-- รอ layout เสร็จจริง
local conn
conn = AnchorFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	if AnchorFrame.AbsolutePosition.Y >= 0 then
		syncBaseY()
		conn:Disconnect()
	end
end)

-- POSITION CALC
local function calcY(index)
	return BASE_Y + (index - 1) * (NOTIF_HEIGHT + NOTIF_SPACING)
end

local function rearrange()
	for i, notif in ipairs(activeNotifications) do
		TweenService:Create(notif, TWEEN_INFO, {
			Position = UDim2.new(
				1,
				-NOTIF_WIDTH - 10,
				0,
				calcY(i)
			)
		}):Play()
	end
end

-- NotificationSound 
local NotificationSound = Instance.new("Sound")
NotificationSound.Name = "Roblox.erc.Notification.Sound"
NotificationSound.SoundId = "rbxassetid://87437544236708"
NotificationSound.Volume = 1
NotificationSound.Parent = SoundService

-- PUBLIC API
local function ERC_Notification(titleText, messageText, duration, enableSpinner)
	duration = duration or 2

	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
	notif.Position = UDim2.new(1, SLIDE_OFFSET, 0, calcY(#activeNotifications + 1))
	notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	notif.ClipsDescendants = true
	notif.ZIndex = 10002
	notif.Parent = Container
	createUICorner(notif)
	createUIStroke(notif, 2)

    local MainTitleimg = Instance.new("ImageLabel")
    MainTitleimg.Size = UDim2.new(0, 25, 0, 25)
    MainTitleimg.Position = UDim2.new(0, 3, 0, 3)
    MainTitleimg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainTitleimg.BackgroundTransparency = 1
    MainTitleimg.Image = ERCMainTitleimg
    MainTitleimg.ScaleType = Enum.ScaleType.Fit
    MainTitleimg.ZIndex = 10004
    MainTitleimg.Parent = notif
    createUICorner(MainTitleimg)
    createUIStroke(MainTitleimg, 0.5)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -75, 0, 25)
	title.Position = UDim2.new(0, 38, 0, 3)
	title.BackgroundTransparency = 1
	title.Text = titleText or "ERC SYSTEM (Beta)"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextScaled = true -- ปรับขนาดอัตโนมัติ
	title.ZIndex = 10003
	title.Parent = notif
	createTextSizeConstraint(title, 14, 16)
	
    -- Main SeparatorImageLabel
    local MainseparatorImageLabel = Instance.new("Frame")
    MainseparatorImageLabel.Size = UDim2.new(0, 2, 0.4, 0)
    MainseparatorImageLabel.Position = UDim2.new(0, 32, 0, 0)
    MainseparatorImageLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MainseparatorImageLabel.BorderSizePixel = 0
    MainseparatorImageLabel.ZIndex = 10004
    MainseparatorImageLabel.Parent = notif
	
    -- Main SeparatorButton
    local MainSeparatorButton = Instance.new("Frame")
    MainSeparatorButton.Size = UDim2.new(0, 2, 0.4, 0)
    MainSeparatorButton.Position = UDim2.new(1, -35, 0, 0)
    MainSeparatorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MainSeparatorButton.BorderSizePixel = 0
    MainSeparatorButton.ZIndex = 10004
    MainSeparatorButton.Parent = notif
	
    -- Main Separator
    local Mainseparator = Instance.new("Frame")
    Mainseparator.Size = UDim2.new(1, 0, 0, 2)
    Mainseparator.Position = UDim2.new(0, 0, 0, 30)
    Mainseparator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Mainseparator.BorderSizePixel = 0
    Mainseparator.ZIndex = 10004
    Mainseparator.Parent = notif

    -- Main Close Button
    local MaincloseButton = Instance.new("TextButton")
    MaincloseButton.Size = UDim2.new(0, 25, 0, 25)
    MaincloseButton.Position = UDim2.new(1, -30, 0, 2)
    MaincloseButton.BackgroundTransparency = 1
    MaincloseButton.Text = "x"
    MaincloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MaincloseButton.TextYAlignment = Enum.TextYAlignment.Center
    MaincloseButton.Font = Enum.Font.SourceSansBold
    MaincloseButton.TextSize = 20
    MaincloseButton.ZIndex = 10003
    MaincloseButton.Parent = notif

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -5, 0, 41)
	body.Position = UDim2.new(0, 3, 0, 33)
	body.BackgroundTransparency = 1
	body.Text = messageText or "(...)"
	body.TextColor3 = Color3.fromRGB(230,230,230)
	body.Font = Enum.Font.SourceSansBold
	body.TextSize = 14
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextScaled = true -- ปรับขนาดอัตโนมัติ
	body.ZIndex = 10003
	body.Parent = notif
	createTextSizeConstraint(body, 12, 14)

local spinnerRunning = false
	local spinnerThread

	if enableSpinner then
		spinnerRunning = true
		spinnerThread = task.spawn(function()
			local i = 1
			while spinnerRunning and notif.Parent do
				body.Text = messageText .. " " .. "[" .. LOADING_FRAMES[i] .. "]"
				i = (i % #LOADING_FRAMES) + 1
				task.wait(LOADING_INTERVAL)
			end
		end)
end

if NotificationSound then
	NotificationSound:Stop()
	NotificationSound:Play()
end

	table.insert(activeNotifications, notif)
	rearrange()

local closed = false
local function closeNotification()
	if closed then return end
	closed = true

	spinnerRunning = false -- << หยุด spinner

	local idx = table.find(activeNotifications, notif)
	if idx then
		table.remove(activeNotifications, idx)
	end

	TweenService:Create(notif, TweenInfo.new(0.2), {
		Position = UDim2.new(1, SLIDE_OFFSET, 0, notif.Position.Y.Offset)
	}):Play()

	task.delay(0.25, function()
		if notif then
			notif:Destroy()
		end
		rearrange()
	end)
end
    
	task.delay(duration, function()
	closeNotification()
end)
	
MaincloseButton.MouseButton1Click:Connect(function()
closeNotification()
end)
	
end

-- ===================================================
-- Script Loading...
ERC_Notification(nil, "[ ⚠ ] Welcome back!", 60, true)

-- ===================================================
task.wait(80)
ScreenGuiNotification:Destroy()

-- ===================================================