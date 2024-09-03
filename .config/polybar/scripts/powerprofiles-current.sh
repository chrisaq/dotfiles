#!/bin/env bash

# Get the current power profile
powerprofilesctl list | grep '*' | awk '{print $2}' | sed -e 's/\://'
