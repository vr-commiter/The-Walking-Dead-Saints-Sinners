local truegear = require "truegear"

local hookIds = {}
local isFirst = true
local weaponHand = 0
local meleeWeaponHand = 0
local LeftHandSMGWeapon = 0
local RightHandSMGWeapon = 0
local playerHealth = 100
local bandageCount = 0
local isLeftJournal = false
local isRightJournal = false
local canRemoveItem = false
local canAddItem = false
local lastInventoryAmmo = 0
local lastChamberAmmo = 1
local isTwoHandMeleeWeapon = false
local isPause = false
local leftHandItem = nil
local rightHandItem = nil
local bowPullTime = 0
local isGrabbedByAttacker = false
local canRegister = true

function Split(str, sep)
	assert(type(str) == 'string' and type(sep) == 'string', 'The arguments must be <string>')
	if sep == '' then return {str} end
	
	local res, from = {}, 1
	repeat
	  local pos = str:find(sep, from)
	  res[#res + 1] = str:sub(from, pos and pos - 1)
	  from = pos and pos + #sep
	until not from
	return res
end

-- 函数: 比较两个字符串中的纯数字部分
local function compare_numbers(str1, str2)
    -- 辅助函数: 从字符串中提取纯数字部分
    local function extract_numbers(s)
        local numbers = {}
        for number in s:gmatch("%d+") do
            table.insert(numbers, number)
        end
        return numbers
    end
    
    -- 辅助函数: 用指定分隔符分割字符串
    local function split_string(s, delimiter)
        local result = {}
        local pattern = string.format("([^%s]+)", delimiter)
        s:gsub(pattern, function(c) table.insert(result, c) end)
        return result
    end

    -- 辅助函数: 提取并收集数字
    local function collect_numbers(s)
        local numbers = {}
        -- 先分割字符串
        local parts = split_string(s, "[_.]")
        -- 提取纯数字部分
        for _, part in ipairs(parts) do
            local nums = extract_numbers(part)
            for _, num in ipairs(nums) do
                table.insert(numbers, num)
            end
        end
        return numbers
    end

    -- 收集两个字符串中的数字部分
    local numbers1 = collect_numbers(str1)
    local numbers2 = collect_numbers(str2)

    -- 比较数字部分
    if #numbers1 ~= #numbers2 then
        return false
    end

    for i = 1, #numbers1 do
        if numbers1[i] ~= numbers2[i] then
            return false
        end
    end

    return true
end

function SendMessage(context)
	if context then
		print(context .. "\n")
		return
	end
	print("nil\n")
end

function PlayAngle(event,tmpAngle,tmpVertical)

	local rootObject = truegear.find_effect(event);

	local angle = (tmpAngle - 22.5 > 0) and (tmpAngle - 22.5) or (360 - tmpAngle)
	
    local horCount = math.floor(angle / 45) + 1
	local verCount = (tmpVertical > 0.1) and -4 or (tmpVertical < 0 and 8 or 0)


	for kk, track in pairs(rootObject.tracks) do
        if tostring(track.action_type) == "Shake" then
            for i = 1, #track.index do
                if verCount ~= 0 then
                    track.index[i] = track.index[i] + verCount
                end
                if horCount < 8 then
                    if track.index[i] < 50 then
                        local remainder = track.index[i] % 4
                        if horCount <= remainder then
                            track.index[i] = track.index[i] - horCount
                        elseif horCount <= (remainder + 4) then
                            local num1 = horCount - remainder
                            track.index[i] = track.index[i] - remainder + 99 + num1
                        else
                            track.index[i] = track.index[i] + 2
                        end
                    else
                        local remainder = 3 - (track.index[i] % 4)
                        if horCount <= remainder then
                            track.index[i] = track.index[i] + horCount
                        elseif horCount <= (remainder + 4) then
                            local num1 = horCount - remainder
                            track.index[i] = track.index[i] + remainder - 99 - num1
                        else
                            track.index[i] = track.index[i] - 2
                        end
                    end
                end
            end
            if track.index then
                local filteredIndex = {}
                for _, v in pairs(track.index) do
                    if not (v < 0 or (v > 19 and v < 100) or v > 119) then
                        table.insert(filteredIndex, v)
                    end
                end
                track.index = filteredIndex
            end
        elseif tostring(track.action_type) ==  "Electrical" then
            for i = 1, #track.index do
                if horCount <= 4 then
                    track.index[i] = 0
                else
                    track.index[i] = 100
                end
            end
            if horCount == 1 or horCount == 8 or horCount == 4 or horCount == 5 then
                track.index = {0, 100}
            end
        end
    end

	truegear.play_effect_by_content(rootObject)
end

function RegisterHooks()

	-- if isFirst == true then
	-- 	isFirst = false
	-- 	SendMessage("--------------------------------")
	-- 	SendMessage("HeartBeat")
	-- 	truegear.play_effect_by_uuid("HeartBeat")
	-- end

	for k,v in pairs(hookIds) do
		UnregisterHook(k, v.id1, v.id2)
	end
		
	hookIds = {}



	local funcName = "/Game/Blueprints/Player/BP_HeadInventorySlot.BP_HeadInventorySlot_C:SetCurrentInventory"
	local hook1, hook2 = RegisterHook(funcName, SetBackpackCurrentInventory)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }


	
	local funcName = "/Game/Blueprints/Player/BP_Backpack.BP_Backpack_C:OnShow"
	local hook1, hook2 = RegisterHook(funcName, BackpackShow)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }	
	
	local funcName = "/Game/Blueprints/Player/BP_Backpack.BP_Backpack_C:OnGripRelease"
	local hook1, hook2 = RegisterHook(funcName, BackpackHide)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnCharacterDeath"
	local hook1, hook2 = RegisterHook(funcName, PlayerDeath)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnPlayerDamaged"
	-- local hook1, hook2 = RegisterHook(funcName, PlayerDamage)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/45Revolver/BP_45Revolver.BP_45Revolver_C:OnInteractPress"
	local hook1, hook2 = RegisterHook(funcName, GetWeaponHand)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Beretta_M9/BP_Beretta_M9.BP_Beretta_M9_C:OnInteractPress"
	local hook1, hook2 = RegisterHook(funcName, GetWeaponHand)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/45Revolver/BP_45Revolver.BP_45Revolver_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, PistolShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Beretta_M9/BP_Beretta_M9.BP_Beretta_M9_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, PistolShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/BoltActionRifle/BP_BoltActionRifle.BP_BoltActionRifle_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, TwoHandRifleShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/DoubleBarrelShotgun/BP_DoubleBarrelShotgun.BP_DoubleBarrelShotgun_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, TwoHandShotgunShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Benelli_SuperNova/BP_Benelli_SuperNova.BP_Benelli_SuperNova_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, TwoHandShotgunShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/LeverActionRifle/BP_LeverActionRifle.BP_LeverActionRifle_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, TwoHandRifleShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/M416/BP_M416.BP_M416_C:ModeFiredRound"
	local hook1, hook2 = RegisterHook(funcName, TwoHandRifleShoot)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Melee/BP_Melee_Weapon_Base.BP_Melee_Weapon_Base_C:EventOnGrabbedDelegate"
	local hook1, hook2 = RegisterHook(funcName, MeleeGetWeaponHand)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Melee/BP_Melee_Weapon_Base.BP_Melee_Weapon_Base_C:BloodyWeaponOnWeaponHit"
	local hook1, hook2 = RegisterHook(funcName, MeleeMajorHit)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Melee/BP_Melee_Weapon_Base.BP_Melee_Weapon_Base_C:OnWeaponRemovedFromStab"
	local hook1, hook2 = RegisterHook(funcName, MeleeMajorHit)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Weapons/Melee/BP_Melee_Weapon_Base.BP_Melee_Weapon_Base_C:StartStab"
	local hook1, hook2 = RegisterHook(funcName, MeleeMajorHit)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Loot/BP_Food_Base.BP_Food_Base_C:FinishConsume"
	local hook1, hook2 = RegisterHook(funcName, Healing)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Loot/BP_Medicine_Base.BP_Medicine_Base_C:FinishConsume"
	local hook1, hook2 = RegisterHook(funcName, Healing)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnHealthUpdated"
	local hook1, hook2 = RegisterHook(funcName, GetHealth)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Props/BP_Bandages.BP_Bandages_C:AttachBandage"
	local hook1, hook2 = RegisterHook(funcName, BandageAttach)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Props/BP_Bandages.BP_Bandages_C:UpdateBandageWinding"
	local hook1, hook2 = RegisterHook(funcName, BandageWinding)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Interactables/Props/BP_Bandages.BP_Bandages_C:FinishBandage"
	local hook1, hook2 = RegisterHook(funcName, Healing)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnGrappleReleasedByAttacker"
	local hook1, hook2 = RegisterHook(funcName, OnGrappleReleasedByAttacker)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnGrappleGrabbedByAttacker"
	local hook1, hook2 = RegisterHook(funcName, OnGrappleGrabbedByAttacker)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:ReceivePointDamage"
	local hook1, hook2 = RegisterHook(funcName, ReceivePointDamage)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:ReceiveRadialDamage"
	local hook1, hook2 = RegisterHook(funcName, ReceiveRadialDamage)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Script/SDIVRPlayerPlugin.SDIWeaponFirearm:ReloadClip"
	local hook1, hook2 = RegisterHook(funcName, AddAmmo)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Script/SDIVRPlayerPlugin.SDIWeaponFirearm:UnloadClip"
	local hook1, hook2 = RegisterHook(funcName, EjectAmmo)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	-- local funcName = "/Script/SDIVRPlayerPlugin.SDIWeaponFirearm:ChamberRound"
	-- local hook1, hook2 = RegisterHook(funcName, Reload)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	-- local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnInventoryAdded"
	-- local hook1, hook2 = RegisterHook(funcName, AddInventoryItem)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	-- local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnInventoryRemoved"
	-- local hook1, hook2 = RegisterHook(funcName, RemoveInventoryItems)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Player/BP_BaseVR3PlayerCharacter.BP_BaseVR3PlayerCharacter_C:OnLanded"
	local hook1, hook2 = RegisterHook(funcName, OnLanded)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/SDIVRPlayerPlugin.SDIWeaponHitCapsuleComponent:OnHeldActorGrabbed"
	local hook1, hook2 = RegisterHook(funcName, OnHeldActorGrabbed)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/SDIVRPlayerPlugin.SDIWeaponHitCapsuleComponent:OnHeldActorDropped"
	local hook1, hook2 = RegisterHook(funcName, OnHeldActorDropped)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }


	local funcName = "/Game/Blueprints/Player/BP_InventoryBodySlot_Base.BP_InventoryBodySlot_Base_C:SetCurrentInventory"
	local hook1, hook2 = RegisterHook(funcName, SetCurrentInventory)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Interactables/Props/BP_Flashlight.BP_Flashlight_C:OnGripRelease"
	local hook1, hook2 = RegisterHook(funcName, OnGripRelease)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Interactables/Props/BP_Flashlight.BP_Flashlight_C:GrabFromInventory"
	local hook1, hook2 = RegisterHook(funcName, GrabFromInventory)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	-- local funcName = "/Game/Blueprints/Player/BP_AmmoPouch.BP_AmmoPouch_C:ReceiveBeginPlay"
	-- local hook1, hook2 = RegisterHook(funcName, SetItemInfo)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/SDIVRPlayerPlugin.SDIInteractiveActorInterface:OnGripPress"
	local hook1, hook2 = RegisterHook(funcName, HandGripPress)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/SDIVRPlayerPlugin.SDIInteractiveActorInterface:OnGripRelease"
	local hook1, hook2 = RegisterHook(funcName, HandGripRelease)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/Blueprints/Player/BP_AmmoPouch.BP_AmmoPouch_C:UpdateItemInfo"
	local hook1, hook2 = RegisterHook(funcName, UpdateItemInfo)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Player/BP_AmmoPouch.BP_AmmoPouch_C:SetCurrentInventory"
	local hook1, hook2 = RegisterHook(funcName, AmmoSetCurrentInventory)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Player/BP_GamePausedUI.BP_GamePausedUI_C:EnableElements"
	local hook1, hook2 = RegisterHook(funcName, EnableElements)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/Blueprints/Player/BP_GamePausedUI.BP_GamePausedUI_C:ReceiveDestroyed"
	local hook1, hook2 = RegisterHook(funcName, HideElements)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }	

	local funcName = "/Script/SDIVRPlayerPlugin.SDIWeaponFirearm:GetChamberedAmmoCount"
	local hook1, hook2 = RegisterHook(funcName, GetChamberedAmmoCount)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }	

	local funcName = "/Script/TWD.TWDWeaponBowV2:GetPullAmount"
	local hook1, hook2 = RegisterHook(funcName, GetPullDistance)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }	

	local funcName = "/Game/Blueprints/Interactables/Loot/BP_Consumable_Base.BP_Consumable_Base_C:FinishConsume"
	local hook1, hook2 = RegisterHook(funcName, Healing)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
			
	local funcName = "/Game/Blueprints/Interactables/Props/Books/Notebook/BP_Notebook.BP_Notebook_C:ReceiveTick"
	local hook1, hook2 = RegisterHook(funcName, NotebookReceiveTick)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
			
	local funcName = "/Game/UI/Widgets/WBP_LoadingScreen.WBP_LoadingScreen_C:ExecuteUbergraph_WBP_LoadingScreen"
	local hook1, hook2 = RegisterHook(funcName, BeginLoadingScreen)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	



	
	local funcName = "/Game/Maps/HubLevel/Hub_Intro_DES.Hub_Intro_DES_C:JournalGripped"
	local hook1, hook2 = RegisterHook(funcName, JournalGripped)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }





	-- local funcName = "/Game/Blueprints/Interactables/Weapons/SawedOff/BP_SawedOff_LowEnd_Crafted.BP_SawedOff_LowEnd_Crafted_C:OnInteractPress"
	-- local hook1, hook2 = RegisterHook(funcName, GetWeaponHand)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Interactables/Weapons/GrenadeLauncher/BP_GrenadeLauncher.BP_GrenadeLauncher_C:ModeFiredRound"
	-- local hook1, hook2 = RegisterHook(funcName, TwoHandShotgunShoot)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Interactables/Weapons/SawedOff/BP_SawedOff_LowEnd_Crafted.BP_SawedOff_LowEnd_Crafted_C:ModeFiredRound"
	-- local hook1, hook2 = RegisterHook(funcName, RifleShoot)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Interactables/Weapons/SMG/BP_SMG_Crafted.BP_SMG_Crafted_C:GrabFromInventory"
	-- local hook1, hook2 = RegisterHook(funcName, SMGGetWeaponHand)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Interactables/Weapons/SMG/BP_SMG_Crafted.BP_SMG_Crafted_C:ModeFiredRound"
	-- local hook1, hook2 = RegisterHook(funcName, SMGShoot)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Interactables/Weapons/Melee/BP_Melee_Chainsaw.BP_Melee_Chainsaw_C:MotorOn"
	-- local hook1, hook2 = RegisterHook(funcName, CHAINSAWMotorOn)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	-- local funcName = "/Game/Blueprints/Interactables/Weapons/Melee/BP_Melee_Chainsaw.BP_Melee_Chainsaw_C:MotorOff"
	-- local hook1, hook2 = RegisterHook(funcName, CHAINSAWMotorOff)
	-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	

