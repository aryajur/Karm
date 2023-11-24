-- Run Spore integrity check
local errors
for k,v in pairs(Karm.SporeData) do
	if k ~= 0 then
		errors = Karm.TaskObject.CheckSporeIntegrity(nil, v)
		if #errors > 0 then
			print("Errors in Spore: "..k)
			for i = 1,#errors do
				print("Task: "..errors[i].Task.Title.." ERROR: "..errors[i].Error)
			end
			print("-------------------------------")
		end
	end
end