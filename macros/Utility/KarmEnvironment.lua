-- Macro to list out all the Global elements and then to list out everything in the Karm Hierarchy

function T2String(t,texclude)
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)
	rL[rL.cL] = {}
	do
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)
		rL[rL.cL].pre = ""
		rL[rL.cL].str = ""
		rL[rL.cL].t = t
		while true do
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)
			rL[rL.cL]._var = k
			if not k and rL.cL == 1 then
				break
			elseif not k then
				-- go up in recursion level
--[[				if string.sub(rL[rL.cL].str,-1,-1) == "," then
					rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)
				end]]
				--wx.wxMessageBox("GOING UP:     "..rL[rL.cL].str)
				rL[rL.cL-1].str = rL[rL.cL-1].str..rL[rL.cL].str--.."}"
				rL.cL = rL.cL - 1
				rL[rL.cL+1] = nil
				rL[rL.cL].str = rL[rL.cL].str.."\n"
			else
				-- Handle the key and value here
				local key
				if type(k) == "number" then
					key = "["..tostring(k).."]"
				else
					key = "."..tostring(k)
				end
				rL[rL.cL].str = rL[rL.cL].str..rL[rL.cL].pre..key.."="..type(v)				
				if type(v) == "table" then
					-- Check if this is not a recursive table
					local goDown = true
					for i = 1, rL.cL do
						if v==rL[i].t then
							-- This is recursive do not go down
							goDown = false
							rL[rL.cL].str = rL[rL.cL].str.."(Recursive)"
							break
						end
					end
					rL[rL.cL].str = rL[rL.cL].str.."\n"
					if goDown then
						-- Check if this is an exclude table
						for i = 1,#texclude do
							if texclude[i] == v then
								goDown = false
								break
							end
						end
					end
					if goDown then
						-- Go deeper in recursion
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)
						rL[rL.cL].pre = rL[rL.cL-1].pre..key
						rL[rL.cL].str = ""
						rL[rL.cL].t = v
						--wx.wxMessageBox("GOING DOWN:"..tostring(k))
					end
				else
					rL[rL.cL].str = rL[rL.cL].str.."\n"
				end		-- if type(v) == "table" then ends
			end		-- if not rL[rL.cL]._var and rL.cL == 1 then ends
		end		-- while true ends here
	end		-- do ends
	return rL[rL.cL].str
end


-- First display the  Global table
local str = "----------------------------GLOBAL TABLE-----------------------------\n"
for k,v in pairs(_G) do
	if type(k) == "number" then
		str = str.."["..tostring(k).."]="..type(v).."\n"
	else
		str = str..tostring(k).."="..type(v).."\n"
	end
end
str = str.."\n\n----------------------------KARM TABLE-----------------------------\n"
str = str..T2String(Karm,{Karm.SporeData,Karm.Filter, Karm.Spores, Karm.GUI.MainMenu})
local file,err = io.open("KarmEnvironment.txt","w+")
file:write(str)
file:close()
wx.wxMessageBox("Written to KarmEnvironment.txt")