end


-- *******************************************************************

function OnPhysicalInteractPush()
	SendMessage("--------------------------------")
	SendMessage("OnPhysicalInteractPush")
end

function BeginLoadingScreen()
	SendMessage("--------------------------------")
	SendMessage("BeginLoadingScreen")
	playerHealth = 50
	isGrabbedByAttacker = false
	leftHandItem = nil
	rightHandItem = nil
	isTwoHandMeleeWeapon = false
	canAddItem = false
	canRemoveItem = false
end


local notebookReceiveTime = 0
local canNotebookRelease = false
function NotebookReceiveTick(self)
	if os.clock() - notebookReceiveTime < 0.1 then
		notebookReceiveTime = os.clock()
		return
	end
	notebookReceiveTime = os.clock()
	canNotebookRelease = true
	SendMessage("--------------------------------")
	SendMessage("RightChestSlotOutputItem")
	truegear.play_effect_by_uuid("RightChestSlotOutputItem")
	SendMessage(self:get():GetFullName())	
end

function NotebookRelease()
	if os.clock() - notebookReceiveTime >= 0.1 then
		if canNotebookRelease then
			canNotebookRelease = false
			SendMessage("--------------------------------")
			SendMessage("RightChestSlotInputItem")
			truegear.play_effect_by_uuid("RightChestSlotInputItem")
		end
	end
