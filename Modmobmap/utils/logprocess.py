#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <sebastien.dudek(<@T>)penthertz.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return FlUxIuS ;)
# ----------------------------------------------------------------------------

from __future__ import print_function
from engines.android.generic.ADBshell import *
from engines.android.samsung.ServiceMode import *
from engines.host.diag.xgoldmod import *
from engines.sdr.srsran_pss import *
from engines.host.serial.AT import AT
from utils.colors import *
from core.mKB import *
import time
from threading import Thread
import argparse
import json


kb = mKB()


def statesmv(func, msg=None, wait=10, arg=None):
    if msg is not None:
        print (bcolors.OKBLUE+msg+bcolors.ENDC)
    if arg is not None:
        func(arg)
    else:
        func()
    time.sleep(wait)


def bringTestMode():
    sm = ADBshell()
    sm.androidsdkpath = mKB.config['androidsdk']
    statesmv(sm.pushsecretcode, arg='4636', wait=2)


def bringServiceMode():
    sm = ADBshell()
    sm.androidsdkpath = mKB.config['androidsdk']
    statesmv(sm.pushsecretcode, arg='0011', wait=2)


def startXgoldmodCollect():
    xg = xgoldmod()
    th = Thread(target=xg.parseFifo)
    th.daemon = True
    th.start()


def startSrsRANxPSSProcess(cmdprog):
    import subprocess
    state = True
    bands = mKB.config['bands'].split(",")
    while state:
        try:
            for band in bands:
                commandstring = [mKB.config['SRSRANTOOLS_PATH']+cmdprog, "-b", band]
                if mKB.config['device_args'] is not None:
                    commandstring.append("-a")
                    commandstring.append(mKB.config['device_args'])
		if mKB.config['device_name'] is not None:
                    commandstring.append("-d")
                    commandstring.append(mKB.config['device_name'])
		print ("Scanning band", band)
                p = subprocess.Popen(commandstring, stdout=subprocess.PIPE)
                p.wait()
        except (KeyboardInterrupt, SystemExit):
            state = False
            cells = kb.data['SM_cells']
            saveCells(cells)


def startSrsRANNPSSProcess():
    startSrsRANxPSSProcess("cell_search_nbiot_modmobmap")


def startSrsRANPSSProcess():
    startSrsRANxPSSProcess("cell_search_modmobmap")


def startSrsRANPSSCollect():
    srs = srsran_pss()
    th = Thread(target=srs.parseFifo)
    th.daemon = True
    th.start()


def startSrsRANPSS():
    th = Thread(target=startSrsRANPSSProcess)
    th.daemon = True
    th.start()
    startSrsRANNPSSCollect()
    state = True
    while state:
        try:
            pass
        except (KeyboardInterrupt, SystemExit):
            state = False
            cells = kb.data['SM_cells']
            saveCells(cells)


def startSrsRANPSS():
    th = Thread(target=startSrsRANPSSProcess)
    th.daemon = True
    th.start()
    startSrsRANPSSCollect()
    state = True
    while state:
        try:
            pass
        except (KeyboardInterrupt, SystemExit):
            state = False
            cells = kb.data['SM_cells']
            saveCells(cells)


def startSrsRANPSSCollect():
    srs = srsran_pss()
    th = Thread(target=srs.parseFifo)
    th.daemon = True
    th.start()


def startServiceModeCollect():
    sm = ServiceMode()
    sm.androidsdkpath = mKB.config['androidsdk']
    bringTestMode()
    bringServiceMode()
    th = Thread(target=sm.grablogcat)
    th.daemon = True
    th.start()


def printInfo(string):
    print (bcolors.OKBLUE+string+bcolors.ENDC)


def saveCells(obj):
    import time
    jscells = json.dumps(obj, indent=4, sort_keys=True)
    name = "cells/cells_%d.json" % float(time.time())
    f = open("%s" % name, 'w+')
    f.write(jscells)
    f.close()
    printInfo("[+] Cells save as %s" % name)


def processOperatorAT(operators):
    at_tty = kb.config['tty_file']
    at = AT(at_tty)
    state = True
    while state:
        try:
            for code in operators:
                statesmv(at.unregister,
                        "[+] Unregistered from current PLMN")
                statesmv(at.changePLMN,
                        "=> Changing MCC/MNC for: %s" % code, arg=code)
                statesmv(at.changeNetworkType,
                        "=> Changing network type for 3G only", arg=14)
                statesmv(at.changeNetworkType,
                        "=> Changing network type for 2G only", arg=13)
                statesmv(at.changeNetworkType,
                        "=> Switching back to auto-mode", arg=2)
        except (KeyboardInterrupt, SystemExit):
            state = False
            cells = kb.data['SM_cells']
            saveCells(cells)


def processOperatorADB(operators):
    sm = ADBshell()
    sm.androidsdkpath = mKB.config['androidsdk']
    state = True
    while state:
        try:
            for code in operators:
                statesmv(sm.deregister,
                        "[+] Unregistered from current PLMN")
                statesmv(sm.changePLMN,
                        "=> Changing MCC/MNC for: %s" % code, arg=code)
                statesmv(sm.changeNetworkType,
                        "=> Changing network type for 3G only", arg=14)
                statesmv(sm.changeNetworkType,
                        "=> Changing network type for 2G only", arg=13)
                statesmv(sm.changeNetworkType,
                        "=> Switching back to auto-mode", arg=2)
        except (KeyboardInterrupt, SystemExit):
            state = False
            kb = mKB()
            cells = kb.data['SM_cells']
            saveCells(cells)
    process = sm.grablogcat()


def scanGRGSM(band):
    from engines.sdr.grgsm_scanner import do_scan
    def trigfunc(found_list):
        for info in sorted(found_list):
            info.attr2dic() # trigger log 
    do_scan(2e6, band, 4, 0, 30.0, "", trigfunc, False)


def processGRGSM(bands):
    state = True
    cbands_list = ["GSM900",
                   "DCS1800",
                   "GSM850",
                   "PCS1900",
                   "GSM450",
                   "GSM480",
                   "GSM-R"]

    if bands is None:
        bands_list = cbands_list
    else:
        bands_list = bands.split(',')

    while state:
        try:
            for band in bands_list:
                statesmv(scanGRGSM,
                        "=> Switching to %s band" % band, arg=band)
        except (KeyboardInterrupt, SystemExit):
            state = False
            kb = mKB()
            cells = kb.data['SM_cells']
            saveCells(cells)


def processManualMCCMN(string):
    dic_ = {}
    splitted = string.replace(' ','').split(',')
    for code in splitted:
        dic_[code] = code
    return dic_


def load_operators():
    try:
        f = open('cache/operators.json', 'r')
        operators = json.loads(f.read())
        return operators
        if len(operators) > 0 or operators is not None:
            print (bcolors.WARNING+"Found %i operators in cache, do you want to reuse them?:\n\t%s"+bcolors.ENDC % (len(operators), str(operators)))
            answ = input('(Y)es or (N)o?')
            if answ.lower() is 'y':
                return operators
        f.close()
    except:
        return None


def saveMCCMNC(obj):
    jscache = json.dumps(obj, indent=4, sort_keys=True)
    f = open('cache/operators.json', 'w+')
    f.write(jscache)
    f.close()
