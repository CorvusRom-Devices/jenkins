#!/usr/bin/env python3

from sys import argv

if len(argv) != 2:
    print('Usage: {} <codename>'.format(argv[0]))
    exit(1)

maintainers = {
    'begonia': 'aashil123',
    'beryllium': 'Saikiran008 and @Reignz3',
    'davinci': 'meetaditya',
    'dipper': 'jullian14',
    'enchilada': 'deadmanxxd',
    'fajita': 'Chandu078',
    'garlic': 'whitebeard_official',
    'ginkgo': 'Introdructor',
    'guacamole': 'moditji',
    'jasmine_sprout': 'RonaldSt',
    'jd2019': 'merser2005',
    'kenzo': 'Azahar123',
    'lavender': 'Bagualisson',
    'miatoll': 'Teamsolo1',
    'mido': 'Apon77',
    'oneplus3': 'ajithzres',
    'phoenix': 'Hard_rock83',
    'potter': 'ZJRDroid',
    'raphael': 'ritzz97',
    's2': 'merser2005',
    'sanders': 'saisamy95',
    'santoni': 'jubayerhimel',
    'tissot': 'Takeshiro',
    'tulip': 'jefinhodatnt',
    'vince': 'mahmoudk1000',
    'violet': 'ShivamKumar2002',
    'wayne': 'RonaldSt',
    'whyred': 'NAHSEEZ',
    'X00P': 'Flamefusion',
    'X00T': 'pkm774',
    'x2': 'RashedSahaji',
}

device = argv[1]

maintainer = maintainers.get(device, 'CorvusJenkinsBot')
print(f'@{maintainer} {device}!')
