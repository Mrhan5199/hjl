#!/usr/bin/python
##Random multiple concurrency
import freeswitch
import re
import random

rootdir = freeswitch.getGlobalVariable("base_dir");
api = freeswitch.API();
upgw = []
count = 0
fullgw = 0
limit = 0

def handler(session, args):
    pass

def fsapi(session, stream, env, args):
    global count
    global fullgw
    global limit
    if args:
        string = re.split('\s+', args)
    else:
        freeswitch.consoleLog('info', 'must argv1 profile %s\n' % args)
    argv1 = string[0]
    argv2 = string[1]
    gwstatusstr = api.executeString("sofia status gateway")
    pattern = re.compile(argv1+"::(\d+)\s+")
    result1 = pattern.findall(gwstatusstr)
    for gw in range(len(result1)):
        if re.search(r"Status\s+UP\s+",api.executeString("sofia status gateway "+result1[gw])):
            upgw.append(result1[gw])
            count = count + 1
    rand = random.randint(0, count-1)
    info = api.executeString("show channels")
    for k in range(count):
        pat = re.compile("sofia/gateway/"+upgw[k])
        for i in pat.findall(info):
            fullgw = fullgw +1
    freeswitch.consoleLog("info", "the current channel total number is: %s\n" % fullgw)
    if fullgw < count * int(argv2):
        while 0 < 1:
            if re.search("sofia/gateway/"+upgw[rand],info):
                pt = re.compile("sofia/gateway/"+upgw[rand])
                for key in pt.findall(info):
                    limit = limit + 1
		    freeswitch.consoleLog("info", "the limit is: %s\n" % limit)
                if limit < argv2:
                    stream.write(str(upgw[rand]))
                    freeswitch.consoleLog("info", "Discovery of available gateway: %s\n" % upgw[rand])
                    break
                else:
                    rand = random.randint(0, count - 1)
            else:
                stream.write(str(upgw[rand]))
                freeswitch.consoleLog("info", "Discovery of available gateway: %s\n" % upgw[rand])
                break
    else:
        freeswitch.consoleLog("ERR","There is unavailable gateway"+"\n")
