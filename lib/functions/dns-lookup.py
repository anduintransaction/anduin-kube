#!/usr/bin/env python

import sys
import socket

if len(sys.argv) < 2:
    sys.exit(1)
try:
    print socket.gethostbyname(sys.argv[1])
except:
    sys.exit(1)
