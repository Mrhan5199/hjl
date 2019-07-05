--单并发随机方式
local rootdir = freeswitch.getGlobalVariable("base_dir");
local api =  freeswitch.API();
local profile = nil
if argv[1] == nil then
        freeswitch.consoleLog("ERR","must argv[1] profile!\n");
        return
end
profile = argv[1]
local count = 0
local fullgw = 0
local index = 0
upgw = {}
gwstatusstr = api:executeString("sofia status gateway")

for gw in string.gmatch(gwstatusstr,profile.."::(%d+)%s+") do
        if string.match(api:executeString("sofia status gateway "..gw),"Status%s+UP%s+") then
                upgw[count] = gw
                count = count+1
        end
end
rand = math.random(0,count-1)
freeswitch.consoleLog("INFO","the origin rand num is : "..rand.." \n");
info = api:executeString("show channels")
for num=0,count-1 do
        index = upgw[num]
        for i in string.gmatch(info,"sofia/gateway/"..index) do
                fullgw = fullgw+1
        end
end
if (fullgw < count) then
	while true do
		st,_ = string.find(info,"sofia/gateway/"..upgw[rand])
        if st==nil then
			freeswitch.consoleLog("INFO","the latest rand num is : "..rand.." \n");
            freeswitch.consoleLog("INFO","Discovery of available gateway : "..upgw[rand].." \n");
            stream:write(upgw[rand])
            break
        else
            rand = math.random(0,count-1)
        end
    end
else
    freeswitch.consoleLog("ERR","There is unavailable gateway".."\n");
    break
end
