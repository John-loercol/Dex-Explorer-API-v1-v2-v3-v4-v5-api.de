-- local Services...
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===================================================
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

local ERCMainTitleimg = "rbxassetid://73848355219801"

-- erc Notification
local ScreenGuiNotification = Instance.new("ScreenGui")
ScreenGuiNotification.Name = "Roblox.erc.Notification2"
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
local LOADING_INTERVAL = 0.2

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
ERC_Notification(nil, "[ ⚠ ] Loading...", 12, true)
task.wait(11.8)

ERC_Notification(nil, "[ ⚠ ] Installing components...", 8, true)
task.wait(7.8)

ERC_Notification(nil, "[ ✓ ] Completing Setup.", 4)
task.wait(0.2)

-- ===================================================
-- ERC GUI

-- ===================================================  
-- สร้าง ScreenERCGui
local ScreenERCGui = Instance.new("ScreenGui")
ScreenERCGui.Name = "Roblox.erc.ScreenGui.Main"
ScreenERCGui.DisplayOrder = 9e8
RobloxGUI(ScreenERCGui)

-- สร้าง MainFrame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 560, 0, 325)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 0
MainFrame.Parent = ScreenERCGui
MainFrame.Active = true
MainFrame.ZIndex = 5000
createUICorner(MainFrame)
createUIStroke(MainFrame, 2)
CenterFrame(MainFrame, 2, 100)

-- ===================================================
-- Main Title GUI
local MainTitleimg = Instance.new("ImageLabel")
MainTitleimg.Size = UDim2.new(0, 25, 0, 25)
MainTitleimg.Position = UDim2.new(0, 5, 0, 5)
MainTitleimg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainTitleimg.BackgroundTransparency = 1
MainTitleimg.Image = ERCMainTitleimg
MainTitleimg.ScaleType = Enum.ScaleType.Fit
MainTitleimg.ZIndex = 10000
MainTitleimg.Parent = MainFrame
createUICorner(MainTitleimg)
createUIStroke(MainTitleimg, 0.5)

local MaintitleLabel = Instance.new("TextLabel")
MaintitleLabel.Size = UDim2.new(1, -138, 0, 25)
MaintitleLabel.Position = UDim2.new(0, 40, 0, 5)
MaintitleLabel.BackgroundTransparency = 1
MaintitleLabel.Text = "ERC GUI - V.0.5.6 (Beta) - Product of erc.t.tm.th - PC & Mobile"
MaintitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MaintitleLabel.Font = Enum.Font.SourceSansBold
MaintitleLabel.TextSize = 18
MaintitleLabel.TextXAlignment = Enum.TextXAlignment.Left
MaintitleLabel.TextScaled = true -- ปรับขนาดอัตโนมัติ
MaintitleLabel.ZIndex = 10000
MaintitleLabel.Parent = MainFrame
createTextSizeConstraint(MaintitleLabel, 16, 18)

-- Main SeparatorImageLabel
local MainseparatorImageLabel = Instance.new("Frame")
MainseparatorImageLabel.Size = UDim2.new(0, 2, 1, 0)
MainseparatorImageLabel.Position = UDim2.new(0, 35, 0, 0)
MainseparatorImageLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MainseparatorImageLabel.BorderSizePixel = 0
MainseparatorImageLabel.ZIndex = 10000
MainseparatorImageLabel.Parent = MainFrame

-- Main SeparatorButton
local MainSeparatorButton = Instance.new("Frame")
MainSeparatorButton.Size = UDim2.new(0, 2, 1, 0)
MainSeparatorButton.Position = UDim2.new(1, -96, 0, 0)
MainSeparatorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MainSeparatorButton.BorderSizePixel = 0
MainSeparatorButton.ZIndex = 10000
MainSeparatorButton.Parent = MainFrame

-- Main Separator
local Mainseparator = Instance.new("Frame")
Mainseparator.Size = UDim2.new(1, 0, 0, 2)
Mainseparator.Position = UDim2.new(0, 0, 0, 35)
Mainseparator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Mainseparator.BorderSizePixel = 0
Mainseparator.ZIndex = 20001
Mainseparator.Parent = MainFrame

-- Main Close Button
local MaincloseButton = Instance.new("TextButton")
MaincloseButton.Size = UDim2.new(0, 25, 0, 25)
MaincloseButton.Position = UDim2.new(1, -30, 0, 4)
MaincloseButton.BackgroundTransparency = 1
MaincloseButton.Text = "x"
MaincloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MaincloseButton.TextYAlignment = Enum.TextYAlignment.Center
MaincloseButton.Font = Enum.Font.SourceSansBold
MaincloseButton.TextSize = 20
MaincloseButton.ZIndex = 10000
MaincloseButton.Parent = MainFrame

-- MainFullcreen Button
local MainFullscreenButton = Instance.new("TextButton")
MainFullscreenButton.Size = UDim2.new(0, 25, 0, 25)
MainFullscreenButton.Position = UDim2.new(1, -60, 0, 5)
MainFullscreenButton.BackgroundTransparency = 1
MainFullscreenButton.Text = "☐"
MainFullscreenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainFullscreenButton.TextYAlignment = Enum.TextYAlignment.Center
MainFullscreenButton.Font = Enum.Font.SourceSansBold
MainFullscreenButton.TextSize = 20
MainFullscreenButton.ZIndex = 10000
MainFullscreenButton.Parent = MainFrame

-- Main Minimize Button
local MainminimizeButton = Instance.new("TextButton")
MainminimizeButton.Size = UDim2.new(0, 25, 0, 25)
MainminimizeButton.Position = UDim2.new(1, -90, 0, 5)
MainminimizeButton.BackgroundTransparency = 1
MainminimizeButton.Text = "–"
MainminimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainminimizeButton.TextYAlignment = Enum.TextYAlignment.Center
MainminimizeButton.Font = Enum.Font.SourceSansBold
MainminimizeButton.TextSize = 20
MainminimizeButton.ZIndex = 10000
MainminimizeButton.Parent = MainFrame

-- Main Icon Button
local MainiconButton  = Instance.new("Frame")
MainiconButton.Size = UDim2.new(0, 150, 0, 35)
MainiconButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainiconButton.ZIndex = 5000
MainiconButton.Parent = ScreenERCGui
MainiconButton.Active = true
createUICorner(MainiconButton) 
createUIStroke(MainiconButton)
CenterFrame(MainiconButton, 2, 100)

-- Main IconText
local MainiconText  = Instance.new("TextButton")
MainiconText.Size = UDim2.new(0, 100, 0, 35)
MainiconText.Position = UDim2.new(0, 0, 0, 0)
MainiconText.BackgroundTransparency = 1
MainiconText.ZIndex = 6000
MainiconText.Text = "ERC GUI"
MainiconText.TextColor3 = Color3.fromRGB(255, 255, 255)
MainiconText.TextYAlignment = Enum.TextYAlignment.Center
MainiconText.Font = Enum.Font.SourceSansBold
MainiconText.TextSize = 20
MainiconText.Parent = MainiconButton
createUICorner(MainiconText) 

