-- Variables --

local CombatServer = {}
local DmgIndicator = require(game.ReplicatedStorage.Modules.DamageIndicator) 
local KnockbackModule = require(game.ServerStorage.Modules.Knockback)
local HitboxModule = require(game.ServerStorage.Modules["MuchachoHitboxV1.1"])
local RockModule = require(game.ReplicatedStorage.Modules.Rock)

local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TS = require(game.ReplicatedStorage.Modules.TweenServiceV2)
local Info = TweenInfo.new(.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Assets = game.ReplicatedStorage.Assets.Combat

local M1Time = .3
local Combo = 0
local Hitted = false
local lastM1 = tick()
local onAir = false

-- Functions --

local function StopAnimation(Humanoid, Animation)
	for i, v in pairs(Humanoid:GetPlayingAnimationTracks()) do
		if v.Name == Animation then
			v:Stop()
		end
	end
end

local function soundEmit(Sound, Parent)

	local soundNew = Sound:Clone()
	soundNew.Parent = Parent
	soundNew:Play()

	game.Debris:AddItem(soundNew, 2)

end

local function emitParticle(Attachment)
	for i, v in pairs(Attachment:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
				v:Emit()
			end
		end
	end


local function stun(Humanoid, Time)
	Humanoid.Parent:SetAttribute("Stunned", true)
	Humanoid.WalkSpeed = 0
	Humanoid.JumpHeight = 0
	
	task.delay(Time, function()
		Humanoid.Parent:SetAttribute("Stunned", nil)
		Humanoid.WalkSpeed = 16
		Humanoid.JumpHeight = 7.2
	end)
end
-- M1 --

function CombatServer.M1(Client, Data)
	local Character = Client.Character
	local Humanoid = Character.Humanoid
	local Player = game.Players:GetPlayerFromCharacter(Character)

	local HitCombo = Player:FindFirstChild("Hit")

	local Stunned = Character:GetAttribute("Stunned")
	local Attacking = Character:GetAttribute("Attacking")
	local Blocking = Character:GetAttribute("Blocking")
	
	if Blocking or Stunned or Attacking then return end
	Character:SetAttribute("Attacking", true)

	
	-- SFX --
	local M1SFX = Assets.SFX.PunchSFX
	local KickSFX = Assets.SFX.KickSFX
	local SwingSFX = Assets.SFX.PunchSwing
	local ParrySFX = Assets.SFX.ParrySFX
	local BlockSFX = Assets.SFX.BlockSFX
	local BlockBreakSFX = Assets.SFX.BlockBreakSFX

	-- VFX --
	local Highlight = Assets.VFX.DamageHihglight
	local BlockBreakVFX = Assets.VFX.BlockBreakVFX
	local BlockVFX = Assets.VFX.BlockVFX
	local ParryVFX = Assets.VFX.ParryVFX
	local HitVFX = Assets.VFX.HitVFX
	local PushVFX = Assets.VFX.PushVFX

	-- Overlap Hitbox --

	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Blacklist
	Params.FilterDescendantsInstances = {Client.Character, workspace.FX}

	local Hitbox = HitboxModule.CreateHitbox()
	Hitbox.Size = Vector3.new(6,6,6)
	Hitbox.Offset = CFrame.new(0, 0, -2.5)
	Hitbox.CFrame = Character.HumanoidRootPart.CFrame
	Hitbox.OverlapParams = Params
	Hitbox.Visualizer = true
	Hitbox.Key = Character.Name.."M1"

	-- Scripting --
	Hitbox.Touched:Connect(function(Hit, EnemyHumanoid)
		if Stunned == true then return end

		if EnemyHumanoid ~= nil then
			Hitted = true

			local EnemyCharacter = EnemyHumanoid.Parent
			local EnemyPlayer = game.Players:GetPlayerFromCharacter(EnemyCharacter)
			local EnemyBlocking = EnemyCharacter:GetAttribute("Blocking")
			local EnemyParry = EnemyCharacter:GetAttribute("Parry")
			
			if onAir == false then
				
				if Combo == 5 then
					if EnemyBlocking then
						if EnemyParry then
							local Parry = ParryVFX.Attachment:Clone()
							Parry.Parent = EnemyCharacter.HumanoidRootPart
							emitParticle(Parry)
							soundEmit(ParrySFX, EnemyCharacter)

							StopAnimation(Humanoid, tostring(Combo))
							local Animation = Humanoid:LoadAnimation(Assets.Animations.Parry)
							Animation:Play()

							game.ReplicatedStorage.Remotes.Camera.BigExplosion:FireClient(Player)
							Humanoid.WalkSpeed = 0
							Humanoid.JumpHeight = 0

							task.delay(2, function()
								Animation:Stop()
								Humanoid.WalkSpeed = 16
								Humanoid.JumpHeight = 7.2
							end)

							stun(Humanoid, 2)
						else
							EnemyCharacter:SetAttribute("Blocking", nil)
							local Animation = EnemyHumanoid:LoadAnimation(Assets.Animations.Parry)
							Animation:Play()
							local BlockBreak = BlockBreakVFX.Attachment:Clone()
							BlockBreak.Parent = EnemyCharacter.HumanoidRootPart
							emitParticle(BlockBreak)
							soundEmit(BlockBreakSFX, EnemyCharacter)
							task.delay(2, function()
								Animation:Stop()
							end)
							stun(EnemyHumanoid, 2)
							HitCombo.Value += 1

							local EnemyHighlight = Highlight:Clone()
							EnemyHighlight.Parent = EnemyCharacter

							TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 0.2}):Play()
							task.delay(.2, function()
								TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 1}):Play()
								task.delay(.12, function()
									EnemyHighlight:Destroy()
								end)
							end)
						end
				else
					local Damage = math.random(7, 15)

					local Hit = HitVFX.Attachment:Clone()
					Hit.Parent = EnemyCharacter.HumanoidRootPart
					soundEmit(KickSFX, EnemyCharacter)
					emitParticle(Hit)

					HitCombo.Value += 1
					EnemyHumanoid:TakeDamage(Damage)
					local HitAnim = EnemyHumanoid:LoadAnimation(Assets.Animations.Hit2)
					KnockbackModule.knockback(Character, EnemyCharacter, 30, Character)

					HitAnim:Play()
					task.delay(.6, function()
						HitAnim:Stop()
					end)

				local newPush = PushVFX:Clone()
				for i, v in pairs(newPush:GetDescendants()) do
					v.Parent = EnemyCharacter.HumanoidRootPart
					game.Debris:AddItem(v, 1)
				end
				local Color = Color3.fromRGB(255, 49, 49)
				local Size = UDim2.new(1.8, 0, 1.8, 0)
				local Font = Enum.Font.Arcade
				DmgIndicator(EnemyCharacter, Damage, Color, Size,Font)
				local EnemyHighlight = Highlight:Clone()
				EnemyHighlight.Parent = EnemyCharacter

				TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 0.2}):Play()
				task.delay(.2, function()
					TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 1}):Play()
					task.delay(.12, function()
						EnemyHighlight:Destroy()
					end)
				end)
			end
			elseif Combo == 4 then
					if Data.Mode == "Air" then
						local AirPos = (Character.HumanoidRootPart.CFrame * CFrame.new(0, 14, 0)).Position
						local enemyAirPos = (Character.HumanoidRootPart.CFrame * CFrame.new(0, 14, -4)).Position

						local BP = Instance.new("BodyPosition")
						BP.Name = "AirUp"
						BP.MaxForce = Vector3.new(4e4,4e4,4e4)
						BP.Position = AirPos
						BP.P = 4e4
						BP.Parent = Character.HumanoidRootPart
						game.Debris:AddItem(BP, 1)

						local EnemyBP = Instance.new("BodyPosition")
						EnemyBP.Name = "AirUp"
						EnemyBP.MaxForce = Vector3.new(4e4,4e4,4e4)
						EnemyBP.Position = enemyAirPos
						EnemyBP.P = 4e4
						EnemyBP.Parent = EnemyHumanoid.Parent.HumanoidRootPart
						game.Debris:AddItem(EnemyBP, 1)
						onAir = true
					else
						
						if EnemyBlocking then
							if EnemyParry then

								local Parry = ParryVFX.Attachment:Clone()
								Parry.Parent = EnemyCharacter.HumanoidRootPart
								emitParticle(Parry)
								soundEmit(ParrySFX, EnemyCharacter)
								StopAnimation(Humanoid, tostring(Combo))
								local Animation = Humanoid:LoadAnimation(Assets.Animations.Parry)
								Animation:Play()
								game.ReplicatedStorage.Remotes.Camera.BigExplosion:FireClient(Player)

								task.delay(2, function()
									Animation:Stop()
								end)

								stun(Humanoid, 2)
								Humanoid.WalkSpeed = 0
								Humanoid.JumpHeight = 0

								task.delay(2, function()
									Humanoid.WalkSpeed = 16
									Humanoid.JumpHeight = 7.2
								end)
							else
								local Block = BlockVFX.Attachment:Clone()
								Block.Parent = EnemyCharacter.HumanoidRootPart
								soundEmit(BlockSFX, EnemyCharacter)
								emitParticle(Block)

								local Color = Color3.fromRGB(255, 176, 66)
								local Size = UDim2.new(5, 0, 5, 0)
								local Font = Enum.Font.Arcade
								DmgIndicator(EnemyCharacter, "Blocking!", Color, Size,Font)
							end
						else
							local Hit = HitVFX.Attachment:Clone()
							Hit.Parent = EnemyCharacter.HumanoidRootPart
							soundEmit(M1SFX, EnemyCharacter)
							emitParticle(Hit)
							local Damage = math.random(3, 6)

							HitCombo.Value += 1

							EnemyHumanoid:TakeDamage(Damage)
							stun(EnemyHumanoid, .31)

							local HitAnim = EnemyHumanoid:LoadAnimation(Assets.Animations.Hit1)
							HitAnim:Play()
							task.delay(.2, function()
								HitAnim:Stop()
							end)

							KnockbackModule.knockback(Character, Character, 5, Character)
							KnockbackModule.knockback(Character, EnemyCharacter, 5.5, Character)

							local Color = Color3.fromRGB(255, 49, 49)
							local Size = UDim2.new(2, 0, 2, 0)
							local Font = Enum.Font.Arcade
							DmgIndicator(EnemyCharacter, Damage, Color, Size,Font)
							local EnemyHighlight = Highlight:Clone()
							EnemyHighlight.Parent = EnemyCharacter

							KnockbackModule.knockback(Character, Character, 5, Character)
							KnockbackModule.knockback(Character, EnemyCharacter, 5, Character)

							TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 0.2}):Play()
							task.delay(.2, function()
								TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 1}):Play()
								task.delay(.12, function()
									EnemyHighlight:Destroy()
								end)
							end)
						end	
					end	
				else
					if EnemyBlocking then
						if EnemyParry then

							local Parry = ParryVFX.Attachment:Clone()
							Parry.Parent = EnemyCharacter.HumanoidRootPart
							emitParticle(Parry)
							soundEmit(ParrySFX, EnemyCharacter)
							StopAnimation(Humanoid, tostring(Combo))
							local Animation = Humanoid:LoadAnimation(Assets.Animations.Parry)
							Animation:Play()
							game.ReplicatedStorage.Remotes.Camera.BigExplosion:FireClient(Player)

							task.delay(2, function()
								Animation:Stop()
							end)

							stun(Humanoid, 2)
							Humanoid.WalkSpeed = 0
							Humanoid.JumpHeight = 0

							task.delay(2, function()
								Humanoid.WalkSpeed = 16
								Humanoid.JumpHeight = 7.2
							end)
						else
							local Block = BlockVFX.Attachment:Clone()
							Block.Parent = EnemyCharacter.HumanoidRootPart
							soundEmit(BlockSFX, EnemyCharacter)
							emitParticle(Block)

							local Color = Color3.fromRGB(255, 176, 66)
							local Size = UDim2.new(5, 0, 5, 0)
							local Font = Enum.Font.Arcade
							DmgIndicator(EnemyCharacter, "Blocking!", Color, Size,Font)
						end
					else
						local Hit = HitVFX.Attachment:Clone()
						Hit.Parent = EnemyCharacter.HumanoidRootPart
						soundEmit(M1SFX, EnemyCharacter)
						emitParticle(Hit)
						local Damage = math.random(3, 6)

						HitCombo.Value += 1

						EnemyHumanoid:TakeDamage(Damage)
						stun(EnemyHumanoid, .31)

						local HitAnim = EnemyHumanoid:LoadAnimation(Assets.Animations.Hit1)
						HitAnim:Play()
						task.delay(.2, function()
							HitAnim:Stop()
						end)

						KnockbackModule.knockback(Character, Character, 5, Character)
						KnockbackModule.knockback(Character, EnemyCharacter, 5.5, Character)

						local Color = Color3.fromRGB(255, 49, 49)
						local Size = UDim2.new(2, 0, 2, 0)
						local Font = Enum.Font.Arcade
						DmgIndicator(EnemyCharacter, Damage, Color, Size,Font)
						local EnemyHighlight = Highlight:Clone()
						EnemyHighlight.Parent = EnemyCharacter

						KnockbackModule.knockback(Character, Character, 5, Character)
						KnockbackModule.knockback(Character, EnemyCharacter, 5, Character)

						TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 0.2}):Play()
						task.delay(.2, function()
							TS:GetTweenObject(EnemyHighlight, Info, {FillTransparency = 1}):Play()
							task.delay(.12, function()
								EnemyHighlight:Destroy()
							end)
						end)
				end
			end	
			else
				local Damage = math.random(7, 15)
				local HitAnim = EnemyHumanoid:LoadAnimation(Assets.Animations.Hit2)
				stun(EnemyHumanoid, 2)
				EnemyHumanoid:TakeDamage(Damage + 2)
				Character:SetAttribute("Attacking", nil)

				if EnemyCharacter.HumanoidRootPart:FindFirstChild("EnemyCharacterAirBP") then
					EnemyCharacter.HumanoidRootPart.EnemyCharacterAirBP:Destroy()
				end
				if Character.HumanoidRootPart:FindFirstChild("CharacterAirBP") then
					Character.HumanoidRootPart.CharacterAirBP:Destroy()
				end

				task.wait(.1)
				
				local enemyAirPos = (EnemyCharacter.HumanoidRootPart.CFrame * CFrame.new(0, -14, -2)).Position
				
				local EnemyBP = Instance.new("BodyPosition")
				EnemyBP.Name = "AirUp"
				EnemyBP.MaxForce = Vector3.new(4e4,4e4,4e4)
				EnemyBP.Position = enemyAirPos
				EnemyBP.P = 4e4
				EnemyBP.Parent = EnemyHumanoid.Parent.HumanoidRootPart
				game.Debris:AddItem(EnemyBP, 1)
				
				task.wait(1)
				onAir = false
			end	
		end
	end)
	if Hitted == false then
		soundEmit(SwingSFX, Character)
	end
	
	if tick() - lastM1 > 1.2 and not onAir then
		Combo = 1
	end
	
	if Combo < 5 then
		Combo += 1
	else
		Combo = 1
	end
	
	if onAir == false then
		local M1Animation = Humanoid:LoadAnimation(Assets.Animations[Combo])
		M1Animation:Play()
	end
	
	lastM1 = tick()
	
	task.delay(.15, function()
		Hitbox:Start()
	end)
	task.delay(.3, function()
		Hitbox:Stop()
		if Combo == 5 then
			task.delay(1, function()
				Character:SetAttribute("Attacking", nil)
			end)
		else
			task.delay(.1, function()
				Character:SetAttribute("Attacking", nil)
			end)
		end


		Hitted = false
		end)

end

return CombatServer