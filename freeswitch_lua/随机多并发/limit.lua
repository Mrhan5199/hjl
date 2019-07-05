--随机方式多并发 limit并发限制

local rootdir = freeswitch.getGlobalVariable("base_dir");
local api =  freeswitch.API();
local limit = nil
local profile = nil
if argv[1] == nil then
        freeswitch.consoleLog("ERR","must argv[1] profile!\n");
        return
end
limit = argv[2]
if argv[2] == nil then
        limit = 1
end
profile = argv[1]
local index = 0
local count = 0
local gwnum = 0
local fullgw = 0
local maxgw = 0
upgw = {}
gwstatusstr = api:executeString("sofia status gateway")

for gw in string.gmatch(gwstatusstr,profile.."::(%d+)%s+") do
        if string.match(api:executeString("sofia status gateway "..gw),"Status%s+UP%s+") then
                upgw[count] = gw
                count = count+1
        end
end
local lt = tonumber(limit);
rand = math.random(0,count-1)
info = api:executeString("show channels")
for num=0,count-1 do
        index = upgw[num]
        for i in string.gmatch(info,"sofia/gateway/"..index) do
                fullgw = fullgw+1
        end
end
freeswitch.consoleLog("INFO","limit is : "..lt.." \n");
freeswitch.consoleLog("INFO","the current channel  is : "..fullgw.." \n");
if (fullgw < count*lt) then
	while true do
		st,_ = string.find(info,"sofia/gateway/"..upgw[rand])
		if st==nil then
			freeswitch.consoleLog("INFO","Discovery of available gateway : "..upgw[rand].." \n");
			stream:write(upgw[rand])
			break
		else
			for i in string.gmatch(info,"sofia/gateway/"..upgw[rand]) do
        			gwnum = gwnum+1
			end
			if (gwnum < lt) then
				freeswitch.consoleLog("INFO","gwnum--limit :"..gwnum.." < "..limit.."   gateway : "..upgw[rand].." \n");
				stream:write(upgw[rand])
				break
			else
				maxgw = maxgw +1
                if (maxgw == count*2) then
					freeswitch.consoleLog("ERR","There is unavailable gateway".."\n");
                    break
                end
				freeswitch.consoleLog("INFO","Exceeding the limit number".."\n");
				rand = math.random(0,count-1)
			end
		end
	end
else
	freeswitch.consoleLog("ERR","There is unavailable gateway".."\n");
end