end

LoopAsync(100,NotebookRelease)







function OnGrappleGrabbedByAttacker(self)
	-- SendMessage("--------------------------------")
	-- SendMessage("OnGrappleGrabbedByAttacker")
	SendMessage(self:get():GetFullName())	
	isGrabbedByAttacker = true
end

function OnGrappleReleasedByAttacker(self)
	-- SendMessage("--------------------------------")
	-- SendMessage("OnGrappleReleasedByAttacker")
	SendMessage(self:get():GetFullName())	
	isGrabbedByAttacker = false
end

function GetPullDistance(self)

	if self:get():GetPropertyValue("LastPullAmount") == 0 then
		return
	end
	if os.clock() - bowPullTime < 0.13 then
		return
	end
	bowPullTime = os.clock()
	SendMessage("--------------------------------")
	SendMessage("GetPullDistance")
	truegear.play_effect_by_uuid("BowStringPull")
	SendMessage(self:get():GetFullName())
	SendMessage(tostring(self:get():GetPropertyValue("LastPullAmount")))
	
end




function GetChamberedAmmoCount(self)
	if lastChamberAmmo == 0 and self:get():GetPropertyValue("RepChamberedAmmoCount") == 1 then
		local hand = self:get():GetPropertyValue("BP_PrimaryHeldHand"):GetControllerHand()
		if hand ~= 1 then
			SendMessage("--------------------------------")
			SendMessage("LeftDownReload")
			truegear.play_effect_by_uuid("LeftDownReload")
		else
			SendMessage("--------------------------------")
			SendMessage("RightDownReload")
			truegear.play_effect_by_uuid("RightDownReload")
		end
	end
	lastChamberAmmo = self:get():GetPropertyValue("RepChamberedAmmoCount")
