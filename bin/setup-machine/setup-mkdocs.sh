#!/bin/bash

cd $HOME/bin/mkdocs-venv
python -m venv .
source bin/activate
pip install -r requirements.txt
