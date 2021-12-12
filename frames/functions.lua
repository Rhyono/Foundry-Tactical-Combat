 
--[[----------------------------------------------------------
    UNIT FRAMES COMPONENT
  ]]----------------------------------------------------------
    local FTC = FTC
    FTC.Frames = {}
    FTC.Frames.Defaults = {

        -- Configuration
        ["PlayerFrame"]             = true,
        ["TargetFrame"]             = true,
        ["DefaultTargetFrame"]      = false,        
        ["LabelFrames"]             = false,
        ["GroupFrames"]             = true,
        ["RaidFrames"]              = true,
        
        -- Player Frame
        ["FTC_PlayerFrame"]         = {TOPRIGHT,CENTER,-250,180},
        ["EnableNameplate"]         = true,
        ["EnableXPBar"]             = true,
        ["FrameWidth"]              = 350,
        ["FrameHeight"]             = 180,  

        -- Target Frame
        ["FTC_TargetFrame"]         = {TOPLEFT,CENTER,250,180},
        ["ExecuteThreshold"]        = 25,
		["TargetFrameLevel"]        = true,
		["TargetFrameTitle"]        = true,
		["TargetFrameWidth"]        = 350,
        ["TargetFrameHeight"]       = 120,  

        -- Shared Settings
        ["FrameFontSize"]           = 18,
		["FrameFontColor"]			= {1,1,1},
        ["FrameHealthColor"]        = {133/255,018/255,013/255},
        ["FrameMagickaColor"]       = {064/255,064/255,128/255},
        ["FrameStaminaColor"]       = {038/255,077/255,033/255},
        ["FrameShieldColor"]        = {255/255,100/255,000/255},
        ["FrameShowMax"]            = false,

        -- Group Frame
        ["FTC_GroupFrame"]          = {TOPLEFT,TOPLEFT,6,50},
        ["GroupWidth"]              = 250,
        ["GroupHeight"]             = 350,  
        ["GroupHidePlayer"]         = false,
        ["GroupFontSize"]           = 18,
        ["ColorRoles"]              = true,
        ["FrameTankColor"]          = {133/255,018/255,013/255},
        ["FrameHealerColor"]        = {117/255,077/255,135/255},
        ["FrameDamageColor"]        = {255/255,196/255,128/255},
		["GroupShowLevel"]          = true,

        -- Raid Frame
        ["FTC_RaidFrame"]           = {TOPLEFT,TOPLEFT,6,50},
        ["RaidWidth"]               = 120,
        ["RaidHeight"]              = 50,  
        ["RaidColumnSize"]          = 6,
        ["RaidFontSize"]            = 14,

        -- Shared Settings
        ["FrameOpacityIn"]          = 100,
        ["FrameOpacityOut"]         = 60, 
		["FrameTargetOpacityIn"]    = 100,   
        ["FrameTargetOpacityOut"]   = 60,    
        ["FrameFont1"]              = 'esobold',
        ["FrameFont2"]              = 'esobold',
    }
    FTC:JoinTables(FTC.Defaults,FTC.Frames.Defaults)