-- Main sidebarDivider
local MainsidebarDivider  = Instance.new("Frame")
MainsidebarDivider.Size = UDim2.new(0, 2, 1, 0)  
MainsidebarDivider.Position = UDim2.new(0,  100, 0, 0)  
MainsidebarDivider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  
MainsidebarDivider.BorderSizePixel = 0  
MainsidebarDivider.BackgroundTransparency = 0
MainsidebarDivider.ZIndex = 6000
MainsidebarDivider.Parent = MainiconButton

-- ===================================================
-- ระบบการ ปิด/เปิด GUI แบบ Roblox

local SavedPositions = {  
	MainFrame = nil,  
	MainIcon = nil  
}  

local SavedSizes = {
    MainFrame = nil,
    MainIcon = nil
}

local Draggable = {
    MainFrame = true,
    MainIcon = true
}

local function DraggingGUI(frame, saveKey)  
	if not frame then return end  

	local dragging = false  
	local dragStart  
	local startPos  
	local dragInput  

	local function update(input)  
		if not dragging or not dragStart or not startPos then return end  

		-- ถ้าถูกปิดการลากด้วย flag ให้ข้ามการอัพเดตตำแหน่ง
		if saveKey and Draggable[saveKey] == false then return end

		local delta = input.Position - dragStart  

		frame.Position = UDim2.new(  
			startPos.X.Scale,  
			startPos.X.Offset + delta.X,  
			startPos.Y.Scale,  
			startPos.Y.Offset + delta.Y  
		)  
	end  

	frame.InputBegan:Connect(function(input)  
		-- ถ้าปิดการลากสำหรับกรอบนี้ -> ไม่รับ InputBegan ที่เป็นการลาก
		if saveKey and Draggable[saveKey] == false then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1  
		or input.UserInputType == Enum.UserInputType.Touch then  

			dragging = true  
			dragStart = input.Position  
			startPos = frame.Position  
			dragInput = input  

			input.Changed:Connect(function()  
				if input.UserInputState == Enum.UserInputState.End then  
					dragging = false  
					dragInput = nil  

					if saveKey then  
						SavedPositions[saveKey] = frame.Position  
                        SavedSizes[saveKey] = frame.Size
					end  
				end  
			end)  
		end  
	end)  

	frame.InputChanged:Connect(function(input)  
		if input.UserInputType == Enum.UserInputType.MouseMovement  
		or input.UserInputType == Enum.UserInputType.Touch then  
			dragInput = input  
		end  
	end)  

	UserInputService.InputChanged:Connect(function(input)  
		if dragging and input == dragInput then  
			update(input)  
		end  
	end)  
end

-- Restore Position
local function getRestorePosition(frame, key, fallback)
	return SavedPositions[key] or fallback(frame)
end

-- Tween Helper
local function tweenPosition(instance, targetPos, duration, callback)
	local tweenInfo = TweenInfo.new(
		duration or 0.18,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(instance, tweenInfo, {
		Position = targetPos
	})

	tween.Completed:Connect(function()
		if callback then callback() end
	end)

	tween:Play()
	return tween
end

-- Safe Off-Screen Position (ALL DEVICES)
local function getOutOfScreenPosition(frame)
	local viewportSize = Camera.ViewportSize
	local buffer = math.floor(viewportSize.Y * 0.05)

	return UDim2.new(
		frame.Position.X.Scale,
		frame.Position.X.Offset,
		0,
		viewportSize.Y + frame.AbsoluteSize.Y + buffer
	)
end

-- Default Center Positions
local function getCenterScreenPosition(frame)
	local viewportSize = Camera.ViewportSize

	if frame == MainFrame then
		return UDim2.new(
			0, (viewportSize.X - frame.AbsoluteSize.X) / 2,
			0, (viewportSize.Y - frame.AbsoluteSize.Y) / 100
		)
	elseif frame == MainiconButton then
		return UDim2.new(
			0, (viewportSize.X - frame.AbsoluteSize.X) / 2,
			0, (viewportSize.Y - frame.AbsoluteSize.Y) / 100
		)
	end
end

-- Apply Dragging
DraggingGUI(MainFrame, "MainFrame")
DraggingGUI(MainiconButton, "MainIcon")

-- MainFrame Animations
local function TweenMainFrameOut(callback)
	tweenPosition(MainFrame, getOutOfScreenPosition(MainFrame), 0.18, function()
		MainFrame.Visible = false
		if callback then callback() end
	end)
end

local function TweenMainFrameIn()
	MainFrame.Position = getOutOfScreenPosition(MainFrame)
	MainFrame.Visible = true

	tweenPosition(
		MainFrame,
		getRestorePosition(MainFrame, "MainFrame", getCenterScreenPosition),
		0.18
	)
end

-- Icon Button Animations
local function TweenIconButtonIn()
	MainiconButton.Position = getOutOfScreenPosition(MainiconButton)
	MainiconButton.Visible = true

	tweenPosition(
		MainiconButton,
		getRestorePosition(MainiconButton, "MainIcon", getCenterScreenPosition),
		0.18
	)
end

local function TweenIconButtonOut(callback)
	tweenPosition(MainiconButton, getOutOfScreenPosition(MainiconButton), 0.18, function()
		MainiconButton.Visible = false
		if callback then callback() end
	end)
end

-- Button Logic
MainiconText.MouseButton1Click:Connect(function()
	TweenIconButtonOut(function()
    	TweenMainFrameIn()
end)
end)

MainminimizeButton.MouseButton1Click:Connect(function()
	TweenMainFrameOut(function()
		TweenIconButtonIn()
	end)
end)

-- Initial State
MainFrame.Visible = false
MainiconButton.Visible = false

TweenIconButtonOut(function()
	TweenMainFrameIn()
end)

MainFrame.Position = getCenterScreenPosition(MainFrame)
MainiconButton.Position = getOutOfScreenPosition(MainiconButton)

-- Resize Safe (Roblox Behavior)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if MainFrame.Visible then
		MainFrame.Position = getRestorePosition(
			MainFrame,
			"MainFrame",
			getCenterScreenPosition
		)
	end

	if MainiconButton.Visible then
		MainiconButton.Position = getRestorePosition(
			MainiconButton,
			"MainIcon",
			getCenterScreenPosition
		)
	end
end)

MainFullscreenButton.MouseButton1Click:Connect(function()
	ERC_Notification(nil, "[ ⚠ ] The full-screen feature is not available at this time.", 6)
end)

-- ===================================================  
-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 180, 1, -35)  
sidebar.Position = UDim2.new(0, 0, 0, 35)  
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  
sidebar.BorderSizePixel = 0  
sidebar.BackgroundTransparency = 0
sidebar.ZIndex = 20000
sidebar.Active = true
sidebar.Parent = MainFrame  
createUICorner(sidebar)
  
