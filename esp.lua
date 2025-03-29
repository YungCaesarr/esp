-- // UI Lib MORADA con colores UI muy oscuros, sliders ajustados, color picker movible con header,
-- // whitelist y target integrados
-- // Créditos: YUNGCAESAR / Modificado por [TU NOMBRE]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local espEnabled = true
local espColor = Color3.fromRGB(150, 150, 150) -- Color inicial del ESP (más apagado)
local uiVisible = true

-- Tabla para guardar jugadores agregados en whitelist/target
-- Se asigna "good" para whitelist y "target" para target
local whitelistedPlayers = {}

------------------------------------------------
-- Crear ScreenGui
------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomUILib"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

------------------------------------------------
-- UI PRINCIPAL (tonos muy oscuros)
------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 500, 0, 300)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 8)

-- Top Bar de la UI principal
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topBarCorner = Instance.new("UICorner", topBar)
topBarCorner.CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "UI Lib"
titleLabel.Font = Enum.Font.GothamSemibold
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Parent = topBar

local creditLabel = Instance.new("TextLabel")
creditLabel.Name = "CreditLabel"
creditLabel.Size = UDim2.new(0, 120, 1, 0)
creditLabel.Position = UDim2.new(0, 60, 0, 0)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "[YUNGCAESAR]"
creditLabel.Font = Enum.Font.GothamSemibold
creditLabel.TextSize = 14
creditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
creditLabel.TextXAlignment = Enum.TextXAlignment.Left
creditLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -35, 0, 0)
closeButton.BackgroundTransparency = 1
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = topBar

closeButton.MouseButton1Click:Connect(function()
	uiVisible = not uiVisible
	mainFrame.Visible = uiVisible
end)

-- Dragging de la UI principal
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

topBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateInput(input)
	end
end)

-- Sidebar
local sideBar = Instance.new("Frame")
sideBar.Name = "SideBar"
sideBar.Size = UDim2.new(0, 120, 1, -35)
sideBar.Position = UDim2.new(0, 0, 0, 35)
sideBar.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
sideBar.BorderSizePixel = 0
sideBar.Parent = mainFrame

local sideCorner = Instance.new("UICorner", sideBar)
sideCorner.CornerRadius = UDim.new(0, 8)

local homeButton = Instance.new("TextButton")
homeButton.Name = "HomeButton"
homeButton.Size = UDim2.new(1, -20, 0, 40)
homeButton.Position = UDim2.new(0, 10, 0, 10)
homeButton.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
homeButton.Text = "Home"
homeButton.Font = Enum.Font.GothamSemibold
homeButton.TextSize = 16
homeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
homeButton.Parent = sideBar

local homeCorner = Instance.new("UICorner", homeButton)
homeCorner.CornerRadius = UDim.new(0, 6)

-------------------------------------------------------
-- Contenido (Panel central) convertido en ScrollingFrame
-------------------------------------------------------
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -120, 1, -35)
contentFrame.Position = UDim2.new(0, 120, 0, 35)
contentFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 8
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner", contentFrame)
contentCorner.CornerRadius = UDim.new(0, 8)

-- UIListLayout para acomodar los elementos uno debajo del otro
local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10) -- Espacio vertical entre elementos
contentLayout.Parent = contentFrame

-- Ajusta el CanvasSize cuando cambie la altura total de los hijos
contentLayout.Changed:Connect(function(property)
	if property == "AbsoluteContentSize" then
		contentFrame.CanvasSize = UDim2.new(
			0,
			0,
			0,
			contentLayout.AbsoluteContentSize.Y + 20
		)
	end
end)

-- Título
local sectionTitle = Instance.new("TextLabel")
sectionTitle.Name = "SectionTitle"
sectionTitle.Size = UDim2.new(1, -20, 0, 30)
sectionTitle.BackgroundTransparency = 1
sectionTitle.Text = "Controles de ESP"
sectionTitle.Font = Enum.Font.GothamSemibold
sectionTitle.TextSize = 16
sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.LayoutOrder = 1  -- Orden en la lista
sectionTitle.Parent = contentFrame

