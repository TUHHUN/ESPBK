
--[[
  Block Spin Aimbot & ESP Script - UI + Features (v1.0)
  Author: YourNameHere
  Note: Make sure this is executed using a supported executor (Synapse, Fluxus, Hydrogen, etc.)
--]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- UI Loader
loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Floating toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(1, -60, 1, -60)
toggleButton.AnchorPoint = Vector2.new(1, 1)
toggleButton.Text = "⚙️"
toggleButton.TextSize = 24
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.BorderSizePixel = 0
toggleButton.Draggable = true
toggleButton.Active = true
toggleButton.Visible = true
toggleButton.Name = "OpenUI_Button"
toggleButton.Parent = game:GetService("CoreGui")

-- Rayfield UI Setup
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
   Name = "Block Spin 🚀",
   LoadingTitle = "Loading Block Spin...",
   LoadingSubtitle = "Features by YourNameHere",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- Tabs
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
local ESPTab = Window:CreateTab("🧠 ESP", 4483362458)

-- Feature toggles
local showFOV, enableSilentAim, enableESP = false, false, false
local aimPart = "Head"

-- FOV settings
local fovRadius = 150
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = fovRadius
fovCircle.Color = Color3.new(1, 1, 0)
fovCircle.Transparency = 0.6
fovCircle.Filled = false

-- UI Toggles
CombatTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Callback = function(Value)
       showFOV = Value
       fovCircle.Visible = Value
   end,
})

CombatTab:CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = false,
   Callback = function(Value)
       enableSilentAim = Value
   end,
})

CombatTab:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "Torso", "Random"},
   CurrentOption = "Head",
   Callback = function(Option)
       aimPart = Option
   end,
})

-- ESP Toggle
ESPTab:CreateToggle({
   Name = "Enable Skeleton ESP",
   CurrentValue = false,
   Callback = function(Value)
       enableESP = Value
   end,
})

-- Helper: Find Closest Player
local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(pos)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < shortest and dist <= fovRadius then
                    closest = player
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- Drawing ESP Lines
local function drawESP(player)
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end

    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end

    local headPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
    local torsoPos = workspace.CurrentCamera:WorldToViewportPoint(torso.Position)

    if onScreen then
        local line = Drawing.new("Line")
        line.From = Vector2.new(torsoPos.X, torsoPos.Y)
        line.To = Vector2.new(headPos.X, headPos.Y)
        line.Thickness = 2
        line.Color = Color3.new(1, 1, 0)
        if player == getClosestPlayer() then
            line.Color = Color3.new(1, 0, 0)
        end
        line.Transparency = 1
        line.Visible = true
        task.delay(0.05, function()
            line:Remove()
        end)
    end
end

-- Hooking the RenderStepped
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    fovCircle.Radius = fovRadius
    fovCircle.Visible = showFOV

    if enableESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                drawESP(player)
            end
        end
    end
end)

-- Toggle visibility
local uiVisible = true
toggleButton.MouseButton1Click:Connect(function()
   uiVisible = not uiVisible
   for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
       if gui.Name == "RayfieldUI" then
           gui.Enabled = uiVisible
       end
   end
end)


-- Silent Aim Logic

-- Smart Silent Aim function
local function getTargetPart(player)
    if not player or not player.Character then return nil end

    if aimPart == "Random" then
        local parts = {"Head", "UpperTorso", "Torso"}
        local partName = parts[math.random(1, #parts)]
        return player.Character:FindFirstChild(partName)
    end

    return player.Character:FindFirstChild(aimPart)
end

-- Smart aiming (hook method)
local __namecall
__namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if enableSilentAim and tostring(self) == "HitPart" and method == "FireServer" then
        local target = getClosestPlayer()
        local part = getTargetPart(target)
        if target and part then
            args[1] = part
            return __namecall(self, unpack(args))
        end
    end

    return __namecall(self, ...)
end))
