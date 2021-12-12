 
--[[----------------------------------------------------------
    PLAYER DATA COMPONENT
  ]]----------------------------------------------------------
    local FTC = FTC
    FTC.Player = {} 

    --[[ 
     * Initialize Player Data Table
     * --------------------------------
     * Called by FTC:Initialize()
     * --------------------------------
     ]]--  
    function FTC.Player:Initialize()

        -- Setup initial character information
        FTC.Player.name     = GetUnitName( 'player' )
        FTC.Player.race     = GetUnitRace( 'player' )
        FTC.Player.class    = FTC.Player:GetClass(GetUnitClassId( 'player' ))
        FTC.Player:GetLevel()
        
        -- Load starting attributes
        local stats = {
            { ["name"] = "health"   , ["id"] = POWERTYPE_HEALTH },
            { ["name"] = "magicka"  , ["id"] = POWERTYPE_MAGICKA },
            { ["name"] = "stamina"  , ["id"] = POWERTYPE_STAMINA },
            { ["name"] = "ultimate" , ["id"] = POWERTYPE_ULTIMATE }
        }
        for i = 1 , #stats , 1 do
            local current, maximum, effMax = GetUnitPower( "player" , stats[i].id )
            FTC.Player[stats[i].name] = { ["current"] = current , ["max"] = maximum , ["pct"] = zo_roundToNearest(current/maximum,0.01) }
        end

        -- Load starting shield
        local value, maxValue   = GetUnitAttributeVisualizerEffectInfo('player',ATTRIBUTE_VISUAL_POWER_SHIELDING,STAT_MITIGATION,ATTRIBUTE_HEALTH,POWERTYPE_HEALTH)
        FTC.Player.shield       = { ["current"] = value or 0 , ["max"] = maxValue or 0 , ["pct"] = zo_roundToNearest((value or 0)/(maxValue or 0),0.01) }

        -- Load quickslot ability
        FTC.Player:GetQuickslot()
        local _ , _ , canPotion = GetSlotCooldownInfo(GetCurrentQuickslot())
        FTC.Player.canPotion    = canPotion
    end


--[[----------------------------------------------------------
    TARGET DATA COMPONENT
  ]]----------------------------------------------------------
    FTC.Target = {}

    --[[ 
     * Initialize Target Data Table
     * --------------------------------
     * Called by FTC:Initialize()
     * --------------------------------
     ]]--  
    function FTC.Target:Initialize()

        -- Setup initial target information
        local target            = {
            ["name"]            = "-999",
            ["level"]           = 0,
            ["class"]           = "",
            ["vlevel"]          = 0,
            ["health"]          = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
            ["magicka"]         = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
            ["stamina"]         = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
            ["shield"]          = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
        }   
        
        -- Populate the target object
        for attr , value in pairs( target ) do FTC.Target[attr] = value end
        
        -- Get target data
        FTC.Target:Update()
    end

--[[ 
 * Update the Target Object
 * --------------------------------
 * Called by FTC.Target:Initialize()
 * Called by FTC:OnTargetChanged()
 * --------------------------------
 ]]--  
function FTC.Target:Update()

    -- Hide default frame
    if ( FTC.init.Frames and not FTC.Vars.DefaultTargetFrame ) then FTC.TARGET_WINDOW:SetHidden(true) end
        
    -- Get the target name
    local name = GetUnitName('reticleover')

    -- Ignore empty and critters, but not during move mode
    local ignore = ( ( not DoesUnitExist('reticleover') ) or FTC:IsCritter('reticleover') ) and not FTC.move

    -- Update valid targets
    if ( not ignore ) then

        -- Update the target data object
        FTC.Target.name     = GetUnitName('reticleover')
        FTC.Target.class    = FTC.Player:GetClass(GetUnitClassId('reticleover'))
        FTC.Target.level    = GetUnitLevel('reticleover')
        FTC.Target.vlevel   = GetUnitChampionPoints('reticleover') 
		FTC.Target.display	=  GetUnitDisplayName('reticleover')
		if FTC.Target.display == '' or not FTC.Target.display then
			FTC.Target.display = FTC.Target.name
		end	

        -- Update target buffs
        if ( FTC.init.Buffs ) then FTC.Buffs:GetBuffs( 'reticleover' ) end

        -- Update target frame
        if ( FTC.init.Frames ) then FTC.Frames:SetupTarget() end

    -- Otherwise ensure target frame stays hidden
    else 
        if ( FTC.init.Frames ) then FTC_TargetFrame:SetHidden(true) end
    end