-- Botón Toggle ESP
local toggleESPBtn = Instance.new("TextButton")
toggleESPBtn.Name = "ToggleESPBtn"
toggleESPBtn.Size = UDim2.new(0, 120, 0, 35)
toggleESPBtn.BackgroundColor3 = Color3.fromRGB(55, 45, 65)
toggleESPBtn.Text = "Toggle ESP"
toggleESPBtn.Font = Enum.Font.GothamSemibold
toggleESPBtn.TextSize = 14
toggleESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleESPBtn.LayoutOrder = 2
toggleESPBtn.Parent = contentFrame

local toggleCorner = Instance.new("UICorner", toggleESPBtn)
toggleCorner.CornerRadius = UDim.new(0, 6)

toggleESPBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	-- Actualiza el estado (Enabled) de todos los highlights
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local highlight = player.Character:FindFirstChild("ESPHighlight")
			if highlight then
				highlight.Enabled = espEnabled
			end
		end
	end
end)

-----------------------------------------------------
-- Panel del Color Picker (ventana movible con header)
-----------------------------------------------------
local colorPickerFrame = Instance.new("Frame")
colorPickerFrame.Name = "ColorPickerFrame"
colorPickerFrame.Size = UDim2.new(0, 320, 0, 280)
colorPickerFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
colorPickerFrame.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
colorPickerFrame.BorderSizePixel = 0
colorPickerFrame.Visible = false
colorPickerFrame.ClipsDescendants = true
colorPickerFrame.Parent = screenGui

local pickerFrameCorner = Instance.new("UICorner", colorPickerFrame)
pickerFrameCorner.CornerRadius = UDim.new(0, 8)

local colorPickerHeader = Instance.new("Frame")
colorPickerHeader.Name = "ColorPickerHeader"
colorPickerHeader.Size = UDim2.new(1, 0, 0, 25)
colorPickerHeader.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
colorPickerHeader.BorderSizePixel = 0
colorPickerHeader.Parent = colorPickerFrame

local headerCorner = Instance.new("UICorner", colorPickerHeader)
headerCorner.CornerRadius = UDim.new(0, 8)

local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "HeaderLabel"
headerLabel.Size = UDim2.new(1, -10, 1, 0)
headerLabel.Position = UDim2.new(0, 5, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "Color Picker"
headerLabel.Font = Enum.Font.GothamSemibold
headerLabel.TextSize = 16
headerLabel.TextColor3 = Color3.fromRGB(255,255,255)
headerLabel.Parent = colorPickerHeader

-- Dragging del Color Picker
local draggingPicker = false
local dragInputPicker, dragStartPicker, startPosPicker

colorPickerHeader.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingPicker = true
		dragStartPicker = input.Position
		startPosPicker = colorPickerFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingPicker = false
			end
		end)
	end
end)

colorPickerHeader.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInputPicker = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInputPicker and draggingPicker then
		local delta = input.Position - dragStartPicker
		colorPickerFrame.Position = UDim2.new(
			startPosPicker.X.Scale,
			startPosPicker.X.Offset + delta.X,
			startPosPicker.Y.Scale,
			startPosPicker.Y.Offset + delta.Y
		)
	end
end)

-- Preview dinámico en el Color Picker
local previewBox = Instance.new("Frame")
previewBox.Name = "PreviewBox"
previewBox.Size = UDim2.new(0, 50, 0, 50)
previewBox.Position = UDim2.new(0, 10, 0, 35)
previewBox.BackgroundColor3 = espColor
previewBox.BorderSizePixel = 0
previewBox.Parent = colorPickerFrame

local previewCorner = Instance.new("UICorner", previewBox)
previewCorner.CornerRadius = UDim.new(0, 6)

-- Tabla de sliders para ajustar R, G, B
local sliders = {}

local function updatePreview()
	local r = sliders.R.Fill.Size.X.Scale
	local g = sliders.G.Fill.Size.X.Scale
	local b = sliders.B.Fill.Size.X.Scale
	previewBox.BackgroundColor3 = Color3.new(r, g, b)
end

