#!/usr/bin/perl
#
# Purpose: SVFE Queue monitoring for Zabbix
#
# Version: 0.3
# Author: Fedor Ivanov
# Nov 2022
#
# use perl || die;
#

use strict;
use warnings;
use 5.010;

# Plain constant PROCESS_DOWN
use constant PROCESS_IS_DOWN => q(PROCESS_DOWN);

# Command to get all current Linux Queues. Returns Queue ID and current count of messages inside the Queue, separated by space
use constant COMMAND_GET_QUE => q(ipcs -q | awk '{print $2" "$6}' | grep -vi message);

# Command to get the Receiver PID of specific Queue
use constant COMMAND_GET_PID => q(ipcs -p | grep %s | awk '{print $NF}');

# Command to get the Process name of specific PID
use constant COMMAND_GET_TAG => q(ps -ef | grep -v grep | awk '{print $2" "$8}' | grep %s | awk '{print $NF}');

# Template for each string in the Result
use constant TEMPLATE_STRING => qq(\n  {\n    "process_name": "%s",\n    "message": %d\n  });

# Final Output template. Output has to be returned as a JSON-like list of dictionaries
use constant TEMPLATE_OUTPUT => qq([\n%s\n]);

# Entry point, the script stars here. 
use constant RESULT_TO_PRINT => get_output();

# We are using constant to guarantee no changes will be made after we'll get the output
say RESULT_TO_PRINT;


# Calculates and returns formatted final output string
# No changes should be made with result of the function, the result fully ready to be printed
# When no running queues were found in system the function returns empty string
sub get_output { 
    my @body = ();
    my %queues = get_queues();

    for my $process (keys %queues) {
        push(@body, sprintf TEMPLATE_STRING, $process, $queues{$process});
    }

    my $output = @body ? sprintf TEMPLATE_OUTPUT, join(',', @body) : '';

    return $output;
}


# Returns hash, containing current state of Queues using template {"process_name": <some_receiver_process>, "messages": <count_of_messages_in_queue>}
# When SVFE runs a few same processes in parallel - the messages count will be summarized using process name
# When the Receiver process is down the process name will be substituted by PROCESS_IS_DOWN constant
sub get_queues {
    my %queues = ();
    my ($qid, $messages, $process_id, $process_name) = '';
    my @queues_set = split "\n", execute_command(COMMAND_GET_QUE);

    for(@queues_set) {
        next if /^\D/; # Proceed to the next integration if line doesn't stars from numbers (no queue id recognized)
        ($qid, $messages) = split;
        $process_id = execute_command(COMMAND_GET_PID, $qid);
        next if not $process_id; # Proceed to the next integration if the Process ID wasn't found using ps command
        $process_name = execute_command(COMMAND_GET_TAG, $process_id);
        $process_name =~  s/\s+//g;
        $process_name = PROCESS_IS_DOWN if not $process_name;
        $queues{$process_name} = 0 if not $queues{$process_name};
        $queues{$process_name} += $messages;
    }

    return %queues;
}


# Runs ssh commans using command template and param
# When the command has no any params the param argument can be absent
# The sprintf function will be used for merge param into the command template
sub execute_command {
    my ($command_template, $param) = @_;
    my $command = sprintf $command_template, $param; # Merge the param to the command template

    chomp(my $result  = qx($command)); # Execute the command

    return $result;
}
