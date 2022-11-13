## SVFE IPC Message Queues Monitoring

![image](https://thumbs.gfycat.com/CheerySeparateGoldeneye-size_restricted.gif)


###  Purpose 
Get current status of inter-process communication (IPC) message queues used by SVFE application's processes, such as nwint, epayint, tcpcomms, etc. The script will return amount of messages in a waiting status and receiver's process name for each IPC message queue. 

The script runs by Zabbix agent in an endless cycle for online tracking interaction between SVFE processes.

If you don't know what the IPC actually mean - go to [IPC related info](#ipc-related-information) first.

### Usage 

The script has no specific run parameters, it runs directly from bash

`$ perl svfe_ipc_monitoring.pl;`


The queue data will be printed once after the script launch, then the script will finish the work. It doesn't repeat the checking by itself, so, if you need multiple checking you have to run the script many times.


<details>
  <summary>Result example</summary>

  ```bash
  smartfe@svfe:/> perl svfe_ipc_monitoring.pl;
[

  {
    "process_name": "tcpcomms",
    "message": 0
  },
  {
    "process_name": "asmssrv",
    "message": 0
  },
  {
    "process_name": "timer00",
    "message": 0
  },
  {
    "process_name": "acq_fraudmon",
    "message": 0
  },
  {
    "process_name": "epayint",
    "message": 0
  },
  {
    "process_name": "hsm_mcp",
    "message": 0
  },
  {
    "process_name": "sms_sender",
    "message": 0
  },
  {
    "process_name": "nwint00",
    "message": 0
  },
  {
    "process_name": "saf_list_mgr",
    "message": 0
  },
  {
    "process_name": "atmswdist",
    "message": 0
  },
  {
    "process_name": "stdauth",
    "message": 2
  },
  {
    "process_name": "hostspec1int",
    "message": 0
  },
  {
    "process_name": "tcpgate_mcp",
    "message": 0
  },
  {
    "process_name": "voice_auth",
    "message": 0
  },
  {
    "process_name": "crout00",
    "message": 0
  },
  {
    "process_name": "txrout",
    "message": 0
  },
  {
    "process_name": "splitint",
    "message": 0
  },
  {
    "process_name": "auth_notif_sender",
    "message": 0
  },
  {
    "process_name": "hstint",
    "message": 0
  },
  {
    "process_name": "acqint",
    "message": 0
  },
  {
    "process_name": "mcp",
    "message": 0
  },
  {
    "process_name": "acqhost_int",
    "message": 0
  }
]

  ```
</details>

<details>
  <summary>Analysing the result</summary>

  Below you can find a hypothetical response to the monitoring script with the data analysis example

```
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
 ...
 ...
 // More dictionaries below
]
```
</details>

I/O interactions perform through the standard Linux stream. The output data will be sent to stdout.

> ℹ️ By the way 
>
> Direct run like `$ svfe_ipc_monitoring.pl;` requires permissions to execute the script file. 
> At the same time if you are running the script through Perl like `$ perl svfe_ipc_monitoring.pl;` read permission will be enough to run the script.
>
>```bash 
># This command will run only if you have execution permissions
>$ svfe_ipc_monitoring.pl;
>
>
># This command will run even if you have read-only permissions
>$ perl svfe_ipc_monitoring.pl;
>```

### Special conditions
 * When SVFE runs a few same processes in parallel - the messages count will be summarized using the process name
 * When the Receiver process is down the process name will be substituted by PROCESS_IS_DOWN constant
 * Technically script can return empty list - [ ]. In case when SVFE doesn't run properly or server has no active queues at the moment
 * The queue data will be printed once after the script launch, then the script will finish the work. It doesn't repeat the checking by itself, so, if you need multiple checking you have to run the script many times.
 
### System requirements
 * Perl 5; (!) Not compatible with Perl 6
 * Linux server with available shell commands: ipcs, awk, grep, ps
 * SVFE on the same server in a running state
 * Has been tested on Linux Centos only 

## IPC related information

### About IPC


IPC is inter-process communication. A kit of FIFO-channels for messaging between two application modules. Each queue has a sender and receiver processes. Sender and receiver is a kind of role of process during internal data exchange. 

SV-application is a group of independent modules, separated according to single-responsibility principle. The modules use message queues and shared memory segments for inter-process communication. Chain of internal modules connected to each other using the queues. A card transaction e.g. card purchase request is a message, which flows through the processes conveyor step-by-step, using queues as a transport.

![image](https://www.tutorialspoint.com/inter_process_communication/images/message_queue.jpg)


See more about IPC here: 

* [Wikipedia IPC article](https://en.wikipedia.org/wiki/Inter-process_communication)
* [Tutorials point IPC article](https://www.tutorialspoint.com/inter_process_communication/inter_process_communication_message_queues.htm)
* [Wikipedia Message Queue article] (https://en.m.wikipedia.org/wiki/Message_queue)


### Common reasons for problems with IPC

Cause of the queues accumulation can be many different problems. In general, messages accumulate in queues because the SVFE application process waits for some event or works too slowly and cannot get new messages to process. Mostly SV by itself is not the root cause of the problem.

Most common one of the following problems becomes the reason of the messages got stuck:

* High load of the system, out of memory or other system resources
* Long waiting of Database
* Network interruptions
* Internal problem with the application process

### System behaviour during problems with IPC 

* Many unexpected declines on production
* SV does not answer PSP in time. On the PSP side transactions are getting the decline "Communication problem"
* SV answer with decline code 68 Timeout (F39 in logs = 68)
* Abnormal network activity, SV don't answer long time, then put batch of responses in short period


## Reaction

>⚠️ Important note
>
>Once the queue begins to accumulate the pending messages at any time 24/7 it is most important to warn SV Technical Support Engineer about the problem. Analysis has to be done on the application level first.

### Reaction criteria

Table of the system malfunction levels when the IPC Queue has a pending messages

| Messages count |0-2 min  |2-5 min  | 5+ min  | Episodic |         
| -------------- |---------|---------|---------|----------|
|         0-10   | 🟢      | 🟢      | 🟡      | 🟡       |
|         10-50  | 🟡      | 🔴      | 🔴      | 🟡       |
|         50+    | 🔴      | 🔴      | 🔴      | 🔴       |


🟢 OK, most probably we have no problem.

🟡 WARNING, need to check the system, probably something goes wrong.

🔴 CRITICAL, need to react immediately. Most probably we currently have a system malfunction.

### Recovery plan

In case when you see the problem with stuck messages check the following:

* Transactions approval rate. First we need to determine is the problem still active or not.
* Often specifically high load of system resources is a reason for the IPC problems. Try to understand which part of system work slower then usual.
* System resource availability - RAM, CPU, etc
* Database availability and response time, running jobs, deadlocks
* Network connections and response time
* Few last system changes which would increase system response time


## About 

```perl
SVFE IPC Message Queues Monitoring v1.0

Written by Fedor Ivanov | Unlimint

Released in Nov 2022
```

> 👋 In case of any question fill free to [contact](mailto:f.ivanov@unlimint.com) author directly. 
>
> Your feedback and suggestions are general drivers of the monitoring system evolution.