-- Divider Sidebar | Content  
local sidebarDivider  = Instance.new("Frame")
sidebarDivider.Size = UDim2.new(0, 2, 1, 0)  
sidebarDivider.Position = UDim2.new(1, -2, 0, 0)  
sidebarDivider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  
sidebarDivider.BorderSizePixel = 0  
sidebarDivider.BackgroundTransparency = 0  
sidebarDivider.ZIndex = 20001
sidebarDivider.Parent = sidebar  

-- ===================================================  
-- Pages (ฟังก์ชัน)  
local pages = {}  
  
local function switchPage(pageName)  
      for name, page in pairs(pages) do  
         page.Visible = (name == pageName)  
       end  
end  

local function createContentPage(name, canvasHeight)
    canvasHeight = canvasHeight or 1000
    
        local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -180, 1, -37.8)
    contentFrame.Position = UDim2.new(0, 180, 0, 37.8)
    contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contentFrame.BackgroundTransparency = 0
    contentFrame.ScrollBarThickness = 5
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
    contentFrame.ScrollBarImageTransparency = 1
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
    contentFrame.ZIndex = 20000
    contentFrame.Visible = false
    contentFrame.Active = true
    contentFrame.Parent = MainFrame
    createUICorner(contentFrame)
    createListLayout(contentFrame, 10, 5)
    
        local pageFrame = Instance.new("Frame")
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Active = true
    pageFrame.Parent = contentFrame
    createUICorner(pageFrame)

    pages[name] = contentFrame

    return contentFrame, pageFrame
end

-- ===================================================  
-- สร้าง ScreenGuiAll หลัก
local ScreenGuiAll = Instance.new("ScreenGui")
ScreenGuiAll.Name = "Roblox.erc.ScreenGui.All"
ScreenGuiAll.DisplayOrder = 9e7
ScreenGuiAll.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
RobloxGUI(ScreenGuiAll)

-- ===================================================  
-- Function: ฟังก์ชัน สร้างแผงสำหรับหัวข้อกลุ่ม

local function createToggleSection(parent, name, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -50, 0, 35)
    container.Position = UDim2.new(0, 25, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.ZIndex = 20000
    container.ClipsDescendants = true -- กันล้นขอบ
    container.Parent = parent
    createUICorner(container)
    createUIStroke(container, 2, Color3.fromRGB(45, 45, 45))

    -- labelFrame
    local labelFrame = Instance.new("Frame")
    labelFrame.Size = UDim2.new(0, 6, 0, 28)
    labelFrame.Position = UDim2.new(0, 6, 0, 3.5)
    labelFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    labelFrame.ZIndex = 20001
    labelFrame.Parent = container
    createUICorner(labelFrame, UDim.new(0, 10))

    -- label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true -- ปรับขนาดอัตโนมัติ
    label.ZIndex = 20001
    label.Parent = container
    createTextSizeConstraint(label, 12, 18)

    return label
end

-- Function: ฟังก์ชัน สร้างแผงสำหรับเปิดใช้งานทั่วไ  (เปิด/ปิด)

local function createToggle(parent, name, TextP, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -50, 0, 35)
    container.Position = UDim2.new(0, 25, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.ZIndex = 20000
    container.Parent = parent
    createUICorner(container)

    -- mainBorder
    local mainBorder  = Instance.new("UIStroke")
    mainBorder.Color = Color3.fromRGB(45, 45, 45)
    mainBorder.Thickness = 2
    mainBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainBorder.Parent = container

    -- flashBorder
    local flashBorder = Instance.new("UIStroke")
    flashBorder.Color = Color3.fromRGB(0, 150, 255)
    flashBorder.Thickness = 2
    flashBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    flashBorder.Enabled = false
    flashBorder.Parent = container

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -150, 0, 15)  
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true -- ปรับขนาดอัตโนมัติ
    label.ZIndex = 20001
    label.Parent = container
    createTextSizeConstraint(label, 14, 16)
    
    local labelP  = Instance.new("TextLabel")
    labelP.Size = UDim2.new(1, -150, 0, 15)  
    labelP.Position = UDim2.new(0, 8, 0, 18)
    labelP.BackgroundTransparency = 1
    labelP.Text = TextP
    labelP.TextColor3 = Color3.fromRGB(100, 100, 100)
    labelP.Font = Enum.Font.SourceSansBold
    labelP.TextSize = 14
    labelP.TextXAlignment = Enum.TextXAlignment.Left
    labelP.TextScaled = true -- ปรับขนาดอัตโนมัติ
    labelP.ZIndex = 20001
    labelP.Parent = container
    createTextSizeConstraint(labelP, 12, 14)

    local toggleBtn  = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.45, -20, 0.8, 0)
    toggleBtn.Position = UDim2.new(0.55, 15, 0.1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 20001
    toggleBtn.Parent = container
    createUICorner(toggleBtn)

    -- จุดไฟสถานะ (เปิด/ปิด)
    local statusLight = Instance.new("Frame")
    statusLight.Size = UDim2.new(0, 20, 0, 20)
    statusLight.Position = UDim2.new(1, -30, 0.5, -10)
    statusLight.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    statusLight.BorderSizePixel = 0
    statusLight.ZIndex = 20002
    statusLight.Parent = container
    createUICorner(statusLight)
    createUIStroke(statusLight, 2, Color3.fromRGB(45,45,45))

    local state = false

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state

        -- ขอบจริงเป็นฟ้า → กลับเทา
        TweenService:Create(mainBorder, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(0, 150, 255)
        }):Play()

        task.delay(0.6, function()
            TweenService:Create(mainBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(45, 45, 45)
            }):Play()
        end)

        -- ขอบฟ้ากระพริบ
        flashBorder.Enabled = true
        flashBorder.Transparency = 0
        TweenService:Create(flashBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()

        -- ไฟติด/ดับ
        if state then
            statusLight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        else
            statusLight.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end
    end)

    return function()
        return state
    end
end

-- Function: ฟังก์ชัน สร้างแผงสำหรับใส่ข้อความ