end



function SetBackpackCurrentInventory(self)	
	if canAddItem then
		canAddItem = false
		SendMessage("--------------------------------")
		SendMessage("LeftBackSlotInputItem1111")
		truegear.play_effect_by_uuid("LeftBackSlotInputItem")
		SendMessage(self:get():GetFullName())
	end
	
end

function HideElements(self)
	SendMessage("--------------------------------")
	SendMessage("UnPause")
	isPause = false
end

function EnableElements(self)
	SendMessage("--------------------------------")
	SendMessage("Pause")
	isPause = true
end

function UpdateItemInfo(self,ItemInfo)
	local item = ItemInfo:get()
	if item['AmmoStock'] < lastInventoryAmmo then
		SendMessage("--------------------------------")
		SendMessage("ChestSlotOutputItem")
		truegear.play_effect_by_uuid("ChestSlotOutputItem")
		SendMessage(self:get():GetFullName())
		SendMessage(ItemInfo:get():GetFullName())
		SendMessage(tostring(item['bShowStock']))
		SendMessage(item['AmmoClip'])
		SendMessage(item['AmmoStock'])
		SendMessage(item['AmmoName']:ToString())
	end	
	lastInventoryAmmo = item['AmmoStock']
end

function AmmoSetCurrentInventory(self)
	SendMessage("--------------------------------")
	SendMessage("ChestSlotInputItem")
	truegear.play_effect_by_uuid("ChestSlotInputItem")
end

function JournalGripped(self,HeldActor,GrabbedBy,hand,HandPtr)
	SendMessage("--------------------------------")
	SendMessage("RightChestSlotOutputItem")
	truegear.play_effect_by_uuid("RightChestSlotOutputItem")
	SendMessage(tostring(hand:get()))
	if hand:get() == 1 then
		isRightJournal = true
	else
		isLeftJournal = true
	end	
end

