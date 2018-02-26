# xs_autostart
Bash script for autostarting Virtual Machines on XenServer

<h3>Motivation:</h3>
...well, I don't know about you. My experience (and from reading posts it is experience of many others too) is that XenServer doesn't make it easy for a small home users to automate (and control for that matter) start of their VMs. If you do not run HA cluster, just a single server, you are pretty much stuck (with some CLI workarounds possible - in fact I managed to have one of my VMs starting automatically upon boot). Now you can use vApp for that, although I don't see a reason to create vApp instead of having simple start-up order. Anyway, I created my own solution and though I'd share it with you.<br>
Also, my environment is a bit specific - I need one VM to start immediately after boot, which initializes ZFS residing on local disks and creates LUN storage. That LUN is used by XenServer itself (of course unavailable after boot), so I run another script to repair the storage after boot. Afterwards, I am ready to start my VMs one by one.

<h3>How it works:</h3>
<p>Very much as you would expect from XenCenter GUI way.</p>
<p>First, you must define 3 custom fields for a VM (once you define them for 1, they automatically appear for others as well):</p>
<ol>
  <li>bs_autostart -> text field, which holds either 1 or 0. 1 means autostart this VM; 0 (or anything else as 1) does not autostart it.</li>
  <li>bs_autostart_group -> text field, which holds numerical value into which autostart group the VM belongs. VMs are starting by groups in ascending order.</li>
  <li>bs_autostart_timeout -> text field, which holds numerical value indicating number of seconds to wait before starting another VM.</li>
</ol>
<p>There is <strong>1 important caviat:</strong></p>
Your machine name cannot contain two consecutive # characters (e.g. VM Name: My pretty Debian VM ##1). Script will not autostart such machines, as ## gets replaced with space.

<i><p>Example:</p>
  <p>Following will start VM2 first, wait 2 minutes and then start VM1. VM3 is not autostarted.</p>
  <ul>
    <li>VM1: bs_autostart=1 bs_autostart_group=20 bs_autostart_timeout=0</li>
    <li>VM2: bs_autostart=1 bs_autostart_group=10 bs_autostart_timeout=120</li>
    <li>VM3: bs_autostart=0 bs_autostart_group=10 bs_autostart_timeout=30</li>
  </ul>
</i>

<h3>Installation:</h3>
<p>In order to make it functional, you need to make these five easy steps:</p>
<ol>
  <li>Download and save the script somewhere in xenserver (I choose <code>/root/xs_autostart.sh</code>)</li>
  <li>Make it executable: <code>chmod +x /root/xs_autostart.sh</code></li>
  <li>Edit <code>/etc/rc.local</code> file and add this line to it:
    <pre>at now +1 min < /root/xs_autostart.sh</pre>
    (of course modify the +1 min to your liking; the above will start autostarting VMs 1 min after /etc/rc.local is ran)</li>
  <li>Make rc.local executable: <code>chmod +x /etc/rc.local</code></li>
  <li>Modify custom fields of your VMs according to the 'How it works' section.</li>
<ol>
<h4>Reboot and enjoy.</h4>
...
<h3>Additional info:</h3>
  <ul>
    <li>Machines with non-numeric or otherwise wrong data in custom fields are treated as follows:
      <ul>
        <li>bs_autostart -> machine is not autostarted</li>
        <li>bs_autostart_group -> machine is not started</li>
        <li>bs_autostart_timeout -> timeout is set to 0 (zero)</li>
      </ul></li>
    <li>Order of machines within a group is arbitrary. If you want a fine control, please use separate group for each VM (and I recommend leaving some gaps for future VMs in-between)</li>
    <li>There is a DRY RUN command line option for testing purposes, so you can see order in which VMs get started and what is the delay after. Just invoke the script with -d option (<code>xs_autostart.sh -d</code>)</li>
    <li>Script outputs some info into log file -> /var/log/xs_autostart.log
      <ul>
        <li>you may change the location and file name at the very beginning of the script</li>
        <li>log gets overwritten each time script is run</li>
      </ul>
    </li>
  </ul>
   
ENJOY IT!
