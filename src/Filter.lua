-- Data structure to store the Global Filter Criteria
Karm.Filter = {}
Karm.FilterObject = {}
-- Table to store the Core values
Karm.Core.FilterObject = {}
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		print("I am here")
		if Karm.FilterObject.key and not Karm.Core.FilterObject.key then
			Karm.Core.FilterObject.key = Karm.FilterObject.key
			print("Set")
		end
		rawset(Karm.FilterObject,key,val)
	end
	setmetatable(Karm.FilterObject,KarmMeta)
end
]]

-- Function to create a text summary of the Filter
function Karm.FilterObject.getSummary(filter)
	local filterSummary = ""
	if filter.Map then
		-- This is a combination filter
		filterSummary = "COMBINATION FILTER:\n"..filter.Bool
	else
		-- Tasks
		if filter.Tasks then
			-- Get the task name
			for i=1,#filter.Tasks do
				if i>1 then
					filterSummary = filterSummary.."\n"
				else
					filterSummary = "TASKS: "
				end
				filterSummary = filterSummary..filter.Tasks[i].Title
				if filter.Tasks[i].Children then
					filterSummary = filterSummary.." and Children"
				end
			end
			filterSummary = filterSummary.."\n"
		end
		-- Show Hierarchy
		if not filter.DontShowHierarchy then
			filterSummary = filterSummary.."SHOW HIERARCHY: YES\n"
		end
		-- Who
		if filter.Who then
			filterSummary = filterSummary.."PEOPLE: "..filter.Who.."\n"
		end
		-- Start Date
		if filter.Start then
			filterSummary = filterSummary.."START DATE: "..filter.Start.."\n"
		end
		-- Finish Date
		if filter.Fin then
			filterSummary = filterSummary.."FINISH DATE: "..filter.Fin.."\n"
		end
		-- Access IDs
		if filter.Access then
			filterSummary = filterSummary.."ACCESS: "..filter.Access.."\n"
		end
		-- Status
		if filter.Status then
			filterSummary = filterSummary.."STATUS: "..filter.Status.."\n"
		end
		-- Priority
		if filter.Priority then
			filterSummary = filterSummary.."PRIORITY: "..filter.Priority.."\n"
		end
		-- Due Date
		if filter.Due then
			filterSummary = filterSummary.."DUE DATE: "..filter.Due.."\n"
		end
		-- Category
		if filter.Cat then
			filterSummary = filterSummary.."CATEGORY: "..filter.Cat.."\n"
		end
		-- Sub-Category
		if filter.SubCat then
			filterSummary = filterSummary.."SUB-CATEGORY: "..filter.SubCat.."\n"
		end
		-- Tags
		if filter.Tags then
			filterSummary = filterSummary.."TAGS: "..filter.Tags.."\n"
		end
		-- Schedules
		if filter.Schedules then
			filterSummary = filterSummary.."SCHEDULES: "..filter.Schedules.."\n"
		end
		if filter.Script then
			filterSummary = filterSummary.."CUSTOM SCRIPT APPLIED".."\n"
		end
		if filterSummary == "" then
			filterSummary = "No Filtering"
		end
	end
	return filterSummary
end

-- Function to filter out tasks from the task hierarchy
function Karm.FilterObject.applyFilterHier(filter, taskHier)
	local hier = taskHier
	local returnList = {count = 0}
	local data = {returnList = returnList, filter = filter}
	for i = 1,#hier do
		data = Karm.TaskObject.applyFuncHier(hier[i],function(task,data)
							  	local passed = Karm.FilterObject.validateTask(data.filter,task)
							  	if passed then
							  		data.returnList.count = data.returnList.count + 1
							  		data.returnList[data.returnList.count] = task
							  	end
							  	return data
							  end, data
		)
	end
	return data.returnList
end

