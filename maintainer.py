#!/usr/bin/env python3

from sys import argv

if len(argv) != 2:
    print('Usage: {} <codename>'.format(argv[0]))
    exit(1)

maintainers = {
    'begonia': 'aashil123',
    'enchilada': 'deadmanxxd',
    'davinci': 'meetaditya',
    'garlic': 'whitebeard_official',
    'ginkgo': 'Introdructor',
    'guacamole': 'moditji',
    'kenzo': 'Azahar123',
    'potter': 'ZJRDroid',
    'raphael': 'ritzz97',
    'mido': 'Apon77',
    'X00P': 'Flamefusion',
    'santoni': 'jubayerhimel',
    'sanders': 'saisamy95',
    'violet': 'ShivamKumar2002',
    'jd2019': 'merser2005',
    's2': 'merser2005',
    'tissot': 'Takeshiro',
    'X00TD': 'pkm774',
    'whyred': 'NAHSEEZ',
    'miatoll': 'Teamsolo1',
    'vince': 'MahmoudK1000',
    'dipper': 'jullian14',
    'wayne': 'RonaldSt',
    'jasmine_sprout': 'RonaldSt',
    'lavender': 'Bagualisson',
    'oneplus3': 'ajithzres',
    'x2': 'RashedSahaji',
    'beryllium': 'Saikiran008 and @Reignz3',
    'phoenix': 'Hard_rock83',
    
}

device = argv[1]

maintainer = maintainers.get(device, 'CorvusJenkinsBot')
print(f'@{maintainer} {device}!')
