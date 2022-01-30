# setup

```
cd $HOME/bin/mkdocs-venv
python -m venv .
source bin/activate
pip install -r requirements.txt

# Enable repos
sysu enable mkdocs-build@home-chrisq-Sync-Wiki-Tech.service --now
sysu enable mkdocs-serve-tech.service --now
```

