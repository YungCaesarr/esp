------------------------------------------------
-- Variables y servicios
------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

------------------------------------------------
-- Configuración base
------------------------------------------------
local espEnabled = true

local whitelistColor = Color3.fromRGB(0, 255, 255)   -- Cyan para whitelist
local targetColor    = Color3.fromRGB(255, 255, 0)    -- Amarillo para target
local chamsColor     = Color3.fromRGB(255, 255, 255)  -- Color para jugadores normales
local outlineColor   = Color3.fromRGB(0, 0, 0)        -- Outline normal

local WhitelistUsers = {}
local TargetUser = nil

local showNameEnabled = false
local showDistanceEnabled = false
local showHealthEnabled = false

local showOutlineEnabled = true
local showChamsEnabled = false
local chamsOpacity = 0.5

local nameTextSize = 12

local labelNameColor = Color3.fromRGB(255, 255, 255)
local labelDistanceColor = Color3.fromRGB(255, 255, 255)

local maxDistance = 1400
local refreshRate = 50 -- ms, más sano que 5ms

------------------------------------------------
-- Funciones auxiliares
------------------------------------------------
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function getInitials(str)
	local initials = ""
	for word in string.gmatch(str or "", "%S+") do
		initials = initials .. word:sub(1, 1)
	end
	return initials:upper()
end

local function Color3ToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

local function safeCallback(callback)
	return function(...)
		local success, err = pcall(callback, ...)
		if not success then
			warn("Callback error: " .. tostring(err))
		end
	end
end

local function isShiftDown()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

local function getLocalHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPlayerCharacterParts(player)
	local character = player.Character
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local feetPart = character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("Torso")
		or hrp

	return character, head, feetPart, hrp
end

local function getDistanceToLocal(hrp)
	local localHRP = getLocalHRP()
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

local function findPlayerByInput(inputText)
	local cleaned = trim(inputText or "")
	if cleaned == "" then
		return nil
	end

	local inputLower = string.lower(cleaned)
	local inputLen = #cleaned

	for _, player in ipairs(Players:GetPlayers()) do
		local name = player.Name or ""
		local display = player.DisplayName or ""
		local displayInitials = getInitials(display)

		if string.lower(name) == inputLower
			or string.lower(display) == inputLower
			or string.lower(name:sub(1, inputLen)) == inputLower
			or string.lower(display:sub(1, inputLen)) == inputLower
			or string.lower(displayInitials) == inputLower
			or string.lower(displayInitials:sub(1, inputLen)) == inputLower
		then
			return player
		end
	end

	return nil
end

local function removeBillboardGui(part, guiName)
	if not part then return end
	local existing = part:FindFirstChild(guiName)
	if existing then
		existing:Destroy()
	end
end

local function removeHighlight(character)
	if not character then return end
	local existing = character:FindFirstChild("ESPHighlight")
	if existing then
		existing:Destroy()
	end
end

