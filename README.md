# easy-multiple-sd-backup
A Raspberry Pi solution to backup multiple SD cards on a storage device

## Installation

First of all, make sure that your Raspberry Pi is connected to the internet.

Run the following command on the Raspberry Pi:

    curl -sSL https://goo.gl/ZVBhbA | bash

When prompted, reboot the Raspberry Pi.

## Usage

1. Boot the Raspberry Pi
2. Plug in the backup storage device (or camera, if you configured Little Backup Box as described above)
3. Plug in as many SD card readers as you want and wait until the Pi shuts down

To geocorrelate the backed up photos, place a GPX file in the root of the storage device before plugging it into the Raspberry Pi.