local function createSlider(labelText, posY, initialValue)
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = labelText.."Slider"
	sliderFrame.Size = UDim2.new(0, 260, 0, 30)
	sliderFrame.Position = UDim2.new(0, 30, 0, posY)
	sliderFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	sliderFrame.Parent = colorPickerFrame
	sliderFrame.ClipsDescendants = true

	local sliderCorner = Instance.new("UICorner", sliderFrame)
	sliderCorner.CornerRadius = UDim.new(0, 4)

	local label = Instance.new("TextLabel")
	label.Name = labelText.."Label"
	label.Size = UDim2.new(0, 40, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = sliderFrame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(initialValue, 0, 1, 0)
	fill.Position = UDim2.new(0, 50, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
	fill.Parent = sliderFrame

	local fillCorner = Instance.new("UICorner", fill)
	fillCorner.CornerRadius = UDim.new(0, 4)

	return {Slider = sliderFrame, Fill = fill}
end

sliders.R = createSlider("R", 90, espColor.R)
sliders.G = createSlider("G", 130, espColor.G)
sliders.B = createSlider("B", 170, espColor.B)

for _, sliderObj in pairs(sliders) do
	sliderObj.Slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local conn
			conn = UserInputService.InputChanged:Connect(function(move)
				if move.UserInputType == Enum.UserInputType.MouseMovement then
					local absPos = sliderObj.Slider.AbsolutePosition.X + 50
					local newVal = math.clamp((move.Position.X - absPos) / (sliderObj.Slider.AbsoluteSize.X - 50), 0, 1)
					sliderObj.Fill.Size = UDim2.new(newVal, 0, 1, 0)
					updatePreview()
				end
			end)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					conn:Disconnect()
				end
			end)
		end
	end)
end

local confirmBtn = Instance.new("TextButton")
confirmBtn.Name = "ConfirmBtn"
confirmBtn.Size = UDim2.new(0, 100, 0, 30)
confirmBtn.Position = UDim2.new(0.5, -110, 1, -40)
confirmBtn.BackgroundColor3 = Color3.fromRGB(70, 60, 80)
confirmBtn.Text = "Confirmar"
confirmBtn.Font = Enum.Font.GothamSemibold
confirmBtn.TextSize = 14
confirmBtn.TextColor3 = Color3.new(1, 1, 1)
confirmBtn.Parent = colorPickerFrame

local confirmCorner = Instance.new("UICorner", confirmBtn)
confirmCorner.CornerRadius = UDim.new(0, 4)

confirmBtn.MouseButton1Click:Connect(function()
	local r = sliders.R.Fill.Size.X.Scale
	local g = sliders.G.Fill.Size.X.Scale
	local b = sliders.B.Fill.Size.X.Scale
	espColor = Color3.new(r, g, b)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local highlight = player.Character:FindFirstChild("ESPHighlight")
			if highlight then
				highlight.OutlineColor = espColor
			end
		end
	end
	colorPickerFrame.Visible = false
end)

local cancelBtn = Instance.new("TextButton")
cancelBtn.Name = "CancelBtn"
cancelBtn.Size = UDim2.new(0, 100, 0, 30)
cancelBtn.Position = UDim2.new(0.5, 20, 1, -40)
cancelBtn.BackgroundColor3 = Color3.fromRGB(70, 60, 80)
cancelBtn.Text = "Cancelar"
cancelBtn.Font = Enum.Font.GothamSemibold
cancelBtn.TextSize = 14
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Parent = colorPickerFrame

local cancelCorner = Instance.new("UICorner", cancelBtn)
cancelCorner.CornerRadius = UDim.new(0, 4)

cancelBtn.MouseButton1Click:Connect(function()
	colorPickerFrame.Visible = false
end)

-- Botón para abrir el Color Picker
local openColorPickerBtn = Instance.new("TextButton")
openColorPickerBtn.Name = "OpenColorPickerBtn"
openColorPickerBtn.Size = UDim2.new(0, 150, 0, 35)
openColorPickerBtn.BackgroundColor3 = Color3.fromRGB(55, 45, 65)
openColorPickerBtn.Text = "Elegir Color ESP"
openColorPickerBtn.Font = Enum.Font.GothamSemibold
openColorPickerBtn.TextSize = 14
openColorPickerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openColorPickerBtn.LayoutOrder = 3
openColorPickerBtn.Parent = contentFrame

local pickerCorner = Instance.new("UICorner", openColorPickerBtn)
pickerCorner.CornerRadius = UDim.new(0, 6)

openColorPickerBtn.MouseButton1Click:Connect(function()
	-- Actualiza los tamaños de los sliders según el color actual
	sliders.R.Fill.Size = UDim2.new(espColor.R, 0, 1, 0)
	sliders.G.Fill.Size = UDim2.new(espColor.G, 0, 1, 0)
	sliders.B.Fill.Size = UDim2.new(espColor.B, 0, 1, 0)
	updatePreview()
	colorPickerFrame.Visible = true
end)

