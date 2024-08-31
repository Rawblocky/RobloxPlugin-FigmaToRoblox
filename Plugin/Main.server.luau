--// Created by Rawblocky

local dockWidgetPluginGuiInfo =
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 100, 75, 100 * 3, 75 * 3)

local PluginGui = plugin:CreateDockWidgetPluginGui("FigmaToRoblox", dockWidgetPluginGuiInfo)

PluginGui.Name = "Figma2Roblox"
PluginGui.Title = "Figma to Roblox"

local toolbar = plugin:CreateToolbar("Figma to Roblox")

local button = toolbar:CreateButton(
	"Figma to Roblox",
	"Convert generated code from the 'Figma to Roblox' plugin into Roblox!",
	"rbxassetid://10801433932",
	"Figma to Roblox"
)

local OldState

local Handler = require(script.Parent["PluginHandler.story"])

local function CheckActive()
	if OldState then
		OldState()
		OldState = nil
	end
	if PluginGui.Enabled then
		OldState = Handler(PluginGui)
	end
end

button.Click:Connect(function()
	PluginGui.Enabled = not PluginGui.Enabled
	CheckActive()
end)

CheckActive()