-- Old Version
--function Karm.FilterObject.applyFilterHier(filter, taskHier)
--	local hier = taskHier
--	local hierCount = {}
--	local returnList = {count = 0}
----[[	-- Reset the hierarchy if not already done so
--	while hier.parent do
--		hier = hier.parent
--	end]]
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
--			local passed = Karm.FilterObject.validateTask(filter,hier[hierCount[hier]])
--			if passed then
--				returnList.count = returnList.count + 1
--				returnList[returnList.count] = hier[hierCount[hier]]
--			end
--			if hier[hierCount[hier]].SubTasks then
--				-- This task has children so go deeper in the hierarchy
--				hier = hier[hierCount[hier]].SubTasks
--				hierCount[hier] = 0
--			end
--		end
--	end		-- while hierCount[hier] < #hier or hier.parent do ends here
--	return returnList
--end

-- Function to filter out tasks from a list of tasks
function Karm.FilterObject.applyFilterList(filter, taskList)
	local returnList = {count = 0}
	for i=1,#taskList do
		local passed = Karm.FilterObject.validateTask(filter,taskList[i])
		if passed then
			returnList.count = returnList.count + 1
			returnList[returnList.count] = taskList[i]
		end
	end
	return returnList
end

--[[ The Task Filter should filter the following:

1. Tasks - Particular tasks with or without its children - This is a table with each element (starting from 1) has a Specified Task ID, Task Title, with 'children' flag. If TaskID = Karm.Globals.ROOTKEY..(Spore File name) then the whole spore will pass the filter
2. Who - People responsible for the task (Boolean) - Boolean string with people IDs with their status in single quotes "'milind.gupta,A' or 'aryajur,A' and not('milind_gupta,A' or 'milind0x,I')" - if status not present then taken to be A (Active) 
3. Date_Started - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by ,
4. Date_Finished - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , Karm.Globals.NoDateStr means no date also passes
5. AccessIDs - Boolean expression of IDs and their access permission - "'milind.gupta,R' or 'aryajur,W' and not('milind_gupta,W' or 'milind0x,W')", Karm.Globals.NoAccessIDStr means tasks without an Access ID list also pass
6. Status - Member of given list of status types - List of status types separated by commas
7. Priority - Member of given list of priority types - List of priority numbers separated by commas -"1,2,3", Karm.Globals.NoPriStr means no priority also passes
8. Date_Due - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , Karm.Globals.NoDateStr means no date also passes
9. Category - Member of given list of Categories - List of categories separated by commas, Karm.Globals.NoCatStr means tasks without any category also pass
10. Sub-Category - Member of given list of Sub-Categories - List of sub-categories separated by commas, Karm.Globals.NoSubCatStr means tasks without any sub-category also pass
11. Tags - Boolean expression of Tags - "'Technical' or 'Electronics'" - Tags allow alphanumeric characters spaces and underscores - For no TAG the tag would be Karm.Globals.NoDateStr
12. Schedules - Type of matching - Fully Contained or any overlap with the given ranges
		Type of Schedule - Estimate, Committed, Revisions (L=Latest, P=Planning or the number of revision) or Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)
		Boolean expression different schedule criterias together 
		"'Full,Estimate(L),12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012' or 'Full,Estimate(L),'..Karm.Globals.NoDateStr"
		Karm.Globals.NoDateStr signifies no schedule for the type of schedule the type of matching is ignored in this case
13. Script - The custom user script. task is passed in task variable. Executes in the Karm.Globals.safeenv environment. Final result (true or false) is present in the result variable
14. DontShowHierarchy - Boolean flag, if false (default set) then the parent hierarchy up to the spore of a task that passes the filter will also pass the filter
]]