--[[----------------------------------------------------------
    UNIT FRAMES FUNCTIONS
  ]]----------------------------------------------------------

    --[[ 
     * Initialize Unit Frames Component
     * --------------------------------
     * Called by FTC:Initialize()
     * --------------------------------
     ]]--
    function FTC.Frames:Initialize()

        -- Unregister events to disable default frames
        if ( FTC.Vars.PlayerFrame ) then
            local frames = { 'Health' , 'Stamina' , 'Magicka' , 'MountStamina' , 'SiegeHealth' , 'Werewolf' }
            for i = 1 , #frames do
                local frame = _G["ZO_PlayerAttribute"..frames[i]]
                frame:UnregisterForEvent(EVENT_POWER_UPDATE)
                frame:UnregisterForEvent(EVENT_INTERFACE_SETTING_CHANGED)
                frame:UnregisterForEvent(EVENT_PLAYER_ACTIVATED)
                EVENT_MANAGER:UnregisterForUpdate("ZO_PlayerAttribute"..frames[i].."FadeUpdate")
                frame:SetHidden(true)       
            end
        end

        -- Create unit frame UI elements
        FTC.Frames:Controls()

        -- Register init status
        FTC.init.Frames = true

        -- Populate initial frames
        FTC.Frames:SetupPlayer()
        FTC.Frames:SetupTarget()
        FTC.Frames:SetupGroup()

        -- Activate safety check
        EVENT_MANAGER:RegisterForUpdate( "FTC_PlayerFrame" , 5000 , function() FTC.Frames:SafetyCheck() end )
    end

      --[[ 
     * Set Up Player Frame
     * --------------------------------
     * Called by FTC.Frames:Initialize()
     * Called by FTC.Frames:OnLevel()
     * --------------------------------
     ]]--
    function FTC.Frames:SetupPlayer()

        -- Bail if frames are disabled
        if ( not FTC.init.Frames ) then return end

        -- Custom player frame
        if ( FTC.Vars.PlayerFrame ) then
        
            -- Configure the nameplate
            if ( FTC.Vars.EnableNameplate ) then
                local name      = zo_strformat("<<!aC:1>>",FTC.Player.name)
                local level     = (FTC.Player.level == 50 and FTC.Player.clevel > 0) and "c" .. FTC.Player.clevel or ((FTC.Player.level < 50 and FTC.Player.clevel > 0)  and FTC.Player.level .. " [c" .. FTC.Player.clevel .. "]" or FTC.Player.level)
                FTC_PlayerFrame_PlateName:SetText( name .. " (" .. level .. ")" )
            end
            FTC_PlayerFrame_Plate:SetHidden( not FTC.Vars.EnableNameplate )
            
            -- Setup alternate bar
            FTC.Frames:SetupAltBar()
        end
        FTC_PlayerFrame:SetHidden( not FTC.Vars.PlayerFrame )

        -- Repopulate attributes
        FTC.Player:UpdateAttribute( 'player', POWERTYPE_HEALTH, nil )
        FTC.Player:UpdateAttribute( 'player', POWERTYPE_MAGICKA, nil )
        FTC.Player:UpdateAttribute( 'player', POWERTYPE_STAMINA, nil )

        -- Repopulate shield
        FTC.Player:UpdateShield(    'player' , nil , nil )
    end
     
     --[[ 
     * Set Up Target Frame
     * --------------------------------
     * Called by FTC.Frames:Initialize()
     * Called by FTC.Target:Update()
     * Called by FTC.Menu:Reposition()
     * --------------------------------
     ]]--
     function FTC.Frames:SetupTarget()

        -- Bail if frames are disabled
        if ( not FTC.init.Frames ) then return end

        -- Ensure the default frame stays hidden
        if ( FTC.Vars.TargetFrame and FTC.Vars.DefaultTargetFrame == false ) then FTC.TARGET_WINDOW:SetHidden(true) end

        -- Bail out if no target unless we are moving
        if ( not DoesUnitExist('reticleover') and not FTC.move ) then 
            FTC_TargetFrame:SetHidden(true)
            return
        end
        
        -- Custom Target Frame
        if ( FTC.Vars.TargetFrame) then 

            -- Get the frame
            local frame     = _G['FTC_TargetFrame']
        
            -- Get data
            local name      = zo_strformat("<<!aC:1>>",FTC.Vars.TargetFrameShowAccount and FTC.Target.display or FTC.Target.name)
            local level     = FTC.Target.vlevel > 0 and "c" .. FTC.Target.vlevel or FTC.Target.level
            local icon      = nil
            local title     = nil
            local rank      = nil

            -- Players
            if ( IsUnitPlayer('reticleover') ) then 
                icon  = GetClassIcon(GetUnitClassId('reticleover'))
                title = GetUnitTitle( 'reticleover' ) == "" and GetAvARankName( GetUnitGender('reticleover') , GetUnitAvARank('reticleover') ) or GetUnitTitle( 'reticleover' )
                rank  = GetAvARankIcon(GetUnitAvARank('reticleover'))
            
            -- Champion Mobs
            elseif ( GetUnitDifficulty('reticleover') == 2) then 
                icon  = "/esoui/art/lfg/lfg_normaldungeon_down.dds"
                title = GetUnitCaption( 'reticleover' )

            -- Boss Mobs
            elseif ( GetUnitDifficulty('reticleover') >= 3 ) then 
                icon  = "/esoui/art/unitframes/target_veteranrank_icon.dds"
                title = GetUnitCaption( 'reticleover' )

            -- Normal NPCs
            else
                title = GetUnitCaption( 'reticleover' )
            end

            -- Populate name plate
            frame.plate.name:SetText(FTC.Vars.TargetFrameLevel and name .. " (" .. level .. ")" or name )
            frame.plate.class:SetTexture( icon )
            frame.plate.class:SetHidden( icon == nil )
            frame.lplate.title:SetText(zo_strformat("<<!aC:1>>",title))
            
            -- Populate rank icon
            frame.lplate.rank:SetTexture( rank )
            frame.lplate.rank:SetHidden( rank == nil )       
        end 
        FTC_TargetFrame:SetHidden(not FTC.Vars.TargetFrame)

        -- Repopulate health
        FTC.Player:UpdateAttribute( 'reticleover', POWERTYPE_HEALTH , nil )
        
        -- Repopulate shield
        FTC.Player:UpdateShield( 'reticleover' , nil )
    end

     --[[ 
     * Set Up Group Frame
     * --------------------------------
     * Called by FTC.Frames:Initialize()
     * --------------------------------
     ]]--
    FTC.Frames.groupUpdate = true
    function FTC.Frames:SetupGroup()

        -- Update data
        FTC.Group.members = GetGroupSize() + GetNumCompanionsInGroup()
		
		local hasLocalCompanion = HasActiveCompanion() or HasPendingCompanion()
		local hasLocalCompanionOnly = hasLocalCompanion and FTC.Group.members == 0

        -- Using group frame
        local context   = nil
		local inGroup = IsUnitGrouped('player') or hasLocalCompanion
        if ( inGroup and FTC.Group.members <= 4 and FTC.Vars.GroupFrames ) then 
			context = "Group"
            FTC_RaidFrame:SetHidden(true) 
            ZO_UnitFramesGroups:SetHidden(true)

        -- Using raid frames
        elseif ( IsUnitGrouped('player') and FTC.Vars.RaidFrames ) then
            context = "Raid"
            FTC_GroupFrame:SetHidden(true) 
            ZO_UnitFramesGroups:SetHidden(true)

        -- Using default frames
        else
            FTC_GroupFrame:SetHidden(true) 
            FTC_RaidFrame:SetHidden(true)
            FTC.Frames.groupUpdate = true
			ZO_UnitFramesGroups:SetHidden(false)
            return 
        end

        -- Get the parent container
        local container = _G["FTC_"..context.."Frame"]

        -- Iterate over members
        local max = FTC.Group.members
		if ( hasLocalCompanionOnly ) then
			max = FTC.Vars.GroupHidePlayer and 1 or 2
		end
        d(max)
        for i = 1 , max do
            local frame   = container["member"..i]
            local groupIndex = i
            local isCompanion = false
            if ( not hasLocalCompanionOnly and i > GetGroupSize() ) then
                groupIndex = i - GetGroupSize()
                isCompanion = true
            end
            local unitTag = GetGroupUnitTagByIndex(groupIndex)
			if ( hasLocalCompanionOnly ) then
				if ( FTC.Vars.GroupHidePlayer ) then
					unitTag = "companion"
				else
					unitTag = i == 1 and "player" or "companion"
				end
			end

            if ( isCompanion ) then
                unitTag = GetCompanionUnitTagByGroupUnitTag(unitTag)
            end

            -- Only proceed for members which exist
            if ( DoesUnitExist(unitTag) ) then

                -- Display the frame
                frame:SetHidden(false)

                -- Configure the nameplate
				local name
				local pendingCompanionName
				if ( unitTag == "companion" and HasPendingCompanion() ) then
					pendingCompanionName = GetCompanionName(GetPendingCompanionDefId())
					name = zo_strformat(SI_COMPANION_NAME_FORMATTER, pendingCompanionName)
				elseif ( IsGroupCompanionUnitTag(unitTag) ) then
					local playerGroupTag = GetLocalPlayerGroupUnitTag()
					local playerCompanionTag = GetCompanionUnitTagByGroupUnitTag(playerGroupTag)
					if ( playerCompanionTag == unitTag and HasPendingCompanion() ) then
						pendingCompanionName = GetCompanionName(GetPendingCompanionDefId())
						name = zo_strformat(SI_COMPANION_NAME_FORMATTER, pendingCompanionName)
					else
						name = GetUnitName(unitTag)
					end
				elseif ( IsUnitPlayer(unitTag) ) then
					name = (FTC.Vars.GroupShowAccount) and GetUnitDisplayName(unitTag) or zo_strformat("<<!aC:1>>",GetUnitName(unitTag))
				else
					name = GetUnitName(unitTag)
				end

                local level     = GetUnitChampionPoints(unitTag) > 0 and "c" .. GetUnitChampionPoints(unitTag) or GetUnitLevel(unitTag)
                local classIcon = GetClassIcon(GetUnitClassId(unitTag)) or nil

                -- Get player roles
				local role = GetGroupMemberSelectedRole(unitTag) 
				role = role==2 and "Tank" or (role==4 and "Healer" or "Damage")
                FTC.Group[i].role = role

                -- Determine bar color
                local color =( FTC.Vars.ColorRoles ) and FTC.Vars["Frame"..role.."Color"] or FTC.Vars.FrameHealthColor

                -- Color bar by role
                frame.health:SetCenterColor(color[1]/5,color[2]/5,color[3]/5,1)
                frame.health.bar:SetColor(color[1],color[2],color[3] ,1)

                -- Populate nameplate
                local label = ( context == "Group" and FTC.Vars.GroupShowLevel) and name .. " (" .. level .. ")" or name
                frame.plate.name:SetText(label)

                -- Populate raid icon
                if ( context == "Raid" ) then 
                    frame.plate.icon:SetTexture(IsUnitGroupLeader(unitTag) and "/esoui/art/lfg/lfg_leader_icon.dds" or classIcon )
                    frame.plate.icon:SetHidden(classIcon==nil)

                -- Populate group icons
                elseif ( context == "Group" ) then
                    local isLeader = IsUnitGroupLeader(unitTag) or hasLocalCompanionOnly and unitTag == "player"
                    frame.plate.icon:SetWidth(isLeader and 24 or 0)
                    frame.plate.class:SetTexture(classIcon)
                    frame.plate.class:SetHidden(classIcon==nil)
                end

                -- Populate health data
                FTC.Player:UpdateAttribute( unitTag , POWERTYPE_HEALTH , nil )

                -- Change the bar color
                FTC.Frames:GroupRange( 'group'..i , nil )

                -- Maybe hide the player
                if ( context == "Group" ) then
                    if ( FTC.Vars.GroupHidePlayer and i == GetGroupIndexByUnitTag('player') ) then
                        frame:SetHidden(true) 
                        frame:SetHeight(0)
                    else frame:SetHeight(FTC.Vars.GroupHeight/4) end
                end

            -- Otherwise hide the frame
            else frame:SetHidden(true) end
        end

        -- Display custom frames
        container:SetHidden(false)

        -- Allow additional updates
        FTC.Frames.groupUpdate = true
    end

     --[[ 
     * Handle Group Member Visibility
     * --------------------------------
     * Called by FTC.Frames:Initialize()
     * --------------------------------
     ]]--
    function FTC.Frames:GroupRange( unitTag , inRange )

        -- Using group frame
        local context   = nil
        if ( FTC.Group.members <= 4 and FTC.Vars.GroupFrames ) then 
            context = "Group"

        -- Using raid frames
        elseif ( FTC.Vars.RaidFrames ) then
            context = "Raid"

        -- Otherwise bail out
        else return end

        -- Retrieve the frame
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
        local frame = _G["FTC_"..context.."Frame"..i]

        -- Bail if the group member has not yet been set up
        if ( FTC.Group[i] == nil ) then return end

        -- If a range status was not passed, retrieve it
        if ( inRange == nil ) then inRange = IsUnitInGroupSupportRange(unitTag) end

        -- Get player roles
        local role  = FTC.Group[i].role
        local color = ( FTC.Vars.ColorRoles and role ~= nil ) and FTC.Vars["Frame"..role.."Color"] or FTC.Vars.FrameHealthColor

        -- Darken the color of the bar
        local newColor  = inRange and color or { color[1]/3 , color[2]/3 , color[3]/3 }
        frame.health.bar:SetColor(unpack(newColor))
    end
	
     --[[ 
     * Get Ultimate Frame
     * --------------------------------
     * Called by FTC.Frames:Initialize()
     * --------------------------------
     ]]--
    function FTC.Frames:GetUltimateFrame(unitTag)

        -- Using group frame
        local context   = nil
        if ( FTC.Group.members <= 4 and FTC.Vars.GroupFrames ) then 
            context = "Group"

        -- Using raid frames
        elseif ( FTC.Vars.RaidFrames ) then
            context = "Raid"

        -- Otherwise bail out
        else
			return nil
		end

        -- Retrieve the frame
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
        local frame = _G["FTC_"..context.."Frame"..i.."_Ultimate"]

        if frame then
			return frame
		else
			return nil
		end
    end


