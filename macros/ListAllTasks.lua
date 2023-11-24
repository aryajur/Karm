-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to list all tasks of the 1st loaded spore
local Spore
-- Get the first loaded spore from the Karm.SporeData table
for k,v in pairs(Karm.SporeData) do
	if k ~= 0 then
		-- This is the 1st spore
		Spore = v
		break
	end
end

-- str is a string variable where we make the list of titles of the tasks
local str = "" 
str = str..Spore[1].Title.."\n"	-- Spore[1] is the 1st task in the Spore
local nextTask = Karm.TaskObject.NextInSequence(Spore[1])
while nextTask do
	str = str..nextTask.Title.."\n"
	nextTask = Karm.TaskObject.NextInSequence(nextTask)
end
-- Display the list
wx.wxMessageBox(str)
