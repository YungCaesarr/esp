------------------------------------------------
-- Variables y servicios
------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local espEnabled = true
-- Colores para el Highlight (estos también se usan para chams)
local whitelistColor = Color3.fromRGB(0, 255, 255)   -- Cyan para whitelist
local targetColor    = Color3.fromRGB(255, 255, 0)     -- Amarillo para target
local defaultColor   = Color3.fromRGB(255, 255, 255)   -- Blanco para los demás

-- Listas para whitelist y target
local WhitelistUsers = {}    -- array de nombres (string)
local TargetUser = nil       -- string, nombre del jugador target

-- Variables para ESP Config
local showNameEnabled = false
local showDistanceEnabled = false
local showHealthEnabled = false   -- Toggle para la salud

-- NUEVAS VARIABLES para elegir el tipo de ESP
local showOutlineEnabled = true   -- Si true, se muestra el outline (Highlight outline)
local showChamsEnabled = false    -- Si true, se colorea todo el cuerpo (chams) en vez de solo outline

-- NUEVA VARIABLE para ajustar la opacidad de los Chams
local chamsOpacity = 0.5  -- Valor entre 0 (completamente opaco) y 1 (completamente transparente)

-- Variables para ajustar el tamaño del texto (size)
local nameTextSize = 12

-- NUEVAS VARIABLES: Colores manuales para el label (ubicados en ESP Colors)
local labelNameColor = Color3.fromRGB(255, 255, 255)
local labelDistanceColor = Color3.fromRGB(255, 255, 255)
local labelHealthColor = Color3.fromRGB(255, 255, 255)