local canDroppedActor = true
function HandGripPress(self,hand,Component,Entry)		
	local gripHand = hand:get():GetControllerHand()
	canDroppedActor = true
	if gripHand == 0 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandPickupItem2")
		truegear.play_effect_by_uuid("LeftHandPickupItem")
		if rightHandItem ~= nil then
			isTwoHandMeleeWeapon = true
			if compare_numbers(Component:get():GetFullName(),rightHandItem) then
				leftHandItem = rightHandItem
				rightHandItem = nil
				canDroppedActor = false
				meleeWeaponHand = 0
			end	
		end
		SendMessage(tostring(rightHandItem))		
	
	end
	if gripHand == 1 then
		SendMessage("--------------------------------")
		SendMessage("RightHandPickupItem2")
		truegear.play_effect_by_uuid("RightHandPickupItem")
		if leftHandItem ~= nil then
			isTwoHandMeleeWeapon = true
			if compare_numbers(Component:get():GetFullName(),leftHandItem) then
				rightHandItem = leftHandItem
				leftHandItem = nil
				canDroppedActor = false
				meleeWeaponHand = 1
			end
		end
		SendMessage(tostring(leftHandItem))

	end	
	SendMessage(tostring(Component:get():GetFullName()))
	SendMessage(tostring(Entry:get():GetPropertyValue("Actor"):GetFullName()))

	canRemoveItem = true
end

function Empty()
end

function HandGripRelease(self,hand)		
	SendMessage("--------------------------------")
	SendMessage("HandGripRelease")
	isTwoHandMeleeWeapon = false
	canAddItem = true
	if leftHandItem == nil or rightHandItem == nil then
		leftHandItem = nil
		rightHandItem = nil
	end


	-- local releaseHand = hand:get():GetControllerHand()
	-- if releaseHand == 0 and leftHandItem ~= nil then
	-- 	leftHandItem = nil
	-- end
	-- if releaseHand == 1 and rightHandItem ~= nil then
	-- 	rightHandItem = nil
	-- end	
	-- SendMessage(tostring(hand:get():GetControllerHand()))


	if isLeftJournal == false and isRightJournal == false then
		return
	end
	if isLeftJournal == true and releaseHand == 0 then
		SendMessage("--------------------------------")
		SendMessage("RightChestSlotInputItem")
		truegear.play_effect_by_uuid("RightChestSlotInputItem")
		SendMessage(tostring(hand:get():GetControllerHand()))
		isLeftJournal = false
		return
	end
	if isRightJournal == true and releaseHand == 1 then
		SendMessage("--------------------------------")
		SendMessage("RightChestSlotInputItem")
		truegear.play_effect_by_uuid("RightChestSlotInputItem")
		SendMessage(tostring(hand:get():GetControllerHand()))
		isRightJournal = false
		return
	end
end

function TutorialJournalGripped()
	SendMessage("--------------------------------")
	SendMessage("RightChestSlotOutputItem")
	truegear.play_effect_by_uuid("RightChestSlotOutputItem")
end

function TutorialJournalDropped()
	SendMessage("--------------------------------")
	SendMessage("RightChestSlotInputItem")
	truegear.play_effect_by_uuid("RightChestSlotInputItem")
end

function SetItemInfo(self)
	SendMessage("--------------------------------")
	SendMessage("SetItemInfo")
end

function OnGripRelease(self)
	SendMessage("--------------------------------")
	SendMessage("LeftChestSlotInputItem")
	truegear.play_effect_by_uuid("LeftChestSlotInputItem")
end

function GrabFromInventory(self)
	SendMessage("--------------------------------")
	SendMessage("LeftChestSlotInputItem")
	truegear.play_effect_by_uuid("LeftChestSlotInputItem")
end

function SetCurrentInventory(self)
	if canRemoveItem == false and canAddItem == false then
		return
	end
	local slotId = self:get():GetPropertyValue("slotIdx")
	if canRemoveItem == true then
		canRemoveItem = false
		if slotId == 1 then
			SendMessage("--------------------------------")
			SendMessage("LeftHipSlotOutputItem")
			truegear.play_effect_by_uuid("LeftHipSlotOutputItem")
		elseif slotId == 2 then
			SendMessage("--------------------------------")
			SendMessage("RightHipSlotOutputItem")
			truegear.play_effect_by_uuid("RightHipSlotOutputItem")
		elseif slotId == 4 then
			SendMessage("--------------------------------")
			SendMessage("RightBackSlotOutputItem")
			truegear.play_effect_by_uuid("RightBackSlotOutputItem")
		end
		return
	end
	if canAddItem == true then
		if slotId == 1 then
			SendMessage("--------------------------------")
			SendMessage("LeftHipSlotInputItem")
			truegear.play_effect_by_uuid("LeftHipSlotInputItem")
			canAddItem = false
		elseif slotId == 2 then
			SendMessage("--------------------------------")
			SendMessage("RightHipSlotInputItem")
			truegear.play_effect_by_uuid("RightHipSlotInputItem")
			canAddItem = false
		elseif slotId == 4 then
			SendMessage("--------------------------------")
			SendMessage("RightBackSlotInputItem")
			truegear.play_effect_by_uuid("RightBackSlotInputItem")
			canAddItem = false
		end
	end
	SendMessage(tostring(self:get():GetFullName()))
	SendMessage(tostring(self:get():GetPropertyValue("slotIdx")))
end	

function OnHeldActorGrabbed(self,HeldActor,GrabbedBy,hand)
	if hand:get() ~= 1 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandPickupItem1")
		SendMessage(HeldActor:get():GetFullName())
		leftHandItem = HeldActor:get():GetFullName()
		-- truegear.play_effect_by_uuid("LeftHandPickupItem")
	else
		SendMessage("--------------------------------")
		SendMessage("RightHandPickupItem1")
		SendMessage(HeldActor:get():GetFullName())
		rightHandItem = HeldActor:get():GetFullName()
		-- truegear.play_effect_by_uuid("RightHandPickupItem")
	end
	canRemoveItem = true
	SendMessage(tostring(hand:get()))
