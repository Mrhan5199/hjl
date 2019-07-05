--gateway route.

local rootdir = freeswitch.getGlobalVariable("base_dir");
loadfile(rootdir.."/scripts/include/functions.lua")();
local api =  freeswitch.API();

local profile = nil
if argv[1] == nil then
	freeswitch.consoleLog("ERR","must argv[1] profile!\n");
	return 
end 
profile = argv[1]

if api:executeString("db exists/gateway_route/current_pos") == "false" then
	api:executeString("db insert/gateway_route/current_pos/0")
end


count = 0
upgw = {}
gwstatusstr = api:executeString("sofia status gateway")

for gw in string.gmatch(gwstatusstr,profile.."::(%w+)%s+") do
	if string.match(api:executeString("sofia status gateway "..gw),"Status%s+UP%s+") then
		upgw[count] = gw
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
while count>0 do	
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
	if current_pos>=count then
		idx = 0
	end
end