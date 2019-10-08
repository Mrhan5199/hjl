#!/usr/bin/python
##Polling
import freeswitch
import re

rootdir = freeswitch.getGlobalVariable("base_dir");
api = freeswitch.API();

def db_insert(current_pos):
     api.executeString("db insert/gateway_route/current_pos/"+str(current_pos))

def db_select():
    return api.executeString("db select/gateway_route/current_pos")

def db_exists():
    if not api.executeString("db select/gateway_route/current_pos"):
        api.executeString("db insert/gateway_route/current_pos/0")

def handler(session, args):
    pass

def fsapi(session, stream, env, args):
    count, fullgw, current_pos, new_pos, idx = 0, 0, 0, 0, 0
    upgw = []
    if args:
        string = re.split('\s+', args)
    else:
        freeswitch.consoleLog('info', 'must argv1 profile %s\n'  % args)
    argv1 = string[0]
    gwstatusstr = api.executeString("sofia status gateway")
    pattern = re.compile(argv1+"::(\d+)\s+")
    result1 = pattern.findall(gwstatusstr)
    for gw in range(len(result1)):
        if re.search(r"State\s+REGED\s+",api.executeString("sofia status gateway "+result1[gw])):
            upgw.append(result1[gw])
            count = count + 1
    db_exists()
    current_pos = db_select()
    if int(current_pos) >= count:
        current_pos = 0
    new_pos = int(current_pos) + 1
    idx = int(current_pos)
    db_insert(new_pos)
    info = api.executeString("show channels")
    while 0 < 1:
        if re.search("sofia/gateway/"+upgw[idx],info):
            idx = idx + 1
            if current_pos >= count:
                idx = 0
            if idx >= count:
                break
        else:
            stream.write(str(upgw[idx]))
            freeswitch.consoleLog("info", "Discovery of available gateway: %s\n" % upgw[idx])
            break
