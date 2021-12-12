
--[[----------------------------------------------------------
	EVENTS COMPONENT
  ]]----------------------------------------------------------
	local FTC = FTC

	--[[ 
	 * Register Event Listeners
	 * --------------------------------
	 * Called by FTC:Initialize()
	 * --------------------------------
	 ]]--
	function FTC:RegisterEvents()

		-- User Interface Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_PLAYER_ACTIVATED				, FTC.OnPlayerActivated )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_ACTION_LAYER_POPPED			, FTC.OnLayerChange )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_ACTION_LAYER_PUSHED			, FTC.OnLayerChange )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_SCREEN_RESIZED				, FTC.OnScreenResize )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_SKILL_POINTS_CHANGED			, FTC.OnAbilitiesChanged )

		-- Hook ChatSystem
		-- FTC.HookChat()

		-- Target Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_RETICLE_TARGET_CHANGED		, FTC.OnTargetChanged )
			
		-- Attribute Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_POWER_UPDATE					, FTC.OnPowerUpdate )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED	, FTC.OnVisualAdded ) 
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED , FTC.OnVisualUpdate )	
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED , FTC.OnVisualRemoved )

		-- Player State Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_PLAYER_COMBAT_STATE			, FTC.OnCombatState )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_STEALTH_STATE_CHANGED			, FTC.OnStealthState )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_UNIT_DEATH_STATE_CHANGED		, FTC.OnDeath )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_WEREWOLF_STATE_CHANGED		, FTC.OnWerewolf )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_BEGIN_SIEGE_CONTROL			, FTC.OnSiege )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_END_SIEGE_CONTROL				, FTC.OnSiege )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_MOUNTED_STATE_CHANGED			, FTC.OnMount )
		
		-- Action Bar Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_ACTIVE_QUICKSLOT_CHANGED		, FTC.OnQuickslotChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_ACTION_UPDATE_COOLDOWNS		, FTC.OnUpdateCooldowns )

		-- Buff Events
		EVENT_MANAGER:RegisterForEvent( "FTC",	EVENT_EFFECT_CHANGED				, FTC.OnEffectChanged )
		EVENT_MANAGER:AddFilterForEvent("FTC",	EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER) 
		EVENT_MANAGER:RegisterForEvent( "FTC2", EVENT_EFFECT_CHANGED				, FTC.OnEffectChanged )
		EVENT_MANAGER:AddFilterForEvent("FTC2", EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER_PET)	 
		EVENT_MANAGER:RegisterForEvent( "FTC3", EVENT_EFFECT_CHANGED				, FTC.OnEffectChanged )
		EVENT_MANAGER:AddFilterForEvent("FTC3", EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
		-- Combat Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_COMBAT_EVENT					, FTC.OnCombatEvent )

		-- Group Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_GROUP_MEMBER_JOINED			, FTC.OnGroupChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_GROUP_MEMBER_LEFT				, FTC.OnGroupChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_LEADER_UPDATE					, FTC.OnGroupChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_GROUP_MEMBER_CONNECTED_STATUS , FTC.OnGroupChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_GROUP_MEMBER_ROLE_CHANGED	   , FTC.OnGroupChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_ACTIVE_COMPANION_STATE_CHANGED , FTC.OnGroupChanged )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_GROUP_SUPPORT_RANGE_UPDATE	, FTC.OnGroupRange )
		
		-- Experience Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_EXPERIENCE_UPDATE				, FTC.OnXPUpdate )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_ALLIANCE_POINT_UPDATE			, FTC.OnAPUpdate )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_LEVEL_UPDATE					, FTC.OnLevel )
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_CHAMPION_POINT_UPDATE			, FTC.OnLevel )

		-- Stats Events
		EVENT_MANAGER:RegisterForEvent( "FTC" , EVENT_MAP_PING						, FTC.OnPing )
	end