local function createToggleText(parent, name, TextP, Text, PlaceholderText, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -50, 0, 35)
    container.Position = UDim2.new(0, 25, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.ZIndex = 20000
    container.Parent = parent
    createUICorner(container)

    -- mainBorder
    local mainBorder  = Instance.new("UIStroke")
    mainBorder.Color = Color3.fromRGB(45, 45, 45)
    mainBorder.Thickness = 2
    mainBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainBorder.Parent = container

    -- flashBorder
    local flashBorder  = Instance.new("UIStroke")
    flashBorder.Color = Color3.fromRGB(0, 150, 255)
    flashBorder.Thickness = 2
    flashBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    flashBorder.Enabled = false
    flashBorder.Parent = container

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -150, 0, 15)  
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true -- ปรับขนาดอัตโนมัติ
    label.ZIndex = 20001
    label.Parent = container
    createTextSizeConstraint(label, 14, 16)
    
    local labelP = Instance.new("TextLabel")
    labelP.Size = UDim2.new(1, -150, 0, 15)  
    labelP.Position = UDim2.new(0, 8, 0, 18)
    labelP.BackgroundTransparency = 1
    labelP.Text = TextP
    labelP.TextColor3 = Color3.fromRGB(100, 100, 100)
    labelP.Font = Enum.Font.SourceSansBold
    labelP.TextSize = 14
    labelP.TextXAlignment = Enum.TextXAlignment.Left
    labelP.TextScaled = true -- ปรับขนาดอัตโนมัติ
    labelP.ZIndex = 20001
    labelP.Parent = container
    createTextSizeConstraint(labelP, 12, 14)
    
    local inputBoxFrame = Instance.new("Frame")
    inputBoxFrame.Size = UDim2.new(0.45, -20, 0.8, 0)
    inputBoxFrame.Position = UDim2.new(0.55, 15, 0.1, 0)
    inputBoxFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    inputBoxFrame.ZIndex = 20001
    inputBoxFrame.Parent = container
    createUICorner(inputBoxFrame)
    createUIStroke(inputBoxFrame, 1, Color3.fromRGB(45,45,45))
    
       -- inputBox
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.45, -20, 0.8, 0)
    inputBox.Position = UDim2.new(0.55, 15, 0.1, 0)
    inputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    inputBox.BackgroundTransparency = 0
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderText = PlaceholderText
    inputBox.Text = Text
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    inputBox.Font = Enum.Font.SourceSansBold
    inputBox.TextSize = 16
    inputBox.ClearTextOnFocus = true
    inputBox.TextWrapped = true
    inputBox.ZIndex = 20002
    inputBox.Parent = container
    createUICorner(inputBox)

    -- เมื่อเริ่มพิมพ์ (Focused)
    inputBox.Focused:Connect(function()
        -- เปลี่ยนขอบหลักเป็นฟ้า (Smooth)
        TweenService:Create(mainBorder, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(0, 150, 255)
        }):Play()

        -- Flash border ฟ้าแบบ Fade-out
        flashBorder.Enabled = true
        flashBorder.Transparency = 0
        TweenService:Create(flashBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()
    end)

    -- เมื่อเลิกพิมพ์ (FocusLost)
    inputBox.FocusLost:Connect(function()
        -- กลับเป็นสีเทาแบบ Smooth
        TweenService:Create(mainBorder, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(45, 45, 45)
        }):Play()

        flashBorder.Enabled = false
    end)

    return inputBox
end

-- Function: ฟังก์ชัน สร้างแผงสำหรับแสดงค่า

local function createToggleTextLabel(parent, name, TextP, Text, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -50, 0, 35)
    container.Position = UDim2.new(0, 25, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.ZIndex = 20000
    container.Parent = parent
    createUICorner(container)

    -- mainBorder
    local mainBorder = Instance.new("UIStroke")
    mainBorder.Color = Color3.fromRGB(45, 45, 45)
    mainBorder.Thickness = 2
    mainBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainBorder.Parent = container

    -- flashBorder
    local flashBorder = Instance.new("UIStroke")
    flashBorder.Color = Color3.fromRGB(0, 150, 255)
    flashBorder.Thickness = 2
    flashBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    flashBorder.Enabled = false
    flashBorder.Parent = container

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -150, 0, 15)  
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true -- ปรับขนาดอัตโนมัติ
    label.ZIndex = 20001
    label.Parent = container
    createTextSizeConstraint(label, 14, 16)
    
    local labelP = Instance.new("TextLabel")
    labelP.Size = UDim2.new(1, -150, 0, 15)  
    labelP.Position = UDim2.new(0, 8, 0, 18)
    labelP.BackgroundTransparency = 1
    labelP.Text = TextP
    labelP.TextColor3 = Color3.fromRGB(100, 100, 100)
    labelP.Font = Enum.Font.SourceSansBold
    labelP.TextSize = 14
    labelP.TextXAlignment = Enum.TextXAlignment.Left
    labelP.TextScaled = true -- ปรับขนาดอัตโนมัติ
    labelP.ZIndex = 20001
    labelP.Parent = container
    createTextSizeConstraint(labelP, 12, 14)
    
    local inputBoxFrame = Instance.new("Frame")
    inputBoxFrame.Size = UDim2.new(0.45, -20, 0.8, 0)
    inputBoxFrame.Position = UDim2.new(0.55, 15, 0.1, 0)
    inputBoxFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    inputBoxFrame.ZIndex = 20001
    inputBoxFrame.Parent = container
    createUICorner(inputBoxFrame)
    createUIStroke(inputBoxFrame, 1, Color3.fromRGB(45,45,45))
    
       -- inputBox
    local inputBox = Instance.new("TextLabel")
    inputBox.Size = UDim2.new(0.45, -20, 0.8, 0)
    inputBox.Position = UDim2.new(0.55, 15, 0.1, 0)
    inputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    inputBox.BackgroundTransparency = 1
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.Text = Text
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    inputBox.Font = Enum.Font.SourceSansBold
    inputBox.TextSize = 16
    inputBox.TextWrapped = true
    inputBox.ZIndex = 20002
    inputBox.Parent = container
    createUICorner(inputBox)

    return inputBox
end

-- Function: ฟังก์ชัน สร้างแผงสำหรับรัน Script ได้

