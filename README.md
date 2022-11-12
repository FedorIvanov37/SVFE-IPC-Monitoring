![image](https://upload.wikimedia.org/wikipedia/commons/0/02/Aperture_Laboratories_Logo.svg)

## :: SVFE Queues Monitoring for Zabbix :: 
Version v1.0

###  Usage annotation

Prints JSON-like list of dictionaries in Linux shell, informing about the current state of interprocess queues. In use by Zabbix monitoring system. The script runs by Zabbix agent in an endless cycle for online tracking interaction between SVFE processes
 
The queues data will be printed one time after each script launch, then the script will finish the work. It doesn't repeat the checking by itself, so, if you need multiple checking you have to run the script many times.

### The script running and I/O

The script has no run parameters, you can run it as is 
```bash
$ perl script.pl;
```

All I/O interactions make through a standard Linux I/O stream. The output data will always be sent to the first stream - the standard stdout stream.

Be aware: direct run like "./script.pl;" requires permissions to execute the script file. At the same time if you are running the script through Perl like "perl ./script.pl;" read permission will be enough to run the script.


```bash
$ ./script.pl;        # Will run only if you have execution permissions
```
```bash
$ perl ./script.pl;   # Will run even if you have read-only permissions
```

### Output example and explanation

```java
[                                    // The JSON-like list 
  {                                  // Of individual dictionaries for each process
    "process_name": "tcpcomms",      
    "message": 110                   // tcpcomms doesn't look good
  },
  {
    "process_name": "PROCESS_DOWN",  // Some processes are down and accumulating the Queues
    "message": 54
  },
  {
   "process_name": "timer00",        // In the same time the timer looks fine
   "message": 0
 },
 // More dictionaries
]
```

### Special conditions
 * When SVFE runs a few same processes in parallel - the messages count will be summarized using the process name
 * When the Receiver process is down the process name will be substituted by PROCESS_IS_DOWN constant
 * Technically script can return empty list - [ ]. In case when SVFE doesn't run properly or server has no active queues at the moment

### System requirements

* Perl 5; (!) Not compatible with Perl 6
* Linux server with available shell commands: ipcs, awk, grep, ps
* SVFE on the same server in a running state
* Has been tested on Linux Centos only 

### Author

Developed by Fedor Ivanov | Unlimint

Released in Nov 2022