--[[----------------------------------------------------------
	USER INTERFACE EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles UI Layer Changes
	 * --------------------------------
	 * Called by EVENT_ACTION_LAYER_POPPED
	 * Called by EVENT_ACTION_LAYER_PUSHED
	 * --------------------------------
	 ]]--
	function FTC.OnLayerChange( eventCode, layerIndex, activeLayerIndex )
		FTC:ToggleVisibility( activeLayerIndex )
	end

	--[[ 
	 * Handles Interface Startup
	 * --------------------------------
	 * Called by EVENT_PLAYER_ACTIVATED
	 * --------------------------------
	 ]]--
	function FTC:OnPlayerActivated()
		EVENT_MANAGER:UnregisterForEvent( "FTC" , EVENT_PLAYER_ACTIVATED )

		-- Show welcome message
		FTC.Welcome()

		-- Setup Combat Log
		if FTC.init.Log then
			FTC.Log:Print( GetString(FTC_LongInfo) , {1,0.8,0} )
		end

		if FTC.init.Frames then
			FTC.Frames:SetupPlayer()
			FTC.Frames:SetupTarget()
			FTC.Frames:SetupGroup()
		end
	end

	--[[ 
	 * Handles UI Rescaling
	 * --------------------------------
	 * Called by EVENT_SCREEN_RESIZED
	 * Called by EVENT_ACTION_LAYER_PUSHED
	 * --------------------------------
	 ]]--
	function FTC.OnScreenResize()
		FTC.UI:TopLevelWindow( "FTC_UI" , GuiRoot , {GuiRoot:GetWidth(),GuiRoot:GetHeight()} , {CENTER,CENTER,0,0} , false )
	end

	--[[ 
	 * Handles Ability Unlocking
	 * --------------------------------
	 * Called by EVENT_ABILITY_LIST_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnAbilitiesChanged()
		FTC:GetAbilityIcons()
	end


--[[----------------------------------------------------------
	TARGET EVENTS
  ]]----------------------------------------------------------
 
	--[[ 
	 * Handles Reticle Target Changes
	 * --------------------------------
	 * Called by EVENT_RETICLE_TARGET_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnTargetChanged()
		FTC.Target:Update() 
	end


--[[----------------------------------------------------------
	ATTRIBUTE EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles Attribute Changes
	 * --------------------------------
	 * Called by EVENT_POWER_UPDATE
	 * --------------------------------
	 ]]--
	function FTC.OnPowerUpdate( eventCode , unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax )
		
		-- Player Updates
		if ( unitTag == 'player' ) then
		
			-- Health, Magicka, and Stamina
			if ( powerType == POWERTYPE_HEALTH or powerType == POWERTYPE_MAGICKA or powerType == POWERTYPE_STAMINA ) then
				if ( FTC.init.SCT ) then FTC.SCT:ResourceAlert( unitTag , powerType , powerValue , powerMax ) end
				FTC.Player:UpdateAttribute( unitTag , powerType , powerValue , powerMax , powerEffectiveMax )
				
			-- Ultimate
			elseif ( powerType == POWERTYPE_ULTIMATE ) then
				FTC.Player:UpdateUltimate( powerValue , powerMax , powerEffectiveMax )
				
			-- Mount Stamina
			elseif ( powerType == POWERTYPE_MOUNT_STAMINA ) then
				if ( FTC.init.Frames ) then FTC.Frames:UpdateMount( powerValue , powerMax , powerEffectiveMax ) end 
			
			-- Werewolf
			elseif ( powerType == POWERTYPE_WEREWOLF ) then
				if ( FTC.init.Frames ) then FTC.Frames:UpdateWerewolf( powerValue, powerMax, powerEffectiveMax ) end
			end

		-- Target Updates
		elseif ( unitTag == 'reticleover' ) then
		
			-- Health
			if ( powerType == POWERTYPE_HEALTH ) then
				FTC.Player:UpdateAttribute( unitTag , powerType , powerValue , powerMax , powerEffectiveMax )
			end
		
		-- Siege Updates
		elseif ( unitTag == 'controlledsiege' ) then
			
			-- Health
			if ( powerType == POWERTYPE_HEALTH ) then
				if ( FTC.init.Frames ) then FTC.Frames:UpdateSiege( powerValue , powerMax , powerEffectiveMax ) end
			end

		-- Group Updates
		elseif ( IsUnitGrouped('player') and string.sub(unitTag, 0, 5) == "group" or unitTag == "companion" ) then

			-- Health
			if ( powerType == POWERTYPE_HEALTH ) then
				if ( FTC.init.Frames ) then 
					FTC.Player:UpdateAttribute( unitTag , powerType , powerValue , powerMax , powerEffectiveMax )
				end
			end
		end
	end

	--[[ 
	 * Handles New Visualizers
	 * --------------------------------
	 * Called by EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED
	 * --------------------------------
	 ]]--
	function FTC.OnVisualAdded( eventCode , unitTag, unitAttributeVisual, statType, attributeType, powerType, value, maxValue )

		-- Only track health
		if ( powerType ~= POWERTYPE_HEALTH ) then return end

		-- Only track Player, Target, and Group
		if ( unitTag ~= "player" and unitTag ~= "reticleover" and string.match(unitTag,"group") == nil ) then return end

		-- Health Regeneration
		if ( unitAttributeVisual == ATTRIBUTE_VISUAL_INCREASED_REGEN_POWER or unitAttributeVisual == ATTRIBUTE_VISUAL_DECREASED_REGEN_POWER ) then
			
			-- Display regen indicator
			if ( FTC.init.Frames and ( unitTag == "player" or unitTag == "reticleover" ) ) then FTC.Frames:Regen(unitTag,unitAttributeVisual,powerType,2000) end
			
			-- Display cleanse alert
			if ( FTC.init.SCT and unitTag == "player" and unitAttributeVisual == ATTRIBUTE_VISUAL_DECREASED_REGEN_POWER ) then FTC.SCT:Cleanse() end
		
		-- Damage Shields 
		elseif ( unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING and value > 0) then
			if ( FTC.init.Frames ) then FTC.Player:UpdateShield( unitTag , value , maxValue ) end
		end
	end

	--[[ 
	 * Handles Updated Visualizers
	 * --------------------------------
	 * Called by EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED
	 * --------------------------------
	 ]]--			  
	function FTC.OnVisualUpdate( eventCode , unitTag, unitAttributeVisual, statType, attributeType, powerType, oldValue, newValue, oldMaxValue, newMaxValue )

		-- Only track health
		if ( powerType ~= POWERTYPE_HEALTH ) then return end

		-- Only track Player, Target, and Group
		if ( unitTag ~= "player" and unitTag ~= "reticleover" and string.match(unitTag,"group") == nil ) then return end

		-- Health Regeneration
		if ( unitAttributeVisual == ATTRIBUTE_VISUAL_INCREASED_REGEN_POWER or unitAttributeVisual == ATTRIBUTE_VISUAL_DECREASED_REGEN_POWER ) then
			
			-- Display regen indicator
			if ( FTC.init.Frames and ( unitTag == "player" or unitTag == "reticleover" ) ) then FTC.Frames:Regen(unitTag,unitAttributeVisual,powerType,2000) end

		-- Damage Shields
		elseif ( unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING ) then
			if ( FTC.init.Frames ) then FTC.Player:UpdateShield( unitTag , newValue , newMaxValue ) end
		end
	end

	--[[ 
	 * Handles Removed Visualizers
	 * --------------------------------
	 * Called by EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED
	 * --------------------------------
	 ]]--  
	function FTC.OnVisualRemoved( eventCode , unitTag, unitAttributeVisual, statType, attributeType, powerType, value, maxValue )

		-- Only track health
		if ( powerType ~= POWERTYPE_HEALTH ) then return end

		-- Only track Player, Target, and Group
		if ( unitTag ~= "player" and unitTag ~= "reticleover" and string.match(unitTag,"group") == nil ) then return end
		
		-- Health Regeneration
		if ( unitAttributeVisual == ATTRIBUTE_VISUAL_INCREASED_REGEN_POWER or unitAttributeVisual == ATTRIBUTE_VISUAL_DECREASED_REGEN_POWER ) then
			
			-- Remove regen indicator
			if ( FTC.init.Frames and ( unitTag == "player" or unitTag == "reticleover" ) ) then FTC.Frames:Regen(unitTag,unitAttributeVisual,powerType,0) end

		-- Damage Shields
		elseif ( unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING and powerType == POWERTYPE_HEALTH ) then

			-- Remove from Unit Frame
			if ( FTC.init.Frames ) then FTC.Player:UpdateShield( unitTag , 0 , maxValue ) end

			-- Verify the shield was removed due to simultaneous damage
			if ( FTC.init.Buffs and unitTag == "player" and FTC.Damage.lastIn >= GetGameTimeMilliseconds() - 5 ) then FTC.Buffs:ClearShields() end
		end
	end 


--[[----------------------------------------------------------
	PLAYER STATE EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles Combat State Changes
	 * --------------------------------
	 * Called by EVENT_PLAYER_COMBAT_STATE
	 * --------------------------------
	 ]]--
	function FTC.OnCombatState( eventCode, inCombat )

		-- Control frame visibility
		if ( FTC.init.Frames ) then 
			if ( FTC.Vars.PlayerFrame ) then FTC.Frames:Fade('player',FTC_PlayerFrame) end
			if ( FTC.Vars.TargetFrame ) then FTC.Frames:Fade('player',FTC_TargetFrame) end
			if ( IsUnitGrouped('player') ) then 
				if ( FTC.Vars.GroupFrames and GetGroupSize() <= 4 ) then FTC.Frames:Fade('player',FTC_GroupFrame)
				elseif ( FTC.Vars.RaidFrames ) then FTC.Frames:Fade('player',FTC_RaidFrame) end
			end
		end

		-- Trigger an alert
		if ( FTC.init.SCT ) then FTC.SCT:Combat(inCombat) end

		-- Maybe report DPS
		if ( FTC.init.Stats and IsUnitGrouped('player') and ( not inCombat ) ) then zo_callLater( function() FTC.Stats:SendPing() end , 250 ) end
	end

	--[[ 
	 * Handles Stealth State Changes
	 * --------------------------------
	 * Called by EVENT_STEALTH_STATE_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnStealthState( eventCode, unitTag , stealthState )

		-- Stealth buff
		if ( FTC.init.Buffs and unitTag == 'player' ) then 

			-- Entered stealth
			local hidden		= GetAbilityName(20309)
			if ( stealthState == STEALTH_STATE_HIDDEN or stealthState == STEALTH_STATE_HIDDEN_ALMOST_DETECTED or stealthState == STEALTH_STATE_STEALTH or stealthState == STEALTH_STATE_STEALTH_ALMOST_DETECTED ) then

				-- Setup buff object
				local ability  = {
					["owner"]  = FTC.Player.name,
					["id"]	   = 20309,
					["name"]   = hidden,
					["dur"]	   = 0,
					["icon"]   = FTC.UI.Textures[hidden],
					["ground"] = false,
					["area"]   = false,
					["debuff"] = false,
					["toggle"] = "T"
				}
				FTC.Buffs:NewEffect( ability , "Player" )

			-- Remove stealth buff
			elseif ( FTC.Buffs.Player[hidden] ~= nil ) then
				local buff = FTC.Buffs.Player[hidden]
				FTC.Buffs.Pool:ReleaseObject(buff.control.id)
				FTC.Buffs.Player[hidden] = nil 
			end
		end
	end

	--[[ 
	 * Handles Death-Related Events
	 * --------------------------------
	 * Called by EVENT_UNIT_DEATH_STATE_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnDeath( ... )

		-- Get the unitTag
		local unitTag = select( 2 , ... )

		-- Wipe player buffs
		if ( FTC.init.Buffs and unitTag == 'player' ) then FTC.Buffs:WipeBuffs(FTC.Player.name) end
	end

	--[[ 
	 * Handles Mounted State Changes
	 * --------------------------------
	 * Called by EVENT_MOUNTED_STATE_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnMount(code,state)
		if ( FTC.init.Frames ) then FTC.Frames:SetupAltBar("mounted",state) end
	end

	--[[ 
	 * Handles Siege Control State Changes
	 * --------------------------------
	 * Called by EVENT_BEGIN_SIEGE_CONTROL
	 * Called by EVENT_END_SIEGE_CONTROL
	 * --------------------------------
	 ]]--
	function FTC.OnSiege()
		if ( FTC.init.Frames ) then FTC.Frames:SetupAltBar() end
	end

	--[[ 
	 * Handles Werewolf State Changes
	 * --------------------------------
	 * Called by EVENT_WEREWOLF_STATE_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnWerewolf()
		if ( FTC.init.Frames ) then zo_callLater( function() FTC.Frames:SetupAltBar() end , 1000 ) end
	end


--[[----------------------------------------------------------
	ACTION BAR EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles Changes to Active Quicslot
	 * --------------------------------
	 * Called by EVENT_ACTIVE_QUICKSLOT_CHANGED
	 * --------------------------------
	 ]]--
	function FTC:OnQuickslotChanged( eventCode , slotNum )
		FTC.Player:GetQuickslot(slotNum)
	end

	--[[ 
	 * Handles Ability Usage Global Cooldown
	 * --------------------------------
	 * Called by EVENT_ACTION_UPDATE_COOLDOWNS
	 * --------------------------------
	 ]]--
	function FTC.OnUpdateCooldowns( ... )
		if ( FTC.init.SCT ) then FTC.SCT:Potion() end
	end

--[[----------------------------------------------------------
	BUFF EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles Buff Effect Changes
	 * --------------------------------
	 * Called by EVENT_EFFECT_CHANGED
	 * --------------------------------
	 ]]--
	function FTC.OnEffectChanged( eventCode , changeType , effectSlot , effectName , unitTag , beginTime , endTime , stackCount , iconName , buffType , effectType , abilityType , statusEffectType , unitName , unitId , abilityId )
							 
		-- Pass information to buffs component
		if ( FTC.init.Buffs ) then FTC.Buffs:EffectChanged( changeType , unitTag , unitName , unitId , effectType , effectName , abilityType , abilityId , buffType , statusEffectType , beginTime , endTime , iconName ) end
	end

--[[----------------------------------------------------------
	COMBAT EVENTS
  ]]----------------------------------------------------------
  
	--[[ 
	 * Handles Combat Events
	 * --------------------------------
	 * Called by EVENT_COMBAT_EVENT
	 * --------------------------------
	 ]]--
	function FTC.OnCombatEvent( eventCode , result , isError , abilityName , abilityGraphic , abilityActionSlotType , sourceName , sourceType , targetName , targetType , hitValue , powerType , damageType , log , sourceUnitId , targetUnitId , abilityId )

		-- Ignore errors
		if ( isError ) then return end

		-- Pass damage event to handler
		FTC.Damage:New( result , abilityName , abilityGraphic , abilityActionSlotType , sourceName , sourceType , targetName , targetType , hitValue , powerType , damageType )
	end


--[[----------------------------------------------------------
	GROUP EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles Group Composition Changes
	 * --------------------------------
	 * Called by EVENT_GROUP_MEMBER_JOINED
	 * Called by EVENT_GROUP_MEMBER_LEFT
	 * --------------------------------
	 ]]--
	function FTC.OnGroupChanged(eventCode)
		if ( FTC.init.Frames ) then 

			-- Prevent this event from running multiple times per refresh
			if ( not FTC.Frames.groupUpdate ) then return end

			-- Plan to refresh the group on a 1 second delay
			zo_callLater( function() FTC.Frames:SetupGroup() end , 1000 ) 

			-- Prevent further refreshes
			FTC.Frames.groupUpdate = false
		end	   
	end

	--[[ 
	 * Handles Group Member Range Changes
	 * --------------------------------
	 * Called by EVENT_GROUP_SUPPORT_RANGE_UPDATE
	 * --------------------------------
	 ]]--
	function FTC.OnGroupRange( eventCode , unitTag , inRange )
		if ( FTC.init.Frames ) then FTC.Frames:GroupRange( unitTag , inRange ) end
	end


--[[----------------------------------------------------------
	EXPERIENCE EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handles Experience Gain
	 * --------------------------------
	 * Called by EVENT_EXPERIENCE_UPDATE
	 * --------------------------------
	 ]]--
	function FTC.OnXPUpdate( eventCode , unitTag , currentExp , maxExp , reason )
		if ( unitTag ~= 'player' ) then return end

		-- Generate SCT Alert
		if ( FTC.init.SCT ) then FTC.SCT:NewExp( currentExp , maxExp , reason ) end

		-- Log experience gain
		if ( FTC.init.Log ) then FTC.Log:Exp( currentExp , reason ) end

		-- Update the data table
		FTC.Player:GetLevel()
		
		-- Update the experience bar
		if ( FTC.init.Frames ) then FTC.Frames:SetupAltBar() end
	end

	--[[ 
	 * Handles Alliance Point Gain
	 * --------------------------------
	 * Called by EVENT_ALLIANCE_POINT_UPDATE
	 * --------------------------------
	 ]]--
	function FTC.OnAPUpdate( ... )
		if ( FTC.init.SCT ) then FTC.SCT:NewAP( ... ) end
		if ( FTC.init.Log ) then FTC.Log:AP( ... ) end
	end

	--[[ 
	 * Handle Player Level-Up
	 * --------------------------------
	 * Called by EVENT_LEVEL_UPDATE
	 * Called by EVENT_VETERAN_RANK_UPDATE
	 * --------------------------------
	 ]]--
	function FTC:OnLevel( ... )

		-- Update character level on unit frames
		if ( FTC.init.Frames ) then 
			FTC.Frames:SetupPlayer() 
			FTC.Frames:SetupGroup()
		end
	end

--[[----------------------------------------------------------
	STATS EVENTS
  ]]----------------------------------------------------------

	--[[ 
	 * Handle Map Pings
	 * --------------------------------
	 * Called by EVENT_LEVEL_UPDATE
	 * Called by EVENT_VETERAN_RANK_UPDATE
	 * --------------------------------
	 ]]--
	function FTC.OnPing( eventCode, pingEventType, pingType, pingTag, offsetX, offsetY , isOwner )

		-- Register DPS posts
		if ( FTC.init.Stats and pingType == MAP_PIN_TYPE_PING ) then
			FTC.Stats:AddPing( offsetX, offsetY , pingTag , isOwner )
		end
	end

