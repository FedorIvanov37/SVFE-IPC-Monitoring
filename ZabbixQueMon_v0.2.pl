#!/usr/bin/perl
#
# Purpose: SVFE Queue monitoring for Zabbix
#
# Version: 0.2
# Author: Fedor Ivanov
# Nov 2022
#
# use perl || die;
#

use strict;
use warnings;
use 5.010;

use constant PROCESS_DOWN     => 'PROCESS_DOWN';
use constant OUTPUT_TEMPLATE  => '[\n%s\n]';
use constant STRING_TEMPLATE  => q/  {\n    "process_name": "%s",\n    "message": %d\n  }/;
use constant GET_QUEUES       => q/ipcs -q | awk '{print $2" "$6}' | grep -vi message/;
use constant GET_PROCESS_ID   => q/ipcs -p | grep %s | awk '{print \$NF}'/;
use constant GET_PROCESS_NAME => q/ps -ef | grep %s | grep -v grep | awk '{print \$NF}'/;

my @body = ();
my %queues = ();

sub execute_command {
    my ($command_template, $param) = @_;
    my $command = sprintf $command_template, $param;
    chomp(qx($command));
}

for(split "\n", qx(GET_QUEUES)) {
    next if /^\D/;
    my ($qid, $messages, $process_pid, $process_name) = '';
    ($qid, $messages) = split;
    $process_pid = execute_command(GET_PROCESS_ID, $qid));
    next if not $process_pid;
    $process_name = execute_command(GET_PROCESS_NAME, $process_pid));
    $process_name =~ s/\s+//g;
    $process_name = PROCESS_DOWN if not $process_name;
    $queues{$process_name} = 0 if not $queues{$process_name}; 
    $queues{$process_name} += $messages;
}

for my $process (keys %queues) {
    push(@body, sprintf STRING_TEMPLATE, $process, $queues{$process});
}

my $output = sprintf OUTPUT_TEMPLATE, join(",\n", @body);

say $output;