end

local actorDroppedTime = 0
function OnHeldActorDropped(self,HeldActor)
	if os.clock() - actorDroppedTime < 0.1 then
		return
	end
	actorDroppedTime = os.clock()
	if canDroppedActor == false then
		canDroppedActor = true
		return
	end
	SendMessage("--------------------------------")
	SendMessage("OnHeldActorDropped")
	SendMessage(HeldActor:get():GetFullName())
	
	if HeldActor:get():GetFullName() == leftHandItem then
		leftHandItem = nil
	elseif HeldActor:get():GetFullName() == rightHandItem then
		rightHandItem = nil
	end
	isTwoHandMeleeWeapon = false
end

function OnLanded(self,Hit)
	SendMessage("--------------------------------")
	SendMessage("FallDamage")
	truegear.play_effect_by_uuid("FallDamage")
	SendMessage(Hit:get():GetFullName())
end

-- function AddInventoryItem(self,Inv)
-- 	if canAddItem == false then
-- 		return
-- 	end
-- 	canAddItem = false
-- 	SendMessage("--------------------------------")
-- 	SendMessage("AddInventoryItem")
-- 	SendMessage(self:get():GetFullName())
-- 	SendMessage(Inv:get():GetFullName())
-- 	local slot = Inv:get():GetPropertyValue("Slot")
-- 		if slot:IsValid() == false then
-- 		SendMessage("slot is not found")
-- 		return
-- 	end
-- 	local slotIdx = slot:GetPropertyValue("slotIdx")
-- 	if slotIdx:IsValid() == false then
-- 		SendMessage("slotIdx is not found")
-- 		return
-- 	end	
-- 	SendMessage(tostring(Inv:get():GetPropertyValue("Slot"):GetPropertyValue("slotIdx"):GetFullName()))
-- end

-- function RemoveInventoryItems(self,Inv)
-- 	if canRemoveItem == false then
-- 		return
-- 	end
-- 	canRemoveItem = false
-- 	SendMessage("--------------------------------")
-- 	SendMessage("RemoveInventoryItems")	
-- 	SendMessage(self:get():GetFullName())
-- 	SendMessage(Inv:get():GetFullName())
-- 	local slot = Inv:get():GetPropertyValue("Slot")
-- 		if slot:IsValid() == false then
-- 		SendMessage("slot is not found")
-- 		return
-- 	end
-- 	local slotIdx = slot:GetPropertyValue("slotIdx")
-- 	if slotIdx:IsValid() == false then
-- 		SendMessage("slotIdx is not found")
-- 		return
-- 	end	
-- 	SendMessage(tostring(Inv:get():GetPropertyValue("Slot"):GetPropertyValue("slotIdx"):GetFullName()))
-- end

-- *******************************************************************

function EjectAmmo(self)
	SendMessage("--------------------------------")
	local hand = self:get():GetPropertyValue("BP_PrimaryHeldHand"):GetControllerHand()
	if hand ~= 1 then
		SendMessage("--------------------------------")
		SendMessage("LeftMagazineEjected")
		truegear.play_effect_by_uuid("LeftMagazineEjected")
	else
		SendMessage("--------------------------------")
		SendMessage("RightMagazineEjected")
		truegear.play_effect_by_uuid("RightMagazineEjected")
	end
end

function AddAmmo(self)
	SendMessage("--------------------------------")
	local hand = self:get():GetPropertyValue("BP_PrimaryHeldHand"):GetControllerHand()
	if hand ~= 1 then
		SendMessage("--------------------------------")
		SendMessage("LeftReloadAmmo")
		truegear.play_effect_by_uuid("LeftReloadAmmo")
	else
		SendMessage("--------------------------------")
		SendMessage("RightReloadAmmo")
		truegear.play_effect_by_uuid("RightReloadAmmo")
	end
end

function Reload(self,Amt)
	-- SendMessage("--------------------------------")
	if Amt:get() == 1 then
		return
	end
	local hand = self:get():GetPropertyValue("BP_PrimaryHeldHand"):GetControllerHand()
	if hand ~= 1 then
		-- SendMessage("--------------------------------")
		-- SendMessage("LeftDownReload")
		truegear.play_effect_by_uuid("LeftDownReload")
	else
		-- SendMessage("--------------------------------")
		-- SendMessage("RightDownReload")
		truegear.play_effect_by_uuid("RightDownReload")
	end
	-- SendMessage(tostring(Amt:get()))
end