-- Function to validate a given task
function Karm.FilterObject.validateTask(filter, task)
	if not filter then
		return true
	end

	local function validateWithFilterUnit(filter,task)
		if not filter then
			return true
		end
		if not filter.DontShowHierarchy and task.SubTasks then
			-- Check if any task in the child hierarchy passes the filter, if it does this task automatically passes
			local hier = task.SubTasks
			local data = {passed=nil, filter = filter}
			for i = 1,#hier do
				data = Karm.TaskObject.applyFuncHier(hier[i],function(task,data)
										if not data.passed then
											local passed = Karm.FilterObject.validateTask(data.filter,task)
											if passed then
												data.passed = true
											end
										end
										return data
									  end, data
				)
				if data.passed then
					-- a task in the child hierarchy passes to this task would pass
					return true
				end
			end
		end
		-- Check if task ID passes
		if filter.Tasks then
			local matched = false
			for i = 1,#filter.Tasks do
				if string.sub(filter.Tasks[i].TaskID,1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
					-- A whole spore is marked check if this task belongs to that spore
					-- Check if this is the spore of the task
					if string.sub(filter.Tasks[i].TaskID,#Karm.Globals.ROOTKEY+1,-1) == task.SporeFile then
						if not filter.Tasks[i].Children then
							return false
						end
						matched = true
						break
					end
				else  
					-- Check if the task ID matches
					if filter.Tasks[i].Children then
						-- Children are allowed
						if filter.Tasks[i].TaskID == task.TaskID or 
						  filter.Tasks[i].TaskID == string.sub(task.TaskID,1,#filter.Tasks[i].TaskID) then
							matched = true
							break
						end
					else
						if filter.Tasks[i].TaskID == task.TaskID then
							matched = true
							break
						end
					end
				end		-- if filter.Tasks.TaskID == Karm.Globals.ROOTKEY.."S" then ends
			end	-- for 1,#filter.Tasks ends here
			if not matched then
				return false
			end
		end
		-- Check if Who passes
		if filter.Who then
			local pattern = "%'([%w%.%_%,]+)%'"
			local whoStr = filter.Who
			for id in string.gmatch(filter.Who,pattern) do
				-- Check if the Status is given
				local idc = id
				local st = string.find(idc,",")
				local stat
				if st then
					-- Status exists, extract it here
					stat = string.sub(idc,st+1,-1)
					idc = string.sub(idc,1,st-1)
				else
					stat = "A"
				end
				-- Check if the id exists in the task
				local result = false
				for i = 1,#task.Who do
					if task.Who[i].ID == idc then
						if stat == "A" and string.upper(task.Who[i].Status) == "ACTIVE" then
							result = true
							break
						end
						if stat =="I" and string.upper(task.Who[i].Status) =="INACTIVE" then
							result = true
							break
						end
						result = false
						break
					end		-- if task.Who[i].ID == idc then ends
				end		-- for i = 1,#task.Who ends
				whoStr = string.gsub(whoStr,"'"..id.."'",tostring(result))
			end		-- for id in string.gmatch(filter.Who,pattern) do ends
			-- Check if the boolean passes
			if not loadstring("return "..whoStr)() then
				return false
			end
		end		-- if filter.Who then ends
		
		-- Check if Date Started Passes
		if filter.Start then
			-- Trim the string from leading and trailing spaces
			local strtStr = string.match(filter.Start,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(strtStr,-1,-1)~="," then
				strtStr = strtStr .. ","
			end
			local matched = false
			for range in string.gmatch(strtStr,"(.-),") do
				-- See if this is a range or a single date
				local strt,stp = string.match(range,"(.-)%-(.*)")
				if not strt then
					-- its not a range
					strt = range
					stp = range
				end
				strt = Karm.Utility.toXMLDate(strt)
				stp = Karm.Utility.toXMLDate(stp)
				local taskDate = task.Start
				if strt <= taskDate and taskDate <=stp then
					matched = true
					break
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Date Finished Passes
		if filter.Fin then
			-- Trim the string from leading and trailing spaces
			local finStr = string.match(filter.Fin,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(finStr,-1,-1)~="," then
				finStr = finStr .. ","
			end
			local matched = false
			for range in string.gmatch(finStr,"(.-),") do
				-- Check if this is Karm.Globals.NoDateStr
				if range == Karm.Globals.NoDateStr and not task.Fin then
					matched = true
					break
				end
				-- See if this is a range or a single date
				local strt,stp = string.match(range,"(.-)%-(.*)")
				if not strt then
					-- its not a range
					strt = range
					stp = range
				end
				strt = Karm.Utility.toXMLDate(strt)
				stp = Karm.Utility.toXMLDate(stp)
				if task.Fin then
					if strt <= task.Fin and task.Fin <=stp then
						matched = true
						break
					end
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Access IDs pass
		if filter.Access then
			local pattern = Karm.Globals.UserIDPattern
			local accStr = filter.Access
			for id in string.gmatch(filter.Access,pattern) do
				local result = false
				if id == Karm.Globals.NoAccessIDStr and not task.Access then
					result = true
				else
					-- Extract the permission character
					local idc = id
					local st = string.find(idc,",")
					local perm
		
					perm = string.sub(idc,st+1,-1)
					idc = string.sub(idc,1,st-1)
					
					-- Check if the id exists in the task
					if task.Access then
						for i = 1,#task.Access do
							if task.Access[i].ID == idc then
								if string.upper(perm) == "R" and string.upper(task.Access[i].Status) == "READ ONLY" then
									result = true
									break
								end
								if string.upper(perm) =="W" and string.upper(task.Access[i].Status) =="READ/WRITE" then
									result = true
									break
								end
								result = false
								break
							end		-- if task.Access[i].ID == idc then ends
						end		-- for i = 1,#task.Access do ends
					end
					if not result then
						-- Check for Read/Write access does the ID exist in the Who table
						if string.upper(perm) == "W" then
							for i = 1,#task.Who do
								if task.Who[i].ID == idc then
									if string.upper(task.Who[i].Status) == "ACTIVE" then
										result = true
									end
									break
								end
							end		-- for i = 1,#task.Who do ends
						end		-- if string.upper(perm) == "W" then ends
					end		-- if not result then ends
				end		-- if id == Karm.Globals.NoAccessIDStr and not task.Access then ends
				accStr = string.gsub(accStr,"'"..id.."'",tostring(result))
			end		-- for id in string.gmatch(filter.Who,pattern) do ends
			-- Check if the boolean passes
			if not loadstring("return "..accStr)() then
				return false
			end
		end		-- if filter.Access then ends
	
		-- Check if Status Passes
		if filter.Status then
			-- Trim the string from leading and trailing spaces
			local statStr = string.match(filter.Status,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(statStr,-1,-1)~="," then
				statStr = statStr .. ","
			end
			local matched = false
			for stat in string.gmatch(statStr,"(.-),") do
				-- Check if this status matches with what we have in the task
				if task.Status == stat then
					matched = true
					break
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Priority Passes
		if filter.Priority then
			-- Trim the string from leading and trailing spaces
			local priStr = string.match(filter.Priority,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(priStr,-1,-1)~="," then
				priStr = priStr .. ","
			end
			local matched = false
			for pri in string.gmatch(priStr,"(.-),") do
				if pri == Karm.Globals.NoPriStr and not task.Priority then
					matched = true
					break
				end
				-- Check if this priority matches with what we have in the task
				if task.Priority == pri then
					matched = true
					break
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Date Due Passes
		if filter.Due then
			-- Trim the string from leading and trailing spaces
			local dueStr = string.match(filter.Due,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(dueStr,-1,-1)~="," then
				dueStr = dueStr .. ","
			end
			local matched = false
			for range in string.gmatch(dueStr,"(.-),") do
				-- Check if this is Karm.Globals.NoDateStr
				if range == Karm.Globals.NoDateStr and not task.Fin then
					matched = true
					break
				end
				-- See if this is a range or a single date
				local strt,stp = string.match(range,"(.-)%-(.*)")
				if not strt then
					-- its not a range
					strt = range
					stp = range
				end
				strt = Karm.Utility.toXMLDate(strt)
				stp = Karm.Utility.toXMLDate(stp)
				if task.Due then
					if strt <= task.Due and task.Due <=stp then
						matched = true
						break
					end
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Category Passes
		if filter.Cat then
			-- Trim the string from leading and trailing spaces
			local catStr = string.match(filter.Cat,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(catStr,-1,-1)~="," then
				catStr = catStr .. ","
			end
			local matched = false
			for cat in string.gmatch(catStr,"(.-),") do
				-- Check if it matches Karm.Globals.NoCatStr
				if cat == Karm.Globals.NoCatStr and not task.Cat then
					matched = true
					break
				end
				-- Check if this status matches with what we have in the task
				if task.Cat == cat then
					matched = true
					break
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Sub-Category Passes
		if filter.SubCat then
			-- Trim the string from leading and trailing spaces
			local subCatStr = string.match(filter.SubCat,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(subCatStr,-1,-1)~="," then
				subCatStr = subCatStr .. ","
			end
			local matched = false
			for subCat in string.gmatch(subCatStr,"(.-),") do
				-- Check if it matches Karm.Globals.NoSubCatStr
				if subCat == Karm.Globals.NoSubCatStr and not task.SubCat then
					matched = true
					break
				end
				-- Check if this status matches with what we have in the task
				if task.SubCat == subCat then
					matched = true
					break
				end
			end
			if not matched then
				return false
			end
		end
	
		-- Check if Tags pass
		if filter.Tags then
			local pattern = "%'([%w%s%_]+)%'"	-- Tags are allowed alphanumeric characters spaces and underscores
			local tagStr = filter.Tags
			for tag in string.gmatch(filter.Tags,pattern) do
				-- Check if the tag exists in the task
				local result = false
				if tag == Karm.Globals.NoTagStr and not task.Tags then
					result = true
				elseif task.Tags then			
					for i = 1,#task.Tags do
						if task.Tags[i] == tag then
							-- Found the tag in the task
							result = true
							break
						end		-- if task.Tags[i] == tag then ends
					end		-- for i = 1,#task.Tags ends
				end
				tagStr = string.gsub(tagStr,"'"..tag.."'",tostring(result))
			end		-- for id in string.gmatch(filter.Tags,pattern) do ends
			-- Check if the boolean passes
			if not loadstring("return "..tagStr)() then
				return false
			end
		end		-- if filter.Access then ends
		
		-- Check if the Schedules pass
		if filter.Schedules then
			local schStr = filter.Schedules
			for sch in string.gmatch(filter.Schedules,"%'(.-)%'") do
				-- Check if this schedule chunk passes in the task
				-- "'Full,Estimate,12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012'"
				local typeMatch, typeSchedule, ranges, rangeStr, index, result
				local firstComma = string.find(sch,",")
				local secondComma = string.find(sch,",",firstComma + 1)
				typeMatch = string.sub(sch,1,firstComma-1)
				typeSchedule = string.sub(sch,firstComma + 1,secondComma - 1)
				ranges = {[0]=string.sub(sch,secondComma + 1, -1),count=0}
				rangeStr = ranges[0]
				-- Make sure the string has "," at the end
				if string.sub(rangeStr,-1,-1)~="," then
					rangeStr = rangeStr .. ","
				end
				-- Now separate individual date ranges
				for range in string.gmatch(rangeStr,"(.-),") do
					ranges.count = ranges.count + 1
					ranges[ranges.count] = range
				end
				-- Type of Schedule - Estimate, Committed, Revision(X) (L=Latest or the number of revision), Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)
				index = nil
				if string.upper(string.sub(typeSchedule,1,#"ESTIMATE")) == "ESTIMATE" then
					if string.match(typeSchedule,"%(%d-%)") then
						-- Get the index number
						index = string.match(typeSchedule,"%((%d-)%)")
					elseif string.upper(string.match(typeSchedule,"%((%a-)%)")) == "L" then
						-- Get the latest schedule index
						if task.Schedules and task.Schedules.Estimate then
							index = #task.Schedules.Estimate
						else
							if ranges[0] == Karm.Globals.NoDateStr then
								result = true
							end
							schStr = string.gsub(schStr,string.gsub("'"..sch.."'","(%W)","%%%1"),tostring(result))
						end		
					else
						-- This is the planning schedule
						if task.Planning and task.Planning.Type == "Estimate" then
							index = "Planning"
						else
							if ranges[0] == Karm.Globals.NoDateStr then
								result = true
							end	
							schStr = string.gsub(schStr,string.gsub("'"..sch.."'","(%W)","%%%1"),tostring(result))
						end
					end
					typeSchedule = "Estimate"
				elseif string.upper(string.sub(typeSchedule,1,#"COMMITTED")) == "COMMITTED" then
					typeSchedule = "Commit"
					if string.match(typeSchedule,"%((%a-)%)") then
						if string.upper(string.match(typeSchedule,"%((%a-)%)")) == "P" then
							index = "Planning"
						else
							index = 1
						end
					else
						index = 1
					end
				elseif string.upper(string.sub(typeSchedule,1,#"REVISION")) == "REVISION" then
					if string.match(typeSchedule,"%(%d-%)") then
						-- Get the index number
						index = string.match(typeSchedule,"%((%d-)%)")
					elseif string.upper(string.match(typeSchedule,"%((%a-)%)")) == "L" then  
						-- Get the latest schedule index
						if task.Schedules and task.Schedules.Revs then
							index = #task.Schedules.Revs
						else
							if ranges[0] == Karm.Globals.NoDateStr then
								result = true
							end
							schStr = string.gsub(schStr,string.gsub("'"..sch.."'","(%W)","%%%1"),tostring(result))
						end			
					else
						-- This is the planning schedule
						if task.Planning and task.Planning.Type == "Revs" then
							index = "Planning"
						else
							if ranges[0] == Karm.Globals.NoDateStr then
								result = true
							end	
							schStr = string.gsub(schStr,string.gsub("'"..sch.."'","(%W)","%%%1"),tostring(result))
						end
					end
					typeSchedule = "Revs"
				elseif string.upper(string.sub(typeSchedule,1,#"ACTUAL")) == "ACTUAL" then
					typeSchedule = "Actual"
					index = 1
				elseif string.upper(string.sub(typeSchedule,1,#"LATEST")) == "LATEST" then
					-- Find the latest schedule in the task here
					if string.upper(task.Status) == "DONE" and task.Schedules and task.Schedules.Actual then
						typeSchedule = "Actual"
						index = 1
					elseif task.Schedules and task.Schedules.Revs then
						-- Actual is not the latest one but Revision is 
						typeSchedule = "Revs"
						index = task.Schedules.Revs.count
					elseif task.Schedules and task.Schedules.Commit then
						-- Actual and Revisions don't exist but Commit does
						typeSchedule = "Commit"
						index = 1
					elseif task.Schedules and task.Schedules.Estimate then
						-- The latest is Estimate
						typeSchedule = "Estimate"
						index = task.Schedules.Estimate.count
					else
						-- typeSchedule is latest but non of the schedule types exist
						-- Check if the range is Karm.Globals.NoDateStr, if not this sch is false
						local result = false
						if ranges[0] == Karm.Globals.NoDateStr then
							result = true
						end
						schStr = string.gsub(schStr,string.gsub("'"..sch.."'","(%W)","%%%1"),tostring(result))
					end
				else
					wx.wxMessageBox("Invalid Type Schedule ("..typeScehdule..") specified in filter: "..sch,"Filter Error",
	                            wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
					return false
				end		-- if string.upper(string.sub(typeSchedule,1,#"ESTIMATE") == "ESTIMATE" then ends  (SETTING of typeSchdule and index)
				if index then
					-- We have a typeSchedule and index
					-- Now loop through the schedule of typeSchedule and index
					local result
					if string.upper(typeMatch) == "OVERLAP" then
						result = false
					else
						result = true
					end
					-- First check if range is Karm.Globals.NoDateStr then this schedule should not exist for filter to pass
					if ranges[0] == Karm.Globals.NoDateStr then
						if index == "Planning" then
							if task.Planning then
								result = false
							else
								result = true
							end
						else
							if task.Schedules[typeSchedule] and not task.Schedules[typeSchedule][index]  or not task.Schedules[typeSchedule] then
								result = true
							else
								result = false
							end
						end
					else
						if index == "Planning" then
							if task.Planning then
								for i = 1,#task.Planning.Period do
									-- Is the date in range?
									local inrange = false
									for j = 1,#ranges do
										local strt,stp = string.match(ranges[j],"(.-)%-(.*)")
										if not strt then
											-- its not a range
											strt = ranges[j]
											stp = ranges[j]
										end
										strt = Karm.Utility.toXMLDate(strt)
										stp = Karm.Utility.toXMLDate(stp)
										if strt <= task.Planning.Period[i].Date and task.Planning.Period[i].Date <=stp then
											inrange = true
										end
									end		-- for j = 1,#ranges do ends
									if inrange and string.upper(typeMatch) == "OVERLAP" then
										-- This date overlaps
										result = true
										break
									elseif not inrange and string.upper(typeMatch) == "FULL" then
										-- This portion is not contained in filter
										result = false
										break
									end
								end
							else
								result = false
							end
						else
							if task.Schedules and task.Schedules[typeSchedule] and task.Schedules[typeSchedule][index] then
								for i = 1,#task.Schedules[typeSchedule][index].Period do
									-- Is the date in range?
									local inrange = false
									for j = 1,#ranges do
										local strt,stp = string.match(ranges[j],"(.-)%-(.*)")
										if not strt then
											-- its not a range
											strt = ranges[j]
											stp = ranges[j]
										end
										strt = Karm.Utility.toXMLDate(strt)
										stp = Karm.Utility.toXMLDate(stp)
										if strt <= task.Schedules[typeSchedule][index].Period[i].Date and task.Schedules[typeSchedule][index].Period[i].Date <=stp then
											inrange = true
										end
									end		-- for j = 1,#ranges do ends
									if inrange and string.upper(typeMatch) == "OVERLAP" then
										-- This date overlaps
										result = true
										break
									elseif not inrange and string.upper(typeMatch) == "FULL" then
										-- This portion is not contained in filter
										result = false
										break
									end
								end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
							else
								-- Task Schedule for the particular index does not exist and noDateStr was not specified so this is not a match
								result = false
							end		-- if task.Schedules[typeSchedule] and task.Schedules[typeSchedule][index] then ends
						end		-- if index == "Planning" then ends
					end	-- if ranges[0] == Karm.Globals.NoDateStr then ends
					schStr = string.gsub(schStr,string.gsub("'"..sch.."'","(%W)","%%%1"),tostring(result))
				end		-- if index then ends
			end		-- for sch in string.gmatch(filter.Schedules,"%'(.-)%'") do ends
			-- Check if the boolean passes
			if not loadstring("return "..schStr)() then
				return false
			end
		end		-- if filter.Schedules then ends
	
		if filter.Script then
			local safeenv = {}
			setmetatable(safeenv,{__index = Karm.Globals.safeenv})
			local func,message = loadstring(filter.Script)
			if not func then
				return false
			end
			safeenv.task = task
			setfenv(func,safeenv)
			local stat,err
			stat,err = pcall(func)
			if not stat then
				wx.wxMessageBox("Error Running Script:\n"..err,"Error",wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
			end			
			if not safeenv.result then
				return false
			end
		end
		
		-- All pass
		return true
	end		-- function validateWithFilterUnit(filter,task) ends
	
	-- Check if this is a simple filter or a filter combination
	if filter.Map then
		-- This is a filter combination
		local bool = filter.Bool
		for i = 1,filter.Map.count do
			local result = "false"
			if validateWithFilterUnit(filter.Map["F"..i].Filter,task) then
				-- This filter unit passes
				result = "true"
			end
			bool = string.gsub(bool, string.gsub("'"..filter.Map["F"..i].Name.."'","[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end), result)
		end
		-- Check if the boolean passes
		if not loadstring("return "..bool)() then
			return false
		else
			return true
		end		
	else
		-- Just use this as a filter
		return validateWithFilterUnit(filter,task)
	end
end		-- function Karm.FilterObject.validateTask(filter, task) ends
