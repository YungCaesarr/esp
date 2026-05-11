------------------------------------------------
-- SERVICES
------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------
-- SETTINGS
------------------------------------------------
local espEnabled = true

local whitelistColor = Color3.fromRGB(0,255,255)
local targetColor = Color3.fromRGB(255,255,0)

local chamsColor = Color3.fromRGB(255,255,255)
local outlineColor = Color3.fromRGB(0,0,0)

local labelNameColor = Color3.fromRGB(255,255,255)
local labelDistanceColor = Color3.fromRGB(255,255,255)

local showNameEnabled = false
local showDistanceEnabled = false
local showHealthEnabled = false

local showOutlineEnabled = true
local showChamsEnabled = false

local chamsOpacity = 0.5
local nameTextSize = 12

local maxDistance = 1400
local refreshRate = 0.05

local uiToggleKey = Enum.KeyCode.K
local espToggleKey = Enum.KeyCode.F3

local WhitelistUsers = {}
local TargetUser = nil

------------------------------------------------
-- UTILS
------------------------------------------------
local function safeCallback(callback)
	return function(...)
		local success, err = pcall(callback,...)

		if not success then
			warn("[ESP ERROR]: ".. tostring(err))
		end
	end
end

local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

local function getInitials(str)
	local result = ""

	for word in string.gmatch(str,"%S+") do
		result = result .. word:sub(1,1)
	end

	return result:upper()
end

local function Color3ToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

local function getCharacter(player)
	return player.Character
end

local function getHRP(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getDistance(character)
	local localChar = getCharacter(LocalPlayer)

	if not localChar then
		return math.huge
	end

	local localHRP = getHRP(localChar)
	local targetHRP = getHRP(character)

	if not localHRP or not targetHRP then
		return math.huge
	end

	return (localHRP.Position - targetHRP.Position).Magnitude
end

local function isPlayerVisible(character)
	return getDistance(character) <= maxDistance
end

local function findPlayer(input)
	input = string.lower(trim(input))

	for _, player in ipairs(Players:GetPlayers()) do
		local username = string.lower(player.Name)
		local display = string.lower(player.DisplayName)
		local initials = string.lower(getInitials(player.DisplayName))

		if username == input
		or display == input
		or username:sub(1,#input) == input
		or display:sub(1,#input) == input
		or initials == input then
			return player
		end
	end
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
		Enabled = false
	},

	KeySystem = false
})

------------------------------------------------
-- TABS
------------------------------------------------
local MainTab = Window:CreateTab("Main",4483362458)
local ColorsTab = Window:CreateTab("ESP Colors","palette")
local ConfigTab = Window:CreateTab("ESP Config","settings")

------------------------------------------------
-- HIGHLIGHT
------------------------------------------------
local function applyHighlight(player)
	if player == LocalPlayer then
		return
	end

	local character = getCharacter(player)

	if not character then
		return
	end

	local highlight = character:FindFirstChild("ESPHighlight")

	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = character
	end

	if not espEnabled or not isPlayerVisible(character) then
		highlight.Enabled = false
		return
	end

	highlight.Enabled = true

	if table.find(WhitelistUsers,player.Name) then
		highlight.FillColor = whitelistColor
		highlight.OutlineColor = whitelistColor

	elseif TargetUser == player.Name then
		highlight.FillColor = targetColor
		highlight.OutlineColor = targetColor

	else
		highlight.FillColor = chamsColor
		highlight.OutlineColor = outlineColor
	end

	highlight.FillTransparency = showChamsEnabled and chamsOpacity or 1
	highlight.OutlineTransparency = showOutlineEnabled and 0 or 1
end

