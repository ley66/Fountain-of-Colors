-- ColorChanger v3.0.3, A modification of ColorChanger v1.3 by Smurfier
-- LICENSE: Creative Commons Attribution-Non-Commercial-Share Alike 3.0

function Initialize()
  random, floor, concat = math.random, math.floor, table.concat
  parent, childTotal, child, childhInvert = 0, 0, {}, {}
  color, colorIdx, hColorIdx, hPosNorm, cacheColor = {}, {}, {}, {}, {}
  for b = 1, 8 do hColorIdx[b] = {} end
  measure, meterName, option = {}, {}, SELF:GetOption("MeterOption")
  hInvert = SELF:GetNumberOption("hInvert")
  hBlendingMultiplier, vBlendingMultiplier = SELF:GetNumberOption("hBlendingMultiplier"), SELF:GetNumberOption("vBlendingMultiplier")
  opacityMultiplier, opacityLower, opacityUpper = SELF:GetNumberOption("OpacityMultiplier"), SELF:GetNumberOption("OpacityLower"), SELF:GetNumberOption("OpacityUpper")
  hLowerLimit, hUpperLimit = SELF:GetNumberOption("hLowerLimit") + 1, SELF:GetNumberOption("hUpperLimit") + 1
  for i = hLowerLimit, hUpperLimit do
    cacheColor[i], colorIdx[i], hPosNorm[i] = 0, {}, hInvert == 0 and (i / hUpperLimit) * hBlendingMultiplier or (1 - (i / hUpperLimit)) * hBlendingMultiplier
	measure[i], meterName[i] = SKIN:GetMeasure(SELF:GetOption("MeasureBaseName") .. i-1), SELF:GetOption("MeterBaseName") .. i-1
	for c = 1, 4 do colorIdx[i][c] = {} end
  end
  updateWhenZero = SELF:GetNumberOption("UpdateWhenZero")
  transitionTime = math.ceil(SELF:GetOption("TransitionTime") * 1000 / 16)
  enableTransition, enableHorizontalTransition = 0, 0
  counterNorm, counter = {}, transitionTime
  for i = 1, transitionTime do counterNorm[i] = i / transitionTime end
  SKIN:Bang("!UpdateMeasure", "EnableColorTransition")
  SKIN:Bang("!UpdateMeasure", "SetColors")
end

function SetParent() parent = 1 end
function AddChild(name, hInvert) child[childTotal + 1], childhInvert[childTotal + 1], childTotal, counter = name, hInvert, childTotal + 1, transitionTime end

function HorizontalInterpolation()
  for i = hLowerLimit, hUpperLimit do
    local c, hPosNorm = 1, hPosNorm[i]
	for b = 1, 8, 2 do
      for a = 1, 3 do
	    colorIdx[i][c][a] = (hColorIdx[b][a] * (1 - hPosNorm) + hColorIdx[b+1][a] * hPosNorm)
	  end
	  c = c + 1
	end
  end
end

function Transition()
  if enableHorizontalTransition ~= 0 then
    for b = 1, 4 do
      for a = 1, 3 do
	    hColorIdx[b][a] = hColorIdx[b+4][a]
	    for k = 1, childTotal do
	      SKIN:Bang("!CommandMeasure", "ScriptColorChanger", "hColorIdx[" .. b .. "][" .. a .. "] = " .. hColorIdx[b][a], child[k])
        end
	  end
    end
    SKIN:Bang("!UpdateMeasure", "SetColors")
    HorizontalInterpolation()
    counter = 1
    for k = 1, childTotal do
      for b = 1, 4 do
        for a = 1, 3 do
          SKIN:Bang("!CommandMeasure", "ScriptColorChanger", "hColorIdx[" .. b+4 .. "][" .. a .. "] = " .. hColorIdx[b+4][a], child[k])
        end
      end
      SKIN:Bang("!CommandMeasure", "ScriptColorChanger", "HorizontalInterpolation(); counter = 1", child[k])
    end
  else
	for i = hLowerLimit, hUpperLimit do
	  for a = 1, 3 do 
		colorIdx[i][1][a], colorIdx[i][2][a] = colorIdx[i][3][a], colorIdx[i][4][a]
      end
	end
	for k = 1, childTotal do
	  for i = hLowerLimit, hUpperLimit do
	    local idx, childIdx = hInvert == 0 and i or (hLowerLimit + hUpperLimit - i), childhInvert[k] == 0 and i or (hLowerLimit + hUpperLimit - i)
	    for a = 1, 3 do 
	      SKIN:Bang("!CommandMeasure", "ScriptColorChanger", "colorIdx[" .. childIdx .. "][1][" .. a .. "], colorIdx[" .. childIdx  .. "][2][" .. a .. "] = " .. colorIdx[idx][1][a] .. "," .. colorIdx[idx][2][a], child[k])
        end
	  end
	end
    SKIN:Bang("!UpdateMeasure", "SetColors")
	counter = 1
	for k = 1, childTotal do
      for i = hLowerLimit, hUpperLimit do
	    local idx, childIdx = hInvert == 0 and i or (hLowerLimit + hUpperLimit - i), childhInvert[k] == 0 and i or (hLowerLimit + hUpperLimit - i)
        for a = 1, 3 do
		  SKIN:Bang("!CommandMeasure", "ScriptColorChanger", "colorIdx[" .. childIdx .. "][3][" .. a .. "], colorIdx[" .. childIdx .. "][4][" .. a .. "] = " .. colorIdx[idx][3][a] .. "," .. colorIdx[idx][4][a], child[k])
		end
      end
	  SKIN:Bang("!CommandMeasure", "ScriptColorChanger", "counter = 1", child[k])
	end
  end
end

function Update()
  if enableTransition ~= 0 then
    if counter ~= transitionTime then counter = counter + 1
    elseif parent ~= 0 then Transition()
	else return 0 end
  end
  for i = hLowerLimit, hUpperLimit do
    if measure[i]:GetValue() ~= 0 or updateWhenZero ~= 0 then
	  local color, colorIdx, counterNorm = color, colorIdx[i], counterNorm[counter]
	  local blendingValue, opacityValue = vBlendingMultiplier * measure[i]:GetValue(), opacityMultiplier * measure[i]:GetValue()
	  if blendingValue > 1 then blendingValue = 1 end
	  local blendingValueRe, counterNormRe = 1 - blendingValue, 1 - counterNorm
	  if enableTransition ~= 0 then
        for a = 1, 3 do
          color[a] = floor((colorIdx[1][a] * counterNormRe + colorIdx[3][a] * counterNorm) * blendingValueRe + (colorIdx[2][a] * counterNormRe + colorIdx[4][a] * counterNorm) * blendingValue + 0.5)
        end
	  else
	    for a = 1, 3 do 
		  color[a] = floor(colorIdx[1][a] * blendingValueRe + colorIdx[2][a] * blendingValue + 0.5)
		end
      end
	  if opacityValue > 1 then opacityValue = 1 end
      color[4] = floor(opacityLower * (1 - opacityValue) + opacityUpper *  opacityValue + 0.5)
	  color = concat(color, ",")
	  if color ~= cacheColor[i] then
	    cacheColor[i] = color
		SKIN:Bang("!SetOption", meterName[i], option, color)
	  end
	end
  end
end