-- Copyright 2015 Antonio Malcolm
--   
-- This file, and all contents herein, is subject to the terms of the Mozilla Public License, v. 2.0. 
-- If a copy of the MPL was not distributed with this file, 
-- you can obtain one at http://mozilla.org/MPL/2.0/.
--
-- conky-curves-system-informatics-colors.lua - Generates usage curves with percentage arcs, useful in describing the states of various system resources. 
--
-- v2015.07.27
--
-- Authored by Antonio Malcolm

require 'cairo'


-- Responsible for drawing the reporting objects to the Conky window,
-- and provides encapsulation for the logic reponsible for doing so.
--
-- cairoContext - Cairo Context object, required, used to draw to the Conky X window
local function drawToConkyWindow(cairoContext)

  -- This is simply a default CPU setting, to ensure reporting of at least the average CPU load.
  -- You can probably leave it alone.
  -- If your system supports nproc and Lua's io.popen(), they will be used to populate this variable dynamically.
  -- Otherwise, change this to the number of CPUs, cores, or threads for which reporting curves should be drawn.
  local cpuCount = 0

  local colorHexidecimals = {0xe5c81c, 0x1faaf0, 0xef5721, 0x7d1346, 0x28c036, 0xc32546, 0x1e557c, 0xa16ac7}
  local backgroundAlphaLowerBound = 0.35
  local backgroundAlphaUpperBound = 0.65

  -- In the case of multiple reporting curves which are related and grouped (such as when reporting for multiple CPUs),
  -- this provides successive stepping of alpha transparency for each background curve, from most to least transparent,
  -- to achieve the visual effect of gradation (makes for improved readablity and aesthetics)
  local function getBackgroundAlphaSteps(stepCount)

    if stepCount <= 1
    then
      return {backgroundAlphaUpperBound}
    end

    local alphaSteps = {backgroundAlphaLowerBound}
    local alphaBoundsQuotient = (backgroundAlphaUpperBound - backgroundAlphaLowerBound) / stepCount

    for idx = 1, (stepCount - 2) 
    do
      table.insert(alphaSteps, (alphaSteps[idx] + alphaBoundsQuotient))
    end

    table.insert(alphaSteps, backgroundAlphaUpperBound)

    return alphaSteps

  end


  -- Provides a mechanism for ensuring a color hexidecmial is returned from the array of available color hexidecimals.
  -- In the case that a provided index is out of bounds of the array, or no index is provided,
  -- a random index within bounds will be generated, and the hexidecimal at that index will be returned.
  -- 
  -- idx - number, optional, the index at which the color hexidecimal is located, or, 
  --       if the index is out of bounds, or not provided, a randomly-selected hexidecimal is returned
  local function getColorHexidecmial(idx)

    local colorCount = table.getn(colorHexidecimals)

    if idx == nil or idx > colorCount
    then
      idx = math.random(1, colorCount)
    end

    return colorHexidecimals[idx]

  end


  -- Returns the object which describes the report curve to be drawn, as requested by name.
  -- Provides encapsulation of reusable objects which describe available report curves.
  -- (If the user wishes to modify a descriptor object, they should copy the object returned by this function,
  -- rather than modify what is intended to be reused, in order to reduce the risk of affecting other curves
  -- which might share the same reusable descriptor object).
  --
  -- name - string, required, the name associated with the descriptor object to be returned
  local function getCurveDescriptor(name)

    local curveDescriptors = {

      cpu = {
        percentage_divisor = 100,
        position_x = 346, 
        position_y = 324,
        radius = 22,
        weight = 18,
        angle_start = 0,
        angle_end = 240,
        color = getColorHexidecmial(3),
        alpha = 0.95,
        background_color = 0x091219,
        background_alpha = backgroundAlphaUpperBound  
      },

      memory = {
        percentage_divisor = 100,
        position_x = 75, 
        position_y = 578,
        radius = 66,
        weight = 18,
        angle_start = 360,
        angle_end = 66,
        color = getColorHexidecmial(5),
        alpha = 0.95,
        background_color = 0x091219,
        background_alpha = backgroundAlphaUpperBound  
      },

      battery = {
        percentage_divisor = 100,
        position_x = 166, 
        position_y = 696,
        radius = 44,
        weight = 18,
        angle_start = 360,
        angle_end = 120,
        color = getColorHexidecmial(4),
        alpha = 0.95,
        background_color = 0x091219,
        background_alpha = backgroundAlphaUpperBound  
      },

      volume_use = {
        percentage_divisor = 100,
        position_x = 456, 
        position_y = 734,
        radius = 66,
        weight = 18,
        angle_start = 0,
        angle_end = 240,
        color = getColorHexidecmial(7),
        alpha = 0.95,
        background_color = 0x091219,
        background_alpha = backgroundAlphaUpperBound  
      },

      network_wired = {
        -- assumes gigabit...
        percentage_divisor = 122070,
        position_x = 105, 
        position_y = 854,
        radius = 66,
        weight = 18,
        angle_start = 360,
        angle_end = 120,
        color = getColorHexidecmial(1),
        alpha = 0.95,
        background_color = 0x091219,
        background_alpha = backgroundAlphaUpperBound  
      },

      network_wireless = {
        -- assumes wireless-n...
        percentage_divisor = 36621,
        position_x = 405, 
        position_y = 982,
        radius = 66,
        weight = 18,
        angle_start = 0,
        angle_end = 240,
        color = getColorHexidecmial(1),
        alpha = 0.95,
        background_color = 0x091219,
        background_alpha = backgroundAlphaUpperBound  
      }

    }

    return curveDescriptors[name]

  end

  
  -- Converts a hexidecimal number and alpha number into decimal numbers with the appended alpha number digestable by Cairo method cairo_set_source_rgba(). 
  --
  -- hexidecimal - number, required, the color hexidecimal to be converted to decimals
  -- alpha - number, the alpha transparency to be appended to the converted decimals
  local function getDecimalsAndAlphaFromHexAndAlpha(hexidecimal, alpha)
	  return ((hexidecimal / 0x10000) % 0x100) / 255., ((hexidecimal / 0x100) % 0x100) / 255., (hexidecimal % 0x100) / 255., alpha
  end


  -- Draws a percentage-based reporting curve to the Conky window, via cairo,
  -- by way of a background curve (which represents the whole) overlaid by an arc (which represents a percent of the whole).
  --
  -- curveDescriptor - required, object, contains attributes which describe the look and position of the curve
  -- percentage - object, required, the percentage to be displayed as an arc against the curve
  local function drawPercentageCurve(curveDescriptor, percentage)

	  local positionX, positionY = curveDescriptor['position_x'], curveDescriptor['position_y']
    local angleStart, angleEnd = curveDescriptor['angle_start'], curveDescriptor['angle_end']
    local radius, weight = curveDescriptor['radius'], curveDescriptor['weight']
	  local color, alpha, backgroundColor, backgroundAlpha = curveDescriptor['color'], curveDescriptor['alpha'], curveDescriptor['background_color'], curveDescriptor['background_alpha']

	  angleStart = angleStart * (2 * (math.pi / 360)) - (math.pi / 2)
	  angleEnd = angleEnd * (2 * (math.pi / 360)) - (math.pi / 2)

	  local arcLength = percentage * (angleEnd - angleStart)
    local isInverted = angleStart > angleEnd

	  -- draw the curve...

    if isInverted
    then
      cairo_arc_negative(cairoContext, positionX, positionY, radius, angleStart, angleEnd)
    else
      cairo_arc(cairoContext, positionX, positionY, radius, angleStart, angleEnd)
    end

	  cairo_set_source_rgba(cairoContext, getDecimalsAndAlphaFromHexAndAlpha(backgroundColor, backgroundAlpha))
	  cairo_set_line_width(cairoContext, weight)
	  cairo_stroke(cairoContext)

	  -- draw the percentage arc...

    angleEnd = angleStart + arcLength

    if isInverted
    then
      cairo_arc_negative(cairoContext, positionX, positionY, radius, angleStart, angleEnd)
    else
      cairo_arc(cairoContext, positionX, positionY, radius, angleStart, angleEnd)
    end

	  cairo_set_source_rgba(cairoContext, getDecimalsAndAlphaFromHexAndAlpha(color, alpha))
	  cairo_stroke(cairoContext)

  end


  -- Draws a percentage-based reporting curve to the Conky window, using reporting data provided by Conky.
  --
  -- curveDescriptor - object, required, contains attributes which describe the look and position of the curve
  -- conkyArg - string, required, the argument used by Conky to obtain the reporting data
  local function drawPercentageCurveFromConkyValue(curveDescriptor, conkyArg)

  	local conkyValue = conky_parse(conkyArg)

	  if conkyValue ~= nil 
    then 

      conkyValue = tonumber(conkyValue)
	    conkyValue = conkyValue / curveDescriptor['percentage_divisor']

	    drawPercentageCurve(curveDescriptor, conkyValue)

    end

  end


  -- draw CPUs (or cores, or threads, whichever the case may be)

  -- start by attempting to get the number of CPUs, cores, or threads from the system...
  local nprocResponseOk, nprocResponse = pcall(io.popen, 'nproc')

  -- in case the user's system doesn't support Lua's io.popen()...

  if nprocResponseOk and nprocResponse
  then

    cpuCount = nprocResponse:read('*a')
    nprocResponse:close()

    if cpuCount == nil
    then

      -- revert to default (report average CPU load)...
      cpuCount = 0

    else
      cpuCount = tonumber(cpuCount)
    end

  end

  if cpuCount > 0
  then

    local alphaSteps = getBackgroundAlphaSteps(cpuCount)

    -- Step backwards through the number of CPUs (or cores, or threads), so the first curve is always outermost...

    for idx = cpuCount, 1 , -1
    do

      -- because we are stepping backwards through the CPU count, 
      -- we need to obtain the inverse of the current index, 
      -- to set (increase) the radius for each new curve,
      -- as well as ensure that data obtained from arrays are taken from the correct indices...
   
      local idxInverse = (cpuCount - idx) + 1

      local cpuCurveDescriptor = getCurveDescriptor('cpu')
      cpuCurveDescriptor['radius'] = cpuCurveDescriptor['radius'] * idxInverse
      cpuCurveDescriptor['color'] = getColorHexidecmial(idx)
      cpuCurveDescriptor['background_alpha'] = alphaSteps[idxInverse]

      local conkyArg = string.format('${%s %s%s}', 'cpu', 'cpu', idx)

      drawPercentageCurveFromConkyValue(cpuCurveDescriptor, conkyArg)

    end

  else

    -- default to displaying the average overall CPU load...

    local cpuCurveDescriptor = getCurveDescriptor('cpu')
    cpuCurveDescriptor['radius'] = cpuCurveDescriptor['radius'] * 3

    drawPercentageCurveFromConkyValue(cpuCurveDescriptor, '${cpu cpu0}')

  end


  -- draw RAM and swap...

  local nextCurveDescriptor = getCurveDescriptor('memory')
  nextCurveDescriptor['radius'] = 44
  nextCurveDescriptor['weight'] = 14
  nextCurveDescriptor['color'] = getColorHexidecmial(8)
  nextCurveDescriptor['background_alpha'] = backgroundAlphaLowerBound

  drawPercentageCurveFromConkyValue(getCurveDescriptor('memory'), '$memperc')
  drawPercentageCurveFromConkyValue(nextCurveDescriptor, '$swapperc')


  -- draw volumes...

  nextCurveDescriptor = getCurveDescriptor('volume_use')
  nextCurveDescriptor['radius'] = 44
  nextCurveDescriptor['color'] = getColorHexidecmial(4)
  nextCurveDescriptor['background_alpha'] = getBackgroundAlphaSteps(4)[3]

  drawPercentageCurveFromConkyValue(getCurveDescriptor('volume_use'), '${fs_used_perc /}')
  drawPercentageCurveFromConkyValue(nextCurveDescriptor, '${fs_used_perc /home}')
  
  
  -- draw battery...

  drawPercentageCurveFromConkyValue(getCurveDescriptor('battery'), '${battery_percent BAT0}')


  -- draw wired network...

  nextCurveDescriptor = getCurveDescriptor('network_wired')
  nextCurveDescriptor['radius'] = 44
  nextCurveDescriptor['weight'] = 14
  nextCurveDescriptor['color'] = getColorHexidecmial(4)
  nextCurveDescriptor['background_alpha'] = getBackgroundAlphaSteps(4)[3]

  drawPercentageCurveFromConkyValue(getCurveDescriptor('network_wired'), '${downspeedf enp0s25}')
  drawPercentageCurveFromConkyValue(nextCurveDescriptor, '${upspeedf enp0s25}')


  -- draw wireless network...

  nextCurveDescriptor = getCurveDescriptor('network_wireless')
  nextCurveDescriptor['radius'] = 44
  nextCurveDescriptor['weight'] = 14
  nextCurveDescriptor['color'] = getColorHexidecmial(4)
  nextCurveDescriptor['background_alpha'] = getBackgroundAlphaSteps(4)[3]

  drawPercentageCurveFromConkyValue(getCurveDescriptor('network_wireless'), '${downspeedf wlp3s0}')
  drawPercentageCurveFromConkyValue(nextCurveDescriptor, '${upspeedf wlp3s0}')

end


-- Sets up the Cairo context, using the Conky display, 
-- and passes it on to functions responsible for drawing data to the Conky window.
-- Used by Conky, should be added to your Conky config (conkyrc) file, like so:
-- lua_draw_hook_pre = 'conky_main'
function conky_main()

	if conky_window == nil 
  then 
    return 
  end

	local cairoSurface = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
	local cairoContext = cairo_create(cairoSurface)	

	if cairoContext == nil 
  then 
    return 
  end
	
	local updates = conky_parse('${updates}')
	updates = tonumber(updates)

  -- in the case cpu updates are present in the curve descriptors, to prevent segfaults, 
  -- ensure conky has had at least five updates, before drawing to the screen...

	if updates > 5 
  then
    drawToConkyWindow(cairoContext)
  end

  cairo_surface_destroy(cairoSurface)
  cairo_destroy(cairoContext)

end