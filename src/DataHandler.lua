Karm.TaskObject = {}
Karm.TaskObject.__index = Karm.TaskObject
-- Table to store the Core values
Karm.Core.TaskObject = {}
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		if Karm.TaskObject.key and not Karm.Core.TaskObject.key then
			Karm.Core.TaskObject.key = Karm.TaskObject.key
		end
		rawset(Karm.TaskObject,key,val)
	end
	setmetatable(Karm.TaskObject,KarmMeta)
end
]]
Karm.Utility = {}
-- Table to store the Core values
Karm.Core.Utility = {}
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		if Karm.Utility.key and not Karm.Core.Utility.key then
			Karm.Core.Utility.key = Karm.Utility.key
		end
		rawset(Karm.Utility,key,val)
	end
	setmetatable(Karm.Utility,KarmMeta)
end
]]
-- Task structure
-- Task.
--	Planning
--  PlanWorkDone.
--	[0] = Task
-- 	SporeFile
--	Title
--	Modified
--	DBDATA
--	TaskID
--	Start
--	Fin
--	Private
--	Who
--	Access
--	Assignee
--	Status
--	Parent = Pointer to the Task to which this is a sub task
--	Priority
--	Due
--	Comments
--	Cat
--	SubCat
--	Tags
--  Estimate
--	Schedules.
--		[0] = "Schedules"
--		Estimate.
--			[0] = "Estimate"
--			count
--			[i] = 
--		Commit.
--			[0] = "Commit"
--		Revs
--		Actual
--	SubTasks.
--		[0] = "SubTasks"
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask this is 
--		tasks = count of number of subtasks
--		[i] = Task table like this one repeated for sub tasks
function Karm.TaskObject.getSummary(task)
	if task then
		local taskSummary = ""
		if not task:IsSpore() then
			-- Get the task hierarchy here
			local tH = ""
			local currTask = task
			while currTask.Parent do
				tH="\n      -->"..currTask.Parent.Title..tH
				currTask = currTask.Parent
			end
			for k,v in pairs(Karm.SporeData) do
				if currTask.SubTasks.parent == v then
					tH = k..tH
					break
				end
			end
			taskSummary = taskSummary.."Hierarchy: "..tH.."\n"
		end
		if task.TaskID then
			taskSummary = taskSummary.."ID: "..task.TaskID.."\n"
		end
		if task.Title then
			taskSummary = taskSummary.."TITLE: "..task.Title.."\n"
		end
		if task.Estimate then
			if Karm.Globals.EstimateUnit == "H" then
				taskSummary = taskSummary.."Estimated Hours: ".. task.Estimate.."\n"
			else
				taskSummary = taskSummary.."Estimated Days: ".. task.Estimate.."\n"
			end
		end
		if task.Start then
			taskSummary = taskSummary.."START DATE: "..task.Start.."\n"
		end
		if task.Fin then
			taskSummary = taskSummary.."FINISH DATE: "..task.Fin.."\n"
		end
		if task.Due then
			taskSummary = taskSummary.."DUE DATE: "..task.Due.."\n"
		end
		if task.Status then
			taskSummary = taskSummary.."STATUS: "..task.Status.."\n"
		end
		-- Responsible People
		if task.Who then
			taskSummary = taskSummary.."PEOPLE: "
			local ACT = ""
			local INACT = ""
			for i=1,task.Who.count do
				if string.upper(task.Who[i].Status) == "ACTIVE" then
					ACT = ACT..","..task.Who[i].ID
				else
					INACT = INACT..","..task.Who[i].ID
				end
			end
			if #ACT > 0 then
				taskSummary = taskSummary.."\n   ACTIVE: "..string.sub(ACT,2,-1)
			end
			if #INACT > 0 then
				taskSummary = taskSummary.."\n   INACTIVE: "..string.sub(INACT,2,-1)
			end
			taskSummary = taskSummary.."\n"
		end
		if task.Access then
			taskSummary = taskSummary.."LOCKED: YES"
			local RA = ""
			local RWA = ""
			for i = 1,task.Access.count do
				if string.upper(task.Access[i].Status) == "READ ONLY" then
					RA = RA..","..task.Access[i].ID
				else
					RWA = RWA..","..task.Access[i].ID
				end
			end
			if #RA > 0 then
				taskSummary = taskSummary.."\n   READ ACCESS PEOPLE: "..string.sub(RA,2,-1)
			end
			if #RWA > 0 then
				taskSummary = taskSummary.."\n   READ/WRITE ACCESS PEOPLE: "..string.sub(RWA,2,-1)
			end
			taskSummary = taskSummary.."\n"
		end
		if task.Assignee then
			taskSummary = taskSummary.."ASSIGNEE: "
			for i = 1,#task.Assignee do
				taskSummary = taskSummary..task.Assignee[i].ID..","
			end
			taskSummary = taskSummary:sub(1,-2).."\n"
		end
		if task.Priority then
			taskSummary = taskSummary.."PRIORITY: "..task.Priority.."\n"
		end
		if task.Private then
			taskSummary = taskSummary.."PRIVATE TASK\n"
		end
		if task.Cat then
			taskSummary = taskSummary.."CATEGORY: "..task.Cat.."\n"
		end
		if task.SubCat then
			taskSummary = taskSummary.."SUB-CATEGORY: "..task.SubCat.."\n"
		end
		if task.Tags then
			taskSummary = taskSummary.."TAGS: "
			for i = 1,#task.Tags do
				taskSummary = taskSummary..task.Tags[i]..","
			end
			taskSummary = taskSummary:sub(1,-2).."\n"
		end
		if task.Comments then
			taskSummary = taskSummary.."COMMENTS:\n"..task.Comments.."\n"
		end
		return taskSummary
	else
		return "No Task Selected"
	end
end

function Karm.validateSpore(Spore)
	if not Spore then
		return nil
	elseif type(Spore) ~= "table" then
		return nil
	elseif Spore[0] ~= "Task_Spore" then
		return nil
	end
	return true
end

function Karm.TaskObject.IsValidTask(task)
	if not (type(task) == "table") then
		return nil
	elseif not task.TaskID then
		return nil
	elseif not task.Title then
		return nil
	elseif not task.Who and task[0] == "Task" then
		return nil
	elseif getmetatable(task) ~= Karm.TaskObject then
		return nil
	end
	if type(checkTask) == "function" then
		local err,msg = checkTask(task)
		if not err then
			return nil
		end
	end
	return true
end


function Karm.TaskObject.getWorkDoneDates(task, planning)
	if planning then
		if task.PlanWorkDone and task.PlanWorkDone.Period then
			local dateList = {}
			for i = 1,#task.PlanWorkDone.Period do
				dateList[#dateList + 1] = task.PlanWorkDone.Period[i].Date
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
			dateList.typeSchedule = task.PlanWorkDone.Type
			dateList.index = task.PlanWorkDone.index
			return dateList
		else
			return nil
		end
	else
		if task.Schedules then
			if task.Schedules.Actual then
				local dateList = {}
				for i = 1,#task.Schedules["Actual"][1].Period do
					dateList[#dateList + 1] = task.Schedules["Actual"][1].Period[i].Date
				end		-- for i = 1,#task.Schedules["Actual"][1].Period do ends
				dateList.typeSchedule = "Actual"
				dateList.index = 1
				return dateList
			else 
				return nil
			end
		else 
			return nil		
		end		-- if task.Schedules then ends
	end		-- if planning then ends
end
-- Function to get the list of dates in the latest schedule of the task.
-- if planning == true then the planning schedule dates are returned
function Karm.TaskObject.getLatestScheduleDates(task,planning)
	local typeSchedule, index
	local dateList = {}
	if planning then
		if task.Planning and task.Planning.Period then
			for i = 1,#task.Planning.Period do
				dateList[#dateList + 1] = task.Planning.Period[i].Date
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
			dateList.typeSchedule = task.Planning.Type
			dateList.index = task.Planning.index
			return dateList
		else
			return nil
		end
	else
		if task.Schedules then
			-- Find the latest schedule in the task here
			if task.Schedules.Revs then
				-- Actual is not the latest one but Revision is 
				typeSchedule = "Revs"
				index = task.Schedules.Revs.count
			elseif task.Schedules.Commit then
				-- Actual and Revisions don't exist but Commit does
				typeSchedule = "Commit"
				index = 1
			elseif task.Schedules.Estimate then
				-- The latest is Estimate
				typeSchedule = "Estimate"
				index = task.Schedules.Estimate.count
			else
				-- task.Schedules can exist if only Actual exists
				return nil
			end
			-- Now we have the latest schedule type in typeSchedule and the index of it in index
			for i = 1,#task.Schedules[typeSchedule][index].Period do
				dateList[#dateList + 1] = task.Schedules[typeSchedule][index].Period[i].Date
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
			dateList.typeSchedule = typeSchedule
			dateList.index = index
			return dateList
		else
			return nil
		end
	end		-- if planning then ends
end

-- Function to convert a table to a string
-- Metatables not followed
-- Unless key is a number it will be taken and converted to a string
function Karm.Utility.tableToString(t)
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)
	rL[rL.cL] = {}
	do
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)
		rL[rL.cL].str = "{"
		rL[rL.cL].t = t
		while true do
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)
			rL[rL.cL]._var = k
			if not k and rL.cL == 1 then
				break
			elseif not k then
				-- go up in recursion level
				if string.sub(rL[rL.cL].str,-1,-1) == "," then
					rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)
				end
				--print("GOING UP:     "..rL[rL.cL].str.."}")
				rL[rL.cL-1].str = rL[rL.cL-1].str..rL[rL.cL].str.."}"
				rL.cL = rL.cL - 1
				rL[rL.cL+1] = nil
				rL[rL.cL].str = rL[rL.cL].str..","
			else
				-- Handle the key and value here
				if type(k) == "number" then
					rL[rL.cL].str = rL[rL.cL].str.."["..tostring(k).."]="
				else
					rL[rL.cL].str = rL[rL.cL].str..tostring(k).."="
				end
				if type(v) == "table" then
					-- Check if this is not a recursive table
					local goDown = true
					for i = 1, rL.cL do
						if v==rL[i].t then
							-- This is recursive do not go down
							goDown = false
							break
						end
					end
					if goDown then
						-- Go deeper in recursion
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)
						rL[rL.cL].str = "{"
						rL[rL.cL].t = v
						--print("GOING DOWN:",k)
					else
						rL[rL.cL].str = rL[rL.cL].str.."\""..tostring(v).."\""
						rL[rL.cL].str = rL[rL.cL].str..","
						--print(k,"=",v)
					end
				elseif type(v) == "number" then
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)
					rL[rL.cL].str = rL[rL.cL].str..","
					--print(k,"=",v)
				else
					rL[rL.cL].str = rL[rL.cL].str..string.format("%q",tostring(v))
					rL[rL.cL].str = rL[rL.cL].str..","
					--print(k,"=",v)
				end		-- if type(v) == "table" then ends
			end		-- if not rL[rL.cL]._var and rL.cL == 1 then ends
		end		-- while true ends here
	end		-- do ends
	if string.sub(rL[rL.cL].str,-1,-1) == "," then
		rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)
	end
	rL[rL.cL].str = rL[rL.cL].str.."}"
	return rL[rL.cL].str
