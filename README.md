# BLEAdv - Bluetooth LE Advertisement
This Linux bash shell script is used in Acer CloudProfessor (CPF) for BLE Advertisement.  It makes CPF as a BLE peripheral role and broadcasts the BT MAC address.  WhenCPF is powered on, the device acts like a BLE beacon waiting for BLE capable devices, such as smartphone or tablet, to discover and connect via GATT.

<b>Usage:</b><br/>
cpf-wifisetup-leadv.sh DeviceName

<b>Example:</b><br/>
To broadcast the text "Super Awesome!", use the following commandline.
sudo cpf-wifisetup-leadv.sh "Super Awesome!"

<b>Beacon data:</b><br/>
32-bit UUID: Lower 24-bits of the BT MAC Address obtained by hciconfig<br/>
128-bit UUID: {37705f0a-c45c-4cbb-b1d3-100f96fb1301}<br/>
Scan Response Data(SRD): DeviceName as Complete Local Name(CLN) <br/>

The MSB 4-bit of BT MAC address is being stripped and replaced by radio type.  Currently, only Bluetooth type is being used.<br/>
0x1:BT<br/>
0x2:Wifi<br/>
0x3:LAN<br/>
For an example, if BT MAC address is AB:CD:EF:12:34:56, it is being broadcasted as 1F:12:34:56.<br/>

The reason to have DeviceName as part of SRD is due to iOS devices reads device name from Beacon payload, but only reads DeviceName from SRD CLN after GATT connect.  It somehow seems like the device name is being cached if SRD CLN data is not present.

Broadcasting interval is set to 1440ms to allow more concurrent devices being discovered and connected simultaneously.  Change it to shorter (i.e. 480ms as in the script) for faster discover, or longer for number of devices.

#Prerequisites
Linux kernel v4.2 and above <br/>
BlueZ 5.35 and above


