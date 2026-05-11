------------------------------------------------
-- Variables y servicios
------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

------------------------------------------------
-- Configuración base
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
local refreshRate = 0.05

------------------------------------------------
-- Funciones auxiliares
------------------------------------------------
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function getInitials(str)
	local initials = ""
	for word in string.gmatch(str or "", "%S+") do
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
		local success, err = pcall(callback, ...)
		if not success then
			warn("Callback error:", err)
		end
	end
end

local function isShiftDown()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

local function getCharacterParts(player)
	local character = player.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local feetPart =
		character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("Torso")
		or hrp

	return character, head, hrp, feetPart
end

local function getDistance(hrp)
	local localChar = LocalPlayer.Character
	if not localChar then return math.huge end

	local localHRP = localChar:FindFirstChild("HumanoidRootPart")
	if not localHRP or not hrp then
		return math.huge
	end

	return (hrp.Position - localHRP.Position).Magnitude
end

local function getESPColors(player)
	if table.find(WhitelistUsers, player.Name) then
		return whitelistColor, whitelistColor
	elseif TargetUser and player.Name == TargetUser then
		return targetColor, targetColor
	end

	return outlineColor, chamsColor
end

local function findPlayer(input)
	input = trim(input or "")
	if input == "" then return nil end

	local lower = string.lower(input)
	local len = #input

	for _, player in ipairs(Players:GetPlayers()) do
		local name = player.Name
		local display = player.DisplayName or ""
		local initials = getInitials(display)

		if string.lower(name) == lower
			or string.lower(display) == lower
			or string.lower(name:sub(1, len)) == lower
			or string.lower(display:sub(1, len)) == lower
			or string.lower(initials) == lower
			or string.lower(initials:sub(1, len)) == lower
		then
			return player
		end
	end
end

------------------------------------------------
-- Rayfield
------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "YungCaesar Hub",
	Icon = "rewind",
	LoadingTitle = "YungCaesar Hub",
	LoadingSubtitle = "by YungCaesar",
	ConfigurationSaving = {
		Enabled = true,
		FileName = "YungCaesarHub"
	},
	KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ColorsTab = Window:CreateTab("ESP Colors", "palette")
local EspConfigTab = Window:CreateTab("ESP Config", "settings")

------------------------------------------------
-- ESP
------------------------------------------------
local function updateHeadLabel(player)
	local character, head, hrp = getCharacterParts(player)
	if not character or not head or not hrp then return end

	local existing = head:FindFirstChild("ESP_HeadGui")

	if not espEnabled or not showNameEnabled or getDistance(hrp) > maxDistance then
		if existing then existing:Destroy() end
		return
	end

	local bg = existing

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
		label.Font = Enum.Font.SourceSans
		label.TextStrokeTransparency = 0
		label.Parent = bg
	end

	local label = bg:FindFirstChild("NameLabel")
	if not label then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	local hpText = ""
	if showHealthEnabled and humanoid then
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

local function updateFeetLabel(player)
	local character, _, hrp, feetPart = getCharacterParts(player)
	if not character or not feetPart or not hrp then return end

	local existing = feetPart:FindFirstChild("ESP_FeetGui")

	if not espEnabled or not showDistanceEnabled or getDistance(hrp) > maxDistance then
		if existing then existing:Destroy() end
		return
	end

	local bg = existing

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
		label.Font = Enum.Font.SourceSans
		label.TextStrokeTransparency = 0
		label.Parent = bg
	end

	local label = bg:FindFirstChild("DistanceLabel")
	if not label then return end

	label.Text = string.format(
		'<font color="%s">%.1f studs</font>',
		Color3ToHex(labelDistanceColor),
		getDistance(hrp)
	)

	label.TextSize = nameTextSize
end

local function updateHighlight(player)
	local character, _, hrp = getCharacterParts(player)
	if not character or not hrp then return end

	local highlight = character:FindFirstChild("ESPHighlight")

	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.Parent = character
	end

	if not espEnabled or getDistance(hrp) > maxDistance then
		highlight.Enabled = false
		return
	end

	local outline, fill = getESPColors(player)

	highlight.Enabled = true
	highlight.OutlineColor = outline
	highlight.FillColor = fill

	highlight.FillTransparency =
		showChamsEnabled and chamsOpacity or 1

	highlight.OutlineTransparency =
		showOutlineEnabled and 0 or 1
end

local function updateAll()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			updateHighlight(player)
			updateHeadLabel(player)
			updateFeetLabel(player)
		end
	end
end

------------------------------------------------
-- Loop
------------------------------------------------
task.spawn(function()
	while task.wait(refreshRate) do
		updateAll()
	end
end)

------------------------------------------------
-- Main UI
------------------------------------------------
MainTab:CreateSection("ESP Options")

MainTab:CreateToggle({
	Name = "Activate ESP",
	CurrentValue = espEnabled,
	Flag = "ESP_Toggle",
	Callback = safeCallback(function(Value)
		espEnabled = Value
		updateAll()
	end)
})

------------------------------------------------
-- Whitelist
------------------------------------------------
MainTab:CreateSection("Whitelist Options")

local WhitelistDropdown

MainTab:CreateInput({
	Name = "Whitelist User",
	PlaceholderText = "Enter username",
	RemoveTextAfterFocusLost = false,
	Flag = "Whitelist_Input",
	Callback = safeCallback(function(Text)
		local player = findPlayer(Text)

		if player then
			if not table.find(WhitelistUsers, player.Name) then
				table.insert(WhitelistUsers, player.Name)
			end
		end

		if WhitelistDropdown then
			WhitelistDropdown:Refresh(WhitelistUsers)
		end

		updateAll()
	end)
})

