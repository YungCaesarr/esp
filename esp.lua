------------------------------------------------
-- Variables y servicios
------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local espEnabled = true
-- Colores para el Highlight (para whitelist y target se mantienen, los demás se configuran por separado)
local whitelistColor = Color3.fromRGB(0, 255, 255)   -- Cyan para whitelist
local targetColor    = Color3.fromRGB(255, 255, 0)     -- Amarillo para target
-- Se eliminó defaultColor, en su lugar se usan chamsColor y outlineColor
local chamsColor     = Color3.fromRGB(255, 255, 255)   -- Color para el fill de jugadores normales
local outlineColor   = Color3.fromRGB(0, 0, 0)         -- Color para el outline de jugadores normales

-- Listas para whitelist y target
local WhitelistUsers = {}    -- array de nombres (string)
local TargetUser = nil       -- string, nombre del jugador target

-- Variables para ESP Config
local showNameEnabled = false          -- Muestra el nombre+vida en la cabeza
local showDistanceEnabled = false      -- Muestra los studs en los pies
local showHealthEnabled = false        -- Toggle para la vida

-- NUEVAS VARIABLES para elegir el tipo de ESP
local showOutlineEnabled = true        -- Si true, se muestra el outline (Highlight outline)
local showChamsEnabled = false         -- Si true, se colorea todo el cuerpo (chams) en vez de solo outline

-- NUEVA VARIABLE para ajustar la opacidad de los Chams
local chamsOpacity = 0.5  -- Valor entre 0 (completamente opaco) y 1 (completamente transparente)

-- Variables para ajustar el tamaño del texto (size)
local nameTextSize = 12

-- NUEVAS VARIABLES: Color para el label (usado tanto en nombre como en studs)
local labelNameColor = Color3.fromRGB(255, 255, 255)
local labelDistanceColor = Color3.fromRGB(255, 255, 255)
-- Se elimina labelHealthColor, ya que no se usa un color diferente

-- Parámetros de actualización
local maxDistance = 1400   -- Valor por defecto dentro del rango (300 - 1400)
local refreshRate = 5      -- en ms

------------------------------------------------
-- Funciones Auxiliares
------------------------------------------------
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function getInitials(str)
	local initials = ""
	for word in string.gmatch(str, "%S+") do
		initials = initials .. word:sub(1,1)
	end
	return initials:upper()
end

-- Convierte un Color3 a un string hexadecimal (para RichText)
local function Color3ToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
end

-- Función para envolver callbacks y capturar errores
local function safeCallback(callback)
	return function(...)
		local success, err = pcall(callback, ...)
		if not success then
			warn("Callback error: " .. err)
		end
	end
end

------------------------------------------------
-- Cargar Rayfield UI Library
------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

------------------------------------------------
-- Crear Ventana y Tabs (UI personalizada)
------------------------------------------------
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

-- Crear pestañas:
local MainTab = Window:CreateTab("Main", 4483362458)
local ColorsTab = Window:CreateTab("ESP Colors", "palette")
local EspConfigTab = Window:CreateTab("ESP Config", "settings")

------------------------------------------------
-- Definición de funciones de ESP
------------------------------------------------

-- Actualizar el BillboardGui en la cabeza (nombre y vida)
function updatePlayerHeadLabel(player)
	if not player.Character then return end
	local head = player.Character:FindFirstChild("Head")
	if not head then return end

	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if localHRP and hrp then
		local distance = (hrp.Position - localHRP.Position).Magnitude
		if distance > maxDistance then
			local existing = head:FindFirstChild("ESP_HeadGui")
			if existing then existing:Destroy() end
			return
		end
	end

	if not espEnabled then
		local existing = head:FindFirstChild("ESP_HeadGui")
		if existing then existing:Destroy() end
		return
	end

	local bg = head:FindFirstChild("ESP_HeadGui")
	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = "ESP_HeadGui"
		bg.Adornee = head
		bg.Size = UDim2.new(0, 150, 0, 25)
		-- Se coloca sobre la cabeza
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
	if nameLabel then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
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
		nameLabel.Visible = showNameEnabled
	end
end

