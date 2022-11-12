#!/usr/bin/perl
#
# Purpose: SVFE Queue monitoring for Zabbix
#
# Version: 0.3
# Author: Fedor Ivanov
# Nov 2022
#
# Requirements: 
# Perl 5.010 or above; 
# Linux server with avaivable shell commands: ipcs, awk, grep, ps; 
# Running SVFE on the server
# 
#
# use perl || die;
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

    # Command to get all current Linux Queues. Returns Queue ID and current count of messages inside the Queue, separated by space
    COMMAND_GET_QUE => q(ipcs -q | awk '{print $2" "$6}' | grep -vi message),

    # Command to get the Receiver PID of specific Queue
    COMMAND_GET_PID => q(ipcs -p | grep %s | awk '{print $NF}'),
    
    # Command to get the Process name of specific PID
    COMMAND_GET_TAG => q(ps -ef | grep -v grep | awk '{print $2" "$8}' | grep %s | awk '{print $NF}'),
};

sub main { 
    my %queues = get_queues_dict();
    my $output = get_output_data(%queues);
    
    say $output;
}

# Returns hash, containing current state of Queues using template {"process_name": <some_receiver_process>, "messages": <count_of_messages_in_queue>}
# When SVFE runs a few same processes in parallel - the messages count will be summarized using process name
# When the Receiver process is down the process name will be substituted by PROCESS_IS_DOWN constant
sub get_queues_dict {
    my %queues = ();
    my ($qid, $messages, $process_id, $process_name) = '';
    my @queues_set = split "\n", execute_command(COMMAND_GET_QUE);

    for(@queues_set) {
        next if /^\D/; # Proceed to the next integration if line doesn't starts from numbers (no queue id recognized)
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

# Calculates and returns formatted final output string
# No changes should be made with result of the function, the result fully ready to be printed
# When no running queues were found in the system the function will return empty result using TEMPLATE_OUTPUT
sub get_output_data { 
    my $output;
    my @body = ();
    my %queues = shift;

    for my $process (keys %queues) {
        my $output_string = sprintf TEMPLATE_STRING, $process, $queues{$process};
        push(@body, $output_string);
    }
    
    $output = join(',', @body);  # $output becomes a blank string if @body has no elements
    $output = sprintf TEMPLATE_OUTPUT, $output;
    
    return $output;
}

# Runs ssh commans using command template and param. Receives from zero up to one param for command template
# When the command has no any external params the param argument can be absent, the command will be run as is
# For the merge the Param into the Command template the sprintf function will be used 
sub execute_command {
    my ($command_template, $param) = @_;
    my $command = $param ? sprintf $command_template, $param : $command_template;
    
    chomp(my $result = qx($command)); # Execute the builded command 

    return $result;
}

main() # Entry point, the script begin here