WhitelistDropdown = MainTab:CreateDropdown({
	Name = "Whitelisted Users",
	Options = WhitelistUsers,
	CurrentOption = nil,
	MultipleOptions = false,
	Flag = "Whitelist_Dropdown",
	Callback = safeCallback(function(Option)
		local selected =
			typeof(Option) == "table" and Option[1] or Option

		if not selected then return end

		for i,v in ipairs(WhitelistUsers) do
			if v == selected then
				table.remove(WhitelistUsers, i)
				break
			end
		end

		WhitelistDropdown:Refresh(WhitelistUsers)
		updateAll()
	end)
})

------------------------------------------------
-- Target
------------------------------------------------
MainTab:CreateSection("Target Options")

local TargetDropdown

MainTab:CreateInput({
	Name = "Target User",
	PlaceholderText = "Enter username",
	RemoveTextAfterFocusLost = false,
	Flag = "Target_Input",
	Callback = safeCallback(function(Text)
		local player = findPlayer(Text)

		if player then
			TargetUser = player.Name
		else
			TargetUser = nil
		end

		if TargetDropdown then
			TargetDropdown:Refresh(
				TargetUser and {TargetUser} or {}
			)
		end

		updateAll()
	end)
})

TargetDropdown = MainTab:CreateDropdown({
	Name = "Targeted User",
	Options = {},
	CurrentOption = nil,
	MultipleOptions = false,
	Flag = "Target_Dropdown",
	Callback = safeCallback(function(Option)
		local selected =
			typeof(Option) == "table" and Option[1] or Option

		if not selected then return end

		TargetUser = nil

		TargetDropdown:Refresh({})
		updateAll()
	end)
})

------------------------------------------------
-- Colors
------------------------------------------------
ColorsTab:CreateSection("ESP Colors")

ColorsTab:CreateColorPicker({
	Name = "Whitelist Color",
	Color = whitelistColor,
	Flag = "Whitelist_Color",
	Callback = function(v)
		whitelistColor = v
	end
})

ColorsTab:CreateColorPicker({
	Name = "Target Color",
	Color = targetColor,
	Flag = "Target_Color",
	Callback = function(v)
		targetColor = v
	end
})

ColorsTab:CreateColorPicker({
	Name = "Chams Color",
	Color = chamsColor,
	Flag = "Chams_Color",
	Callback = function(v)
		chamsColor = v
	end
})

ColorsTab:CreateColorPicker({
	Name = "Outline Color",
	Color = outlineColor,
	Flag = "Outline_Color",
	Callback = function(v)
		outlineColor = v
	end
})

------------------------------------------------
-- ESP Config
------------------------------------------------
EspConfigTab:CreateSection("ESP Config")

EspConfigTab:CreateToggle({
	Name = "Show Player Name",
	CurrentValue = false,
	Flag = "Show_Name",
	Callback = function(v)
		showNameEnabled = v
	end
})

EspConfigTab:CreateToggle({
	Name = "Show Distance",
	CurrentValue = false,
	Flag = "Show_Distance",
	Callback = function(v)
		showDistanceEnabled = v
	end
})

EspConfigTab:CreateToggle({
	Name = "Show Health",
	CurrentValue = false,
	Flag = "Show_Health",
	Callback = function(v)
		showHealthEnabled = v
	end
})

EspConfigTab:CreateToggle({
	Name = "Enable Outline ESP",
	CurrentValue = true,
	Flag = "Outline_ESP",
	Callback = function(v)
		showOutlineEnabled = v
	end
})

EspConfigTab:CreateToggle({
	Name = "Enable Full Chams ESP",
	CurrentValue = false,
	Flag = "Chams_ESP",
	Callback = function(v)
		showChamsEnabled = v
	end
})

EspConfigTab:CreateSlider({
	Name = "Chams Opacity",
	Range = {0,1},
	Increment = 0.05,
	CurrentValue = chamsOpacity,
	Flag = "Chams_Opacity",
	Callback = function(v)
		chamsOpacity = v
	end
})

EspConfigTab:CreateSlider({
	Name = "ESP Max Distance",
	Range = {300,1400},
	Increment = 10,
	CurrentValue = maxDistance,
	Flag = "ESP_Distance",
	Callback = function(v)
		maxDistance = v
	end
})

------------------------------------------------
-- Players
------------------------------------------------
local function setupPlayer(player)
	if player == LocalPlayer then return end

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
-- Configuración
------------------------------------------------
Rayfield:LoadConfiguration()

------------------------------------------------
-- Keybinds
------------------------------------------------
local uiToggleKey = Enum.KeyCode.K
local espToggleKey = Enum.KeyCode.F3

local function toggleUI()
	local CoreGui = game:GetService("CoreGui")

	for _, gui in ipairs(CoreGui:GetChildren()) do
		if gui:IsA("ScreenGui") and string.find(string.lower(gui.Name), "rayfield") then
			gui.Enabled = not gui.Enabled
			return
		end
	end
end

local function toggleESP()
	espEnabled = not espEnabled
	updateAll()

	print(
		"ESP toggled via key:",
		espEnabled and "Enabled" or "Disabled"
	)
end

local function toggleChams()
	showChamsEnabled = not showChamsEnabled
	updateAll()

	print(
		"Chams toggled via key:",
		showChamsEnabled and "Enabled" or "Disabled"
	)
end

UserInputService.InputBegan:Connect(safeCallback(function(input, gp)
	if gp then return end

	if input.KeyCode == uiToggleKey then
		toggleUI()
		return
	end

	if input.KeyCode == espToggleKey then
		if isShiftDown() then
			toggleChams()
		else
			toggleESP()
		end
	end
end))