end


--[[----------------------------------------------------------
    GROUP DATA COMPONENT
  ]]----------------------------------------------------------
FTC.Group = {}
function FTC.Group:Initialize()
    for i = 1 , 24 do 
        FTC.Group[i] = {
            ["health"]          = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
            ["magicka"]         = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
            ["stamina"]         = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
            ["shield"]          = { ["current"] = 0 , ["max"] = 0 , ["pct"] = 100 },
        }
    end
    FTC.Group.members = 0
end

function FTC.Group:HasLocalCompanion()
    return HasActiveCompanion() or HasPendingCompanion()
end

function FTC.Group:IsLocalGroup()
    return HasLocalCompanion() and FTC.Group.members == 0
end

function FTC.Group:GetIndexByUnitTag( unitTag )
    -- Fake group order if it's just player and companion
    if ( FTC.Group:IsLocalGroup() ) then
        if ( unitTag == "player" ) then
            return FTC.Vars.GroupHidePlayer and nil or 1
        elseif ( unitTag == "companion" ) then
            return FTC.Vars.GroupHidePlayer and 1 or 2
        else
            return nil
        end
    end
    local groupUnitTag
    local isCompanion
    -- Is this a companion? then get its group tag (group2companion -> group2)
    if (IsGroupCompanionUnitTag(unitTag)) then
        groupUnitTag = GetGroupUnitTagByCompanionUnitTag(unitTag)
        isCompanion = true
    else
        groupUnitTag = unitTag
        isCompanion = false
    end

    -- Now that we have 
    local i = GetGroupIndexByUnitTag(groupUnitTag)

    -- Companions are all listed at the end for ordering alignment
    if (isCompanion) then
        i = i + GetGroupSize()
    end
    return i
end

function FTC.Group:GetGroupIndexByUnitIndex(unitIndex)
    local groupSize = GetGroupSize()
    if ( not FTC.Group:IsLocalGroup() and unitIndex > groupSize ) then
        return unitIndex - groupSize
    end
end



