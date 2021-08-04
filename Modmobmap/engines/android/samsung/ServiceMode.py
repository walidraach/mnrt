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
from core.mKB import *
from core.mLog import *
from utils.colors import *

class ServiceMode(ADBshell):
    '''
        Class abstracting abstracting action to get mobile cells information from ServiceMode
    '''
    @Cellslogger
    def parse4Gcell(self, string):
        '''
            Parse 4G cells information
            in(1): string returned by logcat
            out: dict infos
        '''
        plmn = None
        tac = None
        earfcn = None
        band = None
        bandwidth = None
        pci = None
        cell = {}
        for s in string.split(b'\r\n'):
            if b'LTE' in s:
                if b'Band' in s:
                    band = re.match(b'^.*Band?:?\s?(\d+)', s).group(1)
                elif b'BAND' in s and b'BW' in s:
                    band, bandwidth = re.match(b'^.*BAND:?\s?(\d+)\sBW:?\s?([\d+\w]+)?\s?\_$', s).groups()
            if b'MCC-MNC' in s:
                if b'TAC' in s:
                    plmn, tac  = re.match(b'^.*MCC-MNC?\s?:?\s?([\d\-]+)\,?\s?TAC:?\s?(\d+)?\s?\_$', s).groups()
                elif b'MeG':
                    plmn = re.match(b'^.*MCC-MNC?\s?:?\s?([\d\-\s]+)', s).group(1)
            if b'Earfcn_dl:' in s:
                earfcn, pci = re.match(b'^.*Earfcn_dl:?\s?(\d+),?\s?PCI:?\s?(\d+)?\s?\_', s).groups()
            if b'LTE DL BW' in s:
                bandwidth = re.match(b'^.*BW?\s?:?\s?([\d\w]+)', s).group(1)
            if tac is None and b'TAC' in s:
                tac = re.match(b'^.*TAC?\s?:?\s?([\d]+)', s).group(1)
        if None not in [plmn, tac, earfcn, band, bandwidth, pci]:
            tac = tac.decode('utf-8')
            plmn = plmn.decode('utf-8').replace(' ','')
            pci = pci.decode('utf-8')
            bandwidth = bandwidth.decode('utf-8')
            cid2 = "%s-%i" % (pci, int(earfcn))
            cell[cid2] = {  'PLMN' : plmn,
                                'band' : int(band),
                                'bandwidth' : bandwidth,
                                'eARFCN': int(earfcn),
                                'PCI' : pci,
                                'TAC' : tac,
                                'type' : '4G',
                        }
        return cell

    @Cellslogger
    def parse3Gcell_sgs3like(self, string):
        '''
            Parse 3G cells information
            in(1): string returned by logcat
            out: dict infos
        '''
        plmn = None
        cid = None
        tx = None
        rx = None
        band = None
        cell = {}
        for s in string.split(b'\r\n'):
            if b'Band' in s:
                band = re.match(b'^.*Band?:?\s?(\d+)', s).group(1)
            if b'Reg PLMN' in s:
                plmn = re.match(b'^.*Reg PLMN?\s?([\d\-]+)', s).group(1)
            if b'CELL_ID' in s:
                cid = re.match(b'^.*CELL_ID:?\s?(\S+)', s).group(1)
            if b'CH DL:' in s:
                tx = re.match(b'^.*CH DL:?\s?(\d+)', s).group(1)
            if b', UL:' in s:
                rx = re.match(b'^.*\,\sUL:?\s?(\d+)', s).group(1)
        if None not in [tx, rx, cid, plmn, band]:
            cid = cid.decode('utf-8').replace('_','')
            plmn = plmn.decode("utf-8").replace(' ', '')
            cid2 = "%s-%i" % (cid, int(rx))
            cell[cid2] = {   'PLMN' : plmn,
                            'TX' : int(tx),
                            'RX' : int(rx),
                            'band': int(band),
                            'type' : '3G',
                        }
        return cell

    @Cellslogger
    def parse3Gcell(self, string):
        '''
            Parse 3G cells information SGS3 like structs
            in(1): string returned by logcat
            out: dict infos
        '''
        plmn = None
        cid = None
        tx = None
        rx = None
        band = None
        cell = {}
        for s in string.split(b'\r\n'):
            if b'Band' in s:
                band = re.match(b'^.*Band?:?\s?(\d+)', s).group(1)
            if b'PLMN:' in s:
                plmn = re.match(b'^.*PLMN:?\s?([\d\-]+)?\s?\_$', s).group(1)
            elif b'MCC-MNC :' in s:
                try:
                  plmn = re.match(b'^.*MCC-MNC\s:?\s?([\d\-\s]+)?\s?\_$', s).group(1)
                except:
                  plmn = None
            if b'CID:' in s:
                cid = re.match(b'^.*CID:?\s?(\S+)?\s?_$', s).group(1)
            if b' TX:' in s:
                tx = re.match(b'^.*TX:?\s?(\d+)', s).group(1)
            if b' RX:' in s:
                rx = re.match(b'^.*RX:?\s?(\d+)', s).group(1)
        if None not in [tx, rx, cid, plmn, band]:
            cid = cid.decode('utf-8')
            plmn = plmn.decode("utf-8").replace(' ', '')
            cid2 = "%s-%i" % (cid, int(rx))
            cell[cid2] = {   'PLMN' : plmn,
                            'TX' : int(tx),
                            'RX' : int(rx),
                            'band': int(band),
                            'type' : '3G',
                        }
        return cell

    @Cellslogger
    def parse2Gcell(self, string):
        '''
            Parse 2G cells information SGS5 like structs
            in(1): string returned by logcat
            out: dict infos
        '''
        plmn = None
        cid = None
        arfcn = None
        cell = {}
        for s in string.split(b'\r\n'):
            if b'PLMN:' in s:
                plmn = re.match(b'^.*PLMN:?\s?([\d\-]+)?\s?\_$', s).group(1)
            elif b'MCC-MNC :' in s:
                plmn = re.match(b'^.*MCC-MNC\s:?\s?([\d\-\s]+)?\s?\_$', s).group(1)
            if b'CID:' in s:
                cid = re.match(b'^.*CID:?\s?(\S+)?\s?_$', s).group(1)
            if b' Tra:' in s:
                arfcn = re.match(b'^.*Tra:?\s?(\d+)', s).group(1)
        if None not in [arfcn, cid, plmn]:
            cid = cid.decode('utf-8')
            plmn = plmn.decode("utf-8").replace(' ', '')
            cid2 = "%s-%i" % (cid, int(arfcn))
            cell[cid2] = {   'PLMN' : plmn,
                            'arfcn' : int(arfcn),
                            'type' : '2G',
                            'cid' : cid,
                        }
        return cell


    def grablogcat(self):
        '''
            Grab ServiceMode information from logcat
            out: dict ParsedCell
        '''
        process = self.run_adbcmdshell('logcat -s ServiceModeApp_RIL:I,ServiceMode:I,ModemServiceMode:I')
        stdout_queue = Queue()
        stdout_reader = AsynchronousFileReader(process.stdout, stdout_queue)
        stdout_reader.daemon=True
        stdout_reader.start()
        stop = False
        capture = b''
        while not stdout_reader.eof() and stop is False:
            while not stdout_queue.empty() and stop is False:
                try:
                    line = stdout_queue.get()
                    if b'Update!' in line:
                        if b'LTE RRC:' in capture:
                            self.parse4Gcell(capture)
                        elif b'UMTS :' in capture:
                            self.parse3Gcell_sgs3like(capture)
                        if b'GSM' in capture:
                            self.parse2Gcell(capture)
                        else:
                            self.parse3Gcell(capture)
                        capture = b''
                    capture += line
                except (KeyboardInterrupt, SystemExit):
                    stop = True
                    stdout_reader.stop()
        stdout_reader.stop()
        process.stdout.close()

    def output2xml():
        from xml.dom.minidom import Document
        kb = mKB()
        root = doc.createElement('moncells')
        for k,v in kb.data['SM_cells'].items():
            cell = doc.createElement('cell')
            root.appendChild(cell)