-----------------------------------------------------
-- SECCIÓN DE WHITELIST
-----------------------------------------------------
local whitelistPanel = Instance.new("Frame")
whitelistPanel.Name = "WhitelistPanel"
whitelistPanel.Size = UDim2.new(1, -20, 0, 150) -- Ajusta la altura a tu gusto
whitelistPanel.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
whitelistPanel.BorderSizePixel = 0
whitelistPanel.LayoutOrder = 4
whitelistPanel.Parent = contentFrame

local wpCorner = Instance.new("UICorner", whitelistPanel)
wpCorner.CornerRadius = UDim.new(0, 8)

local whitelistLabel = Instance.new("TextLabel")
whitelistLabel.Name = "WhitelistLabel"
whitelistLabel.Size = UDim2.new(1, -10, 0, 25)
whitelistLabel.Position = UDim2.new(0, 5, 0, 5)
whitelistLabel.BackgroundTransparency = 1
whitelistLabel.Text = "Whitelist Player"
whitelistLabel.Font = Enum.Font.GothamBold
whitelistLabel.TextSize = 18
whitelistLabel.TextColor3 = Color3.fromRGB(80, 200, 220)
whitelistLabel.Parent = whitelistPanel

local whitelistTextBox = Instance.new("TextBox")
whitelistTextBox.Name = "WhitelistTextBox"
whitelistTextBox.Size = UDim2.new(1, -10, 0, 30)
whitelistTextBox.Position = UDim2.new(0, 5, 0, 35)
whitelistTextBox.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
whitelistTextBox.Font = Enum.Font.GothamSemibold
whitelistTextBox.TextSize = 14
whitelistTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
whitelistTextBox.ClearTextOnFocus = true
whitelistTextBox.Text = ""
whitelistTextBox.PlaceholderText = "Ingrese iniciales..."
whitelistTextBox.Parent = whitelistPanel

local whitelistList = Instance.new("ScrollingFrame")
whitelistList.Name = "WhitelistList"
whitelistList.Size = UDim2.new(1, -10, 0, 60) -- Espacio para la lista
whitelistList.Position = UDim2.new(0, 5, 0, 70)
whitelistList.BackgroundTransparency = 1
whitelistList.CanvasSize = UDim2.new(0, 0, 0, 0)
whitelistList.ScrollBarThickness = 8
whitelistList.Parent = whitelistPanel

local whitelistLayout = Instance.new("UIListLayout", whitelistList)
whitelistLayout.SortOrder = Enum.SortOrder.LayoutOrder
whitelistLayout.Padding = UDim.new(0, 5)
whitelistLayout.Changed:Connect(function(property)
	if property == "AbsoluteContentSize" then
		whitelistList.CanvasSize = UDim2.new(
			0,
			0,
			0,
			whitelistLayout.AbsoluteContentSize.Y
		)
	end
end)

-----------------------------------------------------
-- SECCIÓN DE TARGET
-----------------------------------------------------
local targetPanel = Instance.new("Frame")
targetPanel.Name = "TargetPanel"
targetPanel.Size = UDim2.new(1, -20, 0, 150) -- Ajusta la altura
targetPanel.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
targetPanel.BorderSizePixel = 0
targetPanel.LayoutOrder = 5
targetPanel.Parent = contentFrame

local tpCorner = Instance.new("UICorner", targetPanel)
tpCorner.CornerRadius = UDim.new(0, 8)

local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "TargetLabel"
targetLabel.Size = UDim2.new(1, -10, 0, 25)
targetLabel.Position = UDim2.new(0, 5, 0, 5)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target"
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextSize = 18
targetLabel.TextColor3 = Color3.fromRGB(240, 200, 120)
targetLabel.Parent = targetPanel

local targetTextBox = Instance.new("TextBox")
targetTextBox.Name = "TargetTextBox"
targetTextBox.Size = UDim2.new(1, -10, 0, 30)
targetTextBox.Position = UDim2.new(0, 5, 0, 35)
targetTextBox.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
targetTextBox.Font = Enum.Font.GothamSemibold
targetTextBox.TextSize = 14
targetTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetTextBox.ClearTextOnFocus = true
targetTextBox.Text = ""
targetTextBox.PlaceholderText = "Ingrese iniciales..."
targetTextBox.Parent = targetPanel