-- Actualizar el BillboardGui en los pies (studs)
function updatePlayerFeetLabel(player)
	if not player.Character then return end
	-- Buscamos la parte para los pies: LowerTorso o Torso; si no existe, usamos HumanoidRootPart.
	local feetPart = player.Character:FindFirstChild("LowerTorso") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("HumanoidRootPart")
	if not feetPart then return end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if localHRP and hrp then
		local distance = (hrp.Position - localHRP.Position).Magnitude
		if distance > maxDistance then
			local existing = feetPart:FindFirstChild("ESP_FeetGui")
			if existing then existing:Destroy() end
			return
		end
	end

	if not espEnabled then
		local existing = feetPart:FindFirstChild("ESP_FeetGui")
		if existing then existing:Destroy() end
		return
	end

	local bg = feetPart:FindFirstChild("ESP_FeetGui")
	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = "ESP_FeetGui"
		bg.Adornee = feetPart
		-- Se mantiene debajo de la parte de los pies con StudsOffset negativo
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
	if distLabel and localHRP and hrp then
		local distance = (hrp.Position - localHRP.Position).Magnitude
		distLabel.Text = string.format(
			'<font color="%s">%.1f studs</font>',
			Color3ToHex(labelDistanceColor),
			distance
		)
		distLabel.TextSize = nameTextSize
		distLabel.Visible = showDistanceEnabled
	end
end

-- Función para agregar/actualizar el Highlight (Chams/Outline)
local function addChams(player, character)
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
	
	-- Comprobamos la distancia respecto al jugador local
	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if localHRP and hrp then
		local distance = (hrp.Position - localHRP.Position).Magnitude
		if distance > maxDistance then
			highlight.Enabled = false
			return
		end
	end
	
	highlight.Enabled = true
	
	-- Si el jugador está en whitelist o es target se usan esos colores, de lo contrario se usan los configurables
	if table.find(WhitelistUsers, player.Name) then
		highlight.OutlineColor = whitelistColor
		highlight.FillColor = whitelistColor
	elseif TargetUser and player.Name == TargetUser then
		highlight.OutlineColor = targetColor
		highlight.FillColor = targetColor
	else
		highlight.OutlineColor = outlineColor
		highlight.FillColor = chamsColor
	end
	
	if showChamsEnabled then
		highlight.FillTransparency = chamsOpacity
	else
		highlight.FillTransparency = 1
	end
	
	if showOutlineEnabled then
		highlight.OutlineTransparency = 0
	else
		highlight.OutlineTransparency = 1
	end
end

-- Función para actualizar los Highlights y las etiquetas (head y feet)
local function updateAllHighlights()
	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local highlight = player.Character:FindFirstChild("ESPHighlight")
				if not highlight then
					addChams(player, player.Character)
					highlight = player.Character:FindFirstChild("ESPHighlight")
				end
				
				if localHRP then
					local distance = (hrp.Position - localHRP.Position).Magnitude
					if distance > maxDistance or not espEnabled then
						highlight.Enabled = false
					else
						highlight.Enabled = true
						if table.find(WhitelistUsers, player.Name) then
							highlight.OutlineColor = whitelistColor
							highlight.FillColor = whitelistColor
						elseif TargetUser and player.Name == TargetUser then
							highlight.OutlineColor = targetColor
							highlight.FillColor = targetColor
						else
							highlight.OutlineColor = outlineColor
							highlight.FillColor = chamsColor
						end
						
						if showChamsEnabled then
							highlight.FillTransparency = chamsOpacity
						else
							highlight.FillTransparency = 1
						end
						
						if showOutlineEnabled then
							highlight.OutlineTransparency = 0
						else
							highlight.OutlineTransparency = 1
						end
					end
				else
					highlight.Enabled = espEnabled
				end
			end
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end
	end
end

------------------------------------------------
-- Bucle para actualizar continuamente los highlights
------------------------------------------------
spawn(function()
	while wait(refreshRate/1000) do
		updateAllHighlights()
	end
end)

------------------------------------------------
-- Bucle para actualizar la información de los labels continuamente
------------------------------------------------
RunService.Heartbeat:Connect(function()
	if showNameEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				updatePlayerHeadLabel(player)
			end
		end
	end
	if showDistanceEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				updatePlayerFeetLabel(player)
			end
		end
	end
end)

------------------------------------------------
-- Crear UI en la pestaña Main
------------------------------------------------
local ESPSection = MainTab:CreateSection("ESP Options")
local ToggleESP = MainTab:CreateToggle({
   Name = "Activate ESP",
   CurrentValue = espEnabled,
   Flag = "ESP_Toggle",
   Callback = safeCallback(function(Value)
      espEnabled = Value
      print("ESP is now:", espEnabled and "Enabled" or "Disabled")
      updateAllHighlights()
   end),
})