-- Parámetros de actualización
local maxDistance = 2500
local refreshRate = 5   -- en ms

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
local function addChams(player, character)
	local highlight = character:FindFirstChild("ESPHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.Parent = character
	end
	
	-- Si el ESP está desactivado, se deshabilita el highlight y se retorna
	if not espEnabled then
		highlight.Enabled = false
		return
	end
	
	highlight.Enabled = true
	
	-- Actualizar colores (outline y fill) según whitelist/target/default
	if table.find(WhitelistUsers, player.Name) then
		highlight.OutlineColor = whitelistColor
		highlight.FillColor = whitelistColor
	elseif TargetUser and player.Name == TargetUser then
		highlight.OutlineColor = targetColor
		highlight.FillColor = targetColor
	else
		highlight.OutlineColor = defaultColor
		highlight.FillColor = defaultColor
	end
	
	-- Aplicar modo Chams o solo Outline
	if showChamsEnabled then
		highlight.FillTransparency = chamsOpacity
	else
		highlight.FillTransparency = 1
	end
	
	-- Ajustamos la visibilidad del outline según showOutlineEnabled
	if showOutlineEnabled then
		highlight.OutlineTransparency = 0
	else
		highlight.OutlineTransparency = 1
	end
end

local function updateAllHighlights()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local highlight = player.Character:FindFirstChild("ESPHighlight")
			if not highlight then
				addChams(player, player.Character)
				highlight = player.Character:FindFirstChild("ESPHighlight")
			end
			
			if not espEnabled then
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
					highlight.OutlineColor = defaultColor
					highlight.FillColor = defaultColor
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
			updatePlayerLabels(player)
		end
	end
end

-- Función para crear/actualizar el BillboardGui en el HumanoidRootPart (para labels)
function updatePlayerLabels(player)
	if not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Si el ESP está desactivado, se elimina el label y se retorna
	if not espEnabled then
		local existing = hrp:FindFirstChild("ESP_NameGui")
		if existing then existing:Destroy() end
		return
	end
	
	if showNameEnabled then
		if not hrp:FindFirstChild("ESP_NameGui") then
			local bg = Instance.new("BillboardGui")
			bg.Name = "ESP_NameGui"
			bg.Adornee = hrp
			bg.Size = UDim2.new(0, 150, 0, 25)
			bg.StudsOffset = Vector3.new(0, 2.5, 0)
			bg.AlwaysOnTop = true
			
			local label = Instance.new("TextLabel", bg)
			label.BackgroundTransparency = 1
			label.RichText = true
			label.TextScaled = false
			label.TextSize = nameTextSize
			label.Font = Enum.Font.SourceSans
			label.TextStrokeTransparency = 0
			label.Size = UDim2.new(1, 0, 1, 0)
			bg.Parent = hrp
		end
		
		local label = hrp.ESP_NameGui:FindFirstChildOfClass("TextLabel")
		if label then
			local distanceText = "N/A"
			if showDistanceEnabled then
				local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if localHRP then
					local dist = (hrp.Position - localHRP.Position).Magnitude
					if dist > maxDistance then dist = maxDistance end
					distanceText = string.format("%.1f", dist)
				end
			end
			local healthText = ""
			if showHealthEnabled then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local currentHealth = math.floor(humanoid.Health)
					local maxHealth = math.floor(humanoid.MaxHealth)
					healthText = "HP: " .. currentHealth .. "/" .. maxHealth
				else
					healthText = "HP: N/A"
				end
			end
			
			if showDistanceEnabled and showHealthEnabled then
				label.Text = string.format(
					'<font color="%s">%s</font> | <font color="%s">%s</font> | <font color="%s">%s</font>',
					Color3ToHex(labelNameColor), player.Name,
					Color3ToHex(labelDistanceColor), distanceText,
					Color3ToHex(labelHealthColor), healthText
				)
			elseif showDistanceEnabled then
				label.Text = string.format(
					'<font color="%s">%s</font> | <font color="%s">%s</font>',
					Color3ToHex(labelNameColor), player.Name,
					Color3ToHex(labelDistanceColor), distanceText
				)
			elseif showHealthEnabled then
				label.Text = string.format(
					'<font color="%s">%s</font> | <font color="%s">%s</font>',
					Color3ToHex(labelNameColor), player.Name,
					Color3ToHex(labelHealthColor), healthText
				)
			else
				label.Text = string.format('<font color="%s">%s</font>', Color3ToHex(labelNameColor), player.Name)
			end
			
			label.TextSize = nameTextSize
			label.TextStrokeTransparency = 0
		end
	else
		local existing = hrp:FindFirstChild("ESP_NameGui")
		if existing then existing:Destroy() end
	end
end

------------------------------------------------
-- Bucle para actualizar la información del label continuamente
------------------------------------------------
RunService.Heartbeat:Connect(function()
	if (showDistanceEnabled or showHealthEnabled) and showNameEnabled then
		local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if localHRP then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character then
					updatePlayerLabels(player)
				end
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
               -- Actualizamos el ESP del jugador de inmediato
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
               -- Forzamos la actualización del jugador removido
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
         -- Forzamos la actualización del jugador removido
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

local ColorPickerDefault = ColorsTab:CreateColorPicker({
    Name = "Default Color",
    Color = defaultColor,
    Flag = "Color_Default",
    Callback = safeCallback(function(Value)
        defaultColor = Value
        print("Default color set to:", defaultColor)
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
            updatePlayerLabels(player)
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
            updatePlayerLabels(player)
         end
      end
   end),
})
local healthColorPicker = ColorsTab:CreateColorPicker({
   Name = "Health Color",
   Color = labelHealthColor,
   Flag = "Label_HealthColor",
   Callback = safeCallback(function(Value)
      labelHealthColor = Value
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer then
            updatePlayerLabels(player)
         end
      end
   end),
})

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
            updatePlayerLabels(player)
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
            updatePlayerLabels(player)
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
            updatePlayerLabels(player)
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
            updatePlayerLabels(player)
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

------------------------------------------------
-- Aplicar ESP a jugadores existentes y nuevos
------------------------------------------------
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		if player.Character then
			addChams(player, player.Character)
			updatePlayerLabels(player)
		end
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 5)
			addChams(player, char)
			updatePlayerLabels(player)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 5)
			addChams(player, char)
			updatePlayerLabels(player)
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
