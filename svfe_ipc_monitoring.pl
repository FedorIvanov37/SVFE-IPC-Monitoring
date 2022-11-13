#!/usr/bin/perl
#
# :: SVFE IPC MONITORING ::
#
# Purpose: Get current status of IPC message queues used by 
#          SVFE application's processes, such as nwint, epayint, tcpcomms, etc. 
#
#          This script will return amount of messages in a waiting status and 
#          receiver's process name for each IPC message queue. 
#
# Version: v1.0
# Develop: Fedor Ivanov | Unlimint
# Release: Nov 2022
# 
# See more in README.md file
#

use strict;
use warnings;
use 5.010;

use constant {
    # Plain constant PROCESS_DOWN
    PROCESS_IS_DOWN => q(PROCESS_DOWN),
    
    # Final Output template. Output has to be returned as a JSON-like list of dictionaries
    TEMPLATE_OUTPUT => qq([\n%s\n]),

    # Template for each string in the Result
    TEMPLATE_STRING => qq(\n  {\n    "process_name": "%s",\n    "message": %d\n  }),

    # Command to get all current Linux Queues. Returns space-separated representation "<que_id> <messages_count>\n<another_que_id> <messages_count>" etc
    COMMAND_GET_QUE => q(ipcs -q | awk '{print $2" "$6}' | grep -vi message),

    # Command to get the Receiver PID of a specific Queue. If the process was found returns exactly one number - Linux Process ID
    COMMAND_GET_PID => q(ipcs -p | grep %s | awk '{print $NF}'),
    
    # Command to get the Process name of specific PID. Returns string with process name like tcpcomms, epayint etc
    COMMAND_GET_TAG => q(ps -ef | grep -v grep | awk '{print $2" "$8}' | grep %s | awk '{print $NF}'),
};

sub main { 
    
    #
    # *** I/O *** 
    # Input: No
    # Output: No
    #
    # *** Purpose *** 
    # General high-level function for running the main scenario 
    # The function has no input and output and doesn't perform any data processing by itself, manages other functions instead 
    #
    
    my %queues = get_queues_dict();
    my $output = get_output_data(%queues);
    
    say $output;
    
    # The script's work finished here. Next action is unconditional exit
}

sub get_queues_dict {

    #
    # *** I/O *** 
    # Input: No
    # Output: %hash {"process_name": <some_receiver_process>, "messages": <count_of_messages_in_queue>, ...}
    #
    # *** Purpose *** 
    # Returns hash, containing current state of Queues using template {"process_name": <some_receiver_process>, "messages": <count_of_messages_in_queue>}
    # When SVFE runs a few same processes in parallel - the messages count will be summarized using the process name
    # When the Receiver process is down the process name will be substituted by PROCESS_IS_DOWN constant
    #
    
    my %queues = ();
    my ($qid, $messages, $process_id, $process_name) = '';
    my @queues_set = split "\n", execute_command(COMMAND_GET_QUE);

    for(@queues_set) {
        next if /^\D/; # Proceed to the next iteration if the line doesn't start from numbers (no queue id recognized)
        ($qid, $messages) = split;
        $process_id = execute_command(COMMAND_GET_PID, $qid);
        next if not $process_id; # Proceed to the next iteration if the Process ID wasn't found using the Linux "ps" command
        $process_name = execute_command(COMMAND_GET_TAG, $process_id);
        $process_name =~  s/\s+//g;
        $process_name = PROCESS_IS_DOWN if not $process_name;
        $queues{$process_name} = 0 if not $queues{$process_name};
        $queues{$process_name} += $messages;
    }

    return %queues;
}

sub get_output_data { 

    #
    # *** I/O *** 
    # Input: %hash {"process_name": <some_receiver_process>, "messages": <count_of_messages_in_queue>, ...}
    # Output: $string, ready to print without any changes
    #
    # *** Purpose ***
    # Calculates and returns formatted final output string
    # No changes should be made to the result of the function, the result fully ready to be printed
    # When no running queues were found in the system the function will return an empty result using TEMPLATE_OUTPUT
    #
    
    my $output;
    my @body = ();
    my %queues = @_;

    while (my ($process_name, $messages_count) = each %queues) {  # Split the incoming %hash to key => value pairs
        my $output_string = sprintf TEMPLATE_STRING, $process_name, $messages_count;
        push(@body, $output_string);
    }
    
    $output = join(',', @body);  # $output becomes a blank string if @body has no elements
    $output = sprintf TEMPLATE_OUTPUT, $output;  # When @body has no elements empty JSON-like [list] will be returned
    
    return $output;
}

sub execute_command {

    #
    # *** I/O *** 
    # Input: @list of $strings, the first element is the command template, the others - are command params to be merged with the template
    # Output: $string, the command execution result
    #
    # *** Purpose ***
    # Runs ssh commands using incoming command template and params
    # When the command has no external params the Params can be absent, the command will be run as is
    # For the merge of the Params with the Command template the sprintf function will be used 
    #
    
    my ($command_template, @params) = @_;
    my $command = @params ? sprintf $command_template, @params : $command_template;
    
    chomp(my $result = qx($command)); # Execute the assembled command

    return $result;
}

main(); # Entry point, the script work begin here
