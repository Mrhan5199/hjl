---顺序轮序
local rootdir = freeswitch.getGlobalVariable("base_dir");
local api =  freeswitch.API();

file_path=rootdir.."/scripts/route/number.txt"
local gw = {}
local index = 1
local max = 0
local profile = nil
profile = argv[1]
if argv[1] == nil or string.match(profile,"qidian") == nil then
        freeswitch.consoleLog("ERR","must argv[1] profile!\n");
        return
end
local myfile = io.open(file_path,"r")
for i in myfile:lines() do
	gw[index] = i
	index = index+1
end

if api:executeString("db exists/gateway_route/current_pos") == "false" then
	api:executeString("db insert/gateway_route/current_pos/0")
end

count = 0
upgw = {}
gwstatusstr = api:executeString("sofia status gateway")
for k,v in ipairs(gw) do
	if string.match(api:executeString("sofia status gateway "..v),"Status%s+UP%s+") then
		upgw[count] = v
		count = count+1
	end	
end
current_pos = tonumber(api:executeString("db select/gateway_route/current_pos")) 
if current_pos>=count then
	current_pos = 0
end

new_pos = current_pos + 1
api:executeString("db insert/gateway_route/current_pos/"..new_pos)
info = api:executeString("show channels")
idx = current_pos
while true do	
	st,_ = string.find(info,"sofia/gateway/"..upgw[idx])
	if st==nil then
		freeswitch.consoleLog("INFO","Discovery of available gateway : "..upgw[idx].." \n");
		stream:write(upgw[idx])
		break
	end
	if idx == current_pos-1 then
		freeswitch.consoleLog("WARNING","No available gateways have been found.\n");
		break
	end
	idx = idx+1
	if current_pos>=index then
		idx = 0
	end
end

myfile:close()
