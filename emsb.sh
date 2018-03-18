#!/usr/bin/env bash

# Specify storage device and its mountpoint
STORAGE_DEV="sda1" # Name of the storage device
STORAGE_MOUNT_POINT="/media/storage" # Mount point of the storage device

# Specify minutes to wait before shutdown due to inactivity
SHUTD=5

# Set the ACT LED to heartbeat
sudo sh -c "echo heartbeat > /sys/class/leds/led0/trigger"
echo -n "Starting backup job ..."

# Shutdown after a specified period of time (in minutes) if no device is connected.
sudo shutdown -h $SHUTD "Shutdown is activated. To cancel: sudo shutdown -c"

echo "Looking for storage device ..."

# Wait for a USB storage device (e.g., a USB flash drive)
STORAGE=$(ls /dev/* | grep $STORAGE_DEV | cut -d"/" -f3)
while [ -z ${STORAGE} ]
  do
  sleep 1
  STORAGE=$(ls /dev/* | grep $STORAGE_DEV | cut -d"/" -f3)
done

# Cancel shutdown
sudo shutdown -c

# When the USB storage device is detected, mount it
sudo mount /dev/$STORAGE_DEV $STORAGE_MOUNT_POINT
echo "Storage device mounted."

# Set the ACT LED to blink at 1000ms to indicate that the storage device has been mounted
sudo sh -c "echo timer > /sys/class/leds/led0/trigger"
sudo sh -c "echo 1000 > /sys/class/leds/led0/delay_on"

CARD_INDEX=1
POSSIBLE_DEVS="bcdefghijklmnopqrstuvwxyz"

#look for a possible multiple amount of cards (if no new one is found, we break from this loop)
while true
  do  

  printf "\nLooking for card $CARD_INDEX ...\n"
  
  WAITED_SECONDS=0
  CARD_MOUNT_POINT="/media/cards/card$CARD_INDEX"
  DEV_INDEX=1
  CHAR="$(expr substr $POSSIBLE_DEVS $DEV_INDEX 1)"
  CARD_DEV="sd${CHAR}1"

  # Wait for a card reader or a camera
  CARD_READER=$(ls /dev/* | grep $CARD_DEV | cut -d"/" -f3)
  until [ ! -z $CARD_READER ]
    do
    #if we are not yet at the end of the possible dev string, go to the next one
    if [ "$DEV_INDEX" -le "${#POSSIBLE_DEVS}" ]; then
      let "DEV_INDEX++"
      
    #else, sleep for one second and try again from the start
    else
      DEV_INDEX=1
      sleep 1
      
      #if we've waited for over a specified amount of time, break from the loop and shutdown
      let "WAITED_SECONDS++"
      if [ "$WAITED_SECONDS" -ge 60 ]; then
        echo "No more cards found."
        break 2
      fi
    fi
    
    CHAR="$(expr substr $POSSIBLE_DEVS $DEV_INDEX 1)"
    CARD_DEV="sd${CHAR}1"
    CARD_READER=$(ls /dev/sd* | grep $CARD_DEV | cut -d"/" -f3)
  done

  #remove a couple of possible devices from the possible devs string (for the next card)
  POSSIBLE_DEVS="${POSSIBLE_DEVS:$DEV_INDEX}"

  # If the card reader is detected, mount it and obtain its UUID
  if [ ! -z $CARD_READER ]; then
    sudo mount /dev/$CARD_DEV $CARD_MOUNT_POINT
    
    # Set the ACT LED to blink at 500ms to indicate that the card has been mounted
    sudo sh -c "echo timer > /sys/class/leds/led0/trigger"
    sudo sh -c "echo 500 > /sys/class/leds/led0/delay_on"

    # Set the copy path
    ID="$(date -d "today" +"%Y-%m-%d")_CARD$CARD_INDEX"
    COPY_PATH=$STORAGE_MOUNT_POINT/"$ID"

    # Log the output of the lsblk command for troubleshooting
    cd
    sudo lsblk > lsblk.log
    
    # Perform backup using rsync
    echo "Backing up card $CARD_INDEX."
    sudo rsync -av --exclude "System Volume Information" $CARD_MOUNT_POINT/ $COPY_PATH
    echo "Backup of card $CARD_INDEX completed."

    # Geocorrelate photos if a .gpx file exists
    cd $STORAGE_MOUNT_POINT
    if [ -f *.gpx ]; then
      GPX="$(ls *.gpx)"
      exiftool -overwrite_original -r -ext jpg -geotag "$GPX" -geosync=120 .
    fi

    # Turn off the ACT LED to indicate that the backup is completed
    sudo sh -c "echo 100 > /sys/class/leds/led0/brightness"
  fi
  
  let "CARD_INDEX++"
done
# Eject all media devices
POSSIBLE_DEVS="abcdefghijklmnopqrstuvwxyz"
for i in {1..26}
do
  CHAR="$(expr substr $POSSIBLE_DEVS $i 1)"
  DEVICE="sd${CHAR}"
  
  #check if this device also has the trailing '1' and eject it
  if [ -f "/dev/${DEVICE}1" ]; then
    sudo eject "/dev/${DEVICE}1"
    echo "Ejected ${$DEVICE}1."
  fi
  
  MSG=$(sudo eject /dev/$DEVICE 2>&1)
  if [[ $MSG == *"unable to find or open device"* ]]; then
    echo "All media devices ejected."
    break
  else
    echo "Ejected $DEVICE."
  fi
done

sudo wall -n "Finished backup job. Shutting down now."


# Shutdown
sudo sync
echo "Powering off now."
sudo shutdown -h now