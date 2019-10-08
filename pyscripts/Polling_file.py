#!/usr/bin/python
##Polling file 
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
    upgw_list = file_list(file_path)
    for gw in range(len(upgw_list)):
        if re.search(r"State\s+REGED\s+",api.executeString("sofia status gateway "+upgw_list[gw])):
            upgw.append(upgw_list[gw])
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
            if int(current_pos) >= count:
                idx = 0
            if idx >= count:
                break
        else:
            stream.write(str(upgw[idx]))
            freeswitch.consoleLog("info", "Discovery of available gateway: %s\n" % upgw[idx])
            break