------------------------------------------------
-- Sección: Whitelist Options
------------------------------------------------
local WhitelistSection = MainTab:CreateSection("Whitelist Options")
local WhitelistDropdown
local WhitelistInput = MainTab:CreateInput({
   Name = "Whitelist User",
   PlaceholderText = "Enter username, display name or initials",
   RemoveTextAfterFocusLost = false,
   Flag = "Whitelist_Input",
   Callback = safeCallback(function(Text)
      local inputText = trim(Text)
      if inputText ~= "" then
         local foundPlayer = nil
         local inputLen = #inputText
         for _, player in ipairs(Players:GetPlayers()) do
            local name = player.Name
            local display = player.DisplayName or ""
            local displayInitials = getInitials(display)
            if string.lower(name) == string.lower(inputText)
               or string.lower(display) == string.lower(inputText)
               or string.lower(name:sub(1, inputLen)) == string.lower(inputText)
               or string.lower(display:sub(1, inputLen)) == string.lower(inputText)
               or string.lower(displayInitials) == string.lower(inputText)
               or string.lower(displayInitials:sub(1, inputLen)) == string.lower(inputText)
            then
               foundPlayer = player
               break
            end
         end
         
         if foundPlayer then
            if not table.find(WhitelistUsers, foundPlayer.Name) then
               table.insert(WhitelistUsers, foundPlayer.Name)
               print("Whitelisting user:", foundPlayer.Name)
               if foundPlayer.Character then
                  addChams(foundPlayer, foundPlayer.Character)
               end
            else
               print("User already whitelisted:", foundPlayer.Name)
            end
         else
            print("User not found:", inputText)
         end
         WhitelistDropdown:Refresh(WhitelistUsers)
         WhitelistDropdown:Set({})
         updateAllHighlights()
      end
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
      if selected then
         for i, v in ipairs(WhitelistUsers) do
            if v == selected then
               table.remove(WhitelistUsers, i)
               print("Removed whitelisted user:", selected)
               for _, player in ipairs(Players:GetPlayers()) do
                  if player.Name == selected and player.Character then
                     addChams(player, player.Character)
                  end
               end
               break
            end
         end
         WhitelistDropdown:Refresh(WhitelistUsers)
         WhitelistDropdown:Set({})
         updateAllHighlights()
      end
   end),
})

------------------------------------------------
-- Sección: Target Options
------------------------------------------------
local TargetInput = MainTab:CreateInput({
   Name = "Target User",
   PlaceholderText = "Enter username, display name or initials",
   RemoveTextAfterFocusLost = false,
   Flag = "Target_Input",
   Callback = safeCallback(function(Text)
      local inputText = trim(Text)
      if inputText ~= "" then
         local foundPlayer = nil
         local inputLen = #inputText
         for _, player in ipairs(Players:GetPlayers()) do
            local name = player.Name
            local display = player.DisplayName or ""
            local displayInitials = getInitials(display)
            if string.lower(name) == string.lower(inputText)
               or string.lower(display) == string.lower(inputText)
               or string.lower(name:sub(1, inputLen)) == string.lower(inputText)
               or string.lower(display:sub(1, inputLen)) == string.lower(inputText)
               or string.lower(displayInitials) == string.lower(inputText)
               or string.lower(displayInitials:sub(1, inputLen)) == string.lower(inputText)
            then
               foundPlayer = player
               break
            end
         end
         
         if foundPlayer then
            TargetUser = foundPlayer.Name
            print("Target set to:", TargetUser)
            if foundPlayer.Character then
               addChams(foundPlayer, foundPlayer.Character)
            end
         else
            print("Target user not found:", inputText)
            TargetUser = nil
         end
         local targetOption = {}
         if TargetUser then table.insert(targetOption, TargetUser) end
         TargetDropdown:Refresh(targetOption)
         TargetDropdown:Set({})
         updateAllHighlights()
      end
   end),
})

TargetDropdown = MainTab:CreateDropdown({
   Name = "Targeted User (Click to remove)",
   Options = TargetUser and {TargetUser} or {},
   CurrentOption = {},
   MultipleOptions = false,
   Flag = "Target_Dropdown",
   Callback = safeCallback(function(Options)
      local selected = Options[1]
      if selected then
         print("Removed target user:", selected)
         TargetUser = nil
         for _, player in ipairs(Players:GetPlayers()) do
            if player.Name == selected and player.Character then
               addChams(player, player.Character)
            end
         end
         TargetDropdown:Refresh({})
         TargetDropdown:Set({})
         updateAllHighlights()
      end
   end),
})

