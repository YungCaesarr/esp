------------------------------------------------
-- VARIABLES Y SERVICIOS
------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

------------------------------------------------
-- CONFIG
------------------------------------------------

local espEnabled = true

local whitelistColor = Color3.fromRGB(0,255,255)
local targetColor = Color3.fromRGB(255,255,0)

local chamsColor = Color3.fromRGB(255,255,255)
local outlineColor = Color3.fromRGB(0,0,0)

local WhitelistUsers = {}
local TargetUser = nil

local showNameEnabled = false
local showDistanceEnabled = false
local showHealthEnabled = false

local showOutlineEnabled = true
local showChamsEnabled = false

local chamsOpacity = 0.5

local nameTextSize = 12

local labelNameColor = Color3.fromRGB(255,255,255)
local labelDistanceColor = Color3.fromRGB(255,255,255)

local maxDistance = 1400
local refreshRate = 5

------------------------------------------------
-- TOGGLE KEYS
------------------------------------------------

local uiToggleKey = Enum.KeyCode.K
local espToggleKey = Enum.KeyCode.F3

------------------------------------------------
-- HELPERS
------------------------------------------------

local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function getInitials(str)
	local initials = ""

	for word in string.gmatch(str,"%S+") do
		initials = initials .. word:sub(1,1)
	end

	return initials:upper()
end

local function Color3ToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

local function safeCallback(callback)
	return function(...)
		local success, err = pcall(callback,...)

		if not success then
			warn("Callback error:", err)
		end
	end
end

------------------------------------------------
-- PLAYER FINDER
------------------------------------------------

local function findPlayer(inputText)
	inputText = trim(inputText)

	if inputText == "" then
		return nil
	end

	local inputLen = #inputText

	for _, player in ipairs(Players:GetPlayers()) do
		local name = player.Name
		local display = player.DisplayName or ""

		local initials = getInitials(display)

		if
			string.lower(name) == string.lower(inputText)
			or string.lower(display) == string.lower(inputText)
			or string.lower(name:sub(1,inputLen)) == string.lower(inputText)
			or string.lower(display:sub(1,inputLen)) == string.lower(inputText)
			or string.lower(initials) == string.lower(inputText)
			or string.lower(initials:sub(1,inputLen)) == string.lower(inputText)
		then
			return player
		end
	end

	return nil
end

------------------------------------------------
-- RAYFIELD
------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

------------------------------------------------
-- THEME
------------------------------------------------

local customTheme = {
	TextColor = Color3.fromRGB(230,230,250),
	Background = Color3.fromRGB(20,20,30),
	Topbar = Color3.fromRGB(30,30,40),
	Shadow = Color3.fromRGB(10,10,15),
	NotificationBackground = Color3.fromRGB(20,20,30),
	NotificationActionsBackground = Color3.fromRGB(220,220,240),
	TabBackground = Color3.fromRGB(25,25,35),
	TabStroke = Color3.fromRGB(45,45,55),
	TabBackgroundSelected = Color3.fromRGB(70,70,90),
	TabTextColor = Color3.fromRGB(230,230,250),
	SelectedTabTextColor = Color3.fromRGB(255,255,255),
	ElementBackground = Color3.fromRGB(25,25,35),
	ElementBackgroundHover = Color3.fromRGB(30,30,45),
	SecondaryElementBackground = Color3.fromRGB(20,20,30),
	ElementStroke = Color3.fromRGB(50,50,60),
	SecondaryElementStroke = Color3.fromRGB(35,35,45),
	SliderBackground = Color3.fromRGB(45,45,65),
	SliderProgress = Color3.fromRGB(45,45,65),
	SliderStroke = Color3.fromRGB(55,55,75),
	ToggleBackground = Color3.fromRGB(20,20,30),
	ToggleEnabled = Color3.fromRGB(90,70,140),
	ToggleDisabled = Color3.fromRGB(70,70,70),
	ToggleEnabledStroke = Color3.fromRGB(100,80,150),
	ToggleDisabledStroke = Color3.fromRGB(80,80,80),
	ToggleEnabledOuterStroke = Color3.fromRGB(100,80,150),
	ToggleDisabledOuterStroke = Color3.fromRGB(80,80,80),
	DropdownSelected = Color3.fromRGB(25,25,35),
	DropdownUnselected = Color3.fromRGB(20,20,30),
	InputBackground = Color3.fromRGB(20,20,30),
	InputStroke = Color3.fromRGB(50,50,60),
	PlaceholderColor = Color3.fromRGB(150,150,170)
}