end

-- Creates lua code for a table which when executed will create a table t0 which would be the same as the originally passed table
-- Handles the following types for keys and values:
-- Keys: Number, String, Table
-- Values: Number, String, Table, Boolean
-- It also handles recursive and interlinked tables to recreate them back
function Karm.Utility.tableToString2(t)
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)
	rL[rL.cL] = {}
	local tabIndex = {}	-- Table to store a list of tables indexed into a string and their variable name
	local latestTab = 0
	do
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)
		rL[rL.cL].str = "t0={}"	-- t0 would be the main table
		rL[rL.cL].t = t
		rL[rL.cL].tabIndex = 0
		tabIndex[t] = rL[rL.cL].tabIndex
		while true do
			local key
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)
			rL[rL.cL]._var = k
			if not k and rL.cL == 1 then
				break
			elseif not k then
				-- go up in recursion level
				--print("GOING UP:     "..rL[rL.cL].str.."}")
				rL[rL.cL-1].str = rL[rL.cL-1].str.."\n"..rL[rL.cL].str
				rL.cL = rL.cL - 1
				if rL[rL.cL].vNotDone then
					-- This was a key recursion so add the key string and then doV
					key = "t"..rL[rL.cL].tabIndex.."[t"..tostring(rL[rL.cL+1].tabIndex).."]"
					rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
					v = rL[rL.cL].vNotDone
				end
				rL[rL.cL+1] = nil
			else
				-- Handle the key and value here
				if type(k) == "number" then
					key = "t"..rL[rL.cL].tabIndex.."["..tostring(k).."]"
					rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
				elseif type(k) == "string" then
					key = "t"..rL[rL.cL].tabIndex.."[\""..k.."\"]"
					rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
				else
					-- Table key
					-- Check if the table already exists
					if tabIndex[k] then
						key = "t"..rL[rL.cL].tabIndex.."[t"..tabIndex[k].."]"
						rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
					else
						-- Go deeper to stringify this table
						latestTab = latestTab + 1
						rL[rL.cL].str = rL[rL.cL].str.."\nt"..tostring(latestTab).."={}"	-- New table
						rL[rL.cL].vNotDone = v
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(k)
						rL[rL.cL].tabIndex = latestTab
						rL[rL.cL].t = k
						rL[rL.cL].str = ""
						tabIndex[k] = rL[rL.cL].tabIndex
					end		-- if tabIndex[k] then ends
				end		-- if type(k)ends
			end		-- if not k and rL.cL == 1 then ends
			if key then
				rL[rL.cL].vNotDone = nil
				if type(v) == "table" then
					-- Check if this table is already indexed
					if tabIndex[v] then
						rL[rL.cL].str = rL[rL.cL].str.."t"..tabIndex[v]
					else
						-- Go deeper in recursion
						latestTab = latestTab + 1
						rL[rL.cL].str = rL[rL.cL].str.."{}" 
						rL[rL.cL].str = rL[rL.cL].str.."\nt"..tostring(latestTab).."="..key	-- New table
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)
						rL[rL.cL].tabIndex = latestTab
						rL[rL.cL].t = v
						rL[rL.cL].str = ""
						tabIndex[v] = rL[rL.cL].tabIndex
						--print("GOING DOWN:",k)
					end
				elseif type(v) == "number" then
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)
					--print(k,"=",v)
				elseif type(v) == "boolean" then
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)				
				else
					rL[rL.cL].str = rL[rL.cL].str..string.format("%q",tostring(v))
					--print(k,"=",v)
				end		-- if type(v) == "table" then ends
			end		-- if doV then ends
		end		-- while true ends here
	end		-- do ends
	return rL[rL.cL].str
end

function Karm.Utility.combineDateRanges(range1,range2)
	local comp = Karm.Utility.compareDateRanges(range1,range2)

	local strt1,fin1 = string.match(range1,"(.-)%-(.*)")
	local strt2,fin2 = string.match(range2,"(.-)%-(.*)")
	
	strt1 = Karm.Utility.toXMLDate(strt1)
	local idate = Karm.Utility.XMLDate2wxDateTime(strt1)
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))
	local strt1m1 = Karm.Utility.toXMLDate(idate:Format("%m/%d/%Y"))
	
	fin1 = Karm.Utility.toXMLDate(fin1)
	idate = Karm.Utility.XMLDate2wxDateTime(fin1)
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))
	local fin1p1 = Karm.Utility.toXMLDate(idate:Format("%m/%d/%Y"))

	strt2 = Karm.Utility.toXMLDate(strt2)

	fin2 = Karm.Utility.toXMLDate(fin2)

	if comp == 1 then
		return range1
	elseif comp==2 then
		-- range1 lies entirely before range2
		error("Disjoint ranges",2)
	elseif comp==3 then
		-- range1 pre-overlaps range2
		return string.sub(strt1,6,7).."/"..string.sub(strt1,-2,-1).."/"..string.sub(strt1,1,4).."-"..
			string.sub(fin2,6,7).."/"..string.sub(fin2,-2,-1).."/"..string.sub(fin2,1,4)
	elseif comp==4 then
		-- range1 lies entirely inside range2
		return range2
	elseif comp==5 then
		-- range1 post overlaps range2
		return string.sub(strt2,6,7).."/"..string.sub(strt2,-2,-1).."/"..string.sub(strt2,1,4).."-"..
			string.sub(fin1,6,7).."/"..string.sub(fin1,-2,-1).."/"..string.sub(fin1,1,4)
	elseif comp==6 then
		-- range1 lies entirely after range2
		error("Disjoint ranges",2)
	elseif comp==7 then
		-- range2 lies entirely inside range1
			return range1
	end		
end

function Karm.Utility.XMLDate2wxDateTime(XMLdate)
	local map = {
		[1] = wx.wxDateTime.Jan,
		[2] = wx.wxDateTime.Feb,
		[3] = wx.wxDateTime.Mar,
		[4] = wx.wxDateTime.Apr,
		[5] = wx.wxDateTime.May,
		[6] = wx.wxDateTime.Jun,
		[7] = wx.wxDateTime.Jul,
		[8] = wx.wxDateTime.Aug,
		[9] = wx.wxDateTime.Sep,
		[10] = wx.wxDateTime.Oct,
		[11] = wx.wxDateTime.Nov,
		[12] = wx.wxDateTime.Dec
	}
	return wx.wxDateTimeFromDMY(tonumber(string.sub(XMLdate,-2,-1)),map[tonumber(string.sub(XMLdate,6,7))],tonumber(string.sub(XMLdate,1,4)))
end

