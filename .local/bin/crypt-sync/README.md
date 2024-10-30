Syncs encrypted config files from syncthing and config files on system

If there's difference in date between PasswordStore/ConfigFiles/filename
and its location in the filesystem, replace whichever is older.
Encrypt/decrypt as needed, then set same date on both files with
touch -r detected_updated_file replaced_file