------------------------------------------------
-- WINDOW
------------------------------------------------

local Window = Rayfield:CreateWindow({
	Name = "YungCaesar Hub",
	Icon = "rewind",
	LoadingTitle = "YungCaesar Hub",
	LoadingSubtitle = "by YungCaesar",
	Theme = customTheme,

	ConfigurationSaving = {
		Enabled = true,
		FileName = "YungCaesarHub"
	},

	Discord = {
		Enabled = false,
		Invite = "",
		RememberJoins = true
	},

	KeySystem = false
})

------------------------------------------------
-- TABS
------------------------------------------------

local MainTab = Window:CreateTab("Main",4483362458)
local ColorsTab = Window:CreateTab("ESP Colors","palette")
local EspConfigTab = Window:CreateTab("ESP Config","settings")

------------------------------------------------
-- ESP FUNCTIONS
------------------------------------------------

local function getHighlightColor(player)
	if table.find(WhitelistUsers,player.Name) then
		return whitelistColor
	end

	if TargetUser and player.Name == TargetUser then
		return targetColor
	end

	return chamsColor
end

local function updateHighlight(player)
	if not player.Character then
		return
	end

	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return
	end

	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	local highlight = character:FindFirstChild("ESPHighlight")

	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.Parent = character
	end

	if not espEnabled then
		highlight.Enabled = false
		return
	end

	if localHRP then
		local distance = (hrp.Position - localHRP.Position).Magnitude

		if distance > maxDistance then
			highlight.Enabled = false
			return
		end
	end

	highlight.Enabled = true

	local color = getHighlightColor(player)

	highlight.FillColor = color
	highlight.OutlineColor = outlineColor

	highlight.FillTransparency = showChamsEnabled and chamsOpacity or 1
	highlight.OutlineTransparency = showOutlineEnabled and 0 or 1
end

------------------------------------------------
-- HEAD LABEL
------------------------------------------------

local function updatePlayerHeadLabel(player)
	if not player.Character then
		return
	end

	local head = player.Character:FindFirstChild("Head")

	if not head then
		return
	end

	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")

	if localHRP and hrp then
		local distance = (hrp.Position - localHRP.Position).Magnitude

		if distance > maxDistance then
			local existing = head:FindFirstChild("ESP_HeadGui")

			if existing then
				existing:Destroy()
			end

			return
		end
	end

	if not espEnabled or not showNameEnabled then
		local existing = head:FindFirstChild("ESP_HeadGui")

		if existing then
			existing:Destroy()
		end

		return
	end

	local bg = head:FindFirstChild("ESP_HeadGui")

	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = "ESP_HeadGui"
		bg.Adornee = head
		bg.Size = UDim2.new(0,150,0,25)
		bg.StudsOffset = Vector3.new(0,2,0)
		bg.AlwaysOnTop = true
		bg.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "NameLabel"
		label.BackgroundTransparency = 1
		label.RichText = true
		label.Size = UDim2.new(1,0,1,0)
		label.Font = Enum.Font.SourceSansBold
		label.TextStrokeTransparency = 0
		label.Parent = bg
	end

	local label = bg:FindFirstChild("NameLabel")

	if label then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

		local hpText = ""

		if humanoid and showHealthEnabled then
			hpText = string.format(
				" [%d/%d]",
				math.floor(humanoid.Health),
				math.floor(humanoid.MaxHealth)
			)
		end

		label.Text = string.format(
			'<font color="%s">%s%s</font>',
			Color3ToHex(labelNameColor),
			player.Name,
			hpText
		)

		label.TextSize = nameTextSize
	end
end

------------------------------------------------
-- FEET LABEL
------------------------------------------------