local function createToggleButton(parent, name, TextP, Text, yPos, scriptFunc)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -50, 0, 35)
    container.Position = UDim2.new(0, 25, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.ZIndex = 20000
    container.Parent = parent
    createUICorner(container)

    -- mainBorder
    local mainBorder = Instance.new("UIStroke")
    mainBorder.Color = Color3.fromRGB(45, 45, 45)
    mainBorder.Thickness = 2
    mainBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainBorder.Parent = container

    -- flashBorder
    local flashBorder = Instance.new("UIStroke")
    flashBorder.Color = Color3.fromRGB(0, 150, 255)
    flashBorder.Thickness = 2
    flashBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    flashBorder.Enabled = false
    flashBorder.Parent = container

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -150, 0, 15)  
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true -- ปรับขนาดอัตโนมัติ
    label.ZIndex = 20001
    label.Parent = container
    createTextSizeConstraint(label, 14, 16)
    
    local labelP = Instance.new("TextLabel")
    labelP.Size = UDim2.new(1, -150, 0, 15)  
    labelP.Position = UDim2.new(0, 8, 0, 18)
    labelP.BackgroundTransparency = 1
    labelP.Text = TextP
    labelP.TextColor3 = Color3.fromRGB(100, 100, 100)
    labelP.Font = Enum.Font.SourceSansBold
    labelP.TextSize = 14
    labelP.TextXAlignment = Enum.TextXAlignment.Left
    labelP.TextScaled = true -- ปรับขนาดอัตโนมัติ
    labelP.ZIndex = 20001
    labelP.Parent = container
    createTextSizeConstraint(labelP, 12, 14)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.45, -20, 0.8, 0)
    btn.Position = UDim2.new(0.55, 15, 0.1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 20001
    btn.Parent = container
    createUICorner(btn)
    
    local b = Instance.new("TextLabel")
    b.Size = UDim2.new(0, 20, 0, 20)
    b.Position = UDim2.new(1, -35, 0.5, -10)
    b.BackgroundTransparency = 1
    b.TextColor3 = Color3.fromRGB(100, 100, 100)
    b.Text = Text
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 16
    b.ZIndex = 20002
    b.Parent = container
    createUICorner(b)

    -- เอฟเฟกต์ขอบเมื่อกดปุ่ม
    btn.MouseButton1Click:Connect(function()
        -- เปลี่ยนขอบหลักเป็นฟ้า
        TweenService:Create(mainBorder, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
            Color = Color3.fromRGB(0, 150, 255)
        }):Play()

        -- ค่อย fade กลับเป็นเทา
        task.delay(0.6, function()
            TweenService:Create(mainBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
                Color = Color3.fromRGB(45, 45, 45)
            }):Play()
        end)

        -- Flash (ขอบฟ้าวาบ)
        flashBorder.Enabled = true
        flashBorder.Transparency = 0
        TweenService:Create(flashBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
            Transparency = 1
        }):Play()

        -- รันฟังก์ชันเหมือน Toggle จริง ๆ
        if scriptFunc then
            task.spawn(function()
                pcall(scriptFunc)
            end)
        end
    end)

    return btn
end

-- Function: ฟังก์ชัน สร้างแผงสำหรับปรับค่าแบบปรับค่าแบบเลื่อนได้
-- แบบจำนวนเต็ม

local function createToggleSlider(parent, name, yPos, default, minValue, maxValue, callback)
local container = Instance.new("Frame")
container.Size = UDim2.new(1, -50, 0, 35)
container.Position = UDim2.new(0, 25, 0, yPos)
container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
container.Active = true
container.ZIndex = 20000
container.Parent = parent
createUICorner(container)

-- mainBorder
local mainBorder  = Instance.new("UIStroke")  
mainBorder.Color = Color3.fromRGB(45, 45, 45)  
mainBorder.Thickness = 2  
mainBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border  
mainBorder.Parent = container  

-- flashBorder
local flashBorder = Instance.new("UIStroke")  
flashBorder.Color = Color3.fromRGB(0, 150, 255)  
flashBorder.Thickness = 2  
flashBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border  
flashBorder.Enabled = true  
flashBorder.Transparency = 1  
flashBorder.Parent = container  

local nameLabel = Instance.new("TextLabel")  
nameLabel.Size = UDim2.new(1, -16, 0, 10)  
nameLabel.Position = UDim2.new(0, 8, 0, 2)  
nameLabel.BackgroundTransparency = 1
nameLabel.Text = name  
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  
nameLabel.Font = Enum.Font.SourceSansBold  
nameLabel.TextSize = 16  
nameLabel.TextXAlignment = Enum.TextXAlignment.Left  
nameLabel.TextScaled = true -- ปรับขนาดอัตโนมัติ
nameLabel.ZIndex = 20001  
nameLabel.Parent = container  
createTextSizeConstraint(nameLabel, 14, 16)

local sliderBar = Instance.new("Frame")  
sliderBar.Size = UDim2.new(1, -16, 0, 14)  
sliderBar.Position = UDim2.new(0, 8, 0, 18)  
sliderBar.BackgroundColor3 = Color3.fromRGB(20, 40, 120)  
sliderBar.BorderSizePixel = 0  
sliderBar.ZIndex = 20001  
sliderBar.Parent = container  
createUICorner(sliderBar)  
createUIStroke(sliderBar, 1, Color3.fromRGB(0, 165, 255))

local fill = Instance.new("Frame")  
local relDefaul = (default - minValue) / (maxValue - minValue)  
fill.Size = UDim2.new(relDefault, 0, 1, 0)  
fill.Position = UDim2.new(0, 0, 0, 0)  
fill.BackgroundColor3 = Color3.fromRGB(150, 230, 250)  
fill.BorderSizePixel = 0  
fill.ZIndex = 20002  
fill.Parent = sliderBar  
createUICorner(fill)  

local valueLabel = Instance.new("TextLabel")  
valueLabel.Size = UDim2.new(0, 50, 1, 0)  
valueLabel.Position = UDim2.new(0, 4, 0, -1)  
valueLabel.BackgroundTransparency = 1  
valueLabel.Text = tostring(default)  
valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  
valueLabel.Font = Enum.Font.SourceSansBold  
valueLabel.TextSize = 16  
valueLabel.TextXAlignment = Enum.TextXAlignment.Left  
valueLabel.ZIndex = 20003  
valueLabel.Parent = sliderBar  

local dragging = false  
local targetValue = default  
local smoothValue = default  
local fadeTween -- เก็บ Tween ของขอบ  

RunService.RenderStepped:Connect(function()
    smoothValue = smoothValue + (targetValue - smoothValue) * 0.2
    local rel = (smoothValue - minValue) / (maxValue - minValue)
    
    -- กำหนดค่าความกว้างขั้นต่ำ (Pixel-Based Width)
    local minPixelWidth = 0.001  -- ขนาดพิกเซลขั้นต่ำ (สามารถปรับได้)
    local barWidth = sliderBar.AbsoluteSize.X
    local pixelWidth = math.max(rel * barWidth, minPixelWidth)

    fill.Size = UDim2.new(0, pixelWidth, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    valueLabel.Text = tostring(math.floor(smoothValue))
    callback(math.floor(smoothValue))

    if dragging or math.abs(targetValue - smoothValue) > 0.6 then
        -- ยังเลื่อนอยู่
        TweenService:Create(mainBorder, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(0, 150, 255)}):Play()
        if fadeTween then fadeTween:Cancel() end
        flashBorder.Transparency = 0
    else
        -- หยุดเลื่อนแล้ว
        fadeTween = TweenService:Create(flashBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {Transparency = 1})
        fadeTween:Play()
        TweenService:Create(mainBorder, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(45, 45, 45)}):Play()
    end
end)

local function updateTarget(inputPosX)  
    local barPosX = sliderBar.AbsolutePosition.X  
    local barWidth = sliderBar.AbsoluteSize.X  
    local relPos = math.clamp((inputPosX - barPosX) / barWidth, 0, 1)  
    targetValue = minValue + relPos * (maxValue - minValue)  
end  

sliderBar.InputBegan:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then  
        dragging = true  
        updateTarget(input.Position.X)  
    end  
end)  

