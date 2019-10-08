#!/usr/bin/python
##Polling file
import time
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

def check_gateway_limits(key, limits, upgw):
    count = 0
    today = time.strftime("%Y%m%d", time.localtime())
    if not api.executeString("db exists/call_limit_last_count_of_day/data_time"):
        api.executeString("db insert/call_limit_last_count_of_day/data_time/"+str(today))
    else:
        last_day = api.executeString("db select/call_limit_last_count_of_day/data_time")
    if not api.executeString("db select/call_limit_value_count_of_day/"+str(key)):
        api.executeString("db insert/call_limit_value_count_of_day/"+str(key)+"/0")
    else:
        count = api.executeString("db select/call_limit_value_count_of_day/"+str(key))
    if today != last_day:
        api.executeString("db delete/call_limit_value_count_of_day/data_time")
        for k in range(len(upgw)):
            api.executeString("db delete/call_limit_value_count_of_day/"+str(upgw[k]))
    if int(count) < int(limits):
        count = int(count) + 1
        api.executeString("db insert/call_limit_value_count_of_day/"+str(key)+"/"+str(count))
        api.executeString("db insert/call_limit_last_count_of_day/data_time/"+str(today))
        return True
    else:
        return False

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
        freeswitch.consoleLog('info', 'must argv1 profile %s\n' % args)
    argv1 = string[0]
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
    freeswitch.consoleLog('info', 'the idx is %s\n' % idx)
    freeswitch.consoleLog('info', 'the upgw is %s\n' % upgw[idx])
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
            if check_gateway_limits(upgw[idx],argv1,upgw):
                stream.write(str(upgw[idx]))
                freeswitch.consoleLog("info", "Discovery of available gateway: %s\n" % upgw[idx])
                break
            else:
                freeswitch.consoleLog("err", "unavailable gateway\n")
                break