------------------------------------------------
-- Rayfield UI Library
------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local customTheme = {
	TextColor = Color3.fromRGB(230, 230, 250),
	Background = Color3.fromRGB(20, 20, 30),
	Topbar = Color3.fromRGB(30, 30, 40),
	Shadow = Color3.fromRGB(10, 10, 15),
	NotificationBackground = Color3.fromRGB(20, 20, 30),
	NotificationActionsBackground = Color3.fromRGB(220, 220, 240),
	TabBackground = Color3.fromRGB(25, 25, 35),
	TabStroke = Color3.fromRGB(45, 45, 55),
	TabBackgroundSelected = Color3.fromRGB(70, 70, 90),
	TabTextColor = Color3.fromRGB(230, 230, 250),
	SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
	ElementBackground = Color3.fromRGB(25, 25, 35),
	ElementBackgroundHover = Color3.fromRGB(30, 30, 45),
	SecondaryElementBackground = Color3.fromRGB(20, 20, 30),
	ElementStroke = Color3.fromRGB(50, 50, 60),
	SecondaryElementStroke = Color3.fromRGB(35, 35, 45),
	SliderBackground = Color3.fromRGB(45, 45, 65),
	SliderProgress = Color3.fromRGB(45, 45, 65),
	SliderStroke = Color3.fromRGB(55, 55, 75),
	ToggleBackground = Color3.fromRGB(20, 20, 30),
	ToggleEnabled = Color3.fromRGB(90, 70, 140),
	ToggleDisabled = Color3.fromRGB(70, 70, 70),
	ToggleEnabledStroke = Color3.fromRGB(100, 80, 150),
	ToggleDisabledStroke = Color3.fromRGB(80, 80, 80),
	ToggleEnabledOuterStroke = Color3.fromRGB(100, 80, 150),
	ToggleDisabledOuterStroke = Color3.fromRGB(80, 80, 80),
	DropdownSelected = Color3.fromRGB(25, 25, 35),
	DropdownUnselected = Color3.fromRGB(20, 20, 30),
	InputBackground = Color3.fromRGB(20, 20, 30),
	InputStroke = Color3.fromRGB(50, 50, 60),
	PlaceholderColor = Color3.fromRGB(150, 150, 170)
}

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
	KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ColorsTab = Window:CreateTab("ESP Colors", "palette")
local EspConfigTab = Window:CreateTab("ESP Config", "settings")

------------------------------------------------
-- Funciones de ESP
------------------------------------------------
local function updatePlayerHeadLabel(player)
	local character, head, _, hrp = getPlayerCharacterParts(player)
	if not character or not head then
		return
	end

	if not showNameEnabled then
		removeBillboardGui(head, "ESP_HeadGui")
		return
	end

	local distance = getDistanceToLocal(hrp)
	if distance > maxDistance or not espEnabled then
		removeBillboardGui(head, "ESP_HeadGui")
		return
	end

	local bg = head:FindFirstChild("ESP_HeadGui")
	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = "ESP_HeadGui"
		bg.Adornee = head
		bg.Size = UDim2.new(0, 150, 0, 25)
		bg.StudsOffset = Vector3.new(0, 2, 0)
		bg.AlwaysOnTop = true
		bg.Parent = head

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.BackgroundTransparency = 1
		nameLabel.RichText = true
		nameLabel.TextScaled = false
		nameLabel.TextSize = nameTextSize
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.TextStrokeTransparency = 0
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.Parent = bg
	end

	local nameLabel = bg:FindFirstChild("NameLabel")
	if not nameLabel then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hpText = ""

	if showHealthEnabled and humanoid then
		local currentHealth = math.floor(humanoid.Health)
		local maxHealth = math.floor(humanoid.MaxHealth)
		hpText = string.format(" [%d / %d]", currentHealth, maxHealth)
	end

	nameLabel.Text = string.format(
		'<font color="%s">%s%s</font>',
		Color3ToHex(labelNameColor),
		player.Name,
		hpText
	)
	nameLabel.TextSize = nameTextSize
	nameLabel.Visible = true
end

local function updatePlayerFeetLabel(player)
	local character, _, feetPart, hrp = getPlayerCharacterParts(player)
	if not character or not feetPart then
		return
	end

	if not showDistanceEnabled then
		removeBillboardGui(feetPart, "ESP_FeetGui")
		return
	end

	local distance = getDistanceToLocal(hrp)
	if distance > maxDistance or not espEnabled then
		removeBillboardGui(feetPart, "ESP_FeetGui")
		return
	end

	local bg = feetPart:FindFirstChild("ESP_FeetGui")
	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = "ESP_FeetGui"
		bg.Adornee = feetPart
		bg.StudsOffset = Vector3.new(0, -3, 0)
		bg.Size = UDim2.new(0, 150, 0, 25)
		bg.AlwaysOnTop = true
		bg.Parent = feetPart

		local distLabel = Instance.new("TextLabel")
		distLabel.Name = "DistanceLabel"
		distLabel.BackgroundTransparency = 1
		distLabel.RichText = true
		distLabel.TextScaled = false
		distLabel.TextSize = nameTextSize
		distLabel.Font = Enum.Font.SourceSans
		distLabel.TextStrokeTransparency = 0
		distLabel.Size = UDim2.new(1, 0, 1, 0)
		distLabel.Parent = bg
	end

	local distLabel = bg:FindFirstChild("DistanceLabel")
	if not distLabel then
		return
	end

	distLabel.Text = string.format(
		'<font color="%s">%.1f studs</font>',
		Color3ToHex(labelDistanceColor),
		distance
	)
	distLabel.TextSize = nameTextSize
	distLabel.Visible = true
