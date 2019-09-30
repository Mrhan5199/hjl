#!/usr/bin/python
##Random single concurrency
import freeswitch
import re
import random

rootdir = freeswitch.getGlobalVariable("base_dir");
api = freeswitch.API();

file_path = rootdir+"/scripts/pyscripts/sipnumber/number"
def file_list(filename):
    num_list = []
    file = open(filename,"r")
    for line in file.readlines():
        line = line.strip('\n')
        num_list.append(line)
    file.close()
    return num_list

def handler(session, args):
    pass

def fsapi(session, stream, env, args):
    count, fullgw, count, loop = 0, 0, 0, 0
    upgw = []
    upgw_list = file_list(file_path)
    for gw in range(len(upgw_list)):
        if re.search(r"Status\s+UP\s+", api.executeString("sofia status gateway " + upgw_list[gw])):
            upgw.append(upgw_list[gw])
            count = count + 1
    rand = random.randint(0, count-1)
    info = api.executeString("show channels")
    for k in range(count):
        pt = re.compile("sofia/gateway/"+upgw[k])
        for i in pt.findall(info):
            fullgw = fullgw + 1
    freeswitch.consoleLog("info","the current channel total number is %s" % fullgw )
    if fullgw < count:
        while 0 < 1:
            if re.search("sofia/gateway/"+upgw[rand],info):
                loop = loop + 1
                if loop < count:
                    rand = random.randint(0, count-1)
                else:
                    break
            else:
                stream.write(str(upgw[rand]))
                freeswitch.consoleLog("info", "Discovery of available gateway: %s\n" % upgw[rand])
                break
    else:
        freeswitch.consoleLog("ERR","There is unavailable gateway"+"\n")