function ReceivePointDamage(self,DamageType,HitLocation,HitNormal,HitComponent,BoneName,ShotFromDirection,InstigatedBy,DamageCauser,HitInfo)
	SendMessage("--------------------------------")
	local playerController = self:get():GetPropertyValue('Controller')
	if playerController:IsValid() == false then 
		SendMessage("playerController is not found")
		return
	end
	local playerRotation = playerController:GetPropertyValue('ControlRotation')
	if playerRotation:IsValid() == false then 
		SendMessage("playerRotation is not found")
		return
	end
	local enemyRotation = DamageCauser:get():GetPropertyValue('ControlRotation')
	if enemyRotation:IsValid() == false then 
		SendMessage("enemyRotation is not found")
		return
	end

	local angleYaw = playerRotation.Yaw - enemyRotation.Yaw
	angleYaw = angleYaw + 180
	if angleYaw > 360 then 
		angleYaw = angleYaw - 360
	end

	SendMessage("PlayerBulletDamage," .. angleYaw .. ",0")

	PlayAngle("PlayerBulletDamage",angleYaw,0)

	SendMessage(self:get():GetFullName())
	SendMessage(DamageCauser:get():GetFullName())
	SendMessage(tostring(playerRotation.Yaw))
	SendMessage(tostring(enemyRotation.Yaw))
end

function ReceiveRadialDamage(self,DamageReceived,DamageType,Origin,HitInfo,InstigateBy,DamageCauser)
	SendMessage("--------------------------------")
	local playerController = self:get():GetPropertyValue('Controller')
	if playerController:IsValid() == false then 
		SendMessage("playerController is not found")
		return
	end
	local playerRotation = playerController:GetPropertyValue('ControlRotation')
	if playerRotation:IsValid() == false then 
		SendMessage("playerRotation is not found")
		return
	end
	local enemyRotation = DamageCauser:get():GetPropertyValue('ControlRotation')
	if enemyRotation:IsValid() == false then 
		SendMessage("enemyRotation is not found")
		return
	end

	local angleYaw = playerRotation.Yaw - enemyRotation.Yaw
	angleYaw = angleYaw + 180
	if angleYaw > 360 then 
		angleYaw = angleYaw - 360
	end

	SendMessage("DefaultDamage," .. angleYaw .. ",0")

	PlayAngle("DefaultDamage",angleYaw,0)

	SendMessage(self:get():GetFullName())
	SendMessage(DamageCauser:get():GetFullName())
	SendMessage(tostring(playerRotation.Yaw))
	SendMessage(tostring(enemyRotation.Yaw))
end

function BackpackShow(self)
	SendMessage("--------------------------------")
	SendMessage("LeftBackSlotOutputItem")
	truegear.play_effect_by_uuid("LeftBackSlotOutputItem")
end

function BackpackHide(self)
	SendMessage("--------------------------------")
	SendMessage("LeftBackSlotInputItem")
	truegear.play_effect_by_uuid("LeftBackSlotInputItem")
end

function PlayerDeath(self)
	SendMessage("--------------------------------")
	SendMessage("PlayerDeath")
	truegear.play_effect_by_uuid("PlayerDeath")
	isTwoHandMeleeWeapon = false
	leftHandItem = nil
	rightHandItem = nil
	canAddItem = false
end


function GetWeaponHand(self,Type,Hand)
	SendMessage("--------------------------------")
	SendMessage("WeaponHand")
	SendMessage(Hand:get():GetFullName())
	SendMessage(tostring(Type:get()))
	weaponHand = Hand:get():GetControllerHand()
end

function PistolShoot(self)	
	if weaponHand == 0 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandPistolShoot")
		truegear.play_effect_by_uuid("LeftHandPistolShoot")
	else
		SendMessage("--------------------------------")
		SendMessage("RightHandPistolShoot")
		truegear.play_effect_by_uuid("RightHandPistolShoot")
	end
end

function ShotgunShoot(self)	
	if weaponHand == 0 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandShotgunShoot")
		truegear.play_effect_by_uuid("LeftHandShotgunShoot")
	else
		SendMessage("--------------------------------")
		SendMessage("RightHandShotgunShoot")
		truegear.play_effect_by_uuid("RightHandShotgunShoot")
	end
end

function TwoHandShotgunShoot(self)	
	SendMessage("--------------------------------")
	SendMessage("LeftHandShotgunShoot")
	truegear.play_effect_by_uuid("LeftHandShotgunShoot")
	SendMessage("RightHandShotgunShoot")
	truegear.play_effect_by_uuid("RightHandShotgunShoot")
end

function RifleShoot(self)	
	if weaponHand == 0 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandRifleShoot")
		truegear.play_effect_by_uuid("LeftHandRifleShoot")
	else
		SendMessage("--------------------------------")
		SendMessage("RightHandRifleShoot")
		truegear.play_effect_by_uuid("RightHandRifleShoot")
	end
end

function TwoHandRifleShoot(self)	
	SendMessage("--------------------------------")
	SendMessage("LeftHandRifleShoot")
	truegear.play_effect_by_uuid("LeftHandRifleShoot")
	SendMessage("RightHandRifleShoot")
	truegear.play_effect_by_uuid("RightHandRifleShoot")
end

function SMGGetWeaponHand(self, Grabber, Hand)	
	if Hand:get() == 0 then
		LeftHandSMGWeapon = self:get():GetAddress()
		if RightHandSMGWeapon == LeftHandSMGWeapon then
			RightHandSMGWeapon = 0
		end
	else
		RightHandSMGWeapon = self:get():GetAddress()
		if RightHandSMGWeapon == LeftHandSMGWeapon then
			LeftHandSMGWeapon = 0
		end
	end
end

