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

# Command to get all current Linux Queues. Returns Queue ID and count of current messages inside the Queue, separated by space
use constant COMMAND_GET_QUE => q(ipcs -q | awk '{print $2" "$6}' | grep -vi message);

# Command to get the Receiver PID of specific Queue
use constant COMMAND_GET_PID => q(ipcs -p | grep %s | awk '{print $NF}');

# Command to get the Process name of specific PID
use constant COMMAND_GET_TAG => q(ps -ef | grep -v grep | awk '{print $2" "$8}' | grep %s | awk '{print $NF}');

# Template for each string in the Result
use constant TEMPLATE_STRING => qq(\n  {\n    "process_name": "%s",\n    "message": %d\n  });

# Final Output template. Output has to be returned as a JSON-like list of dictionaries
use constant TEMPLATE_OUTPUT => qq([\n%s\n]);


say get_output(); # Entry point


sub get_output {  # Calculates and returns formatted final output string
    my $output = '';
    my @body = ();
    my %queues = get_queues();

    for my $process (keys %queues) {
        push(@body, sprintf TEMPLATE_STRING, $process, $queues{$process});
    }

    $output = sprintf TEMPLATE_OUTPUT, join(",", @body);

    return $output;
}


# Returns hash, containing current state of Queues using template {"process_name": <some_receiver_process>, "messages": <count_of_messages_in_queue>}
# When SVFE runs a few same processes in parallel - the messages count will be summarized using process name
sub get_queues {
    my %queues = ();
    my ($qid, $messages, $process_id, $process_name) = '';
    my @queues_set = split "\n", execute_command(COMMAND_GET_QUE);

    for(@queues_set) {
        next if /^\D/;
        ($qid, $messages) = split;
        $process_id = execute_command(COMMAND_GET_PID, $qid);
        next if not $process_id;
        $process_name = execute_command(COMMAND_GET_TAG, $process_id);
        $process_name =~  s/\s+//g;
        $process_name = PROCESS_IS_DOWN if not $process_name;
        $queues{$process_name} = 0 if not $queues{$process_name};
        $queues{$process_name} += $messages;
    }

    return %queues;
}


# Runs ssh co
sub execute_command {
    my ($command_template, $param) = @_;
    my $command = sprintf $command_template, $param;

    chomp(my $result  = qx($command));

    return $result;
}
