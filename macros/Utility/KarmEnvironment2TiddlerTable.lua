-- Macro to list out all the Global elements and then to list out everything in the Karm Hierarchy

function T2String(t,texclude)
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)
	rL[rL.cL] = {}
	do
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)
		rL[rL.cL].pre = "Karm"
		rL[rL.cL].str = {}
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
				for i = 1,#rL[rL.cL].str do
					rL[rL.cL-1].str[#rL[rL.cL-1].str+1] = rL[rL.cL].str[i]
				end
				rL.cL = rL.cL - 1
				rL[rL.cL+1] = nil
			else
				-- Handle the key and value here
				local key
				if type(k) == "number" then
					key = "["..tostring(k).."]"
				else
					key = "."..tostring(k)
				end
				rL[rL.cL].str[#rL[rL.cL].str+1] = {k=rL[rL.cL].pre..key,v=type(v)}
				-- rL[rL.cL].str..'| style="border-style: solid; border-width: 1px"| '.."[[Karm"..rL[rL.cL].pre..key.."|"..string.rep("_",rL.cL)..rL[rL.cL].pre..key..']]\n| style="border-style: solid; border-width: 1px"| '..type(v)				
				if type(v) == "table" then
					-- Check if this is not a recursive table
					local goDown = true
					for i = 1, rL.cL do
						if v==rL[i].t then
							-- This is recursive do not go down
							goDown = false
							rL[rL.cL].str[#rL[rL.cL].str].v = rL[rL.cL].str[#rL[rL.cL].str].v.."(Recursive)"
							break
						end
					end
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
						rL[rL.cL].str = {}
						rL[rL.cL].t = v
						--wx.wxMessageBox("GOING DOWN:"..tostring(k))
					end
				end		-- if type(v) == "table" then ends
			end		-- if not rL[rL.cL]._var and rL.cL == 1 then ends
		end		-- while true ends here
	end		-- do ends
	return rL[rL.cL].str
end


local str = '| ! Object | ! Type |'
local texclude = {
					Karm.SporeData,
					Karm.Filter, 
					Karm.Spores, 
					Karm.GUI.MainMenu,
					Karm.Globals.StatusList,
					Karm.Globals.Resources,
					Karm.Globals.StatusNodeColor,
					Karm.Globals.Categories,
					Karm.Globals.SubCategories,
					Karm.Globals.PriorityList
				}
local tab = T2String(Karm,texclude)
local done = false
-- Sort with keys
while not done do
	done = true
	for i = 1,#tab-1 do
		if tab[i].k > tab[i+1].k then
			tab[i],tab[i+1] = tab[i+1],tab[i]
			done = false
		end
	end
end
for i = 1,#tab do
	local _,num = string.gsub(tab[i].k,"%.","o")
	str = str..'\n|[['..tab[i].k.."]] | "..tab[i].v.." |"
	--str = str..tab[i].k.."="..tab[i].v.."\n"
end
str = str.."|}"
local file,err = io.open("KarmEnvironment.txt","w+")
file:write(str)
file:close()
wx.wxMessageBox("Written to KarmEnvironment.txt")