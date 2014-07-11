-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application module providing the core code for task database management
-- Author:      Milind Gupta
-- Created:     6/5/2014
-- Comments:	This module should be loaded in a global table called Karm to provide scripts a standard access to the Karm API in whatever application it is used
-----------------------------------------------------------------------------



local modname = ...
local Globals = Globals

-- Lua functions
local type = type
local flag
local getfenv = getfenv
local setfenv = setfenv
local loadstring = loadstring
local load = load


-- Karm Module
-- .ROOTKEY = string containing the rootkey for the theoretical root node
-- .loadKarmSporeLua = function to load a spore from a table stored Lua code file
-- .loadKarmSporeXML = function to load a spore from a XML stored spore file
-- .loadKarmSporeDB = if present this function will load the spore from the database file using tableDB
-- .validateSpore
-- .validateTask
-- .getSpore = Returns the spore object given the spore index from SporeData

-- Setup the module environment
----------------------------------------------------------
local M = {}
package.loaded[modname] = M
if setfenv then
	setfenv(1,M)
else
	_ENV = M
end
----------------------------------------------------------

-- PARAMETER AND TABLE INITIALIZATIONS

-- Configuration parameters
local CORECONFIGFILE = "KarmCoreConfig.lua"
ROOTKEY = "T0"



local SporeData = {}	-- Table to store all the Spores raw data table 
local interFaceMap = {}	-- Table to store the interface to actual task/Spore in the SporeData table

local taskObject = {__metatable = true}


-- INITIALIZATIONS
if type(Globals) ~= "table" then
	Globals = {}
end
SporeData[0] = 0	-- To hold the number of loaded spores

-- Task Table structure (this has a metatable taskObject)
-- Task.
------------------CONTROLLED PARAMETERS ALSO USED FOR OBJECT VALIDATION------------------------------
--	[0] = "Task"   
--	Title
--	DBDATA.
--	TaskID
--	Modified
--	Who.
--	Parent. = Pointer to the Task to which this is a sub task (Nil for root tasks in a Spore)
--  Next. = Pointer to the next task under the same Parent (Nil if this is the last task)
--  Previous. = Pointer to the previous task under the same Parent (Nil if this is the first task)
--	SubTasks.
--		[0] = "SubTasks"
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask Node this is (Points to Spore table for root tasks of a Spore) - Thus this is always present in a task even if it does not have sub tasks.
--		tasks = count of number of subtasks
--		[i] = Task table like this one repeated for sub tasks
----------------------------------------------------------------------------------------------------------------
--	Planning.
--  PlanWorkDone.
--	Start
--	Fin
--	Private
--	Access.
--	Assignee.
--	Status
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

-- Spore table structure
-- Title = Spore file name
-- SporeFile = File path and name
-- tasks = number of root tasks
-- TaskID = Karm.Globals.ROOTKEY..<number>..SporeFile
-- [0] = "Task_Spore"
-- [i] = Task table structure

-- Function to check if the file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function validateSpore(spore)
	if getmetatable(spore) ~= taskObject then
		return nil
	end
	if spore[0] ~= "Task_Spore" then
		return nil
	end
	if not spore.tasks or type(spore.tasks) ~= "number" then
		return nil
	end
	if not spore.SporeFile or type(spore.SporeFile) ~= "string" then
		return nil
	end
	if not spore.TaskID or type(spore.TaskID) ~= "string" then
		return nil
	end
	return true
end

function validateTask(task)
	if task[0] ~= "Task" then
		return nil
	end
	if not task.Title or type(task.Title) ~= "string" then
		return nil
	end
	if not task.TaskID or type(task.TaskID) ~= "string" then
		return nil
	end
	if not task.SubTasks or type(task.SubTasks) ~= "table" or task.SubTasks[0] ~= "SubTasks" or not task.SubTasks.Parent or not task.SubTasks.tasks or type(task.SubTasks.tasks) ~= "number" then
		return nil
	end
	if not task.Who or type(task.Who) ~= "table" then
		return nil
	end
	return true
end

-- Function to handle access to the Spore/task object
function taskObject.__index(t,k)
end

-- Function to handle write access to the Spore/task object
function taskObject.__newindex(t,k,v)
end