------------------------------------------------
-- HEAD LABEL
------------------------------------------------
local function updateHeadLabel(player)
	local character = getCharacter(player)

	if not character then
		return
	end

	local head = character:FindFirstChild("Head")

	if not head then
		return
	end

	local existing = head:FindFirstChild("ESP_HeadGui")

	if not showNameEnabled or not espEnabled or not isPlayerVisible(character) then
		if existing then
			existing:Destroy()
		end

		return
	end

	local billboard = existing

	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "ESP_HeadGui"
		billboard.Size = UDim2.new(0,150,0,25)
		billboard.StudsOffset = Vector3.new(0,2,0)
		billboard.AlwaysOnTop = true
		billboard.Adornee = head
		billboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.RichText = true
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.SourceSansBold
		label.Parent = billboard
	end

	local label = billboard:FindFirstChild("Label")

	if not label then
		return
	end

	local healthText = ""

	if showHealthEnabled then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			healthText = string.format(
				" [%d/%d]",
				math.floor(humanoid.Health),
				math.floor(humanoid.MaxHealth)
			)
		end
	end

	label.Text = string.format(
		'<font color="%s">%s%s</font>',
		Color3ToHex(labelNameColor),
		player.Name,
		healthText
	)

	label.TextSize = nameTextSize
end

------------------------------------------------
-- DISTANCE LABEL
------------------------------------------------
local function updateDistanceLabel(player)
	local character = getCharacter(player)

	if not character then
		return
	end

	local root =
		character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local existing = root:FindFirstChild("ESP_DistanceGui")

	if not showDistanceEnabled or not espEnabled or not isPlayerVisible(character) then
		if existing then
			existing:Destroy()
		end

		return
	end

	local billboard = existing

	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "ESP_DistanceGui"
		billboard.Size = UDim2.new(0,150,0,25)
		billboard.StudsOffset = Vector3.new(0,-3,0)
		billboard.AlwaysOnTop = true
		billboard.Adornee = root
		billboard.Parent = root

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.RichText = true
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.SourceSansBold
		label.Parent = billboard
	end

	local label = billboard:FindFirstChild("Label")

	if not label then
		return
	end

	label.Text = string.format(
		'<font color="%s">%.0f studs</font>',
		Color3ToHex(labelDistanceColor),
		getDistance(character)
	)

	label.TextSize = nameTextSize
end

------------------------------------------------
-- UPDATE ALL
------------------------------------------------
local function updateAll()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			applyHighlight(player)
			updateHeadLabel(player)
			updateDistanceLabel(player)
		end
	end
end

------------------------------------------------
-- LOOP
------------------------------------------------
task.spawn(function()
	while task.wait(refreshRate) do
		updateAll()
	end
end)

------------------------------------------------
-- MAIN TAB
------------------------------------------------
MainTab:CreateToggle({
	Name = "Activate ESP",
	CurrentValue = espEnabled,
	Flag = "ESP_ENABLED",

	Callback = safeCallback(function(value)
		espEnabled = value
		updateAll()
	end)
})

------------------------------------------------
-- TOGGLE KEY CHANGER
------------------------------------------------
local keyOptions = {
	"K","L","J","H","F1","F2","F3","F4","Insert","Home","End","RightShift"
}

ConfigTab:CreateDropdown({
	Name = "Choose Toggle Key",
	Options = keyOptions,
	CurrentOption = {"K"},
	MultipleOptions = false,
	Flag = "UI_KEY",

	Callback = safeCallback(function(option)
		local selected = typeof(option) == "table" and option[1] or option

		if selected and Enum.KeyCode[selected] then
			uiToggleKey = Enum.KeyCode[selected]
			print("UI Toggle Key:",selected)
		end
	end)
})

------------------------------------------------
-- CONFIG TAB
------------------------------------------------
ConfigTab:CreateToggle({
	Name = "Show Player Names",
	CurrentValue = false,

	Callback = safeCallback(function(v)
		showNameEnabled = v
		updateAll()
	end)
})

ConfigTab:CreateToggle({
	Name = "Show Distance",
	CurrentValue = false,

	Callback = safeCallback(function(v)
		showDistanceEnabled = v
		updateAll()
	end)
})

ConfigTab:CreateToggle({
	Name = "Show Health",
	CurrentValue = false,

	Callback = safeCallback(function(v)
		showHealthEnabled = v
		updateAll()
	end)
})

ConfigTab:CreateToggle({
	Name = "Enable Outline",
	CurrentValue = true,

	Callback = safeCallback(function(v)
		showOutlineEnabled = v
		updateAll()
	end)
})

ConfigTab:CreateToggle({
	Name = "Enable Chams",
	CurrentValue = false,

	Callback = safeCallback(function(v)
		showChamsEnabled = v
		updateAll()
	end)
})

