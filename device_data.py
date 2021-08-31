#! /usr/bin/env python
import os,sys
import json
import requests

def get_device_details(device):
    url = 'https://raw.githubusercontent.com/CorvusRom-Devices/jenkins/main/devices.json'
    req = requests.get(url)
    data = json.loads(req.text)
    for k in data:
        for key in data[k]:
                if key == device:
                        details = data[k][device]
                        return details
    return None

device = sys.argv[1]
fetch = sys.argv[2]
data = get_device_details(device)
whatever=data[fetch]
print(whatever)