------------------------------------------------
-- Sección: ESP Colors
------------------------------------------------
local ColorSection = ColorsTab:CreateSection("Adjust ESP Colors")
local ColorPickerWhitelist = ColorsTab:CreateColorPicker({
    Name = "Whitelist Color",
    Color = whitelistColor,
    Flag = "Color_Whitelist",
    Callback = safeCallback(function(Value)
        whitelistColor = Value
        print("Whitelist color set to:", whitelistColor)
        updateAllHighlights()
    end),
})

local ColorPickerTarget = ColorsTab:CreateColorPicker({
    Name = "Target Color",
    Color = targetColor,
    Flag = "Color_Target",
    Callback = safeCallback(function(Value)
        targetColor = Value
        print("Target color set to:", targetColor)
        updateAllHighlights()
    end),
})

local ColorPickerChams = ColorsTab:CreateColorPicker({
   Name = "Chams Color",
   Color = chamsColor,
   Flag = "Color_Chams",
   Callback = safeCallback(function(Value)
      chamsColor = Value
      print("Chams color set to:", chamsColor)
      updateAllHighlights()
   end),
})

local ColorPickerOutline = ColorsTab:CreateColorPicker({
   Name = "Outline Color",
   Color = outlineColor,
   Flag = "Color_Outline",
   Callback = safeCallback(function(Value)
      outlineColor = Value
      print("Outline color set to:", outlineColor)
      updateAllHighlights()
   end),
})

-- Sección para elegir los colores manuales del label
local LabelColorsSection = ColorsTab:CreateSection("Label Colors")
local nameColorPicker = ColorsTab:CreateColorPicker({
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
local distanceColorPicker = ColorsTab:CreateColorPicker({
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
-- Se elimina el picker de Health Color

------------------------------------------------
-- Sección: ESP Config
------------------------------------------------
local ConfigSection = EspConfigTab:CreateSection("ESP Config")
local nameToggle = EspConfigTab:CreateToggle({
   Name = "Show Player Name",
   CurrentValue = false,
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
local distanceToggle = EspConfigTab:CreateToggle({
   Name = "Show Distance",
   CurrentValue = false,
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
local healthToggle = EspConfigTab:CreateToggle({
   Name = "Show Health",
   CurrentValue = false,
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
local nameSizeSlider = EspConfigTab:CreateSlider({
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
-- NUEVAS OPCIONES: toggles para Outline y Chams
local outlineToggle = EspConfigTab:CreateToggle({
   Name = "Enable Outline ESP",
   CurrentValue = true,
   Flag = "ESP_EnableOutline",
   Callback = safeCallback(function(Value)
      showOutlineEnabled = Value
      updateAllHighlights()
   end),
})
local chamsToggle = EspConfigTab:CreateToggle({
   Name = "Enable Full Chams ESP",
   CurrentValue = false,
   Flag = "ESP_EnableChams",
   Callback = safeCallback(function(Value)
      showChamsEnabled = Value
      updateAllHighlights()
   end),
})
-- NUEVA OPCIÓN: Slider para ajustar la opacidad de los Chams
local chamsOpacitySlider = EspConfigTab:CreateSlider({
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
-- NUEVA OPCIÓN: Slider para ajustar la distancia máxima (studs)
local maxDistanceSlider = EspConfigTab:CreateSlider({
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
			addChams(player, player.Character)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 5)
			addChams(player, char)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 5)
			addChams(player, char)
			updatePlayerHeadLabel(player)
			updatePlayerFeetLabel(player)
		end)
	end
end)

------------------------------------------------
-- Cargar la Configuración (Guardado automático)
------------------------------------------------
Rayfield:LoadConfiguration()

------------------------------------------------
-- Teclas de atajo para toggle UI y ESP
------------------------------------------------
local uiToggleKey = Enum.KeyCode.K
local espToggleKey = Enum.KeyCode.F3

UserInputService.InputBegan:Connect(safeCallback(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == uiToggleKey then
		Window:ToggleVisibility()
	end
	if input.KeyCode == espToggleKey then
		espEnabled = not espEnabled
		updateAllHighlights()
		print("ESP toggled via key:", espEnabled and "Enabled" or "Disabled")
	end
end))
