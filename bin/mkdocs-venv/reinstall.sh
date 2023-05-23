!/bin/bash
cd $HOME/bin/mkdocs-venv
rm -rf bin include lib lib64
python -m venv .
source bin/activate
pip install -r requirements.txt