--****f* Karm/compareDateRanges
-- FUNCTION
-- Function to compare 2 date ranges
-- 
-- INPUT
-- o range1 -- Date Range 1 eg. 2/25/2012-2/27/2012
-- o range2 -- Date Range 2 eg. 2/25/2012-3/27/2012
-- 
-- RETURNS
-- o 1 -- If date ranges identical
-- o 2 -- If range1 lies entirely before range2
-- o 3 -- If range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2 and not condition 2
-- o 4 -- If range1 lies entirely inside range2
-- o 5 -- If range1 post overlaps range2 i.e. start date of range 1 >= start date of range 2 and start date of range 1 - 1 day <= end date of range 2 and not condition 4 
-- o 6 -- If range1 lies entirely after range2
-- o 7 -- If range2 lies entirely inside range1
-- o nil -- for error
--
-- SOURCE
function Karm.Utility.compareDateRanges(range1,range2)
--@@END@@
	if not(range1 and range2) or range1=="" or range2=="" then
		error("Expected a valid date range.",2)
	end
	
	if range1 == range2 then
		--  date ranges identical
		return 1
	end
	
	local strt1,fin1 = string.match(range1,"(.-)%-(.*)")
	local strt2,fin2 = string.match(range2,"(.-)%-(.*)")
	
	strt1 = Karm.Utility.toXMLDate(strt1)
	local idate = Karm.Utility.XMLDate2wxDateTime(strt1)
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))
	local strt1m1 = Karm.Utility.toXMLDate(idate:Format("%m/%d/%Y"))
	
	fin1 = Karm.Utility.toXMLDate(fin1)
	idate = Karm.Utility.XMLDate2wxDateTime(fin1)
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))
	local fin1p1 = Karm.Utility.toXMLDate(idate:Format("%m/%d/%Y"))
	
	strt2 = Karm.Utility.toXMLDate(strt2)
	
	fin2 = Karm.Utility.toXMLDate(fin2)
	
	if strt1>fin1 or strt2>fin2 then
		error("Range given is not valid. Start date should be less than finish date.",2)
	end
	
	if fin1p1<strt2 then
		-- range1 lies entirely before range2
		return 2
	elseif fin1<=fin2 and strt1<strt2 then
		-- range1 pre-overlaps range2
		return 3
	elseif strt1>strt2 and fin1<fin2 then
		-- range1 lies entirely inside range2
		return 4
	elseif strt1m1<=fin2 and strt1>=strt2 then
		-- range1 post overlaps range2
		return 5
	elseif strt1m1>fin2 then
		-- range1 lies entirely after range2
		return 6
	elseif strt1<strt2 and fin1>fin2 then
		-- range2 lies entirely inside range1
		return 7
	end
end
--****f* Karm/ToXMLDate
-- FUNCTION
-- Function to convert display format date to XML format date YYYY-MM-DD
-- display date format is MM/DD/YYYY
--
-- INPUT
-- o displayDate -- String variable containing the date string as MM/DD/YYYY
--
-- RETURNS
-- The date as a string compliant to XML date format YYYY-MM-DD
--
-- SOURCE
function Karm.Utility.toXMLDate(displayDate)
--@@END@@

    local exYear, exMonth, exDate
    local count = 1
    for num in string.gmatch(displayDate,"%d+") do
    	if count == 1 then
    		-- this is month
    		exMonth = num
	    	if #exMonth == 1 then
        		exMonth = "0" .. exMonth
        	end
        elseif count==2 then
        	-- this is the date
        	exDate = num
        	if #exDate == 1 then
        		exDate = "0" .. exDate
        	end
        elseif count== 3 then
        	-- this is the year
        	exYear = num
        	if #exYear == 1 then
        		exYear = "000" .. exYear
        	elseif #exYear == 2 then
        		exYear = "00" .. exYear
        	elseif #exYear == 3 then
        		exYear = "0" .. exYear
        	end
        end
        count = count + 1
	end    
    return exYear .. "-" .. exMonth .. "-" .. exDate
end