local function updatePlayerFeetLabel(player)
	if not player.Character then
		return
	end

	local feetPart =
		player.Character:FindFirstChild("LowerTorso")
		or player.Character:FindFirstChild("Torso")
		or player.Character:FindFirstChild("HumanoidRootPart")

	if not feetPart then
		return
	end

	if not espEnabled or not showDistanceEnabled then
		local existing = feetPart:FindFirstChild("ESP_FeetGui")

		if existing then
			existing:Destroy()
		end

		return
	end

	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")

	if not localHRP or not hrp then
		return
	end

	local distance = (hrp.Position - localHRP.Position).Magnitude

	if distance > maxDistance then
		local existing = feetPart:FindFirstChild("ESP_FeetGui")

		if existing then
			existing:Destroy()
		end

		return
	end

	local bg = feetPart:FindFirstChild("ESP_FeetGui")

	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = "ESP_FeetGui"
		bg.Adornee = feetPart
		bg.Size = UDim2.new(0,150,0,25)
		bg.StudsOffset = Vector3.new(0,-3,0)
		bg.AlwaysOnTop = true
		bg.Parent = feetPart

		local label = Instance.new("TextLabel")
		label.Name = "DistanceLabel"
		label.BackgroundTransparency = 1
		label.RichText = true
		label.Size = UDim2.new(1,0,1,0)
		label.Font = Enum.Font.SourceSansBold
		label.TextStrokeTransparency = 0
		label.Parent = bg
	end

	local label = bg:FindFirstChild("DistanceLabel")

	if label then
		label.Text = string.format(
			'<font color="%s">%.1f studs</font>',
			Color3ToHex(labelDistanceColor),
			distance
		)

		label.TextSize = nameTextSize
	end
end

------------------------------------------------
-- UPDATE ALL
------------------------------------------------

local function updateAllESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			updateHighlight(player)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end
	end
end

------------------------------------------------
-- LOOPS
------------------------------------------------

task.spawn(function()
	while true do
		task.wait(refreshRate / 1000)
		updateAllESP()
	end
end)

------------------------------------------------
-- MAIN UI
------------------------------------------------

MainTab:CreateSection("ESP")

MainTab:CreateToggle({
	Name = "Activate ESP",
	CurrentValue = espEnabled,
	Flag = "ESP_ENABLED",
	Callback = safeCallback(function(Value)
		espEnabled = Value
		updateAllESP()
	end)
})

------------------------------------------------
-- CHOOSE UI TOGGLE KEY
------------------------------------------------

MainTab:CreateInput({
	Name = "Choose UI Toggle Key",
	PlaceholderText = "Example: K, L, F1",
	RemoveTextAfterFocusLost = false,
	Flag = "UI_KEY",
	Callback = safeCallback(function(Text)

		Text = string.upper(trim(Text))

		local success, result = pcall(function()
			return Enum.KeyCode[Text]
		end)

		if success and result then
			uiToggleKey = result
			print("UI Toggle Key:", Text)
		else
			warn("Invalid UI key.")
		end
	end)
})

------------------------------------------------
-- CHOOSE ESP TOGGLE KEY
------------------------------------------------

MainTab:CreateInput({
	Name = "Choose ESP Toggle Key",
	PlaceholderText = "Example: F3, H, J",
	RemoveTextAfterFocusLost = false,
	Flag = "ESP_KEY",
	Callback = safeCallback(function(Text)

		Text = string.upper(trim(Text))

		local success, result = pcall(function()
			return Enum.KeyCode[Text]
		end)

		if success and result then
			espToggleKey = result
			print("ESP Toggle Key:", Text)
		else
			warn("Invalid ESP key.")
		end
	end)
})

------------------------------------------------
-- WHITELIST
------------------------------------------------

MainTab:CreateSection("Whitelist")

local WhitelistDropdown

MainTab:CreateInput({
	Name = "Whitelist User",
	PlaceholderText = "Username / Display / Initials",
	RemoveTextAfterFocusLost = false,

	Callback = safeCallback(function(Text)

		local player = findPlayer(Text)

		if not player then
			return
		end

		if not table.find(WhitelistUsers,player.Name) then
			table.insert(WhitelistUsers,player.Name)

			if WhitelistDropdown then
				WhitelistDropdown:Refresh(WhitelistUsers)
			end
		end

		updateAllESP()
	end)
})

WhitelistDropdown = MainTab:CreateDropdown({
	Name = "Whitelisted Users",
	Options = {},
	CurrentOption = nil,
	MultipleOptions = false,

	Callback = safeCallback(function(Value)

		if not Value then
			return
		end

		for i,v in ipairs(WhitelistUsers) do
			if v == Value then
				table.remove(WhitelistUsers,i)
				break
			end
		end

		WhitelistDropdown:Refresh(WhitelistUsers)

		updateAllESP()
	end)
})

