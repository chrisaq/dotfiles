# Xiaomi bluetooth weight

## Permissions

**setcap**

_Give permission to run blescan to a script/program_

* `setcap 'cap_net_raw,cap_net_admin+eip' /path/tp/script`
* `setcap 'cap_net_raw,cap_net_admin+eip' $(which hcitool)`


**dbus**

_Script to give the user iot permissions to blescan, normally root is needed._

```
cd /etc/dbus-1/system.d

if ! grep -q '<policy user="iot">' bluetooth.conf
then
    echo add user iot to bluetooth.conf
    mount -o remount,rw /
    cp /etc/passwd /etc/passwd.bak
    echo 'iot:x:1000:100::/home/iot:/bin/sh' >>/etc/passwd
    cp bluetooth.conf bluetooth.conf.bak
    sed -i 's|</busconfig>|  <policy user="iot"> \
    <allow own="org.bluez"/> \
    <allow send_destination="org.bluez"/> \
    <allow send_interface="org.bluez.GattCharacteristic1"/> \
    <allow send_interface="org.bluez.GattDescriptor1"/> \
    <allow send_interface="org.freedesktop.DBus.ObjectManager"/> \
    <allow send_interface="org.freedesktop.DBus.Properties"/> \
  </policy> \
</busconfig>|' bluetooth.conf
fi
echo bluetooth enabled for user iot
EOF
```