function Karm.Utility.getWeekDay(xmlDate)
	if #xmlDate ~= 10 then
		error("Expected XML Date in the form YYYY-MM-DD",2)
	end
	local WeekDays = {"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}
	-- Using the Gauss Formula
	-- http://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Gaussian_algorithm
	local d = tonumber(xmlDate:sub(-2,-1))
	local m = tonumber(xmlDate:sub(6,7))
	m = (m + 9)%12 + 1
	local Y
	if m > 10 then
		Y = string.match(tostring(tonumber(xmlDate:sub(1,4)) - 1),"%d+")
		Y = string.rep("0",4-#Y)..Y
	else
		Y = xmlDate:sub(1,4)
	end
	local y = tonumber(Y:sub(-2,-1))
	local c = tonumber(Y:sub(1,2))
	local w = (d + (2.6*m-0.2)-(2.6*m-0.2)%1 + y + (y/4)-(y/4)%1 + (c/4)-(c/4)%1-2*c)%7+1
	return WeekDays[w]
end

function Karm.Utility.addItemToArray(item,array)
	local pos = 0
	for i = 1,#array do
		if array[i] == item  then
			return array
		end
		if array[i]>item then
			pos = i
			break
		end
	end
	if pos == 0 then
		-- place item in the end
		array[#array+1] = item
		return array
	end
	local newarray = {}
	for i = 1,pos-1 do
		newarray[i] = array[i]
	end
	newarray[pos] = item
	for i = pos,#array do
		newarray[i+1] = array[i]
	end
	return newarray
end

function Karm.TaskObject.CheckSporeIntegrity(task, Spore)
	if not task and not Spore then
		error("Need a task or a Spore object to check the spore integrity", 2)
	end
	if task and getmetatable(task) ~= Karm.TaskObject then
		error("Need a valid task object to check Spore integrity.", 2)
	end
	local spore 
	if task then
		if not task.Parent then
			spore = task.SubTasks.parent
		else
			spore = task.Parent.SubTasks.parent
			while spore.parent do
				spore = spore.parent
			end
		end
	else
		spore = Spore
	end
	local integrityError = {}
	local checkFunc = function(task)
		local pa = task.Parent
		local index
		for i = 1,#pa.SubTasks do
			if pa.SubTasks[i] == task then
				index = i
				break
			end
		end
		if not index then
			integrityError[#integrityError + 1] = {Task = task, Error = "Parent mismatch"}
			return
		end
		if (index > 1 and pa.SubTasks[index - 1] ~= task.Previous) or (index == 1 and task.Previous) then
			integrityError[#integrityError + 1] = {Task = task, Error = "Previous mismatch"}
		end
		if (index < #pa.SubTasks and pa.SubTasks[index + 1] ~= task.Next) or (index == #pa.SubTasks and task.Next) then
			integrityError[#integrityError + 1] = {Task = task, Error = "Next mismatch"}
		end		
		-- Check parents of all subTasks
		if task.SubTasks then
			for i = 1,#task.SubTasks do
				if task.SubTasks[i].Parent ~= task then
					integrityError[#integrityError + 1] = {Task = task.SubTasks[i], Error = "Parent mismatch"}
				end
			end
			if task.SubTasks.parent ~= task.Parent.SubTasks then
				integrityError[#integrityError + 1] = {Task = task, Error = "SubTasks Parent mismatch"}
			end
		end
	end
	for i = 1,#spore do
		if (i > 1  and spore[i-1] ~= spore[i].Previous) or (i == 1 and spore[i].Previous) then
			integrityError[#integrityError + 1] = {Task = spore[i], Error = "Previous mismatch"}
		end
		if (i < #spore and spore[i + 1] ~= spore[i].Next) or (i == #spore and spore[i].Next) then
			integrityError[#integrityError + 1] = {Task = spore[i], Error = "Next mismatch"}
		end	
		if spore[i].SubTasks then
			for j = 1,#spore[i].SubTasks do
				if spore[i].SubTasks[j].Parent ~= spore[i] then
					integrityError[#integrityError + 1] = {Task = spore[i].SubTasks[j], Error = "Parent mismatch"}
				end
			end
			if spore[i].SubTasks.parent ~= spore then	
				integrityError[#integrityError + 1] = {Task = spore[i], Error = "SubTasks Parent mismatch"}
			end
		end	
		spore[i]:applyFuncHier(checkFunc, nil, true)
	end
	return integrityError
end

-- Function to apply a function to a task and its hierarchy
-- The function should have the task as the 1st argument 
-- and whatever it returns is passed to it it as the 2nd argument in the next call to it with the next task
-- In the 1st call the second argument is passed if it is given as the 3rd argument to this function
-- The last return from the function is returned by this function
-- if omitTask is true then the func is not run for the task itself and it starts from the subTasks
function Karm.TaskObject.applyFuncHier(task, func, initialValue, omitTask)
	local passedVar	= initialValue	-- Variable passed to the function
	if not omitTask then
		passedVar = func(task,initialValue)
	end
	if task.SubTasks then
		-- Traverse the task hierarchy here
		local hier = task.SubTasks
		local hierCount = {}
		hierCount[hier] = 0
		while hierCount[hier] < #hier or hier.parent do
			if not(hierCount[hier] < #hier) then
				if hier == task.SubTasks then
					-- Do not go above the passed task
					break
				end 
				hier = hier.parent
			else
				-- Increment the counter
				hierCount[hier] = hierCount[hier] + 1
				passedVar = func(hier[hierCount[hier]],passedVar)
				if hier[hierCount[hier]].SubTasks then
					-- This task has children so go deeper in the hierarchy
					hier = hier[hierCount[hier]].SubTasks
					hierCount[hier] = 0
				end
			end
		end		-- while hierCount[hier] < #hier or hier.parent do ends here
	end
	return passedVar
end

-- To find out if a task is under the sub task tree of ancestor
function Karm.TaskObject.IsUnder(task,ancestor)
	if task==ancestor then
		return true
	end
	local t = task
	while t.Parent do
		t = t.Parent
		if t == ancestor then
			return true
		end
	end
end

-- Function to get a next task (from the given task) in the task hierarchy. After all tasks for a spore are finished then it will return a nil
-- Traversal is in the order as if listing out the tasks for a fully expanded task tree
function Karm.TaskObject.NextInSequence(task)
	if not task then
		error("Need a task object to give the next task", 2)
	end
	if not type(task) == "table" then
		error("Need a task object to give the next task", 2)
	end
	if task.SubTasks and task.SubTasks[1] then
		return task.SubTasks[1]
	end	
	if task.Next then
		return task.Next
	end
	if task.Parent then
		local currTask = task.Parent
		if currTask.Next then
			return currTask.Next
		end
		while currTask.Parent do
			currTask = currTask.Parent
			if currTask.Next then
				return currTask.Next
			end
		end
	end
end

-- Function to get a next task (from the given task) in the task hierarchy. After all tasks for a spore are finished then it will return a nil
-- Traversal is in the order as if listing out the tasks for a fully expanded task tree
function Karm.TaskObject.PreviousInSequence(task)
	if not task then
		error("Need a task object to give the next task", 2)
	end
	if not type(task) == "table" then
		error("Need a task object to give the next task", 2)
	end
	if task.Previous then
		local currTask = task.Previous
		while Karm.TaskObject.NextInSequence(currTask) ~= task do
			currTask = Karm.TaskObject.NextInSequence(currTask)
		end
		return currTask
	end
	return task.Parent
end

function Karm.TaskObject.accumulateTaskData(task,Data)
	Data = Data or {}
	Data.Who = Data.Who or {}
	Data.Access = Data.Access or {}
	Data.Priority = Data.Priority or {}
	Data.Cat = Data.Cat or {}
	Data.SubCat = Data.SubCat or {}
	Data.Tags = Data.Tags or {}
	-- Who data
	for i = 1,#task.Who do
		Data.Who = Karm.Utility.addItemToArray(task.Who[i].ID,Data.Who)
	end
	-- Access Data
	if task.Access then
		for i = 1,#task.Access do
			Data.Access = Karm.Utility.addItemToArray(task.Access[i].ID,Data.Access)
		end
	end
	-- Priority Data
	if task.Priority then
		Data.Priority = Karm.Utility.addItemToArray(task.Priority,Data.Priority)
	end			
	-- Category Data
	if task.Cat then
		Data.Cat = Karm.Utility.addItemToArray(task.Cat,Data.Cat)
	end			
	-- Sub-Category Data
	if task.SubCat then
		Data.SubCat = Karm.Utility.addItemToArray(task.SubCat,Data.SubCat)
	end			
	-- Tags Data
	if task.Tags then
		for i = 1,#task.Tags do
			Data.Tags = Karm.Utility.addItemToArray(task.Tags[i],Data.Tags)
		end
	end
	return Data
end


-- Function to collect and return all data from the task heirarchy on the basis of which task filtration criteria can be selected
function Karm.accumulateTaskDataHier(filterData, taskHier)
	local hier = taskHier
	-- Reset the hierarchy if not already done so
	while hier.parent do
		hier = hier.parent
	end
	for i = 1,#hier do
		filterData = Karm.TaskObject.applyFuncHier(hier[i],Karm.TaskObject.accumulateTaskData,filterData)
	end
end

-- Old version 
--function Karm.accumulateTaskDataHier(filterData, taskHier)
--	local hier = taskHier
--	local hierCount = {}
--	-- Reset the hierarchy if not already done so
--	while hier.parent do
--		hier = hier.parent
--	end
--	-- Traverse the task hierarchy here
--	hierCount[hier] = 0
--	while hierCount[hier] < #hier or hier.parent do
--		if not(hierCount[hier] < #hier) then
--			if hier == taskHier then
--				-- Do not go above the passed task
--				break
--			end 
--			hier = hier.parent
--		else
--			-- Increment the counter
--			hierCount[hier] = hierCount[hier] + 1
--			Karm.TaskObject.accumulateTaskData(hier[hierCount[hier]],filterData)
--			if hier[hierCount[hier]].SubTasks then
--				-- This task has children so go deeper in the hierarchy
--				hier = hier[hierCount[hier]].SubTasks
--				hierCount[hier] = 0
--			end
--		end
--	end		-- while hierCount[hier] < #hier or hier.parent do ends here
--end

function Karm.accumulateTaskDataList(filterData,taskList)
	for i=1,#taskList do
		Karm.TaskObject.accumulateTaskData(taskList[i],filterData)
	end
end

-- Function to make a copy of a task
-- Each task has at most 9 tables:

-- Who
-- Access
-- Assignee
-- Schedules
-- Tags

-- Parent
-- Previous
-- Next
-- SubTasks
-- DBDATA
-- Planning  
-- PlanWorkDone

-- 1st 5 are made a copy of
-- Parent, Next and Previous are the same linked tables
-- If copySubTasks is true then SubTasks are made a copy as well with the same parameters (in this case Previous and Next are 
--         updated for all the SubTasks (irrespective of the updateSubTaskParents flag) and so are the parent of the subtasks) otherwise it is the same linked SubTask table
-- If removeDBDATA is true then it removes the DBDATA table to make this an individual task otherwise it is the same linked table
-- Normally the sub-task parents are linked to the tasks from which the hierarchy is being copied over, if updateSubTaskParents is true then all the sub-task parents
-- 		   in the copied hierarchy (excluding this task) will be updated to point to the copied hierarchy tasks
-- WARNING: If copySubTasks is false and if updateSubTaskParents is true then even though a copy of sub tasks is not made the sub task parents are updated to point to this new task
-- 		   This may break the original task hierarchy if that is needed later
-- copySubTasks updateSubTaskParents   Result
--    false          false				The subtasks of the original task is linked to the new copy task, the subtasks remain untouched
--    false          true				The subtasks of the original task is linked to the new copy task and the parent data in each task in the hierarchy points to the new copy task hierarchy - this effectively moves the subtask hierarchy to the copy task but the original task subtasks still link to this subtasks table
--	  true 			 false/true			The subtasks are copied task by task and their Parent links are updated to be in the new hierarchy
-- Planning is not copied over
-- PlanWorkDone is not copied over
function Karm.TaskObject.copy(task, copySubTasks, removeDBDATA,updateSubTaskParents)
	-- Copied from http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
	local copyTableFunc
	local function copyTable(t, deep, seen)
	    seen = seen or {}
	    if t == nil then return nil end
	    if seen[t] then return seen[t] end
	
	    local nt = {}
	    for k, v in pairs(t) do
	        if deep and type(v) == 'table' then
	            nt[k] = copyTableFunc(v, deep, seen)
	        else
	            nt[k] = v
	        end
	    end
	    setmetatable(nt, copyTableFunc(getmetatable(t), deep, seen))
	    seen[t] = nt
	    return nt
	end
	copyTableFunc = copyTable

	if not task then
		return
	end
	local nTask = {}
	for k,v in pairs(task) do
		if k ~= "Planning" and k~="PlanWorkDone" and not (k == "DBDATA" and removeDBDATA)then
			if k ~= "Who" and k ~= "Schedules" and k~= "Tags" and k ~= "Access" and k ~= "Assignee" and not (k == "SubTasks" and copySubTasks)then
				nTask[k] = task[k]
			else
				if k == "SubTasks" then
					-- This has to be copied task by task
					local parent
					if task.Parent then
						parent = task.Parent.SubTasks
					else
						-- Must be a root node in a Spore so take the Spore table as the parent itself
						parent = task.SubTasks.parent
					end
					nTask.SubTasks = {parent = parent, tasks = #task.SubTasks, [0]="SubTasks"}
					for i = 1,#task.SubTasks do
						nTask.SubTasks[i] = Karm.TaskObject.copy(task.SubTasks[i],true,removeDBDATA,true)
						if i == 1  then
							nTask.SubTasks[1].Previous = nil
						end
						if i > 1 then
							nTask.SubTasks[i].Previous = nTask.SubTasks[i-1]
							nTask.SubTasks[i-1].Next = nTask.SubTasks[i]
						end
						if i == #task.SubTasks then
							nTask.SubTasks[i].Next = nil
						end
						if nTask.SubTasks[i].SubTasks then
							nTask.SubTasks[i].SubTasks.parent = nTask.SubTasks
						end
					end
				else
					nTask[k] = copyTable(task[k],true)
				end
			end
		end
	end		-- for k,v in pairs(task) do ends
	if updateSubTaskParents and nTask.SubTasks then
		-- Correct for the task parents of all subtasks
		Karm.TaskObject.applyFuncHier(nTask,function(task, subTaskParent)
								if task.SubTasks then
									if subTaskParent then
										task.SubTasks.parent = task.Parent.SubTasks
									end
									for i = 1,#task.SubTasks do
										task.SubTasks[i].Parent = task
									end
								end
								return true
							end
		)
	end
	Karm.TaskObject.MakeTaskObject(nTask)
	return nTask
end		-- function Karm.TaskObject.copy(task)ends

function Karm.TaskObject.MakeTaskObject(task)
	setmetatable(task,Karm.TaskObject)
end

-- Function to convert a task to a task list with incremental schedules i.e. 1st will be same as task passed (but a copy of it) and last task will have 1st schedule only
-- This function ignores the Actual Schedule since that is always a single chunk of periods and is not an incremental schedule
-- The task ID however have additional _n where n is a serial number from 1 
function Karm.TaskObject.incSchTasks(task)
	local taskList = {}
	taskList[1] = Karm.TaskObject.copy(task)
	taskList[1].TaskID = taskList[1].TaskID.."_1"
	while taskList[#taskList].Schedules do
		-- Find the latest schedule in the task here
		--[[
		if string.upper(taskList[#taskList].Status) == "DONE" and taskList[#taskList].Schedules.Actual then
			-- Actual Schedule is the latest so remove this one
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])
			-- Remove the actual schedule
			taskList[#taskList].Schedules.Actual = nil
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		else]]
		if taskList[#taskList].Schedules.Revs then
			-- Actual is not the latest one but Revision is 
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])
			-- Remove the latest Revision Schedule
			taskList[#taskList].Schedules.Revs[taskList[#taskList].Schedules.Revs.count] = nil
			taskList[#taskList].Schedules.Revs.count = taskList[#taskList].Schedules.Revs.count - 1
			if taskList[#taskList].Schedules.Revs.count == 0 then
				taskList[#taskList].Schedules.Revs = nil
			end
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif taskList[#taskList].Schedules.Commit then
			-- Actual and Revisions don't exist but Commit does
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])
			-- Remove the Commit Schedule
			taskList[#taskList].Schedules.Commit = nil
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif taskList[#taskList].Schedules.Estimate then
			-- The latest is Estimate
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])
			-- Remove the latest Estimate Schedule
			taskList[#taskList].Schedules.Estimate[taskList[#taskList].Schedules.Estimate.count] = nil
			taskList[#taskList].Schedules.Estimate.count = taskList[#taskList].Schedules.Estimate.count - 1
			if taskList[#taskList].Schedules.Estimate.count == 0 then
				taskList[#taskList].Schedules.Estimate = nil
			end
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit
		  and not taskList[#taskList].Schedules.Revs then
		  	-- Since there can be an Actual Schedule but task is not done so Schedules cannot be nil
		  	break
		end
		if not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit 
		  and not taskList[#taskList].Schedules.Revs and not taskList[#taskList].Schedules.Actual then
			taskList[#taskList].Schedules = nil
		end
	end			-- while taskList[#taskList].Schedules do ends
	taskList[#taskList] = nil
	return taskList
end		-- function Karm.TaskObject.incSchTasks(task) ends

-- Function to return an Empty task that satisfies the minimum requirements
function Karm.getEmptyTask(SporeFile)
	local nTask = {}
	nTask[0] = "Task"
	nTask.SporeFile = SporeFile
	nTask.Title = "DUMMY"
	nTask.TaskID = "DUMMY"
	nTask.Start = "1900-01-01"
	nTask.Public = true
	nTask.Who = {[0] = "Who", count = 1,[1] = "DUMMY"}
	nTask.Status = "Not Started"
	Karm.TaskObject.MakeTaskObject(nTask)
	return nTask
end

-- Function to cycle the planning schedule type for a task
-- This function depends on the task setting methodology chosen to be in the sequence of Estimate->Commit->Revs->Actual
-- So conversions are:
-- Nothing->Estimate
-- Estimate->Commit
-- Commit->Revs
-- Revs->Actual
-- Actual->Back to Estimate
function Karm.TaskObject.togglePlanningType(task,type)
	if type == "NORMAL" then
		if not task.Planning then
			task.Planning = {}
		end
		local dateList = Karm.TaskObject.getLatestScheduleDates(task)
		if not dateList then
			dateList = {}
			dateList.index = 0
			dateList.typeSchedule = "Estimate"
		end
				
		if not task.Planning.Type then
			if dateList.typeSchedule == "Estimate" then
				task.Planning.Type = "Estimate"
				task.Planning.index = dateList.index + 1
			elseif dateList.typeSchedule == "Commit" then
				task.Planning.Type = "Revs"
				task.Planning.index = 1
			else
				task.Planning.Type = "Revs"
				task.Planning.index = dateList.index + 1
			end
		elseif task.Planning.Type == "Estimate" then
			task.Planning.Type = "Commit"
			task.Planning.index = 1
		elseif task.Planning.Type == "Commit" then
			task.Planning.Type = "Revs"
			if task.Schedules and task.Schedules.Revs then
				task.Planning.index = #task.Schedules.Revs + 1
			else
				task.Planning.index = 1
			end
		elseif task.Planning.Type == "Revs" then
			-- in "NORMAL" type the schedule does not go to "Actual"
			task.Planning.Type = "Estimate"
			if task.Schedules and task.Schedules.Estimate then
				task.Planning.index = #task.Schedules.Estimate + 1
			else
				task.Planning.index = 1
			end
		end		-- if not task.Planning.Type then ends
	else
		if not task.PlanWorkDone then
			task.PlanWorkDone = {}
		end
		task.PlanWorkDone.Type = "Actual"
		task.PlanWorkDone.index = 1
	end		-- if type == "NORMAL" then ends
end


-- Function to toggle a planning date in the given task. If the planning schedule table is not present it creates it with the schedule type Estimate
-- returns 1 if added, 2 if removed, 3 if removed and no more planning schedule left
function Karm.TaskObject.togglePlanningDate(task,xmlDate,type)
	local planTable
	if type == "NORMAL" then
		planTable = task.Planning
	else
		planTable = task.PlanWorkDone
	end
	if not planTable then
		Karm.TaskObject.togglePlanningType(task,type)
		if type == "NORMAL" then
			planTable = task.Planning
		else
			planTable = task.PlanWorkDone
		end
	end
	if not planTable.Period then
		planTable.Period = {
									[0]="Period",
									count=1,
									[1]={
											[0]="DP",
											Date = xmlDate
										}
								}
		
		return 1
	end
	for i=1,planTable.Period.count do
		if planTable.Period[i].Date == xmlDate then
			-- Remove this date
			for j=i+1,planTable.Period.count do
				planTable.Period[j-1] = planTable.Period[j]
			end
			planTable.Period[planTable.Period.count] = nil
			planTable.Period.count = planTable.Period.count - 1
			if planTable.Period.count>0 then
				return 2
			else
				if type == "NORMAL" then
					task.Planning = nil
				else
					task.PlanWorkDone = nil
				end				
				return 3
			end
		elseif planTable.Period[i].Date > xmlDate then
			-- Insert Date here
			planTable.Period.count = planTable.Period.count + 1
			for j = planTable.Period.count,i+1,-1 do
				planTable.Period[j] = planTable.Period[j-1]
			end
			planTable.Period[i] = {[0]="DP",Date=xmlDate}
			return 1
		end
	end
	-- Date must be added in the end
	planTable.Period.count = planTable.Period.count + 1
	planTable.Period[planTable.Period.count] = {[0]="DP",Date = xmlDate	}
	return 1
end		-- function togglePlanningDate ends

function Karm.TaskObject.getNewChildTaskID(parent)
	local taskID
	if not parent.SubTasks then
		taskID = parent.TaskID.."_1"
	else 
		local intVar1 = 0
		for count = 1,#parent.SubTasks do
	        local tempTaskID = parent.SubTasks[count].TaskID
	        if tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1)) > intVar1 then
	            intVar1 = tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1))
	        end
		end
		intVar1 = intVar1 + 1
		taskID = parent.TaskID.."_"..tostring(intVar1)
	end
	return taskID
end

function Karm.TaskObject.add2Spore(task,dataStruct)
	if not task.SubTasks then
		task.SubTasks = {parent = dataStruct, tasks = 0, [0]="SubTasks"}
	else
		task.SubTasks.parent = dataStruct
	end
	dataStruct.tasks = dataStruct.tasks + 1
	dataStruct[dataStruct.tasks] = task 
	if dataStruct.tasks > 1 then
		dataStruct[dataStruct.tasks - 1].Next = dataStruct[dataStruct.tasks]
		dataStruct[dataStruct.tasks].Previous = dataStruct[dataStruct.tasks-1]
	else
		dataStruct[dataStruct.tasks].Previous = nil
	end
	dataStruct[dataStruct.tasks].Next = nil
end

-- Function to add a task to a parent as a subtask
function Karm.TaskObject.add2Parent(task, parent, Spore)
	if not (task and parent) then
		error("nil parameter cannot be handled at add2Parent in DataHandler.lua.",2)
	end
	if getmetatable(task) ~= Karm.TaskObject or getmetatable(parent) ~= Karm.TaskObject then
		error("Need a valid task and parent task object to add the task to parent", 2)
	end
	if not parent.SubTasks then
		parent.SubTasks = {tasks = 0, [0]="SubTasks"}
		if not parent.Parent then
			---- THIS CONDITION SHOULD NEVER OCCUR SINCE A ROOT TASK ADDED TO A SPORE ALWAYS HAS A SUBTASKS NODE TO LINK TO THE SPORE TABLE
			---- SEE add2Spore above
			if not Spore then
				error("Spore cannot be nil in Karm.TaskObject.add2Parent call.",2)
			end
			-- This is a Spore root node
			parent.SubTasks.parent = Spore
		else
			parent.SubTasks.parent = parent.Parent.SubTasks
		end 
	end
	parent.SubTasks.tasks = parent.SubTasks.tasks + 1
	parent.SubTasks[parent.SubTasks.tasks] = task
	if parent.SubTasks.tasks > 1 then
		parent.SubTasks[parent.SubTasks.tasks - 1].Next = parent.SubTasks[parent.SubTasks.tasks]
		parent.SubTasks[parent.SubTasks.tasks].Previous = parent.SubTasks[parent.SubTasks.tasks-1]
	else
		parent.SubTasks[parent.SubTasks.tasks].Previous = nil
	end
	parent.SubTasks[parent.SubTasks.tasks].Next = nil
	if task.SubTasks then 
		task.SubTasks.parent = parent.SubTasks
	else
		task.SubTasks = {parent = parent.SubTasks, tasks = 0, [0]="SubTasks"}		
	end
end

-- Function to get all work done dates for a task and color and type for each date
-- This function is called by the taskTree UI element to display the Gantt chart
-- if bubble is true it bubbles up the latest schedule dates of the entire task hierarchy to this task
--
-- The function returns a table in the following format
-- typeSchedule - Type of schedule for this task
-- index - index of schedule for this task
-- Subtables starting from index 1 corresponding to each date
	-- Each subtable has the following keys:
	-- Date - XML format date 
	-- typeSchedule - Type of schedule the date comes from "Estimate", "Commit", "Revision", "Actual"
	-- index - the index of the schedule
	-- Bubbled - True/False - True if date is from a subtask 
	-- BackColor - Background Color (Red, Green, Blue) table for setting the background color in the Gantt Chart
	-- ForeColor - Foreground Color (Red, Green, Blue) table for setting the test color in the Gantt Chart date
	-- Text - Text to be written in the Gantt cell for the date
function Karm.TaskObject.getWorkDates(task,bubble,planning)
	local updateDateTable = function(task,dateTable)
		local dateList = Karm.TaskObject.getWorkDoneDates(task,planning)
		if dateList then
			if not dateTable then
				dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}
			end
			for i = 1,#dateList do
				local found = false
				local index = 0
				for j = 1,#dateTable do
					if dateTable[j].Date == dateList[i] then
						found = true
						break
					end
					if dateTable[j].Date > dateList[i] then
						index = j-1
						break
					end
				end
				if not found then
					-- Create a space at index
					for j = #dateTable, index+1, -1 do
						dateTable[j+1] = dateTable[j]
					end
					local newColor = {Red=Karm.GUI.ScheduleColor.Red - Karm.GUI.bubbleOffset.Red,Green=Karm.GUI.ScheduleColor.Green - Karm.GUI.bubbleOffset.Green,
					Blue=Karm.GUI.ScheduleColor.Blue-Karm.GUI.bubbleOffset.Blue}
					if newColor.Red < 0 then newColor.Red = 0 end
					if newColor.Green < 0 then newColor.Green = 0 end
					if newColor.Blue < 0 then newColor.Blue = 0 end
					dateTable[index+1] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, 
					  Bubbled = true, BackColor = newColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = "A"}
				end
			end		-- for i = 1,#dateList do ends
		end		-- if dateList then ends
		return dateTable
	end
	if bubble then
		local dateTable = updateDateTable(task)
		if dateTable then
			-- Remove the Bubbled flag and text for the task that actually has that schedule date.
			for i = 1,#dateTable do
				dateTable[i].Bubbled = nil
				dateTable[i].BackColor = Karm.GUI.ScheduleColor
				dateTable[i].Text = ""
			end
		end
		local dateTable = Karm.TaskObject.applyFuncHier(task,updateDateTable,dateTable,true)
		return dateTable
	else 
		-- Just get the latest dates for this task
		local dateList = Karm.TaskObject.getWorkDoneDates(task,planning)
		if dateList then
			-- Convert the dateList to modified return table
			local dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}
			for i = 1,#dateList do
				dateTable[i] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, 
				  Bubbled = nil, BackColor = Karm.GUI.ScheduleColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = ""}
			end
			return dateTable
		else
			return nil
		end
	end
end

-- Function to get all dates for a task and color and type for each date
-- This function is called by the taskTree UI element to display the Gantt chart
-- if bubble is true it bubbles up the latest schedule dates of the entire task hierarchy to this task
-- if planning is true it returns the planning date list for this task
--
-- The function returns a table in the following format
-- typeSchedule - Type of schedule for this task
-- index - index of schedule for this task
-- Subtables starting from index 1 corresponding to each date
	-- Each subtable has the following keys:
	-- Date - XML format date 
	-- typeSchedule - Type of schedule the date comes from "Estimate", "Commit", "Revision", "Actual"
	-- index - the index of the schedule
	-- Bubbled - True/False - True if date is from a subtask 
	-- BackColor - Background Color (Red, Green, Blue) table for setting the background color in the Gantt Chart
	-- ForeColor - Foreground Color (Red, Green, Blue) table for setting the test color in the Gantt Chart date
	-- Text - Text to be written in the Gantt cell for the date
function Karm.TaskObject.getDates(task,bubble,planning)
	local plan = planning
	local updateDateTable = function(task,dateTable)
		local dateList = Karm.TaskObject.getLatestScheduleDates(task,plan)
		if dateList then
			if not dateTable then
				dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}
			end
			-- Loop through the latest schedule dates to check whether it is in the already in the dateTable
			for i = 1,#dateList do
				local found = false
				local index = 0
				for j = 1,#dateTable do
					if dateTable[j].Date == dateList[i] then
						found = true
						break
					end
					if dateTable[j].Date > dateList[i] then
						-- Need to add this dateList[i] date at the index j
						index = j - 1
						break
					end
				end
				if not found then
					-- Create a space at index + 1
					for j = #dateTable, index+1, -1 do
						dateTable[j+1] = dateTable[j]
					end
					local newColor = {Red=Karm.GUI.ScheduleColor.Red - Karm.GUI.bubbleOffset.Red,Green=Karm.GUI.ScheduleColor.Green - Karm.GUI.bubbleOffset.Green,
					Blue=Karm.GUI.ScheduleColor.Blue-Karm.GUI.bubbleOffset.Blue}
					if newColor.Red < 0 then newColor.Red = 0 end
					if newColor.Green < 0 then newColor.Green = 0 end
					if newColor.Blue < 0 then newColor.Blue = 0 end
					dateTable[index+1] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, 
					  Bubbled = true, BackColor = newColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = dateList.typeSchedule:sub(1,1)}
				end
			end		-- for i = 1,#dateList do ends
		end		-- if dateList then ends
		return dateTable
	end
	if bubble then
		-- Main task schedule
		local dateTable = updateDateTable(task)
		if dateTable then
			-- Remove the Bubbled flag and text for the task that actually has that schedule date.
			for i = 1,#dateTable do
				dateTable[i].Bubbled = nil
				dateTable[i].BackColor = Karm.GUI.ScheduleColor
				dateTable[i].Text = ""
			end
		end
		--plan = nil
		dateTable = Karm.TaskObject.applyFuncHier(task,updateDateTable,dateTable, true)
		return dateTable
	else 
		-- Just get the latest dates for this task
		local dateList = Karm.TaskObject.getLatestScheduleDates(task,planning)
		if dateList then
			-- Convert the dateList to modified return table
			local dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}
			for i = 1,#dateList do
				dateTable[i] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, 
				  Bubbled = nil, BackColor = Karm.GUI.ScheduleColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = ""}
			end
			return dateTable
		else
			return nil
		end
	end
end

-- function to update the taskID in the whole hierarchy
function Karm.TaskObject.updateTaskID(task,taskID)
	if not(task and taskID) then
		error("Need a task and taskID for Karm.TaskObject.updateTaskID in DataHandler.lua",2)
	end
	local prevTaskID = task.TaskID
	Karm.TaskObject.applyFuncHier(task,function(task,taskIDs)
							task.TaskID = task.TaskID:gsub("^"..taskIDs.prevTaskID,taskIDs.newTaskID)
							return taskIDs
						end, {prevTaskID = prevTaskID, newTaskID = taskID}
	)
end

-- Old Version
--function Karm.TaskObject.updateTaskID(task,taskID)
--	if not(task and taskID) then
--		error("Need a task and taskID for Karm.TaskObject.updateTaskID in DataHandler.lua",2)
--	end
--	local prevTaskID = task.TaskID
--	task.TaskID = taskID
--	if task.SubTasks then
--		local currNode = task.SubTasks
--		local hierCount = {}
--		-- Traverse the task hierarchy here
--		hierCount[currNode] = 0
--		while hierCount[currNode] < #currNode or currNode.parent do
--			if not(hierCount[currNode] < #currNode) then
--				if currNode == task.SubTasks then
--					-- Do not go above the passed task
--					break
--				end 
--				currNode = currNode.parent
--			else
--				-- Increment the counter
--				hierCount[currNode] = hierCount[currNode] + 1
--				currNode[hierCount[currNode]].TaskID = currNode[hierCount[currNode]].TaskID:gsub("^"..prevTaskID,task.TaskID)
--				if currNode[hierCount[currNode]].SubTasks then
--					-- This task has children so go deeper in the hierarchy
--					currNode = currNode[hierCount[currNode]].SubTasks
--					hierCount[currNode] = 0
--				end
--			end
--		end		-- while hierCount[hier] < #hier or hier.parent do ends here
--	end		-- if task.SubTasks then ends
--end

-- Function to move the task before/after
function Karm.TaskObject.bubbleTask(task,relative,beforeAfter,parent)
	if task.Parent ~= relative.Parent then
		error("The task and relative should be on the same level in the Karm.TaskObject.bubbleTask call in DataHandler.lua",2)
	end
	if not (task.Parent or parent) then
		error("parent argument should be specified for tasks/relative that do not have a parent defined in Karm.TaskObject.bubbleTask call in DataHandler.lua",2)
	end	
	if task==relative then
		return
	end
	local pTable, swapID
	if not task.Parent then
		-- These are root nodes in a spore
		pTable = parent
		swapID = false	-- since IDs for spore root nodes should not be swapped since they are roots and unique
	else
		pTable = relative.Parent.SubTasks
		swapID = true
	end
	if beforeAfter:upper() == "AFTER" then
		-- Next Sibling
		-- Find the relative and task number
		local posRel, posTask
		for i = 1,pTable.tasks do
			if pTable[i] == relative then
				posRel = i
			end
			if pTable[i] == task then
				posTask = i
			end
		end
		if posRel < posTask then
			-- Start the bubble up 
			for i = posTask,posRel+2,-1 do
				if swapID then
					-- Swap TaskID
					local tim1 = pTable[i].TaskID
					local ti = pTable[i-1].TaskID
					Karm.TaskObject.updateTaskID(pTable[i],ti) 
					Karm.TaskObject.updateTaskID(pTable[i-1],tim1)
				end 
				-- Swap task position
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]
				-- Update the Previous and Next pointers
				pTable[i].Previous = pTable[i-1]
				pTable[i-1].Next = pTable[i]
				if i > 2 then
					pTable[i-2].Next = pTable[i-1]
					pTable[i-1].Previous = pTable[i-2]
				else
					pTable[i-1].Previous = nil
				end
				if i < pTable.tasks then
					pTable[i].Next = pTable[i+1]
					pTable[i+1].Previous = pTable[i]
				else
					pTable[i].Next = nil
				end
			end
		else
			-- Start the bubble down 
			for i = posTask,posRel-1 do
				if swapID then
					-- Swap TaskID
					local tip1 = pTable[i].TaskID
					local ti = pTable[i+1].TaskID
					Karm.TaskObject.updateTaskID(pTable[i],ti) 
					Karm.TaskObject.updateTaskID(pTable[i+1],tip1)
				end 
				-- Swap task position
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]
				-- Update the Previous and Next pointers
				pTable[i+1].Previous = pTable[i]
				pTable[i].Next = pTable[i+1]
				if i > 1 then
					pTable[i-1].Next = pTable[i]
					pTable[i].Previous = pTable[i-1]
				else
					pTable[i].Previous = nil
				end
				if i+1 < pTable.tasks then
					pTable[i+1].Next = pTable[i+2]
					pTable[i+2].Previous = pTable[i+1]
				else
					pTable[i+1].Next = nil
				end
			end
		end
	else
		-- Previous sibling
		-- Find the relative and task number
		local posRel, posTask
		for i = 1,pTable.tasks do
			if pTable[i] == relative then
				posRel = i
			end
			if pTable[i] == task then
				posTask = i
			end
		end
		if posRel < posTask then
			-- Start the bubble up 
			for i = posTask,posRel+1,-1 do
				if swapID then
					-- Swap TaskID
					local tim1 = pTable[i].TaskID
					local ti = pTable[i-1].TaskID
					Karm.TaskObject.updateTaskID(pTable[i],ti) 
					Karm.TaskObject.updateTaskID(pTable[i-1],tim1)
				end 
				-- Swap task position
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]
				-- Update the Previous and Next pointers
				pTable[i].Previous = pTable[i-1]
				pTable[i-1].Next = pTable[i]
				if i > 2 then
					pTable[i-2].Next = pTable[i-1]
					pTable[i-1].Previous = pTable[i-2]
				else
					pTable[i-1].Previous = nil
				end
				if i < pTable.tasks then
					pTable[i].Next = pTable[i+1]
					pTable[i+1].Previous = pTable[i]
				else
					pTable[i].Next = nil
				end
			end
		else
			-- Start the bubble down 
			for i = posTask,posRel-2 do
				if swapID then
					-- Swap TaskID
					local tip1 = pTable[i].TaskID
					local ti = pTable[i+1].TaskID
					Karm.TaskObject.updateTaskID(pTable[i],ti) 
					Karm.TaskObject.updateTaskID(pTable[i+1],tip1)
				end 
				-- Swap task position
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]
				-- Update the Previous and Next pointers
				pTable[i+1].Previous = pTable[i]
				pTable[i].Next = pTable[i+1]
				if i > 1 then
					pTable[i-1].Next = pTable[i]
					pTable[i].Previous = pTable[i-1]
				else
					pTable[i].Previous = nil
				end
				if i+1 < pTable.tasks then
					pTable[i+1].Next = pTable[i+2]
					pTable[i+2].Previous = pTable[i+1]
				else
					pTable[i+1].Next = nil
				end
			end
		end
	end

end

--function DeleteTaskFromSpore(task, Spore)
--	if task.Parent then
--		error("DeleteTaskFromSpore: Cannot delete task that is not a root task in Spore.",2)
--	end
--	local taskList
--	taskList = Spore
--	for i = 1,#taskList do
--		if taskList[i] == task then
--			for j = i, #taskList-1 do
--				taskList[j] = taskList[j+1]
--			end
--			taskList[#taskList] = nil
--			taskList.tasks = taskList.tasks - 1
--			break
--		end
--	end
--end

function Karm.TaskObject.DeleteFromDB(task)
	local taskList
	if not task.Parent then
		taskList = task.SubTasks.parent		
	else
		taskList = task.Parent.SubTasks
	end
	for i = 1,#taskList do
		if taskList[i] == task then
			if i<#taskList then
				for j = i, #taskList-1 do
					taskList[j] = taskList[j+1]
					if j>1 then
						taskList[j].Previous = taskList[j-1]
						taskList[j-1].Next = taskList[j]
					else
						taskList[j].Previous = nil
					end
				end
			else
				if #taskList > 1 then
					taskList[i-1].Next = nil
				end
			end
			taskList[#taskList] = nil
			taskList.tasks = taskList.tasks - 1
			break
		end
	end
end

function Karm.sporeTitle(path)
	-- Find the name of the file
	local strVar
	local intVar1 = -1
	for intVar = #path,1,-1 do
		if string.sub(path, intVar, intVar) == "." then
	    	intVar1 = intVar
		end
		if string.sub(path, intVar, intVar) == "\\" or string.sub(path, intVar, intVar) == "/" then
	    	strVar = string.sub(path, intVar + 1, intVar1-1)
	    	break
		end
	end
	if not strVar then
		strVar = path
	end
	return strVar
end

function Karm.TaskObject.IsSpore(task)
	if task.TaskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
		return true
	else
		return false
	end
end

-- Function to convert XML data from a single spore to internal data structure
-- Task structure
-- Task.
--	Planning.
--  PlanWorkDone.
--	[0] = Task
-- 	SporeFile
--	Title
--	Modified
--	DBDATA.
--	TaskID
--	Start
--	Fin
--	Private
--	Who.
--	Access.
--	Assignee.
--	Status
--	Parent. = Pointer to the Task to which this is a sub task (Nil for root tasks in a Spore)
--  Next. = Pointer to the next task under the same Parent (Nil if this is the last task)
--  Previous. = Pointer to the previous task under the same Parent (Nil if this is the first task)
--	Priority
--	Due
--	Comments
--	Cat
--	SubCat
--	Tags.
--  Estimate
--	Schedules.
--		[0] = "Schedules"
--		Estimate.
--			[0] = "Estimate"
--			count
--			[i] = 
--		Commit.
--			[0] = "Commit"
--		Revs
--		Actual
--	SubTasks.
--		[0] = "SubTasks"
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask Node this is (Points to Spore table for root tasks of a Spore) - Thus this is always present in a task even if it does not have sub tasks.
--		tasks = count of number of subtasks
--		[i] = Task table like this one repeated for sub tasks

function Karm.XML2Data(SporeXML, SporeFile)
	-- tasks counts the number of tasks at the current level
	-- index 0 contains the name of this level to make it compatible with LuaXml
	local dataStruct = {Title = Karm.sporeTitle(SporeFile), SporeFile = SporeFile, tasks = 0, TaskID = Karm.Globals.ROOTKEY..SporeFile, [0] = "Task_Spore"}	-- to create the data structure
	if SporeXML[0]~="Task_Spore" then
		return nil
	end
	local currNode = SporeXML		-- currNode contains the current XML node being processed
	local hierInfo = {}
	hierInfo[currNode] = {count = 1}		-- hierInfo contains associated information with the currNode i.e. its Parent and count of the node being processed
	while(currNode[hierInfo[currNode].count] or hierInfo[currNode].parent) do
		if not(currNode[hierInfo[currNode].count]) then
			currNode = hierInfo[currNode].parent
			dataStruct = dataStruct.parent
		else
			if currNode[hierInfo[currNode].count][0] == "Task" then
				local task = currNode[hierInfo[currNode].count]
				hierInfo[currNode].count = hierInfo[currNode].count + 1
				local necessary = 0
				dataStruct.tasks = dataStruct.tasks + 1
				dataStruct[dataStruct.tasks] = {[0] = "Task"}
				
				dataStruct[dataStruct.tasks].SporeFile = SporeFile
				-- Set the Previous and next pointers
				if dataStruct.tasks > 1 then
					dataStruct[dataStruct.tasks].Previous = dataStruct[dataStruct.tasks - 1]
				end
				dataStruct[dataStruct.tasks].Next = dataStruct[dataStruct.tasks + 1]
				-- Each task has a Parent Attribute which points to a parent Task containing this task. For root tasks in the spore this is nil
				dataStruct[dataStruct.tasks].Parent = hierInfo[currNode].parentTask
				-- Extract all task information here
				local count = 1
				while(task[count]) do
					if task[count][0] == "Title" then
						dataStruct[dataStruct.tasks].Title = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Modified" then
						if task[count][1] == "YES" then
							dataStruct[dataStruct.tasks].Modified = true
						else
							dataStruct[dataStruct.tasks].Modified = false
						end
						necessary = necessary + 1
					elseif task[count][0] == "DB-Data" then
						dataStruct[dataStruct.tasks].DBDATA = {[0]="DB-Data",DBID = task[count][1][1], Updated = task[count][2][1]}
					elseif task[count][0] == "TaskID" then
						dataStruct[dataStruct.tasks].TaskID = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Start" then
						dataStruct[dataStruct.tasks].Start = task[count][1]
					elseif task[count][0] == "Fin" then
						dataStruct[dataStruct.tasks].Fin = task[count][1]
					elseif task[count][0] == "Private" then
						if task[count][1] == "Private" then
							dataStruct[dataStruct.tasks].Private = true
						else
							dataStruct[dataStruct.tasks].Private = false
						end
						necessary = necessary + 1
					elseif task[count][0] == "People" then
						for j = 1,#task[count] do
							if task[count][j][0] == "Who" then
								local WhoTable = {[0]="Who", count = #task[count][j]}
								-- Loop through all the items in the Who element
								for i = 1,#task[count][j] do
									WhoTable[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}
								end
								necessary = necessary + 1
								dataStruct[dataStruct.tasks].Who = WhoTable
							elseif task[count][j][0] == "Locked" then
								local locked = {[0]="Access", count = #task[count][j]}
								-- Loop through all the items in the Locked element Access List
								for i = 1,#task[count][j] do
									locked[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}
								end
								dataStruct[dataStruct.tasks].Access = locked
							elseif task[count][j][0] == "Assignee" then
								local assignee = {[0]="Assignee", count = #task[count][j]}
								-- Loop through all the items in the Assignee element
								for i = 1,#task[count][j] do
									assignee[i] = {ID = task[count][j][i][1]}
								end				
								dataStruct[dataStruct.tasks].Assignee = assignee					
							end		-- if task[count][j][0] == "Who" then ends here				
						end		-- for j = 1,#task[count] do ends here				
					elseif task[count][0] == "Status" then
						dataStruct[dataStruct.tasks].Status = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Priority" then
						dataStruct[dataStruct.tasks].Priority = task[count][1]
					elseif task[count][0] == "Due" then
						dataStruct[dataStruct.tasks].Due = task[count][1]
					elseif task[count][0] == "Comments" then
						dataStruct[dataStruct.tasks].Comments = task[count][1]
					elseif task[count][0] == "Category" then
						dataStruct[dataStruct.tasks].Cat = task[count][1]
					elseif task[count][0] == "Sub-Category" then
						dataStruct[dataStruct.tasks].SubCat = task[count][1]
					elseif task[count][0] == "Tags" then
						local tagTable = {[0]="Tags", count = #task[count]}
						-- Loop through all the items in the Tags element
						for i = 1,#task[count] do
							tagTable[i] = task[count][i][1]
						end
						dataStruct[dataStruct.tasks].Tags = tagTable
					elseif task[count][0] == "Estimate" then
						dataStruct[dataStruct.tasks].Estimate = task[count][1]
					elseif task[count][0] == "Schedules" then
						local schedule = {[0]="Schedules"}
						for i = 1,#task[count] do
							if task[count][i][0] == "Estimate" then
								local estimate = {[0]="Estimate", count = #task[count][i]}
								-- Loop through all the estimates
								for j = 1,#task[count][i] do
									estimate[j] = {[0]="Estimate"}
									-- Loop through the children of Estimates element
									for n = 1,#task[count][i][j] do
										if task[count][i][j][n][0] == "Comment" then
											estimate[j].Comment = task[count][i][j][n][1]
										elseif task[count][i][j][0] == "Updated" then
											estimate[j].Updated = task[count][i][j][n][1]
										elseif task[count][i][j][n][0] == "Period" then
											local period = {[0] = "Period", count = #task[count][i][j][n]}
											-- Loop through all the day plans
											for k = 1,#task[count][i][j][n] do
												period[k] = {[0] = "DP", Date = task[count][i][j][n][k][1][1]}
												if task[count][i][j][n][k][2] then
													if task[count][i][j][n][k][2] == "Hours" then
														period[k].Hours = task[count][i][j][n][k][2][1]
													else
														-- Collect all the time plans
														period[k].TP = {[0]="Time Plan", count = #task[count][i][j][n][k]-1}
														for m = 2,#task[count][i][j][n][k] do
															-- Add this time plan to the kth day plan
															period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}
														end
													end
												end		-- if task[count][i][n][k][2] then ends
											end		-- for k = 1,#task[count][i][j] do ends
											estimate[j].Period = period
										end		-- if task[count][i][j][0] == "Hours" then ends
									end		-- for n = 1,#task[count][i][j] do ends
								end		-- for j = 1,#task[count][i] do ends
								schedule.Estimate = estimate
							elseif task[count][i][0] == "Commit" then
								local commit = {[0]="Commit"}
								commit.Comment = task[count][i][1][1][1]
								commit.Updated = task[count][i][1][2][1]
								local period = {[0] = "Period", count = #task[count][i][1][3]}
								-- Loop through all the day plans
								for k = 1,#task[count][i][1][3] do
									period[k] = {[0] = "DP", Date = task[count][i][1][3][k][1][1]}
									if task[count][i][1][3][k][2] then
										if task[count][i][1][3][k][2] == "Hours" then
											period[k].Hours = task[count][i][1][3][k][2][1]
										else
											-- Collect all the time plans
											period[k].TP = {[0]="Time Plan", count = #task[count][i][1][3][k]-1}
											for m = 2,#task[count][i][1][3][k] do
												-- Add this time plan to the kth day plan
												period[k].TP[m-1] = {STA = task[count][i][1][3][k][m][1][1], STP = task[count][i][1][3][k][m][2][1]}
											end
										end
									end		-- if task[count][i][n][k][2] then ends
								end		-- for k = 1,#task[count][i][j] do ends
								commit.Period = period
								schedule.Commit = {commit,[0]="Commit", count = 1}
							elseif task[count][i][0] == "Revs" then
								local revs = {[0]="Revs", count = #task[count][i]}
								-- Loop through all the Revisions
								for j = 1,#task[count][i] do
									revs[j] = {[0]="Revs"}
									-- Loop through the children of Revision element
									for n = 1,#task[count][i][j] do
										if task[count][i][j][n][0] == "Comment" then
											revs[j].Comment = task[count][i][j][n][1]
										elseif task[count][i][j][0] == "Updated" then
											revs[j].Updated = task[count][i][j][n][1]
										elseif task[count][i][j][n][0] == "Period" then
											local period = {[0] = "Period", count = #task[count][i][j][n]}
											-- Loop through all the day plans
											for k = 1,#task[count][i][j][n] do
												period[k] = {[0] = "DP", Date = task[count][i][j][n][k][1][1]}
												if task[count][i][j][n][k][2] then
													if task[count][i][j][n][k][2] == "Hours" then
														period[k].Hours = task[count][i][j][n][k][2][1]
													else
														-- Collect all the time plans
														period[k].TP = {[0]="Time Plan", count = #task[count][i][j][n][k]-1}
														for m = 2,#task[count][i][j][n][k] do
															-- Add this time plan to the kth day plan
															period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}
														end
													end
												end		-- if task[count][i][n][k][2] then ends
											end		-- for k = 1,#task[count][i][j] do ends
											revs[j].Period = period
										end		-- if task[count][i][j][0] == "Hours" then ends
									end		-- for n = 1,#task[count][i][j] do ends
								end		-- for j = 1,#task[count][i] do ends
								schedule.Revs = revs
							elseif task[count][i][0] == "Actual" then
								local actual = {[0]= "Actual", count = 1}
								local period = {[0] = "Period", count = #task[count][i]-1} 
								-- Loop through all the work done elements
								for j = 2,period.count+1 do
									period[j] = {[0]="WD", Date = task[count][i][j][1][1]}
									for k = 2,#task[count][i][j] do
										if task[count][i][j][k][0] == "Hours" then
											period[j].Hours = task[count][i][j][k][1]
										elseif task[count][i][j][k][0] == "Comment" then
											period[j].Comment = task[count][i][j][k][1]
										end
									end
								end
								actual[1] = {Period = period,[0]="Actual", Updated = task[count][i][1][1]}
								schedule.Actual = actual
							end							
						end
						dataStruct[dataStruct.tasks].Schedules = schedule
					elseif task[count][0] == "SubTasks" then
						hierInfo[task[count]] = {count = 1, parent = currNode,parentTask = dataStruct[dataStruct.tasks]}
						currNode = task[count]
						dataStruct[dataStruct.tasks].SubTasks = {parent = dataStruct, tasks = 0, [0]="SubTasks"}
						dataStruct = dataStruct[dataStruct.tasks].SubTasks
					end
					count = count + 1
				end		-- while(task[count]) do ends
				if necessary < 6 then
					-- this is not valid task
					dataStruct[dataStruct.tasks] = nil
					dataStruct.tasks = dataStruct.tasks - 1
				end
			else
				if currNode[hierInfo[currNode].parent] then
					currNode = hierInfo[currNode].parent
					dataStruct = dataStruct.parent
				end		-- if currNode[hierInfo[level].parent ends here
			end		-- if currNode[hierInfo[level].count][0] == "Task"  ends here
		end		-- if not(currNode[hierInfo[currNode].count]) then ends
	end		-- while(currNode[hierInfo[level].count]) ends here
	while dataStruct.parent do
		dataStruct = dataStruct.parent
	end
	
	-- Convert all tasks to proper task Objects
	local list1 = Karm.FilterObject.applyFilterHier(nil,dataStruct)
	if #list1 > 0 then
		for i = 1,#list1 do
			Karm.TaskObject.MakeTaskObject(list1[i])
		end
	end        	
	
	-- Create a SubTasks node for each root node to get link to spore data table
	for i = 1,#dataStruct do
		if not dataStruct[i].SubTasks then
			dataStruct[i].SubTasks = {parent = dataStruct, tasks = 0, [0]="SubTasks"}
		end
	end
	return dataStruct
end		-- function Karm.XML2Data(SporeXML) ends here
