-- Variables

local Player = game.Players.LocalPlayer
local Character = Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.Remotes
local CombatRemotes = Remotes.Combat

local InputFunction = CombatRemotes.Input

-- Combat Related --

local Debounce = false
local HeavyDebounce = false
local BlockDebounce = true
local Equipped = false

-- Scripting --

UIS.InputBegan:Connect(function(Input, GPE)
	if GPE then return end
	if Equipped == false then return end
	
	if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Debounce then
		Debounce = true
		Humanoid.JumpHeight = 0
		
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			InputFunction:InvokeServer("Combat", "M1", {Mode = "Air"})
		else
			InputFunction:InvokeServer("Combat", "M1", {Mode = "None"})
		end

		
		task.delay(.17, function()
			Debounce = false

		end)
		
		task.wait(2)
			Humanoid.JumpHeight = 7.2
		
		
	elseif Input.KeyCode == Enum.KeyCode.F and not BlockDebounce then
		Debounce = true
		BlockDebounce = true
		
		Humanoid.WalkSpeed = 5
		Humanoid.JumpHeight = 2
		
		InputFunction:InvokeServer("Combat", "Block", {})
	end
end)

UIS.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.F then
		Debounce = false
		Humanoid.WalkSpeed = 16
		Humanoid.JumpHeight = 7.2
		
		InputFunction:InvokeServer("Combat", "Unblock", {})
		
		task.delay(1, function()
			BlockDebounce = false
		end)
	end
end)

script.Parent.Equipped:Connect(function()
	Equipped = true
end)

script.Parent.Unequipped:Connect(function()
	Equipped = false
end)