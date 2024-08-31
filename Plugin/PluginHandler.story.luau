--// Created by Rawblocky

local Players = game:GetService("Players")
local ScriptEditorService = game:GetService("ScriptEditorService")
local StarterGui = game:GetService("StarterGui")

local HttpService = game:GetService("HttpService")

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local LocalPlayer = Players.LocalPlayer
local plugin = plugin

local insertJSONScript = Instance.new("ModuleScript")
insertJSONScript.Archivable = false
insertJSONScript.Name = "Insert JSON Code"

local currentSource

local function openJSONScript()
	ScriptEditorService:UpdateSourceAsync(insertJSONScript, function()
		currentSource = "-- Paste in the exported JSON code here, then press [ENTER]\n"
		return currentSource
	end)
	plugin:OpenScript(insertJSONScript, 2)
end

local function getJSONSource()
	if not currentSource then
		return
	end
	-- Don't include the 1st line, if it's a comment
	local lines = string.split(currentSource, "\n")
	if lines[1]:find("^%s*%-%-") then
		table.remove(lines, 1)
	end
	return table.concat(lines, "\n")
end

return function(ParentInto, pluginArgument)
	plugin = pluginArgument or plugin
	local IsHoarcekat = not LocalPlayer
		and ParentInto:FindFirstAncestorWhichIsA("PluginGui")
		and ParentInto:FindFirstAncestorWhichIsA("PluginGui").Name == "Hoarcekat"
	local Disconnected = false
	local Events = {}
	local function RemoveEvent(Event)
		pcall(function()
			Event:Disconnect()
		end)
		pcall(function()
			Event:Destroy()
		end)
	end
	local function AddEvent(Event)
		if Disconnected then
			task.spawn(RemoveEvent, Event)
			return error("Disconnected")
		end
		pcall(function()
			Event.Archivable = false
		end)
		table.insert(Events, Event)
		return Event
	end
	local UI = AddEvent(script.Parent:WaitForChild("Container"):Clone())
	insertJSONScript.Parent = UI
	local TextBox = UI.InsertCode.TextBox.TextBox
	local GenerateButton = UI.Generate.TextButton
	local CanGenerate = false
	local Busy = false
	UI.Parent = ParentInto
	local function Update()
		if not getJSONSource() then
			return
		end
		local Success, _ = pcall(function()
			local Table = HttpService:JSONDecode(getJSONSource())
			if not Table[1] then
				return error("No contents")
			end
		end)
		local Enabled = not (not Success or getJSONSource() == "[]")
		GenerateButton.AutoButtonColor = Enabled
		GenerateButton.DisabledGradient.Enabled = not Enabled
		CanGenerate = Enabled
		TextBox.Text = string.sub(getJSONSource(), 1, 100)
		return Enabled
	end
	AddEvent(ScriptEditorService.TextDocumentDidChange:Connect(function(document: ScriptDocument, changes: table)
		local changedScript = document:GetScript()
		if changedScript ~= insertJSONScript then
			return
		end
		local newText = document:GetText(2, 1)
		currentSource = newText
		if string.split(newText, "\n")[2] ~= nil then
			local isEnabled = Update()
			if isEnabled then
				document:CloseAsync()
			else
				ScriptEditorService:UpdateSourceAsync(changedScript, function(source: string)
					-- Replace the first line
					local lines = string.split(source, "\n")
					lines[1] = "-- ⚠️ Invalid format! Paste in the exported JSON code here, then press [ENTER]"
					currentSource = lines[1] .. "\n" .. (lines[2] or "")
					return currentSource
				end)
				local lineText = document:GetLine(2)
				document:ForceSetSelectionAsync(2, 1, 2, #lineText + 1)
			end
			return
		end
		Update()
	end))
	AddEvent(TextBox:GetPropertyChangedSignal("Text"):Connect(Update))
	AddEvent(TextBox.Focused:Connect(openJSONScript))
	TextBox.PlaceholderText = "Open script to paste JSON code"
	Update()

	local Types = {
		["FRAME"] = "Frame",
		["TEXT"] = "TextLabel",
		["GROUP"] = "Folder",
	}
	local ImageNodes = {}
	local ImageNodesArray = {}
	local TextNodes = {}
	local function UpdateUIGradient(UIGradient, Information)
		local Sequence = {}
		local AlphaSequence = {}
		for _, Color in ipairs(Information.gradientStops) do
			local RGB = Color.color
			table.insert(AlphaSequence, NumberSequenceKeypoint.new(Color.position, 1 - RGB.a))
			table.insert(Sequence, ColorSequenceKeypoint.new(Color.position, Color3.new(RGB.r, RGB.g, RGB.b)))
		end
		UIGradient.Color = ColorSequence.new(Sequence)
		UIGradient.Transparency = NumberSequence.new(AlphaSequence)
	end
	local Properties = {

		["visible"] = "Visible",
		["rotation"] = "Rotation",
		["name"] = "Name",
		["clipsContent"] = "ClipsDescendants",

		["characters"] = "Text",
		["fontSize"] = "TextSize",

		-- Functions
		["width"] = function(Object, Information)
			Object.Size = UDim2.fromOffset(Information.width, Information.height)
			Object.Position = UDim2.fromOffset(Information.x, Information.y)
		end,
		["cornerRadius"] = function(Object, Information)
			local cornerRadius = Information.cornerRadius
			if typeof(cornerRadius) ~= "number" or math.round(cornerRadius) <= 0 then
				return
			end
			local UICorner = Instance.new("UICorner")
			UICorner.CornerRadius = UDim.new(0, math.round(cornerRadius))
			UICorner.Parent = Object
		end,
		["type"] = function(Object, Information)
			if Information["type"] == "ELLIPSE" then
				local UICorner = Instance.new("UICorner")
				UICorner.CornerRadius = UDim.new(1, 0)
				UICorner.Parent = Object
			elseif Information["type"] == "GROUP" then
				--Object.BackgroundTransparency = 1
				--Object.BackgroundColor3 = Color3.new(1, 1, 1)
				--Object.BorderSizePixel = 0
			end
		end,

		["textAlignHorizontal"] = function(Object, Information)
			local textAlignHorizontal = Information.textAlignHorizontal
			local Alignments = {
				["LEFT"] = Enum.TextXAlignment.Left,
				["RIGHT"] = Enum.TextXAlignment.Right,
			}
			Object.TextXAlignment = Alignments[textAlignHorizontal] or Enum.TextXAlignment.Center
		end,
		["textAlignVertical"] = function(Object, Information)
			local textAlignVertical = Information.textAlignVertical
			local Alignments = {
				["TOP"] = Enum.TextYAlignment.Top,
				["BOTTOM"] = Enum.TextYAlignment.Bottom,
			}
			Object.TextYAlignment = Alignments[textAlignVertical] or Enum.TextYAlignment.Center
		end,
		["fills"] = function(Object, Information)
			local Changing = "Background"
			if Object:IsA("TextLabel") then
				Changing = "Text"
			end
			local fills = Information.fills
			Object.BackgroundTransparency = 1
			Object.BackgroundColor3 = Color3.new(1, 1, 1)
			Object.BorderSizePixel = 0
			Object[Changing .. "Transparency"] = 1
			for _, fillInformation in ipairs(fills) do
				if not fillInformation or not fillInformation.visible then
					Object[Changing .. "Transparency"] = 1
					continue
				elseif fillInformation.type == "SOLID" then
					Object[Changing .. "Color3"] =
						Color3.new(fillInformation.color.r, fillInformation.color.g, fillInformation.color.b)
					Object[Changing .. "Transparency"] = 1 - fillInformation.opacity
				elseif fillInformation.type == "GRADIENT_LINEAR" then
					Object[Changing .. "Color3"] = Color3.new(1, 1, 1)
					Object[Changing .. "Transparency"] = 1 - fillInformation.opacity
					local UIGradient = Instance.new("UIGradient")
					UpdateUIGradient(UIGradient, fillInformation)
					UIGradient.Parent = Object
				elseif fillInformation.type == "IMAGE" then
					local ScaleModes = {
						["FILL"] = Enum.ScaleType.Crop,
						["FIT"] = Enum.ScaleType.Fit,
						["CROP"] = Enum.ScaleType.Stretch,
						["TILE"] = Enum.ScaleType.Stretch,
					}
					Object.ImageTransparency = 1 - fillInformation.opacity
					Object.ScaleType = ScaleModes[fillInformation.scaleMode] or Enum.ScaleType.Crop
					ImageNodesArray[fillInformation.imageHash] = ImageNodesArray[fillInformation.imageHash] or {}
					table.insert(ImageNodesArray[fillInformation.imageHash], Object)
				end
			end
		end,
		["textAutoResize"] = function(Object, Information)
			local textAutoResize = Information.textAutoResize
			--Object.TextScaled = textAutoResize == "WIDTH_AND_HEIGHT" or "HEIGHT"
			if textAutoResize == "TRUNCATE" then
				Object.TextTruncate = Enum.TextTruncate.AtEnd
			end
			Object.TextWrapped = true --textAutoResize ~= "NONE"
		end,
		["fontName"] = function(Object, Information)
			local fontName = Information.fontName
			if typeof(Information.fontName) == "table" then
				fontName = Information.fontName.family
			elseif Information.fontName ~= "string" then
				fontName = "Roboto"
			end
			if fontName == "Fredoka" then
				fontName = "FredokaOne"
			end
			local fontNameAlt = ""
			local Splitted = string.split(fontName, " ")
			for _, Text in ipairs(Splitted) do
				if Text == "Pro" or Text == "SSm" then
					continue
				end
				fontNameAlt = fontNameAlt .. Text
			end
			local Fonts = Enum.Font:GetEnumItems()
			local function CheckFont(Font_)
				Object.Font = Enum.Font[Font_]
				pcall(function()
					Object.Font = Enum.Font[Font_ .. Information.fontName.weight]
				end)
			end
			pcall(CheckFont, "Roboto")
			pcall(CheckFont, fontName)
			pcall(CheckFont, fontNameAlt)
			if not table.find(Fonts, fontName) and not table.find(Fonts, fontNameAlt) then
				Object:SetAttribute("fontName", fontName)
			end
		end,
		["strokeWeight"] = function(Object, Information)
			local strokeWeight = math.round(Information.strokeWeight or 0) or 0
			local strokes = Information.strokes
			if strokeWeight <= 0 or not strokes or not strokes[1] then
				return
			end
			local UIStroke = Instance.new("UIStroke")
			UIStroke.Enabled = strokes[1].visible
			UIStroke.Transparency = 1 - strokes[1].opacity
			if strokes[1].color then
				UIStroke.Color = Color3.new(strokes[1].color.r, strokes[1].color.g, strokes[1].color.b)
			elseif strokes[1].type == "GRADIENT_LINEAR" then
				UIStroke.Color = Color3.new(1, 1, 1)
				UIStroke.Transparency = 0
				local UIGradient = Instance.new("UIGradient")
				UpdateUIGradient(UIGradient, strokes[1])
				UIGradient.Parent = UIStroke
			end
			UIStroke.Thickness = strokeWeight
			UIStroke.Parent = Object
		end,
		--
	}
	local function Generate(Information, Parent)
		local Object = Instance.new(Types[Information["type"]] or "ImageLabel")
		if Object:IsA("ImageLabel") then
			Object.Image = ""
		end
		for PropertyName, PropertyValue in pairs(Information) do
			if Properties[PropertyName] then
				if typeof(Properties[PropertyName]) == "function" then
					if PropertyName == "width" and Object:IsA("Folder") then
						continue
					end
					Properties[PropertyName](Object, Information)
				else
					if PropertyName ~= "name" and Object:IsA("Folder") then
						continue
					end
					Object[Properties[PropertyName]] = PropertyValue
				end
			end
		end
		if Information["type"] ~= "BOOLEAN_OPERATION" then
			for _, Child in ipairs(Information.children) do
				Generate(Child, Object)
			end
		end
		if Information["type"] == "BOOLEAN_OPERATION" then
			table.insert(ImageNodes, Object)
		elseif Information["type"] == "TEXT" then
			table.insert(TextNodes, Object)
		end
		Object.Parent = Parent
		return Object
	end
	AddEvent(GenerateButton.MouseButton1Click:Connect(function()
		if not CanGenerate or Busy then
			return
		end
		Busy = true
		ImageNodes = {}
		TextNodes = {}
		GenerateButton.Text = "..."
		local Success, Error = pcall(function()
			local Table = HttpService:JSONDecode(getJSONSource())
			local AllGenerated = {}
			for _, Information in ipairs(Table) do
				table.insert(AllGenerated, Generate(Information, nil))
			end
			if not AllGenerated[1] then
				return warn("Nothing generated!")
			end
			local NewParent = game.Selection:Get()[1]
			if not NewParent then
				local ScreenGui = Instance.new("ScreenGui")
				ScreenGui.Name = "Figma to Roblox Result"
				ScreenGui.Parent = StarterGui
				NewParent = ScreenGui
			end
			ChangeHistoryService:SetWaypoint("Importing UI")
			for _, Object in ipairs(AllGenerated) do
				Object.Parent = NewParent
			end
			game.Selection:Set(AllGenerated)
			return ChangeHistoryService:SetWaypoint("Imported UI")
		end)
		Busy = false
		GenerateButton.Text = "Generate UI"
		if not Success then
			warn(Error)
		end
	end))
	return function()
		if Disconnected then
			return
		end
		Disconnected = true
		for _, Event in ipairs(Events) do
			task.spawn(RemoveEvent, Event)
		end
		if IsHoarcekat then
			--
		end
	end
end
