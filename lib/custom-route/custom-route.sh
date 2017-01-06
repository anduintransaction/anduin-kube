#!/bin/sh

echo "Setting custom route"
route del -net 0.0.0.0 gw 10.0.2.2
