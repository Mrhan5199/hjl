---顺序轮序,限制呼叫次数
local rootdir = freeswitch.getGlobalVariable("base_dir");
local api =  freeswitch.API();


function string_spilt(str,sep)
	if str == nil or sep == nil then 
		return {};
	end
	local s = 1;
	local arr = {};
	local c = 1;
	while true do
		local s1 = string.find(str,sep,s);		
		if s1 == nil then
			arr[c] = string.sub(str,s,-1);
			break;
		end
		if s == s1 then
			arr[c] = "";
		else
			arr[c] = string.sub(str,s,s1-1); 
		end		
		s = s1 + 1;
		c = c+1;
	end
	return arr;
end


function check_gateway_limits(key,limits)
	local last = nil
	if api:executeString("db exists/call_limit_last_count_of_day/data_time") == "false" then
	    	local last_day = os.date("%Y%m%d")
	    	api:executeString("db insert/call_limit_last_count_of_day/data_time/"..last_day)
	else
        	last_day = api:executeString("db select/call_limit_last_count_of_day/data_time")
    end
	local count = 0
	if api:executeString("db exists/call_limit_value_count_of_day/"..key) == "false" then
		api:executeString("db insert/call_limit_value_count_of_day/"..key.."/0")
	else
        	count = tonumber(api:executeString("db select/call_limit_value_count_of_day/"..key)) 	
    	end
	local current_time = os.date("%Y%m%d")
	if current_time ~= last_day then
		count = 0
		api:executeString("db delete/call_limit_last_count_of_day/data_time")
		local keys = string_spilt(api:executeString("db list/call_limit_value_count_of_day/"),",")
		for k,v in ipairs(keys) do
            		api:executeString("db delete/call_limit_value_count_of_day/"..v)		
		end	
		api:executeString("db insert/call_limit_last_count_of_day/data_time/"..current_time)
	end
	freeswitch.consoleLog("info","Limit the number of calls per day,'"..key.."',limits:"..limits..",count:"..count..".\n")
	if count < limits then
		count = count + 1 
		api:executeString("db insert/call_limit_value_count_of_day/"..key.."/"..count)
		return true
	else
	    	return false
   	end
	
end

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
if argv[2] == nil then
	freeswitch.consoleLog("ERR","must argv[2] limits!\n")
	return 
end 
local limits = tonumber(argv[2])
local myfile = io.open(file_path,"r")
for i in myfile:lines() do
	gw[index] = i
	index = index+1
end
myfile:close()
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
		if check_gateway_limits(upgw[idx],limits) then
			stream:write(upgw[idx])
			break
		end
	end
	if idx == current_pos-1 then
		freeswitch.consoleLog("WARNING","No available gateways have been found.\n");
		break
	end
	idx = idx+1
	if current_pos>=count then
		idx = 0
	end
	if idx >= count then
		break
	end
end