--[[----------------------------------------------------------
    ATTRIBUTES
  ]]----------------------------------------------------------

    --[[ 
     * Render Attribute Change
     * --------------------------------
     * Called by FTC.Player:UpdateAttribute()
     * --------------------------------
     ]]--
    function FTC.Frames:Attribute( unitTag , attribute , powerValue , powerMax , pct , shieldValue ) 

        -- Setup placeholders
        local frame     = nil
        local default   = nil
        local round     = false
        local max       = FTC.Vars.FrameShowMax
        local enabled   = false

        -- Player Frame
        if ( unitTag == 'player' ) then
            frame   = _G["FTC_PlayerFrame"]
            default = _G["FTC_Player"..attribute]
            enabled = FTC.Vars.PlayerFrame
        
        -- Target Frame
        elseif ( unitTag == 'reticleover' ) then
            frame   = _G["FTC_TargetFrame"]
            default = _G["FTC_Target"..attribute]
            enabled = FTC.Vars.TargetFrame

        -- Group Frames
        elseif ( string.sub(unitTag, 0, 5) == "group" or unitTag == "companion" ) then

            -- Get the group member
            local i
            local hasLocalCompanion = HasActiveCompanion() or HasPendingCompanion()
            local hasLocalCompanionOnly = hasLocalCompanion and FTC.Group.members == 0
            if ( unitTag == "companion" ) then
                if ( hasLocalCompanionOnly ) then
                    i = FTC.Vars.GroupHidePlayer and 1 or 2
                else
                    return
                end
            elseif ( hasLocalCompanionOnly ) then
                i = 1
                unitTag = "player"
            else
                local groupUnitTag
                local isCompanion
                if (IsGroupCompanionUnitTag(unitTag)) then
                    groupUnitTag = GetGroupUnitTagByCompanionUnitTag(unitTag)
                    isCompanion = true
                else
                    groupUnitTag = unitTag
                    isCompanion = false
                end
                i = GetGroupIndexByUnitTag(groupUnitTag)

                if (isCompanion) then
                    i = i + GetGroupSize()
                end
            end

            -- Small group
            if ( FTC.Group.members <= 4 and FTC.Vars.GroupFrames ) then 
                enabled = true
                frame   = _G["FTC_GroupFrame" .. i]

            -- Raid group
            elseif ( FTC.Vars.RaidFrames ) then 
                enabled = true
                frame   = _G["FTC_RaidFrame" .. i]  
                round   = true
                max     = false
            
            -- Otherwise bail
            else return end
        end

        -- Compute data
        if ( enabled or ( FTC.Vars.LabelFrames and default ~= nil ) ) then

            -- Update bar labels
			local label = FTC.DisplayNumber( powerValue )
			--Over 1M HP
			if (powerValue > 1000000) then
				label = FTC.DisplayNumber( powerValue/1000000 , 3 ) .. "m"
			elseif (powerValue > 100000 or round) then
				label = FTC.DisplayNumber( powerValue/1000 , 1 ) .. "k"
			end	
            local pctLabel = (pct*100) .. "%"
                
            -- Maybe add shielding
            if ( attribute == "health" ) then
                local shield = shieldValue or 0
                local slabel = ( round ) and FTC.DisplayNumber(shield/1000,1).."k" or FTC.DisplayNumber(shield)
                label = ( shield > 0 ) and label .. " [" .. slabel .. "]" or label
            end

            -- Maybe add maximum
            if ( max ) then 
                local maxHealth = ( round ) and FTC.DisplayNumber(powerMax/1000,1).."k" or FTC.DisplayNumber(powerMax)
                label = label .. "  /  " .. maxHealth
            end

            -- Override for dead things
            if ( attribute == "health" and ( IsUnitDead(unitTag) or powerValue == 0 ) ) then 
                label = GetString(FTC_Dead)
                pct = 0
                pctLabel = ""
            end

            -- Override for offline members
            if ( not IsUnitOnline(unitTag) ) then 
                label = GetString(FTC_Offline)
                pct = 0
                pctLabel = ""
            end

            -- Update custom frames
            if ( enabled ) then

                -- Update bar width
                local control = frame[attribute]
                control.bar:SetWidth( pct * (control:GetWidth()-4) )

                -- Set the label
                control.current:SetText(label)
                control.pct:SetText(pctLabel)

                -- Maybe prompt for execute
                if ( unitTag == 'reticleover' ) then
                    frame.execute:SetHidden( not ( pct < FTC.Vars.ExecuteThreshold/100 ) )
                    if ( ( not IsUnitDead(unitTag) ) and ( pct < FTC.Vars.ExecuteThreshold/100 ) and ( FTC.Target.health.pct > FTC.Vars.ExecuteThreshold/100 ) ) then FTC.Frames:Execute() end
                end
            end

            -- Update default frames
            if ( FTC.Vars.LabelFrames and default ~= nil ) then
                local defLabel = ( pctLabel ~= "" ) and label .. "  (" .. pctLabel .. ")" or label
                default:SetText(defLabel)
            end
        end
    end

   
     --[[ 
     * Render Shield Change
     * --------------------------------
     * Called by FTC.Player:UpdateShield()
     * --------------------------------
     ]]--
    function FTC.Frames:Shield( unitTag , shieldValue , shieldPct , healthValue , healthMax , healthPct )

        -- Setup placeholders
        local frame = nil
        local round = false
        local enabled   = false

        -- Player Frame
        if ( unitTag == 'player' ) then
            frame   = _G["FTC_PlayerFrame"]
            enabled = FTC.Vars.PlayerFrame
        
        -- Target Frame
        elseif ( unitTag == 'reticleover' ) then
            frame   = _G["FTC_TargetFrame"]
            enabled = FTC.Vars.TargetFrame

        -- Group Frames
        elseif ( string.sub(unitTag, 0, 5) == "group" and ( FTC.Vars.GroupFrames or FTC.Vars.RaidFrames ) ) then

            -- Get the group member
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

            -- Small group
            if ( FTC.Group.members <= 4 and FTC.Vars.GroupFrames ) then 
                enabled = true
                frame   = _G["FTC_GroupFrame" .. i]

            -- Raid group
            elseif ( FTC.Vars.RaidFrames ) then 
                enabled = true
                frame   = _G["FTC_RaidFrame" .. i]
                round   = true  

            -- Otherwise bail out
            else return end
        end
        
        -- Update custom frames
        if ( enabled ) then 
            frame.shield:SetWidth( math.min(shieldPct,1) * frame.health:GetWidth())
            frame.shield.bar:SetWidth(frame.shield:GetWidth()-4)
            frame.shield:SetHidden( shieldValue <= 0 )   
        end

        -- Refresh health display
        FTC.Frames:Attribute( unitTag , "health" , healthValue , healthMax , healthPct , shieldValue )
    end