function SMGShoot(self)	
	if LeftHandSMGWeapon == self:get():GetAddress() then
		SendMessage("--------------------------------")
		SendMessage("LeftHandRifleShoot")
		truegear.play_effect_by_uuid("LeftHandRifleShoot")
	end				
	if RightHandSMGWeapon == self:get():GetAddress() then
		SendMessage("--------------------------------")
		SendMessage("RightHandRifleShoot")
		truegear.play_effect_by_uuid("RightHandRifleShoot")
	end
end

function MeleeGetWeaponHand(self, HeldActor, GrabbedBy, Hand)	
	SendMessage("--------------------------------")
	SendMessage("MeleeWeaponHand")
	SendMessage(Hand:get())
	meleeWeaponHand = Hand:get()
end

function MeleeMajorHit(self)
	if isTwoHandMeleeWeapon and (rightHandItem == nil or leftHandItem == nil) then
		SendMessage("--------------------------------")
		SendMessage("LeftHandMeleeMajorHit")
		SendMessage("RightHandMeleeMajorHit")
		truegear.play_effect_by_uuid("LeftHandMeleeMajorHit")
		truegear.play_effect_by_uuid("RightHandMeleeMajorHit")
	elseif meleeWeaponHand == 0 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandMeleeMajorHit")
		truegear.play_effect_by_uuid("LeftHandMeleeMajorHit")
	else
		SendMessage("--------------------------------")
		SendMessage("RightHandMeleeMajorHit")
		truegear.play_effect_by_uuid("RightHandMeleeMajorHit")
	end
	SendMessage(self:get():GetFullName())
	SendMessage(leftHandItem)
	SendMessage(rightHandItem)
	SendMessage(tostring(isTwoHandMeleeWeapon))

end

function Healing(self)
	SendMessage("--------------------------------")
	SendMessage("Healing")
	truegear.play_effect_by_uuid("Healing")
	bandageCount = 0
end

function GetHealth(self, PrevHealth, NewHealth)
	playerHealth = NewHealth:get()
end

function BandageAttach(self)
	local hand = self:get():GetPropertyValue("BandageAttachHand"):GetControllerHand()
	if hand ~= 1 then			
		SendMessage("--------------------------------")
		SendMessage("RightHandPickupItem")
		truegear.play_effect_by_uuid("RightHandPickupItem")
	else
		SendMessage("--------------------------------")
		SendMessage("LeftHandPickupItem")
		truegear.play_effect_by_uuid("LeftHandPickupItem")
	end
	
end

function BandageWinding(self)
	local hand = self:get():GetPropertyValue("BandageAttachHand"):GetControllerHand()
	bandageCount = bandageCount + 1
	if bandageCount % 25 == 0 then
		if hand ~= 1 then
			SendMessage("--------------------------------")
			SendMessage("LeftHandPickupItem")
			truegear.play_effect_by_uuid("LeftHandPickupItem")
		else
			SendMessage("--------------------------------")
			SendMessage("RightHandPickupItem")
			truegear.play_effect_by_uuid("RightHandPickupItem")
		end
	end
end

function MeleeHit(self)
	SendMessage("--------------------------------")
	SendMessage("LeftHandMeleeHit")
	truegear.play_effect_by_uuid("LeftHandMeleeHit")
	SendMessage("RightHandMeleeHit")
	truegear.play_effect_by_uuid("RightHandMeleeHit")
end

function HeartBeat()
	if isPause then
		return
	end
	if playerHealth < 33 and playerHealth > 0 then
		SendMessage("--------------------------------")
		SendMessage("HeartBeat")
		truegear.play_effect_by_uuid("HeartBeat")
	end
end

function GrabbedByAttacker()
	if isPause then
		return
	end
	if isGrabbedByAttacker then
		SendMessage("--------------------------------")
		SendMessage("GrabbedByAttacker")
		truegear.play_effect_by_uuid("GrabbedByAttacker")
	end
end


truegear.seek_by_uuid("DefaultDamage")
truegear.seek_by_uuid("PlayerBulletDamage")
truegear.init("916840", "TWD")


function CheckPlayerSpawned()
	RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
		if canRegister then
			local ran, errorMsg = pcall(RegisterHooks)
			print(tostring(ran))
			if ran then
				canRegister = false
				SendMessage("--------------------------------")
				SendMessage("SuccessHeartBeat")
				truegear.play_effect_by_uuid("HeartBeat")
			else
				print(errorMsg)
				-- local funcName = "/Game/Maps/SP_GardenDistrict_BreakoutMaps/SP_GardenDistrict_Tutorial/Map_Master_GD_Tutorial.Map_Master_GD_Tutorial_C:JournalGripped"
				-- local hook1, hook2 = RegisterHook(funcName, TutorialJournalGripped)
				-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }	
	
				-- local funcName = "/Game/Maps/SP_GardenDistrict_BreakoutMaps/SP_GardenDistrict_Tutorial/Map_Master_GD_Tutorial.Map_Master_GD_Tutorial_C:JournalDropped"
				-- local hook1, hook2 = RegisterHook(funcName, TutorialJournalDropped)
				-- hookIds[funcName] = { id1 = hook1; id2 = hook2 }
			end
		end
	end)
end

-- function CheckPlayerSpawned()
-- 	RegisterHooks()
-- end

SendMessage("TrueGear Mod is Loaded");
CheckPlayerSpawned()

LoopAsync(1000, HeartBeat)
LoopAsync(300, GrabbedByAttacker)