------------------------------------------------
-- TARGET
------------------------------------------------

MainTab:CreateSection("Target")

MainTab:CreateInput({
	Name = "Target User",
	PlaceholderText = "Username / Display / Initials",
	RemoveTextAfterFocusLost = false,

	Callback = safeCallback(function(Text)

		local player = findPlayer(Text)

		if player then
			TargetUser = player.Name
		else
			TargetUser = nil
		end

		updateAllESP()
	end)
})

------------------------------------------------
-- COLORS
------------------------------------------------

ColorsTab:CreateSection("ESP Colors")

ColorsTab:CreateColorPicker({
	Name = "Whitelist Color",
	Color = whitelistColor,

	Callback = safeCallback(function(Value)
		whitelistColor = Value
		updateAllESP()
	end)
})

ColorsTab:CreateColorPicker({
	Name = "Target Color",
	Color = targetColor,

	Callback = safeCallback(function(Value)
		targetColor = Value
		updateAllESP()
	end)
})

ColorsTab:CreateColorPicker({
	Name = "Chams Color",
	Color = chamsColor,

	Callback = safeCallback(function(Value)
		chamsColor = Value
		updateAllESP()
	end)
})

ColorsTab:CreateColorPicker({
	Name = "Outline Color",
	Color = outlineColor,

	Callback = safeCallback(function(Value)
		outlineColor = Value
		updateAllESP()
	end)
})

------------------------------------------------
-- CONFIG
------------------------------------------------

EspConfigTab:CreateSection("ESP Config")

EspConfigTab:CreateToggle({
	Name = "Show Player Name",
	CurrentValue = showNameEnabled,

	Callback = safeCallback(function(Value)
		showNameEnabled = Value
	end)
})

EspConfigTab:CreateToggle({
	Name = "Show Distance",
	CurrentValue = showDistanceEnabled,

	Callback = safeCallback(function(Value)
		showDistanceEnabled = Value
	end)
})

EspConfigTab:CreateToggle({
	Name = "Show Health",
	CurrentValue = showHealthEnabled,

	Callback = safeCallback(function(Value)
		showHealthEnabled = Value
	end)
})

EspConfigTab:CreateToggle({
	Name = "Enable Outline ESP",
	CurrentValue = showOutlineEnabled,

	Callback = safeCallback(function(Value)
		showOutlineEnabled = Value
		updateAllESP()
	end)
})

EspConfigTab:CreateToggle({
	Name = "Enable Full Chams ESP",
	CurrentValue = showChamsEnabled,

	Callback = safeCallback(function(Value)
		showChamsEnabled = Value
		updateAllESP()
	end)
})

EspConfigTab:CreateSlider({
	Name = "Chams Opacity",
	Range = {0,1},
	Increment = 0.05,
	CurrentValue = chamsOpacity,

	Callback = safeCallback(function(Value)
		chamsOpacity = Value
		updateAllESP()
	end)
})

EspConfigTab:CreateSlider({
	Name = "Text Size",
	Range = {8,24},
	Increment = 1,
	CurrentValue = nameTextSize,

	Callback = safeCallback(function(Value)
		nameTextSize = Value
	end)
})

EspConfigTab:CreateSlider({
	Name = "ESP Distance",
	Range = {300,1400},
	Increment = 10,
	CurrentValue = maxDistance,

	Callback = safeCallback(function(Value)
		maxDistance = Value
		updateAllESP()
	end)
})

------------------------------------------------
-- PLAYER CONNECTIONS
------------------------------------------------

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()
		task.wait(1)
		updateAllESP()
	end)

	if player.Character then
		updateAllESP()
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

------------------------------------------------
-- KEYBINDS
------------------------------------------------

UserInputService.InputBegan:Connect(safeCallback(function(input,gp)

	if gp then
		return
	end

	if input.KeyCode == uiToggleKey then
		Window:ToggleVisibility()
	end

	if input.KeyCode == espToggleKey then
		espEnabled = not espEnabled

		updateAllESP()

		print("ESP:", espEnabled and "Enabled" or "Disabled")
	end
end))

------------------------------------------------
-- LOAD CONFIG
------------------------------------------------

pcall(function()
	Rayfield:LoadConfiguration()
end)
