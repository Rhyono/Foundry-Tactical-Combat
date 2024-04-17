--[[----------------------------------------------------------
	FTC CORE FUNCTIONS
  ]]----------------------------------------------------------
local FTC = FTC

--[[
* A handy chaining function for quickly setting up UI elements
* Allows us to reference methods to set properties without calling the specific object
]]--
function FTC.Chain(object)

  -- Setup the metatable
  local T = {}
  setmetatable(T, { __index = function(self, func)

    -- Know when to stop chaining
    if func == "__END" then return object end

    -- Otherwise, add the method to the parent object
    return function(self, ...)
      assert(object[func], func .. " missing in object")
      object[func](object, ...)
      return self
    end
  end })

  -- Return the metatable
  return T
end

--[[
 * Append Table 2 to Table 1
 * --------------------------------
 * Called by Default Vars
 * --------------------------------
 ]]--
function FTC:JoinTables(t1, t2)
  t1 = t1 or {}
  t2 = t2 or {}
  for k, v in pairs(t2) do t1[k] = v end
  return t1
end

--[[
 * Display Addon Welcome Message / Notes
 * --------------------------------
 * Called by FTC:OnLoad()
 * --------------------------------
 ]]--
function FTC.Welcome()

  -- Show welcome message
  if (FTC.Vars.welcomed ~= FTC.version) then
    --[[ Disabled for now due to lack of need
    -- Only show welcome message for English clients
    if ( FTC.language == "en" ) then

      -- Add welcome message content
      FTC.inWelcome = true
      FTC.UI:Welcome()

            local buffer  = FTC_Welcome:GetNamedChild("Buffer")
            local slider  = FTC_Welcome:GetNamedChild("Slider")

            -- Set the welcome position
            buffer:SetScrollPosition(1)
            slider:SetValue(buffer:GetNumHistoryLines()-1)
            slider:SetHidden(false)
            welcome:SetHidden(false)
            FTC_UI:SetAlpha(0)
        end
    --]]

    -- Register that the user has been welcomed
    FTC.Vars.welcomed = FTC.version

    --until reenabled
    welcome:SetHidden(true)
    FTC_UI:SetAlpha(100)
    -- Do not show
  else
    welcome:SetHidden(true)
    FTC_UI:SetAlpha(100)
  end
end

--[[
* Handle Special Visibility Needs
* --------------------------------
* Called by FTC.OnLayerChange()
* --------------------------------
]]--
function FTC:ToggleVisibility(activeLayerIndex)

  -- We only need to act if it's in move, or welcome mode
  if not (FTC.move or FTC.inWelcome) then return end

  -- Maybe get action layer
  activeLayerIndex = activeLayerIndex or GetNumActiveActionLayers()

  -- Maybe disable move mode
  if (FTC.move and activeLayerIndex > 3) then FTC.Menu:MoveFrames(false) end

  -- Maybe disable welcome message
  if (FTC.inWelcome and activeLayerIndex > 2) then FTC.Welcome() end
end

--[[
* Return Localized Delimited Number
* --------------------------------
* Called by (many)
* --------------------------------
]]--
function FTC.DisplayNumber(number, places)

  -- Determine thousands and decimal format
  local thousands = FTC.language == "en" and "," or "."
  local decimal = FTC.language == "en" and "." or ","

  -- If no places were passed assume zero
  places = places or 0
  local output = 0

  -- If the number is less than 1000
  if (number < 1000) then
    output = string.format("%." .. places .. "f", number)
    output = string.gsub(output, "%.", decimal)

    -- Greater than 1000 with decimals
  elseif (number >= 1000 and places > 0) then
    output = string.format("%." .. places .. "f", number)
    local left, right = zo_strsplit("%.", output)
    left = FormatIntegerWithDigitGrouping(left, thousands)
    output = left .. decimal .. right

    -- Greater than 1000 no decimals
  else
    output = FormatIntegerWithDigitGrouping(number, thousands)
  end

  -- Return the output
  return output
end
