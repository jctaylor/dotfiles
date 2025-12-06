

## RAID

```bash
mdadm -D /dev/md127   # Assuming the Multi-device (RAID) is md127
```


## iostat

```bash
 iostat               # shows statistics for input and output of devices and partitions since boot
 iostat -m -y -d 2    # -m display in MB/s, -y omit first report since system boot, -d 2 display stats every 2 seconds
 iostat /dev/sdd1 /dev/sdd2 /dev/sdd3  # Show iostats from these 3 partitions
```