ConfigTab:CreateSlider({
	Name = "Text Size",
	Range = {8,24},
	Increment = 1,
	CurrentValue = nameTextSize,

	Callback = safeCallback(function(v)
		nameTextSize = v
	end)
})

ConfigTab:CreateSlider({
	Name = "Max Distance",
	Range = {100,1400},
	Increment = 10,
	CurrentValue = maxDistance,

	Callback = safeCallback(function(v)
		maxDistance = v
	end)
})

ConfigTab:CreateSlider({
	Name = "Chams Opacity",
	Range = {0,1},
	Increment = 0.05,
	CurrentValue = chamsOpacity,

	Callback = safeCallback(function(v)
		chamsOpacity = v
	end)
})

------------------------------------------------
-- COLORS TAB
------------------------------------------------
ColorsTab:CreateColorPicker({
	Name = "Whitelist Color",
	Color = whitelistColor,

	Callback = safeCallback(function(v)
		whitelistColor = v
	end)
})

ColorsTab:CreateColorPicker({
	Name = "Target Color",
	Color = targetColor,

	Callback = safeCallback(function(v)
		targetColor = v
	end)
})

ColorsTab:CreateColorPicker({
	Name = "Chams Color",
	Color = chamsColor,

	Callback = safeCallback(function(v)
		chamsColor = v
	end)
})

ColorsTab:CreateColorPicker({
	Name = "Outline Color",
	Color = outlineColor,

	Callback = safeCallback(function(v)
		outlineColor = v
	end)
})

------------------------------------------------
-- WHITELIST
------------------------------------------------
local whitelistDropdown

MainTab:CreateInput({
	Name = "Whitelist User",
	PlaceholderText = "Username / Display / Initials",

	Callback = safeCallback(function(text)
		local player = findPlayer(text)

		if player and not table.find(WhitelistUsers,player.Name) then
			table.insert(WhitelistUsers,player.Name)

			if whitelistDropdown then
				whitelistDropdown:Refresh(WhitelistUsers)
			end
		end
	end)
})

whitelistDropdown = MainTab:CreateDropdown({
	Name = "Whitelisted Users",
	Options = WhitelistUsers,
	CurrentOption = nil,
	MultipleOptions = false,

	Callback = safeCallback(function(option)
		local selected = typeof(option) == "table" and option[1] or option

		if not selected then
			return
		end

		for i,v in ipairs(WhitelistUsers) do
			if v == selected then
				table.remove(WhitelistUsers,i)
				break
			end
		end

		whitelistDropdown:Refresh(WhitelistUsers)
	end)
})

------------------------------------------------
-- TARGET
------------------------------------------------
local targetDropdown

MainTab:CreateInput({
	Name = "Target User",
	PlaceholderText = "Username / Display / Initials",

	Callback = safeCallback(function(text)
		local player = findPlayer(text)

		if player then
			TargetUser = player.Name

			if targetDropdown then
				targetDropdown:Refresh({TargetUser})
			end
		end
	end)
})

targetDropdown = MainTab:CreateDropdown({
	Name = "Current Target",
	Options = {},
	CurrentOption = nil,
	MultipleOptions = false,

	Callback = safeCallback(function(option)
		local selected = typeof(option) == "table" and option[1] or option

		if selected then
			TargetUser = nil
			targetDropdown:Refresh({})
		end
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
		updateAll()
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

------------------------------------------------
-- LOAD CONFIG
------------------------------------------------
Rayfield:LoadConfiguration()

------------------------------------------------
-- KEYBINDS
------------------------------------------------
local function toggleUI()
	for _, gui in ipairs(CoreGui:GetChildren()) do
		if gui:IsA("ScreenGui") and string.find(string.lower(gui.Name),"rayfield") then
			gui.Enabled = not gui.Enabled
		end
	end
end

UserInputService.InputBegan:Connect(safeCallback(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == uiToggleKey then
		toggleUI()
	end

	if input.KeyCode == espToggleKey then
		espEnabled = not espEnabled
		updateAll()

		print("ESP:", espEnabled and "Enabled" or "Disabled")
	end
end))