sliderBar.InputChanged:Connect(function(input)  
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then  
        updateTarget(input.Position.X)  
    end  
end)  

sliderBar.InputEnded:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then  
        dragging = false  
    end  
end)  

UIS.InputChanged:Connect(function(input)  
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then  
        updateTarget(input.Position.X)  
    end  
end)  

UIS.InputEnded:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then  
        dragging = false  
    end  
end)

end

-- Function: ฟังก์ชัน สร้างแผงสำหรับปรับค่าแบบปรับค่าแบบเลื่อนได้
-- แบบทศนิยม

local function createToggleSliderDecimal(parent, name, yPos, default, minValue, maxValue, callback)

    local function round3(num)
        return math.floor(num * 1000 + 0.5) / 1000
    end


    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -50, 0, 35)
    container.Position = UDim2.new(0, 25, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.Active = true
    container.ZIndex = 20000
    container.Parent = parent
    createUICorner(container)

    -- mainBorder
    local mainBorder = Instance.new("UIStroke")
    mainBorder.Color = Color3.fromRGB(45, 45, 45)
    mainBorder.Thickness = 2
    mainBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainBorder.Parent = container

    -- flashBorder
    local flashBorder = Instance.new("UIStroke")
    flashBorder.Color = Color3.fromRGB(0, 150, 255)
    flashBorder.Thickness = 2
    flashBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    flashBorder.Transparency = 1
    flashBorder.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 70, 0, 10)
    nameLabel.Position = UDim2.new(0, 8, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextScaled = true -- ปรับขนาดอัตโนมัติ
    nameLabel.ZIndex = 20001
    nameLabel.Parent = container
    createTextSizeConstraint(nameLabel, 14, 16)
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -16, 0, 14)
    sliderBar.Position = UDim2.new(0, 8, 0, 18)
    sliderBar.BackgroundColor3 = Color3.fromRGB(20, 40, 120)
    sliderBar.BorderSizePixel = 0
    sliderBar.ZIndex = 20001
    sliderBar.Parent = container
    createUICorner(sliderBar)
    createUIStroke(sliderBar, 1, Color3.fromRGB(0, 165, 255))

    local fill = Instance.new("Frame")
    local relDefault = (default - minValue) / (maxValue - minValue)
    fill.Size = UDim2.new(relDefault, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 230, 250)
    fill.BorderSizePixel = 0
    fill.ZIndex = 20002
    fill.Parent = sliderBar
    createUICorner(fill)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 80, 1, 0)
    valueLabel.Position = UDim2.new(0, 4, 0, -1)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = string.format("%.3f", default)
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.Font = Enum.Font.SourceSansBold
    valueLabel.TextSize = 16
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.ZIndex = 20003
    valueLabel.Parent = sliderBar

    local dragging = false
    local targetValue = default
    local smoothValue = default
    local fadeTween

    RunService.RenderStepped:Connect(function()
        smoothValue = smoothValue + (targetValue - smoothValue) * 0.2

        local rel = (smoothValue - minValue) / (maxValue - minValue)
        local barWidth = sliderBar.AbsoluteSize.X
        local pixelWidth = math.max(rel * barWidth, 0.001)

        fill.Size = UDim2.new(0, pixelWidth, 1, 0)

        local displayValue = round3(smoothValue)
        valueLabel.Text = string.format("%.3f", displayValue)
        callback(displayValue)

        if dragging or math.abs(targetValue - smoothValue) > 0.0006 then
            TweenService:Create(
                mainBorder,
                TweenInfo.new(0.1, Enum.EasingStyle.Sine),
                { Color = Color3.fromRGB(0, 150, 255) }
            ):Play()

            if fadeTween then fadeTween:Cancel() end
            flashBorder.Transparency = 0
        else
            fadeTween = TweenService:Create(
                flashBorder,
                TweenInfo.new(0.6, Enum.EasingStyle.Sine),
                { Transparency = 1 }
            )
            fadeTween:Play()

            TweenService:Create(
                mainBorder,
                TweenInfo.new(0.6, Enum.EasingStyle.Sine),
                { Color = Color3.fromRGB(45, 45, 45) }
            ):Play()
        end
    end)

    local function updateTarget(inputX)
        local barX = sliderBar.AbsolutePosition.X
        local barW = sliderBar.AbsoluteSize.X
        local rel = math.clamp((inputX - barX) / barW, 0, 1)
        targetValue = minValue + rel * (maxValue - minValue)
    end

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateTarget(input.Position.X)
        end
    end)

    sliderBar.InputChanged:Connect(function(input)
        if dragging then
            updateTarget(input.Position.X)
        end
    end)

    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging then
            updateTarget(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

end

-- Function: ฟังก์ชัน สร้างแผงสำหรับปรับสีได้



-- ===================================================  
-- Page: Player
local contentFramePlayer, PlayerPage = createContentPage("Player", 133)

-- ==========================
-- UI Sliders
-- ==========================
createToggleSlider(PlayerPage, "Walk Speed", 3, 16, 0, 400, function(value)
	currentWalkSpeed = value
end)

createToggleSlider(PlayerPage, "Jump Power", 46, 50, 0, 400, function(value)
	currentJumpPower = value
end)

-- ==========================
-- Page: PlayerPage
-- ==========================
local getFly = createToggle(PlayerPage, "FLY GUI", "Click to open GUI", 89)

local getInfiniteJump = createToggle(PlayerPage, "Infinite Jump", "Click to open Infinite Jump", 132)

local getNoClip = createToggle(PlayerPage, "NoClip", "Click to open NoClip", 175)

local getShiftLock = createToggle(PlayerPage, "Shift Lock", "Click to open Shift Lock", 218)

-- ===================================================  
-- Page: Visual
local contentFrameVisual, VisualPage = createContentPage("Visual", 478)

-- Fullbright & FOV
local targetExposure = 0
local targetFOV = 70

-- ==========================
-- Create Sliders
-- ==========================
createToggleSlider(VisualPage, "Fullbright", 3, targetExposure, -10, 20, function(value)
	targetExposure = value
	applyExposure()
end)

createToggleSlider(VisualPage, "FOV Camera", 46, targetFOV, 0, 100, function(value)
	targetFOV = value
	applyFOV()
end)

-- ==========================
-- Page: VisualPage
-- ==========================
local getRemovefog = createToggle(VisualPage, "Remove fog", "Click to open Remove fog", 89)

local getGrayscaleMode = createToggle(VisualPage, "Grayscale Mode", "Click to open Grayscale Mode", 132)

local getVividMode = createToggle(VisualPage, "Vivid Mode", "Click to open Vivid Mode", 175)

local getESPPlayer = createToggle(VisualPage, "ESP Player", "Click to open ESP Player", 218)

local getXray = createToggle(VisualPage, "X-ray", "Click to open X-ray", 261)

local getFPS = createToggle(VisualPage, "FPS GUI", "Click to open GUI", 304)

local getInfiniteZoom = createToggle(VisualPage, "Infinite Zoom", "Click to open Infinite Zoom", 347)

local getblackscreen = createToggle(VisualPage, "Black Screen", "Click to open Black Screen", 390)

local getWhitescreen = createToggle(VisualPage, "white Screen", "Click to open Black Screen", 433)

-- ===================================================  
-- Page: Function
local contentFrameFunction, FunctionPage = createContentPage("Tools", 438)

-- ==========================
-- Page: FunctionPage
-- ==========================
createToggleButton(FunctionPage, "[ ❖ ] Roblox Developer Console", "Click to Open the Developer Console", "Button", 3, function()
  
  ERC_Notification("ERC SYSTEM (Beta)", "Roblox Developer Console Loading!", 5)
  
-- ฟังก์ชันกด F9
local function pressF9()

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F9, false, game)
    wait(0.05)
    
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F9, false, game)
end