--[[----------------------------------------------------------
    EVENT HANDLERS
  ]]----------------------------------------------------------

    --[[ 
     * Process Updates to Attributes
     * --------------------------------
     * Called by FTC.OnPowerUpdate()
     * Called by FTC.Frames:SetupPlayer()
     * Called by FTC.Frames:SetupTarget()
     * --------------------------------
     ]]--
     function FTC.Player:UpdateAttribute( unitTag , powerType ,  powerValue , powerMax , powerEffectiveMax )

        -- Player
        local data = nil

        local hasLocalCompanion = HasActiveCompanion() or HasPendingCompanion()
        local hasLocalCompanionOnly = hasLocalCompanion and FTC.Group.members == 0

		if ( unitTag == nil ) then
			return
		
        elseif ( unitTag == 'player' ) then
            data    = FTC.Player
            unitTag = 'player'
        
        -- Target
        elseif ( unitTag == 'reticleover' ) then
            data    = FTC.Target

        -- Group
        elseif ( string.sub(unitTag, 0, 5) == "group" ) then
            local groupUnitTag
            local isCompanion
            if (IsGroupCompanionUnitTag(unitTag)) then
                groupUnitTag = GetGroupUnitTagByCompanionUnitTag(unitTag)
                isCompanion = true
            else
                groupUnitTag = unitTag
                isCompanion = false
            end
            local i = GetGroupIndexByUnitTag(groupUnitTag)

            if (isCompanion) then
                i = i + GetGroupSize()
            end

            data    = FTC.Group[i]

        -- Check for companion
        else
            if ( hasLocalCompanionOnly ) then
                local i = FTC.Vars.GroupHidePlayer and 1 or 2
                data    = FTC.Group[i]
            else
                return
            end
        end
        
        -- Translate the attribute
        local attrs = { [POWERTYPE_HEALTH] = "health", [POWERTYPE_MAGICKA] = "magicka", [POWERTYPE_STAMINA] = "stamina" }
        local power = attrs[powerType]

        -- If no value was passed, get new data
        if ( powerValue == nil ) then
            powerValue, powerMax, powerEffectiveMax = GetUnitPower( unitTag , powerType )
        end
        
        -- Get the percentage
        local pct = math.max(zo_roundToNearest((powerValue or 0)/powerMax,0.01),0)
        
        -- Update frames
        if ( FTC.init.Frames ) then 
            FTC.Frames:Attribute( unitTag , power , powerValue , powerMax , pct , data.shield.current )
            if ( hasLocalCompanionOnly and unitTag == "player" and not FTC.Vars.GroupHidePlayer and powerType == POWERTYPE_HEALTH ) then
                FTC.Frames:Attribute( "group1" , power , powerValue , powerMax , pct , data.shield.current )
            end
        end
        
        -- Update the database object
        data[power] = { ["current"] = powerValue , ["max"] = powerMax , ["pct"] = pct }
     end

     --[[ 
     * Update Shielding Attribute
     * --------------------------------
     * Called by FTC.OnVisualAdded()
     * Called by FTC.OnVisualUpdate()
     * Called by FTC.OnVisualRemoved()
     * Called by FTC.Frames:SetupPlayer()
     * Called by FTC.Frames:SetupTarget()
     * --------------------------------
     ]]--
    function FTC.Player:UpdateShield( unitTag , value , maxValue )

        -- Player
        local data  = nil
        if ( unitTag == 'player' ) then
            data    = FTC.Player
        
        -- Target
        elseif ( unitTag == 'reticleover' ) then
            data    = FTC.Target

        -- Group
        elseif ( string.sub(unitTag, 0, 5) == "group" and ( ( GetGroupSize() <= 4 and FTC.Vars.GroupFrames ) or FTC.Vars.RaidFrames ) ) then
            local groupUnitTag
            local isCompanion
            if (IsGroupCompanionUnitTag(unitTag)) then
                groupUnitTag = GetGroupUnitTagByCompanionUnitTag(unitTag)
                isCompanion = true
            else
                groupUnitTag = unitTag
                isCompanion = false
            end
            local i = GetGroupIndexByUnitTag(groupUnitTag)

            if (isCompanion) then
                i = i + GetGroupSize()
            end
            data    = FTC.Group[i]

        -- Check for companion
        else
            if ( hasLocalCompanionOnly ) then
                local i = FTC.Vars.GroupHidePlayer and 1 or 2
                data    = FTC.Group[i]
            else
                return
            end
        end

        -- If no value was passed, get new data
        if ( value == nil ) then 
            value = GetUnitAttributeVisualizerEffectInfo(unitTag,ATTRIBUTE_VISUAL_POWER_SHIELDING,STAT_MITIGATION,ATTRIBUTE_HEALTH,POWERTYPE_HEALTH) or 0
        end
        
        -- Get the unit's maximum health
        local pct = zo_roundToNearest(value/data["health"]["max"],0.01)
        
        -- Update frames
        if ( FTC.init.Frames ) then 
            FTC.Frames:Shield( unitTag , value , pct , data.health.current , data.health.max , data.health.pct )
            if ( hasLocalCompanionOnly and unitTag == "player" and not FTC.Vars.GroupHidePlayer ) then
                FTC.Frames:Shield( "group1" , value , pct , data.health.current , data.health.max , data.health.pct )
            end
        end
        
        -- Update the database object
        data.shield = { ["current"] = value , ["max"] = maxValue , ["pct"] = pct }
    end
  
     --[[ 
     * Update Player Ultimate
     * --------------------------------
     * Called by FTC.OnPowerUpdate()
     * --------------------------------
     ]]--
    function FTC.Player:UpdateUltimate( powerValue , powerMax , powerEffectiveMax )
            
        -- Get the currently slotted ultimate cost
        cost, mechType = GetSlotAbilityCost(8)
        
        -- Calculate the percentage to activation
        local pct = ( cost > 0 ) and math.max(zo_roundToNearest((powerValue/cost),0.01),0) or 0
        
        -- Maybe fire an alert
        if ( FTC.init.SCT and pct >= 1 and FTC.Player.ultimate.pct < 1 ) then FTC.SCT:Ultimate() end

        -- Update the hotbar label
        if ( FTC.init.Hotbar ) then FTC.Hotbar:UpdateUltimate( powerValue , cost ) end
        
        -- Update the database object
        FTC.Player.ultimate = { ["current"] = powerValue , ["max"] = powerEffectiveMax , ["pct"] = pct }
    end


