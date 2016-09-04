#!/bin/bash

# CPF Wifi Setup via BLE
# Set BLE Advertising mode with correct advertising data for incoming app (i.e. Android & iOS) to setup Wifi
# Command-line Parameter:
#     ${1} - local name to be displayed for remote device (client role).
#
# 2016/07/07
# Mark Yang
# version: 0.07
#     - Change: min/max interval changed from 480ms (0x0300) to 1440ms (0x0900)
#                    Longer interval allows more CPF devices to be found and connected simultaneously.
#                    In real experiment, interval at 480ms allows 20~25 devices being connected.
#
# 2016/01/07
# Mark Yang
# version: 0.06
#     - Add: 32-bit service uuidas BT MAC address (use lower 4-byte of the address).
#              the MSB 4-bit of the 4-byte address is used as RF type (1 for BT).  In current version, RF type is always 1.
#              the reason to add this 32-bit BT MAC is because in iOS, BT MAC is always hidden from the iOS BT framework.
#              example: in myang's development system, BT Mac is C4:85:08:0F:EF:7D.
#                    the 4-bit uuid being advertised would be 18 0F EF 7D (1 indicating it's BT Mac)
#              

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

hcidev=hci0
adv_devname=$1     # 1st argument is the device name seen by remote scanner device


#hciconfig ${hcidev} down
#hciconfig ${hcidev} reset
hciconfig ${hcidev} up



hciconfig ${hcidev} name $adv_devname

#----- SET ADVERTISING DATA FLAG
#0x09: total data length
#0x02: 1st AD data length
#  0x01: ADType - flag
#  0x06: LE General Discoverable Mode, BR/EDR Not Supported
#0x05: 2nd AD data length
#  0x05: ADType - 32-bit uuid
#0x11: 3rd AD data length
#  0x11: ADType - 128-bit uuid

#----- snippet for advertising 32-bit uuid (BT MAC lower 4 bytes) & 128-bit uuid (Service UUID)
# 32-bit uuid: lower 4-bytes of BT Mac address
# Get BT MAC address and put them into hexdecimal array $hci_mac.  ${hci_mac[0]}, ${hci_mac[1]} .. ${hci_mac[5]}, 
hci_mac=($(hciconfig ${hcidev} | grep -o -E '([[:xdigit:]]{1,2}[:-]){5}[[:xdigit:]]{1,2}'))
#test bt mac
#hci_mac="11:22:33:44:55:66"
hci_mac=($(echo $hci_mac | sed 's/:/ /g'))

#Use 4-bit MSB as mac type.  1: BT, 2: Wifi, 3:LAN.
mac_type=1  #  only 1: BT is used for now.  All others are reserved for future 32-bit uuid use
hci_mac[2]=${hci_mac[2]:1:1}  #strip of 4-bit MSB
hci_mac_uuid32="${hci_mac[5]} ${hci_mac[4]} ${hci_mac[3]} ${mac_type}${hci_mac[2]}"

# 128-bit uuid: {37705f0a-c45c-4cbb-b1d3-100f96fb1301}

# payload definitions:               Data len    AD1        AD2- 32-bit uuid         AD3 - 128-bit uuid                                    trailing zeros
hcitool -i ${hcidev} cmd 0x08 0x0008 1b          02 01 06   05 05 ${hci_mac_uuid32}  11 06 01 13 fb 96 0f 10 d3 b1 bb 4c 5c 4c 0a 5f 70 37 00 00 00 00

#-----COMPOSE DEVICE LOCAL NAME FOR SCAN RESPOSE
# convert local name to scan response data
sr_data=$(echo -n $adv_devname | od -A n -t x1) # scan response hex - convert ascii to hex

i=${#adv_devname}
#echo "i: ${i}"

# adding trailing zeros
while [ "${i}" -ne "29" ] # 29 (dec) is the max payload size
do
  sr_data="$sr_data 00"
  i=$(($i+1))
done

#echo "sr_data: ${sr_data}"


#----- SET SCAN RESPONSE DATA
# Set scan response data: complete local name (CLN)
#   On Android devices, the CLN is displayed during scanning.
#
#   On iOS devices, the device name being displayed during scanning due to different state:
#     - CLN is displayed if there was no previous BT GATT connection.
#     - Device Name (retrieved by GATT UUID {0x2A00}) is displayed upon BT GATT connection.
#         The Device Name is then being used during future scanning until new name is read again via {0x2A00}.
adv_devname_len=${#adv_devname}
packet_data_len=$(printf '%x\n' $(($adv_devname_len+2)))
ad_len_devname=$(printf '%x\n' $(($adv_devname_len+1)))

hcitool -i ${hcidev} cmd 0x08 0x0009 ${packet_data_len} ${ad_len_devname} 09 ${sr_data}

#----- ADV SETTINGS
# 00 03 00 03     MIN/MAX INTERVAL (00 03 --> 0x0300 = 480ms.  00 09 --> 0x0900 = 1440ms)
hcitool -i ${hcidev} cmd 0x08 0x0006 00 09 00 09  00  00  00  00 00 00 00 00 00  07  00

#----- START ADVERTISING
hcitool -i ${hcidev} cmd 0x08 0x000a 01
#hciconfig ${hcidev} leadv 0

exit 0