pressF9()

end)

createToggleButton(FunctionPage, "[ ❖ ] Rejoin", "Rejoins your current server", "Button", 46, function()

ERC_Notification("ERC SYSTEM (Beta)", "Rejoins your current server!", 5)

TeleportService:TeleportToPlaceInstance(PlaceId, JobId, player)
    
end)

createToggleButton(FunctionPage, "[ ❖ ] Small Server", "Joins a server with a low playercount", "Button", 89, function()

ERC_Notification("ERC SYSTEM (Beta)", "Joins a server with a low playercount!", 5)

local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

    local function getSmallServer(cursor)
        local raw = game:HttpGet(url .. (cursor and "&cursor=" .. cursor or ""))
        local data = HttpService:JSONDecode(raw)

        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, player)
                return
            end
        end

        if data.nextPageCursor then
            getSmallServer(data.nextPageCursor)
        end
    end

    getSmallServer()

end)

createToggleButton(FunctionPage, "[ ❖ ] Serverhop", "Teleport to a new server", "Button", 132, function()

ERC_Notification("ERC SYSTEM (Beta)", "Teleport to a new server!", 5)
    
local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
    local raw = game:HttpGet(url)
    local data = HttpService:JSONDecode(raw)

    local servers = {}
    for _, server in ipairs(data.data) do
        if server.id ~= JobId and server.playing < server.maxPlayers then
            table.insert(servers, server.id)
        end
    end

    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(
            PlaceId,
            servers[math.random(1, #servers)],
            player
        )
    end
    
end)

createToggleButton(FunctionPage, "Infinite Yield FE", "Click to run the script", "Button", 175, function()

ERC_Notification("ERC SYSTEM (Beta)", "Script Infinite Yield FE Loading!", 5)

loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))();
    
end)

createToggleButton(FunctionPage, "Dex Explorer", "Click to run the script", "Button", 218, function()
    
    ERC_Notification("ERC SYSTEM (Beta)", "Script Dex Explorer For Mobile & PC Loading!", 5)
    
loadstring(game:HttpGet("https://raw.githubusercontent.com/pid4k/scripts/refs/heads/main/dexwithtags.lua"))()
    
end)

createToggleButton(FunctionPage, "ERROR HUB (All Map)", "Click to run the script", "Button", 261, function()

ERC_Notification("ERC SYSTEM (Beta)", "Script ERROR HUB (All Map) Loading!", 5)

loadstring(game:HttpGet("https://api.junkie-development.de/api/v1/luascripts/public/c88af945f482012c60e95d30e8311487aa5780fc013b77a18b21c14c373fe198/download"))()
    
end)

createToggleButton(FunctionPage, "Emotes Animation", "Click to run the script", "Button",  304, function()
    
    ERC_Notification("ERC SYSTEM (Beta)", "Script Emotes Animation Loading!", 5)

loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))();
    
end)

createToggleButton(FunctionPage, "Simple Shader", "Click to run the script", "Button", 347, function()

ERC_Notification("ERC SYSTEM (Beta)", "Script Simple Shader Loading!", 5)
    
loadstring(game:HttpGet("https://raw.githubusercontent.com/p0e1/1/refs/heads/main/SimpleShader.lua"))();
    
end)

createToggleButton(FunctionPage, "Script", "Click to run the script", "Button", 390, function()
    
ERC_Notification(nil, "*No Function*", 5)
    
end)

-- ===================================================  
-- Page: Teleport
local contentFrameTeleport, TeleportPage = createContentPage("Teleport", 300)

-- ==========================
-- Page: Teleport
-- ==========================
local teleportInput = createToggleText(TeleportPage, "Enter the Player name.", "Click to enter the player's name", "", "Player Name...", 3)

local getTPPlayerLooped = createToggle(TeleportPage, "Teleport to Plater", "Click to Teleport", 46)

-- ===================================================
-- Page: Games
local contentFrameGames, GamesPage = createContentPage("Games", 133)

-- ==========================
-- Page: GamesPage
-- ==========================
createToggleSection(GamesPage, "Evade (Coming Soon...)", 3)

-- สไลเดอร์ Walk Speed (Evade)
createToggleSlider(GamesPage, "Walk Speed", 46, 1450, 0, 2000, function(value)
	
end)

-- สไลเดอร์ Jump Power (Evade)
createToggleSlider(GamesPage, "Jump Cap", 89, 1, 0, 100, function(value)
	
end)

-- สไลเดอร์ Strafe (Evade)
createToggleSlider(GamesPage, "Strafe", 132, 200, 0, 500, function(value)
	
end)

-- ===================================================
-- Page: Music
local contentFrameMusic, musicPage = createContentPage("Music", 481)

-- ==========================
-- Sound Object
-- ==========================
local sound = Instance.new("Sound")
sound.Parent = SoundService
sound.Volume = 1
sound.Looped = false
sound.PlaybackSpeed = 1

-- ==========================
-- UI
-- ==========================
local SongName = createToggleSection(musicPage, "Song : None", 3)
local Status = createToggleSection(musicPage, "Status : System is on standby.", 46)
local TimeSong = createToggleTextLabel(musicPage, "Time Song", "Time display", "00:00 : 00:00", 89)
local idBox = createToggleText(musicPage, "ID Song", "Click to Message", "108531350726198", "ID...", 132)

-- ==========================
-- Volume Slider (Decimal)
-- ==========================
local currentVolume = 1
local VolumeSlider = createToggleSliderDecimal(
    musicPage, "Song Volume", 175, 1, 0, 10,
    function(value)
        currentVolume = value
        sound.Volume = currentVolume
    end
)

-- ==========================
-- Music Speed Slider (Decimal 1x → 5x)
-- ==========================
local currentSpeed = 1
local Musicspeed = createToggleSliderDecimal(
    musicPage, "Song speed", 218, 1, 0.1, 5,
    function(value)
        currentSpeed = value
        if sound.IsPlaying then
            sound.PlaybackSpeed = currentSpeed
        end
    end
)