--[[----------------------------------------------------------
    HELPER FUNCTIONS
  ]]----------------------------------------------------------

    --[[ 
     * Filters Targets for "Critters"
     * --------------------------------
     * Called by FTC.Target:Update()
     * --------------------------------
     ]]-- 
    function FTC:IsCritter( unitTag )
        -- Critters meet all the following criteria: Level 1, Difficulty = NONE, and Neutral or Friendly reaction
        return (( GetUnitLevel(unitTag) == 1 ) and ( GetUnitDifficulty(unitTag) == MONSTER_DIFFICULTY_NONE ) and ( GetUnitReaction(unitTag) == UNIT_REACTION_NEUTRAL or GetUnitReaction(unitTag) == UNIT_REACTION_FRIENDLY ) )
    end

    --[[ 
     * Re-populates Player Experience
     * --------------------------------
     * Called by FTC.Player:Initialize()
     * Called by FTC:OnXPUpdate()
     * Called by FTC:OnVPUpdate()
     * --------------------------------
     ]]--  
    function FTC.Player:GetLevel()
        FTC.Player.level    = GetUnitLevel('player')
        FTC.Player.alevel   = GetUnitAvARank('player')
        FTC.Player.clevel   = GetPlayerChampionPointsEarned()
        FTC.Player.exp      = GetUnitXP('player')
        FTC.Player.cxp      = GetPlayerChampionXP()
    end

    --[[ 
     * Translate Class-ID to English Name
     * --------------------------------
     * Called by FTC.Player:Initialize()
     * --------------------------------
     ]]-- 
    function FTC.Player:GetClass(classId)
		--START
		local arr = {"Dragonknight", "Scorcerer", "Nightblade", "Warden", "Necromancer", "Templar"}
		return arr[classId]
		--END
        --if ( classId == 1 ) then return "Dragonknight"
        --elseif ( classId == 2 ) then return "Sorcerer"
        --elseif ( classId == 3 ) then return "Nightblade"
        --elseif ( classId == 6 ) then return "Templar" end
    end

    --[[ 
     * Get Currently Active Quickslot
     * --------------------------------
     * Called by FTC:OnQuickslotChanged
     * --------------------------------
     ]]-- 
    function FTC.Player:GetQuickslot(slotNum)

        -- Get the current slot
        local slotNum       = slotNum or GetCurrentQuickslot()

        -- Populate the quickslot object
        if ( IsSlotUsed(slotNum) ) then
            local abilityId     = GetSlotBoundId(slotNum)

            -- Get potion base duration
            local baseDur       = tonumber(zo_strformat("<<x:1>>",string.match(GetAbilityDescription(abilityId),'for (.*) seconds'))) or 0

            -- Get potion level
            local itemLevel     = ( GetItemLinkRequiredLevel(GetSlotItemLink(slotNum)) or 0 ) + ( GetItemLinkRequiredChampionPoints(GetSlotItemLink(slotNum)) or 0 )

            -- Get Medicinal Use multiplier
            local multiplier    = GetSkillAbilityUpgradeInfo(SKILL_TYPE_TRADESKILL, 1, 3)
            multiplier          = 1.0 + (0.1*multiplier)

            -- Approximate potion duration with a close (but incorrect) formula
            local duration      = ( baseDur + ( itemLevel * .325 ) ) * multiplier * 1000

            -- Setup object
            local ability = {
                ["owner"]       = FTC.Player.name,
                ["slot"]        = slotNum,
                ["id"]          = abilityId,
                ["name"]        = zo_strformat("<<t:1>>",GetSlotName(slotNum)),
                ["cast"]        = 0,
                ["chan"]        = 0,
                ["dur"]         = duration,
                ["tex"]         = GetSlotTexture(slotNum),
            }

            -- Save the slot
            FTC.Player.Quickslot = ability

        -- Otherwise empty the object
        else FTC.Player.Quickslot = {} end 
    end

--[[ 
 * Get abilityID from abilityName
 * --------------------------------
 * UNUSED / DEBUGGING
 * --------------------------------
 ]]--
function FTC:GetAbilityId( abilityName )

    -- Loop over all ability IDs until we find it
    for i = 1, 70000 do
       if ( DoesAbilityExist(i) and ( GetAbilityName(i) == abilityName ) ) then
            d(i .. " -- " .. abilityName)
            return i
       end
    end
end
