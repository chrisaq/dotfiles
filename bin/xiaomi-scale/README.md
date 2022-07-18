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

The above requires that a `bluetooth.conf` exists for dbus.

Example:

```

<!-- This configuration file specifies the required security policies
     for Bluetooth core daemon to work. -->
<!-- Debian-compatible additions to https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/src/bluetooth.conf?h=5.49 -->

<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

  <!-- ../system.conf have denied everything, so we just punch some holes -->

  <policy user="root">
    <allow own="org.bluez"/>
    <allow send_destination="org.bluez"/>
    <allow send_interface="org.bluez.Agent1"/>
    <allow send_interface="org.bluez.MediaEndpoint1"/>
    <allow send_interface="org.bluez.MediaPlayer1"/>
    <allow send_interface="org.bluez.Profile1"/>
    <allow send_interface="org.bluez.GattCharacteristic1"/>
    <allow send_interface="org.bluez.GattDescriptor1"/>
    <allow send_interface="org.bluez.LEAdvertisement1"/>
    <allow send_interface="org.freedesktop.DBus.ObjectManager"/>
    <allow send_interface="org.freedesktop.DBus.Properties"/>
  </policy>

  <policy at_console="true">
    <allow send_destination="org.bluez"/>
  </policy>

  <!-- allow users of bluetooth group to communicate with hcid -->
  <policy group="bluetooth">
    <allow send_destination="org.bluez"/>
  </policy>

  <!-- allow users of lp group (printing subsystem) to 
       communicate with bluetoothd -->
  <policy group="lp">
    <allow send_destination="org.bluez"/>
  </policy>

  <policy context="default">
    <deny send_destination="org.bluez"/>
  </policy>

</busconfig>
```