-- ==========================
-- Looped
-- ==========================
local Looped = createToggle(musicPage, "Looped", "Click to open Looped", 390)

-- ==========================
-- Internal
-- ==========================
local lastId
local lastName = "Song : None"
local isLoading = false

local function formatTime(sec)
    sec = math.floor(sec or 0)
    return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

local function setStatus(text)
    Status.Text = text
end

-- ==========================
-- Update Loop
-- ==========================
RunService.RenderStepped:Connect(function()
    -- Update Time
    if sound.SoundId ~= "" and sound.TimeLength > 0 then
        TimeSong.Text = formatTime(sound.TimePosition) .. " | " .. formatTime(sound.TimeLength)
    else
        TimeSong.Text = "00:00 : 00:00"
    end

    -- Loop
    sound.Looped = Looped()

    -- Update Song Name (Audio Only)
    local id = tonumber(idBox.Text)
    if id and id ~= lastId then
        isLoading = true
        setStatus("Status : Loading audio resource…")
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
        end)
        if ok and info then
            if info.AssetTypeId == 3 then
                lastName = "Song : " .. (info.Name or "Unknown")
                isLoading = false
                setStatus("Status : System is on standby.")
            else
                lastName = "Please use only the song ID."
                isLoading = false
                setStatus("Status : Restricted / Not an audio asset.")
            end
        else
            lastName = "Song : Unknown"
            isLoading = false
            setStatus("Status : Failed to load the audio resource.")
        end
        lastId = id
    elseif not id then
        lastName = "Song : None"
        lastId = nil
        setStatus("Status: System is on standby.")
    end
    SongName.Text = lastName

    -- Update Status in real-time
    if isLoading then
        setStatus("Status : Loading audio resource…")
    elseif sound.IsPlaying then
        setStatus("Status : Playing audio...")
    elseif sound.SoundId ~= "" and not sound.IsPlaying then
        setStatus("Status : Audio paused.")
    else
        setStatus("Status : System is on standby.")
    end
end)

-- ==========================
-- Buttons
-- ==========================
-- Play
local PlaySong = createToggleButton(
    musicPage, "Play Song", "Click to Play", "Button", 261,
    function()
        local id = tonumber(idBox.Text)
        if not id then return end

        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
        end)

        if not ok or not info or info.AssetTypeId ~= 3 then
            SongName.Text = "Please use only the song ID."
            setStatus("Status : Restricted / Not an audio asset.")
            return
        end

        local assetId = "rbxassetid://" .. id

        if sound.SoundId ~= assetId then
            sound.SoundId = assetId
            sound.TimePosition = 0
            sound.Volume = currentVolume
            sound.PlaybackSpeed = currentSpeed
            isLoading = true
            setStatus("Status : Loading audio resource…")
            sound.Loaded:Wait()
            isLoading = false
            sound:Play()
            ERC_Notification("ERC SYSTEM (Beta)", "Song is playing.", 2)
        else
            if not sound.IsPlaying then
                sound.PlaybackSpeed = currentSpeed
                sound:Resume()
                ERC_Notification("ERC SYSTEM (Beta)", "Song is playing.", 2)
            end
        end
    end
)

-- Stop
local StopSong = createToggleButton(
    musicPage, "Stop Song", "Click to Stop", "Button", 304,
    function()
        if sound.IsPlaying then
            sound:Pause()
            ERC_Notification("ERC SYSTEM (Beta)", "Stop the Song.", 2)
        end
    end
)

-- Reset
local Reset = createToggleButton(
    musicPage, "Reset Song", "Click to reset", "Button", 347,
    function()
        if sound.SoundId ~= "" then
            sound.TimePosition = 0
            sound.PlaybackSpeed = currentSpeed
            sound:Play()
            ERC_Notification("ERC SYSTEM (Beta)", "Song reset complete.", 2)
        end
    end
)

-- Copy ID
local CopyID = createToggleButton(
    musicPage, "Copy ID Song", "Click to copy", "Button", 433,
    function()
        if idBox.Text ~= "" then
            setclipboard(idBox.Text)
            ERC_Notification("ERC SYSTEM (Beta)", "Copying is complete.", 2)
        end
    end
)

-- ===================================================  
-- Sidebar Buttons
local menuItems = {"Player", "Visual", "Tools", "Teleport", "Games", "Music"}
local currentSelected = nil
local buttons = {}

for i, name in ipairs(menuItems) do
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, -12, 0, 32)
    buttonFrame.Position = UDim2.new(0, 5, 0, (i-1.01) * 38 + 10)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.ZIndex = 20000
    buttonFrame.Parent = sidebar
    createUICorner(buttonFrame)

    -- ปุ่มจริง
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = "  " .. name
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.ZIndex = 20001
    button.Parent = buttonFrame
    button:SetAttribute("MenuName", name) -- เก็บชื่อเมนูไว้
    createUICorner(button)

    -- ขอบ
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(45, 45, 45)
    stroke.Enabled = false
    stroke.Parent = buttonFrame

    buttons[name] = {button = button, stroke = stroke}

    -- Hover Effect
    button.MouseEnter:Connect(function()
        if currentSelected ~= button then
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)

    button.MouseLeave:Connect(function()
        if currentSelected ~= button then
            button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)

    -- เมื่อคลิก
    button.MouseButton1Click:Connect(function()
        -- ปิดปุ่มเก่า
        if currentSelected then
            local oldName = currentSelected:GetAttribute("MenuName")
            currentSelected.TextColor3 = Color3.fromRGB(200, 200, 200)
            currentSelected.Text = "  " .. oldName
            currentSelected.Parent:FindFirstChildOfClass("UIStroke").Enabled = false
        end

        -- ปุ่มใหม่
        currentSelected = button
        local newName = button:GetAttribute("MenuName")
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        stroke.Enabled = true

        -- เอฟเฟกต์ขยับข้อความแบบ Tween
        local startText = "  " .. newName
        local endText = "     " .. newName
        button.Text = startText

        local tween = TweenService:Create(button, TweenInfo.new(0.0001, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {})
        tween.Completed:Connect(function()
            button.Text = endText
        end)
        tween:Play()

        -- สลับหน้า
        switchPage(newName)
    end)
end

-- ==========================
-- ตั้งค่าเริ่มต้น (เลือกหน้าแรก)
-- ==========================
local firstName = menuItems[1]
local firstData = buttons[firstName]

if firstData then
    local button = firstData.button
    local stroke = firstData.stroke

    currentSelected = button
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "     " .. firstName
    stroke.Enabled = true

    switchPage(firstName)
end

-- ===================================================
-- Close ScreenGui
MaincloseButton.MouseButton1Click:Connect(function()
ScreenGuiun:Destroy()
ScreenERCGui:Destroy()
ScreenGuiAll:Destroy()
ScreenGuiBW:Destroy()
end)

-- ===================================================