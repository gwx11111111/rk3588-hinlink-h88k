#!/bin/bash -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# voltage_scale
# 1.7578125 8bit
# 0.439453125 12bit
get_index(){
    ADC_RAW=$1
    INDEX=0xff

    if [ `echo "$ADC_voltage_scale > 1 "|bc` -eq 1 ] ; then
        declare -a ADC_INDEX=(229 344 460 595 732 858 975 1024)
    else
        declare -a ADC_INDEX=(916 1376 1840 2380 2928 3432 3900 4096)
    fi

    for i in 00 01 02 03 04 05 06 07; do
        if [ $ADC_RAW -lt ${ADC_INDEX[$i]} ]; then
            INDEX=$i
            break
        fi	
    done 
}

board_id() {
    ADC_voltage_scale=$(cat /sys/bus/iio/devices/iio\:device0/in_voltage_scale)
    echo "ADC_voltage_scale:"$ADC_voltage_scale
    ADC_CH2_RAW=$(cat /sys/bus/iio/devices/iio\:device0/in_voltage2_raw)
    echo "ADC_CH2_RAW:"$ADC_CH2_RAW
    ADC_CH3_RAW=$(cat /sys/bus/iio/devices/iio\:device0/in_voltage3_raw)
    echo "ADC_CH3_RAW:"$ADC_CH3_RAW

    get_index $ADC_CH2_RAW
    ADC_CH2_INDEX=$INDEX

    get_index $ADC_CH3_RAW
    ADC_CH3_INDEX=$INDEX

    BOARD_ID=$ADC_CH2_INDEX$ADC_CH3_INDEX
    echo "BOARD_ID:"$BOARD_ID

}

board_id
board_info ${BOARD_ID}

# first boot configure

until [ -e "/dev/disk/by-partlabel/boot" ]
do
    echo "wait /dev/disk/by-partlabel/boot"
    sleep 0.1
done

if [ ! -e "/boot/boot_init" ] ;
then

    if [ ! -e "/dev/disk/by-partlabel/userdata" ] ;
    then

        if [ ! -e "/boot/rk-kernel.dtb" ] ; then
            mount /dev/disk/by-partlabel/boot /boot
            echo "PARTLABEL=boot  /boot  auto  defaults  0 2" >> /etc/fstab
        fi	

        service lightdm stop || echo "skip error"

        apt install -fy --allow-downgrades /boot/kerneldeb/*
        # rm -f /boot/kerneldeb/*
        ln -sf dtb/$BOARD_DTB /boot/rk-kernel.dtb
    
        touch /boot/boot_init
        cp -f /boot/logo_kernel.bmp /boot/logo.bmp
        reboot
    else
        echo "PARTLABEL=oem  /oem  ext2  defaults  0 2" >> /etc/fstab
        echo "PARTLABEL=userdata  /userdata  ext2  defaults  0 2" >> /etc/fstab
        touch /boot/boot_init
    fi
fi