local targetList = Instance.new("ScrollingFrame")
targetList.Name = "TargetList"
targetList.Size = UDim2.new(1, -10, 0, 60)
targetList.Position = UDim2.new(0, 5, 0, 70)
targetList.BackgroundTransparency = 1
targetList.CanvasSize = UDim2.new(0, 0, 0, 0)
targetList.ScrollBarThickness = 8
targetList.Parent = targetPanel

local targetLayout = Instance.new("UIListLayout", targetList)
targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetLayout.Padding = UDim.new(0, 5)
targetLayout.Changed:Connect(function(property)
	if property == "AbsoluteContentSize" then
		targetList.CanvasSize = UDim2.new(
			0,
			0,
			0,
			targetLayout.AbsoluteContentSize.Y
		)
	end
end)

-----------------------------------------------------
-- Funciones para agregar y remover jugadores
-----------------------------------------------------
local function createListEntry(player, parentFrame)
	local entryFrame = Instance.new("Frame")
	entryFrame.Size = UDim2.new(1, 0, 0, 30)
	entryFrame.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
	local ecorner = Instance.new("UICorner", entryFrame)
	ecorner.CornerRadius = UDim.new(0, 4)
	entryFrame.Parent = parentFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.Font = Enum.Font.GothamSemibold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Parent = entryFrame

	local removeBtn = Instance.new("TextButton")
	removeBtn.Size = UDim2.new(0.3, 0, 1, 0)
	removeBtn.Position = UDim2.new(0.7, 0, 0, 0)
	removeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	removeBtn.Text = "Remove"
	removeBtn.Font = Enum.Font.GothamSemibold
	removeBtn.TextSize = 14
	removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	removeBtn.Parent = entryFrame

	removeBtn.MouseButton1Click:Connect(function()
		whitelistedPlayers[tostring(player.UserId)] = nil
		entryFrame:Destroy()
		if player.Character then
			local highlight = player.Character:FindFirstChild("ESPHighlight")
			if highlight then
				highlight.OutlineColor = espColor
			end
		end
	end)
end

local function addPlayerByInitials(inputText, listType)
	local inputLower = inputText:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		local nameLower = player.Name:lower()
		local displayLower = player.DisplayName:lower()
		if nameLower:find(inputLower) or displayLower:find(inputLower) then
			local key = tostring(player.UserId)
			if whitelistedPlayers[key] then return end
			whitelistedPlayers[key] = listType

			-- Ajusta color si el personaje existe
			if player.Character then
				local highlight = player.Character:FindFirstChild("ESPHighlight")
				if highlight then
					if listType == "target" then
						highlight.OutlineColor = Color3.fromRGB(240, 200, 120)
					elseif listType == "good" then
						highlight.OutlineColor = Color3.fromRGB(80, 200, 220)
					end
				end
			end

			-- Crea el item en la lista
			if listType == "good" then
				createListEntry(player, whitelistList)
			elseif listType == "target" then
				createListEntry(player, targetList)
			end
		end
	end
end

whitelistTextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed and whitelistTextBox.Text ~= "" then
		addPlayerByInitials(whitelistTextBox.Text, "good")
		whitelistTextBox.Text = ""
	end
end)

targetTextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed and targetTextBox.Text ~= "" then
		addPlayerByInitials(targetTextBox.Text, "target")
		targetTextBox.Text = ""
	end
end)

-----------------------------------------------------
-- Función para crear/actualizar el Highlight (ESP)
-----------------------------------------------------
local function addChams(character)
	local highlight = character:FindFirstChild("ESPHighlight")
	if highlight then
		highlight.OutlineColor = espColor
		highlight.Enabled = espEnabled
	else
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.FillColor = Color3.new(1, 1, 1)
		highlight.OutlineColor = espColor
		highlight.FillTransparency = 1
		highlight.Enabled = espEnabled
		highlight.Parent = character
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		if player.Character then
			addChams(player.Character)
		end
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 5)
			addChams(char)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 5)
			addChams(char)
		end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
		uiVisible = not uiVisible
		mainFrame.Visible = uiVisible
	end
end)