-- Function to return the spore object to the outside code
function getSpore(index)
	if index > SporeData[0] then
		return nil
	end
	for k,v in pairs(SporeData) do
		if v.TaskID:sub(1,#(ROOTKEY..tostring(index))) == (ROOTKEY..tostring(index)) then
			-- This is the spore
			-- Check if an interface exists
			if interFaceMap[v] then
				return interFaceMap[v]
			end
			-- Create and return the interface for it
			interFaceMap[v] = {}
			interFaceMap[interFaceMap[v]] = v
			setmetatable(interFaceMap[v],taskObject)
			return interFaceMap[v]
		end
	end
	-- Nothing found
	return nil
end

-- Function to return the iterator to iterate over the tasks from the provided task or spore
-- The given task is not repeated
function task_iter(task)
	if not validateTask(task) and not validateSpore(task) then
		return function() 
				return nil
			end
	end
	return 
		function(s,t)
			-- If t is spore then return its 1st task
			if validataSpore(t) then
				return t[1]
			end
			-- If t is not a spore and not a tas
			if not validateTask(t) then
				return nil
			end
			if t.SubTasks[1] then
				return t.Subtasks[1]
			end
			if t.Next then
				return t.Next
			end
			local tn = t.Parent
			while tn and not tn.Next do
				tn = tn.Parent
			end
			if tn then
				return tn.Next
			end
			return nil
		end,nil,task
end

-- Function to load a Spore given the Spore file path in the data structure
-- Inputs:
-- file - the file name with full path of the Spore to load
-- force - if true reloads the data over the existing data
-- Returns true if successful otherwise returns nil and message     
-- Error Messges returned:
--		 1 - Spore Already loaded
-- 		 2 - Task ID in the Spore already exists in the memory
--		 3 - No valid Spore found in the file
--		 4 - File load error
function loadKarmSporeLua(file, force)
	local Spore
	do
		local safeenv = {}
		setmetatable(safeenv, {__index = Globals.safeenv})
		local f,message
		if setfenv then
			f,message = loadfile(file)
			if not f then
				return nil,"File Load Error:"..message
			end
			setfenv(f,safeenv)
		else
			f,message = load(file,"bt",safeenv)
			if not f then
				return nil,"File Load Error:"..message
			end
		end
		f()
		if validateSpore(safeenv.t0) then
			Spore = safeenv.t0
		else
			return nil, "No valid Spore found in file"
		end
	end
	-- Update the SporeFile in all the tasks and set the metatable
	Spore.SporeFile = file
	
	-- First update the ROOTKEY
	Spore.TaskID = ROOTKEY..tostring(SporeData[0]+1)..file
	
	local reload = nil
	-- Now check if the spore is already loaded in the dB
	for k,v in pairs(Karm.SporeData) do
		if k~=0 then
			if k == Spore.SporeFile then
				if force then
					-- Reload the spore
					reload = true
				else
					return nil, "Spore already loaded"
				end
			end		-- if k == Spore.SporeFile then ends
			-- Check if any task ID is clashing with the existing tasks
			for task1 in task_iter(Spore) do
				for task2 in task_iter(v) do
					if task1.TaskID == task2.TaskID then
						return nil, "Task ID in the Spore already exists in the memory"
					end
				end		-- for j = 1,#list2 do ends
			end		-- for i = 1,#list1 do ends
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(Karm.SporeData) do ends
	if reload then
		-- Delete the current spore
		Karm.SporeData[Spore.SporeFile] = nil
		if not commands.onlyData and Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore.SporeFile] then
			Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore.SporeFile)
		end
	end
	-- Load the spore here
	Karm.SporeData[Spore.SporeFile] = Spore
	Karm.SporeData[0] = Karm.SporeData[0] + 1
	if not commands.onlyData then
		-- Load the Spore in the Karm.GUI here
		Karm.GUI.addSpore(Spore.SporeFile,Spore)
	end
	return true
end		-- function Karm.loadKarmSpore(file, commands) ends here

local function KarmInit()
	Karm.SporeData[0] = 0	-- number of spores in the SporeData
	-- Check and load the configuration file if it exists
	if file_exists(CORECONFIGFILE) then
		local f,msg 
		f,msg = loadfile(CORECONFIGFILE)
		if f~=nil then 
			pcall(f)
		end
	end
end
