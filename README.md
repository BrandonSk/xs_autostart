# xs_autostart
Bash script for autostarting Virtual Machines on XenServer

### Motivation:
...well, I don't know about you. My experience (and from reading posts it is experience of many others too) is that XenServer doesn't make it easy for a small home users to automate (and control for that matter) start of their VMs. If you do not run HA cluster, just a single server, you are pretty much stuck (with some CLI workarounds possible - in fact I managed to have one of my VMs starting automatically upon boot). Now you can use vApp for that, although I don't see a reason to create vApp instead of having simple start-up order. Anyway, I created my own solution and though I'd share it with you.

Also, my environment is a bit specific - I need one VM to start immediately after boot, which initializes ZFS residing on local disks and creates LUN storage. That LUN is used by XenServer itself (of course unavailable after boot), so I run another script to repair the storage after boot. Afterwards, I am ready to start my VMs one by one.

### How it works:
Very much as you would expect from XenCenter GUI way.

First, you must define 3 custom fields for a VM (once you define them for 1, they automatically appear for others as well):
1. bs_autostart -> text field, which holds either 1 or 0. 1 means autostart this VM; 0 (or anything else as 1) does not autostart it.
2. bs_autostart_group -> text field, which holds numerical value into which autostart group the VM belongs. VMs are starting by groups in ascending order.
3. bs_autostart_timeout -> text field, which holds numerical value indicating number of seconds to wait before starting another VM.

There is **1 important caviat:**

Your machine name cannot contain two consecutive # characters (e.g. VM Name: My pretty Debian VM ##1). Script will not autostart such machines, as ## gets replaced with space.

_Example:
Following will start VM2 first, wait 2 minutes and then start VM1. VM3 is not autostarted._
- VM1: `bs_autostart=1 bs_autostart_group=20 bs_autostart_timeout=0`
- VM2: `bs_autostart=1 bs_autostart_group=10 bs_autostart_timeout=120`
- VM3: `bs_autostart=0 bs_autostart_group=10 bs_autostart_timeout=30`

### Installation:
In order to make it functional, you need to make these five easy steps:
1. Download and save the script somewhere in xenserver (I choose `/root/xs_autostart.sh`)
2. Make it executable: `chmod +x /root/xs_autostart.sh`
3. Edit `/etc/rc.local` file and add this line to it:
    ```at now +1 min < /root/xs_autostart.sh```
    (of course modify the +1 min to your liking; the above will start autostarting VMs 1 min after /etc/rc.local is ran)
4. Make rc.local executable: `chmod +x /etc/rc.local`
5. Modify custom fields of your VMs according to the 'How it works' section.

#### Reboot and enjoy.
...
### Additional info:
- Machines with non-numeric or otherwise wrong data in custom fields are treated as follows:
  - bs_autostart -> machine is not autostarted
  - bs_autostart_group -> machine is not started
  - bs_autostart_timeout -> timeout is set to 0 (zero)
- Order of machines within a group is arbitrary. If you want a fine control, please use separate group for each VM (and I recommend leaving some gaps for future VMs in-between)
- There is a DRY RUN command line option for testing purposes, so you can see order in which VMs get started and what is the delay after. Just invoke the script with -d option (`xs_autostart.sh -d`)
- Script outputs some info into log file -> `/var/log/xs_autostart.log`
  - you may change the location and file name at the very beginning of the script
  - log gets overwritten each time script is run

ENJOY IT!
