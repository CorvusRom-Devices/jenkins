#!/usr/bin/env python3

from sys import argv

if len(argv) != 2:
    print('Usage: {} <codename>'.format(argv[0]))
    exit(1)

maintainers = {
    'raphael': 'ritzz97',
}

device = argv[1]

maintainer = maintainers.get(device, 'CorvusJenkinsBot')
print(f'@{maintainer}  {device} !')