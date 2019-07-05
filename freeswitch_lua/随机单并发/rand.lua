---随机选取一个可用网关
local rootdir = freeswitch.getGlobalVariable("base_dir");
local api =  freeswitch.API();

file_path="/usr/local/freeswitch/scripts/route/number.txt"
local gw = {}
local index = 0
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
info = api:executeString("show channels")
rand = math.random(0,index-1)
while true do
        st,_ = string.find(info,"sofia/gateway/"..gw[rand])
        if st==nil then
                freeswitch.consoleLog("INFO","Discovery of available channel : "..gw[rand].." \n");
                stream:write(gw[rand])
                break
        else
                max = max+1
                if max >= index then
                        freeswitch.consoleLog("ERR","No available gateways have been found.\n");
                        break
                end
                rand = math.random(0,index-1)
        end
end
myfile:close()
