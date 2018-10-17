#!/usr/bin/env python3

import re
import subprocess
import sys
import urllib.request
from bs4 import BeautifulSoup
from distutils.version import LooseVersion

DOWNLOAD_SITE = "http://cmake.org/files/LatestRelease"

# Fetch the list of latest CMake releases available on the server.
latest_release_page = urllib.request.urlopen(DOWNLOAD_SITE)
html_parse = BeautifulSoup(latest_release_page, 'lxml')

# Get the list of available releases for the current machine.
# For Linux machines this is usually "linux2", and we need to strip that.
platform = 'linux' if sys.platform.startswith('linux') else sys.platform
bit_width = subprocess.check_output(['uname', '-m']).strip().decode('utf-8')
match_regex = re.compile('cmake-.*-%s-%s.tar.gz' % (platform, bit_width),
                         flags=re.IGNORECASE)

links = html_parse.body.findAll('a', attrs={'href': True},
                                string=match_regex)

versions = [LooseVersion(tag.string) for tag in links]
versions.sort()

print(DOWNLOAD_SITE + '/' + str(versions[-1]))