--[[----------------------------------------------------------
    ALTERNATE BAR
  ]]-----------------------------------------------------------

     --[[ 
     * Set Up Alternate Experience/Mount/Werewolf/Siege Bar
     * --------------------------------
     * Called by FTC.Frames:SetupPlayer()
     * Called by FTC.OnMount()
     * Called by FTC.OnSiege()
     * Called by FTC.OnWerewolf()
     * --------------------------------
     ]]--
    function FTC.Frames:SetupAltBar(mode,state)
		if not mode then mode = false end
		if not state then state = false end
		
        -- Bail if the player frame is hidden
        if ( not FTC.Vars.PlayerFrame ) then return end

        -- Retrieve the bar
        local parent = _G["FTC_PlayerFrame_Alt"]
        
        -- Player is mounted
        if (mode == "mounted" and state) then
            -- Set the context
            parent.context = "mount" 

            -- Change the icon and color
            parent.icon:SetTexture("/esoui/art/icons/mapkey/mapkey_stables.dds")
            parent.bg:SetCenterColor(FTC.Vars.FrameStaminaColor[1]/5,FTC.Vars.FrameStaminaColor[2]/5,FTC.Vars.FrameStaminaColor[3]/5,1)
            parent.bar:SetColor(FTC.Vars.FrameStaminaColor[1],FTC.Vars.FrameStaminaColor[2],FTC.Vars.FrameStaminaColor[3],1)

            -- Fetch the current mount stamina level
            local current, maximum, effectiveMax = GetUnitPower( 'player' , POWERTYPE_MOUNT_STAMINA )
            parent.bar:SetWidth( math.min(current/effectiveMax,1) * (parent.bg:GetWidth()-6) )

        -- Player is transformed into a werewolf
        elseif ( IsWerewolf() ) then
            -- Set the context
            parent.context = "werewolf"

            -- Change the icon and color
            parent.icon:SetTexture("/esoui/art/icons/mapkey/mapkey_undaunted.dds")
            parent.bg:SetCenterColor(0.2,0,0,1)
            parent.bar:SetColor(0.8,0,0,1)

            -- Fetch the current werewolf time remaining
            local current, maximum, effectiveMax = GetUnitPower( 'player' , POWERTYPE_WEREWOLF )
            parent.bar:SetWidth( math.min(current/maximum,1) * (parent.bg:GetWidth()-6) )

        -- Player is controlling a siege weapon
        elseif ( ( IsPlayerControllingSiegeWeapon() or IsPlayerEscortingRam() ) ) then
            -- Set the context
            parent.context = "siege"

            -- Change the icon and color
            parent.icon:SetTexture("/esoui/art/icons/mapkey/mapkey_borderkeep.dds")
            parent.bg:SetCenterColor(0.2,0,0,1)
            parent.bar:SetColor(0.8,0,0,1)

            -- Fetch the current siege health level
            local current, maximum, effectiveMax = GetUnitPower( 'controlledsiege' , POWERTYPE_HEALTH )
            parent.bar:SetWidth( math.min(current/maximum,1) * (parent.bg:GetWidth()-6) )

        -- Player is above level 50
        elseif ( FTC.Player.level >= 50 ) then
            -- Set the context
            parent.context = "exp"

            -- Bail if the bar is disabled
            if ( not FTC.Vars.EnableXPBar ) then 
                parent:SetHidden(true)  
                return 
            end
            
            -- Setup placeholders
            local icon = nil
            local color = nil

            -- Get champion rank
            local rank = GetChampionPointPoolForRank(GetPlayerChampionPointsEarned())

            -- The Warrior
            if ( rank == 2 ) then 
                icon = "/esoui/art/champion/champion_points_health_icon-hud-32.dds"
                color = {0.6,0.2,0}

            -- The Mage
            elseif ( rank == 0 ) then
                icon = "/esoui/art/champion/champion_points_magicka_icon-hud-32.dds"
                color = {0,0.6,1}
            
            -- The Thief
            else
                icon = "/esoui/art/champion/champion_points_stamina_icon-hud-32.dds"
                color = {0.3,0.6,0.1}
            end

            -- Change the icon and color
            parent.icon:SetTexture(icon)
            parent.bg:SetCenterColor(color[1]/6,color[2]/6,color[3]/6,1)
            parent.bar:SetColor(unpack(color))  
            
            -- Fetch the current experience level
			maxExp = GetNumChampionXPInChampionPoint(FTC.Player.clevel)
            currExp = GetPlayerChampionXP()
			if maxExp == nil then
				maxExp = 1
				currExp = 1
			end
            parent.bar:SetWidth( math.min(currExp/maxExp,1) * (parent.bg:GetWidth()-6) )

        -- Player is below level 50
        else
            -- Set the context
            parent.context = "exp"

            -- Bail if the bar is disabled
            if ( not FTC.Vars.EnableXPBar ) then 
                parent:SetHidden(true)  
                return 
            end

            -- Change the icon and color
            parent.icon:SetTexture("/esoui/art/compass/quest_icon_assisted.dds")
            parent.bg:SetCenterColor(0,0.1,0.1,1)
            parent.bar:SetColor(0,1,1,1)

            -- Fetch the current experience level
            maxExp = GetUnitXPMax('player')
            currExp = FTC.Player.exp
            parent.bar:SetWidth( math.min(currExp/maxExp,1) * (parent.bg:GetWidth()-6) )
        end

        -- Ensure bar visibility
        parent:SetHidden(false)     
    end
     
     --[[ 
     * Update Mount Stamina Bar
     * --------------------------------
     * Called by FTC.OnPowerUpdate()
     * --------------------------------
     ]]--
    function FTC.Frames:UpdateMount( powerValue , powerMax , powerEffectiveMax )

        -- Get the alternate bar
        local parent    = _G["FTC_PlayerFrame_Alt"]
        
        -- Bail if the bar is currently used for something else
        if ( parent.context ~= "mount" ) then return end
        
        -- Change the bar width
        parent.bar:SetWidth( ( powerValue / powerEffectiveMax ) * ( parent.bg:GetWidth()-6 ) )
    end

     --[[ 
     * Update Siege Health Bar
     * --------------------------------
     * Called by FTC.OnPowerUpdate()
     * --------------------------------
     ]]--
     function FTC.Frames:UpdateSiege( powerValue , powerMax , powerEffectiveMax )
     
        -- Get the alternate bar
        local parent    = _G["FTC_PlayerFrame_Alt"]
        
        -- Bail if the bar is currently used for something else
        if ( parent.context ~= "siege" ) then return end

        -- Change the bar width
        parent.bar:SetWidth( ( powerValue / powerEffectiveMax ) * ( parent.bg:GetWidth()-6 ) )
    end
     
     --[[ 
     * Update Werewolf Remaining Timer
     * --------------------------------
     * Called by FTC.OnPowerUpdate()
     * --------------------------------
     ]]--
    function FTC.Frames:UpdateWerewolf( powerValue , powerMax , powerEffectiveMax )

        -- Get the alternate bar
        local parent    = _G["FTC_PlayerFrame_Alt"]
        
        -- Bail if the bar is currently used for something else
        if ( parent.context ~= "werewolf" ) then return end
        
        -- Change the bar width
        parent.bar:SetWidth( math.min(powerValue/powerEffectiveMax,1) * ( parent:GetWidth()-6 ) )
    end