end

local function addOrUpdateChams(player, character)
	if not character then
		return
	end

	local highlight = character:FindFirstChild("ESPHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.Parent = character
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local distance = getDistanceToLocal(hrp)

	if not espEnabled or distance > maxDistance then
		highlight.Enabled = false
		return
	end

	local outline, fill = getESPColors(player)

	highlight.Enabled = true
	highlight.OutlineColor = outline
	highlight.FillColor = fill
	highlight.FillTransparency = showChamsEnabled and chamsOpacity or 1
	highlight.OutlineTransparency = showOutlineEnabled and 0 or 1
end

local function updateAllHighlights()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			addOrUpdateChams(player, player.Character)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end
	end
end

local function cleanupPlayerESP(player)
	local character = player.Character
	if not character then
		return
	end

	removeHighlight(character)

	local head = character:FindFirstChild("Head")
	if head then
		removeBillboardGui(head, "ESP_HeadGui")
	end

	local feetPart = character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")

	if feetPart then
		removeBillboardGui(feetPart, "ESP_FeetGui")
	end
end

------------------------------------------------
-- Loop principal de actualización
------------------------------------------------
task.spawn(function()
	while task.wait(math.max(refreshRate / 1000, 0.05)) do
		updateAllHighlights()
	end
end)

------------------------------------------------
-- UI: Main
------------------------------------------------
MainTab:CreateSection("ESP Options")

MainTab:CreateToggle({
	Name = "Activate ESP",
	CurrentValue = espEnabled,
	Flag = "ESP_Toggle",
	Callback = safeCallback(function(Value)
		espEnabled = Value
		updateAllHighlights()
		print("ESP is now:", espEnabled and "Enabled" or "Disabled")
	end),
})

MainTab:CreateSection("Whitelist Options")

local WhitelistDropdown
MainTab:CreateInput({
	Name = "Whitelist User",
	PlaceholderText = "Enter username, display name or initials",
	RemoveTextAfterFocusLost = false,
	Flag = "Whitelist_Input",
	Callback = safeCallback(function(Text)
		local foundPlayer = findPlayerByInput(Text)
		if foundPlayer then
			if not table.find(WhitelistUsers, foundPlayer.Name) then
				table.insert(WhitelistUsers, foundPlayer.Name)
				print("Whitelisting user:", foundPlayer.Name)
				if foundPlayer.Character then
					addOrUpdateChams(foundPlayer, foundPlayer.Character)
				end
			else
				print("User already whitelisted:", foundPlayer.Name)
			end
		else
			print("User not found:", tostring(Text))
		end

		if WhitelistDropdown then
			WhitelistDropdown:Refresh(WhitelistUsers)
			WhitelistDropdown:Set({})
		end

		updateAllHighlights()
	end),
})

WhitelistDropdown = MainTab:CreateDropdown({
	Name = "Whitelisted Users (Click to remove)",
	Options = WhitelistUsers,
	CurrentOption = {},
	MultipleOptions = false,
	Flag = "Whitelist_Dropdown",
	Callback = safeCallback(function(Options)
		local selected = Options[1]
		if not selected then
			return
		end

		for i, v in ipairs(WhitelistUsers) do
			if v == selected then
				table.remove(WhitelistUsers, i)
				print("Removed whitelisted user:", selected)
				break
			end
		end

		if WhitelistDropdown then
			WhitelistDropdown:Refresh(WhitelistUsers)
			WhitelistDropdown:Set({})
		end

		updateAllHighlights()
	end),
})

MainTab:CreateSection("Target Options")

local TargetDropdown
MainTab:CreateInput({
	Name = "Target User",
	PlaceholderText = "Enter username, display name or initials",
	RemoveTextAfterFocusLost = false,
	Flag = "Target_Input",
	Callback = safeCallback(function(Text)
		local foundPlayer = findPlayerByInput(Text)
		if foundPlayer then
			TargetUser = foundPlayer.Name
			print("Target set to:", TargetUser)
			if foundPlayer.Character then
				addOrUpdateChams(foundPlayer, foundPlayer.Character)
			end
		else
			TargetUser = nil
			print("Target user not found:", tostring(Text))
		end

		local targetOption = {}
		if TargetUser then
			table.insert(targetOption, TargetUser)
		end

		if TargetDropdown then
			TargetDropdown:Refresh(targetOption)
			TargetDropdown:Set({})
		end

		updateAllHighlights()
	end),
})

TargetDropdown = MainTab:CreateDropdown({
	Name = "Targeted User (Click to remove)",
	Options = TargetUser and { TargetUser } or {},
	CurrentOption = {},
	MultipleOptions = false,
	Flag = "Target_Dropdown",
	Callback = safeCallback(function(Options)
		local selected = Options[1]
		if not selected then
			return
		end

		print("Removed target user:", selected)
		TargetUser = nil

		if TargetDropdown then
			TargetDropdown:Refresh({})
			TargetDropdown:Set({})
		end

		updateAllHighlights()
	end),
})

------------------------------------------------
-- UI: Colors
------------------------------------------------
ColorsTab:CreateSection("Adjust ESP Colors")

ColorsTab:CreateColorPicker({
	Name = "Whitelist Color",
	Color = whitelistColor,
	Flag = "Color_Whitelist",
	Callback = safeCallback(function(Value)
		whitelistColor = Value
		updateAllHighlights()
	end),
})

ColorsTab:CreateColorPicker({
	Name = "Target Color",
	Color = targetColor,
	Flag = "Color_Target",
	Callback = safeCallback(function(Value)
		targetColor = Value
		updateAllHighlights()
	end),
})

ColorsTab:CreateColorPicker({
	Name = "Chams Color",
	Color = chamsColor,
	Flag = "Color_Chams",
	Callback = safeCallback(function(Value)
		chamsColor = Value
		updateAllHighlights()
	end),
})

ColorsTab:CreateColorPicker({
	Name = "Outline Color",
	Color = outlineColor,
	Flag = "Color_Outline",
	Callback = safeCallback(function(Value)
		outlineColor = Value
		updateAllHighlights()
	end),
})

ColorsTab:CreateSection("Label Colors")

ColorsTab:CreateColorPicker({
	Name = "Name Color",
	Color = labelNameColor,
	Flag = "Label_NameColor",
	Callback = safeCallback(function(Value)
		labelNameColor = Value
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerHeadLabel(player)
			end
		end
	end),
})

ColorsTab:CreateColorPicker({
	Name = "Distance Color",
	Color = labelDistanceColor,
	Flag = "Label_DistanceColor",
	Callback = safeCallback(function(Value)
		labelDistanceColor = Value
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerFeetLabel(player)
			end
		end
	end),
})

------------------------------------------------
-- UI: ESP Config
------------------------------------------------
EspConfigTab:CreateSection("ESP Config")

EspConfigTab:CreateToggle({
	Name = "Show Player Name",
	CurrentValue = showNameEnabled,
	Flag = "ESP_ShowName",
	Callback = safeCallback(function(Value)
		showNameEnabled = Value
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerHeadLabel(player)
			end
		end
	end),
})

EspConfigTab:CreateToggle({
	Name = "Show Distance",
	CurrentValue = showDistanceEnabled,
	Flag = "ESP_ShowDistance",
	Callback = safeCallback(function(Value)
		showDistanceEnabled = Value
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerFeetLabel(player)
			end
		end
	end),
})

EspConfigTab:CreateToggle({
	Name = "Show Health",
	CurrentValue = showHealthEnabled,
	Flag = "ESP_ShowHealth",
	Callback = safeCallback(function(Value)
		showHealthEnabled = Value
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerHeadLabel(player)
			end
		end
	end),
})

EspConfigTab:CreateSlider({
	Name = "Name Text Size",
	Range = {8, 24},
	Increment = 1,
	Suffix = "px",
	CurrentValue = nameTextSize,
	Flag = "ESP_NameTextSize",
	Callback = safeCallback(function(Value)
		nameTextSize = Value
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerHeadLabel(player)
				updatePlayerFeetLabel(player)
			end
		end
	end),
})

EspConfigTab:CreateToggle({
	Name = "Enable Outline ESP",
	CurrentValue = showOutlineEnabled,
	Flag = "ESP_EnableOutline",
	Callback = safeCallback(function(Value)
		showOutlineEnabled = Value
		updateAllHighlights()
	end),
})

EspConfigTab:CreateToggle({
	Name = "Enable Full Chams ESP",
	CurrentValue = showChamsEnabled,
	Flag = "ESP_EnableChams",
	Callback = safeCallback(function(Value)
		showChamsEnabled = Value
		updateAllHighlights()
	end),
})

EspConfigTab:CreateSlider({
	Name = "Chams Opacity",
	Range = {0, 1},
	Increment = 0.05,
	Suffix = "",
	CurrentValue = chamsOpacity,
	Flag = "ESP_ChamsOpacity",
	Callback = safeCallback(function(Value)
		chamsOpacity = Value
		updateAllHighlights()
	end),
})

EspConfigTab:CreateSlider({
	Name = "ESP Max Distance",
	Range = {300, 1400},
	Increment = 10,
	Suffix = " studs",
	CurrentValue = maxDistance,
	Flag = "ESP_MaxDistance",
	Callback = safeCallback(function(Value)
		maxDistance = Value
		updateAllHighlights()
	end),
})

------------------------------------------------
-- Aplicar ESP a jugadores existentes y nuevos
------------------------------------------------
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		if player.Character then
			addOrUpdateChams(player, player.Character)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end

		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 5)
			char:WaitForChild("HumanoidRootPart", 5)
			addOrUpdateChams(player, char)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 5)
			char:WaitForChild("HumanoidRootPart", 5)
			addOrUpdateChams(player, char)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cleanupPlayerESP(player)
end)

------------------------------------------------
-- Cargar configuración
------------------------------------------------
Rayfield:LoadConfiguration()

------------------------------------------------
-- Teclas de atajo
------------------------------------------------
local uiToggleKey = Enum.KeyCode.K
local espToggleKey = Enum.KeyCode.F3

local function toggleESP()
	espEnabled = not espEnabled
	updateAllHighlights()
	print("ESP toggled via key:", espEnabled and "Enabled" or "Disabled")
end

local function toggleFullChams()
	showChamsEnabled = not showChamsEnabled
	updateAllHighlights()
	print("Full Chams toggled via key:", showChamsEnabled and "Enabled" or "Disabled")
end

UserInputService.InputBegan:Connect(safeCallback(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == uiToggleKey then
		Window:ToggleVisibility()
		return
	end

	if input.KeyCode == espToggleKey then
		if isShiftDown() then
			toggleFullChams() -- Shift + F3
		else
			toggleESP() -- F3
		end
	end
end))