--[[----------------------------------------------------------
    UPDATING
  ]]----------------------------------------------------------

     --[[ 
     * Safety Check Function to Ensure Accuracy
     * --------------------------------
     * Called by FTC.Frames:Initialize()
     * --------------------------------
     ]]--
    function FTC.Frames:SafetyCheck()

        -- Don't update the player in combat
        if ( FTC.Vars.PlayerFrame and ( not IsUnitInCombat('player') ) ) then

            -- Make sure attributes are up to date
            if ( not FTC.inMenu ) then
                FTC.Player:UpdateAttribute( 'player',POWERTYPE_HEALTH,nil,nil,nil  )
                FTC.Player:UpdateAttribute( 'player',POWERTYPE_MAGICKA,nil,nil,nil )
                FTC.Player:UpdateAttribute( 'player',POWERTYPE_STAMINA,nil,nil,nil )
                FTC.Player:UpdateShield(    'player',nil,nil )
            end

            -- Make sure fade is correct
            FTC.Frames:Fade('player',FTC_PlayerFrame)
        end

        -- Group frames
		local hasLocalCompanion = HasActiveCompanion() or HasPendingCompanion()
		local hasLocalCompanionOnly = hasLocalCompanion and FTC.Group.members == 0
		local inGroup = IsUnitGrouped('player')
        if ( IsUnitGrouped('player') or hasLocalCompanion ) then
            local context   = nil
            if (  FTC.Group.members <= 4 and FTC.Vars.GroupFrames ) then context = "Group"
            elseif ( FTC.Vars.RaidFrames ) then context = "Raid"
            else return end

            -- Update attributes out of combat
            local max = FTC.Group.members
		    if ( hasLocalCompanionOnly ) then
			    max = FTC.Vars.GroupHidePlayer and 1 or 2
            end
            for i = 1 , max do
                if ( not IsUnitInCombat('player') ) then 
					local unitTag = GetGroupUnitTagByIndex(i)
					if ( hasLocalCompanionOnly ) then
						if ( FTC.Vars.GroupHidePlayer ) then
							unitTag = "companion"
						else
							unitTag = i == 1 and "player" or "companion"
						end
					end

					local companionTag = GetCompanionUnitTagByGroupUnitTag(unitTag)					
					if companionTag then
						unitTag = companionTag
					end

					FTC.Player:UpdateAttribute( unitTag,POWERTYPE_HEALTH,nil,nil,nil )
				end

                FTC.Frames:GroupRange( unitTag , nil )
            end
        end
    end