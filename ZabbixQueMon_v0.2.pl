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

my @body = ();
my %queues = ();
my $queue_id_command = q/ipcs -q | awk '{print $2" "$6}' | grep -vi message/;

for(split "\n", `$queue_id_command`) {
    next if /^\D/;
    my ($qid, $messages, $process_pid, $process_name) = '';
    ($qid, $messages) = split;
    chomp($process_pid = qx/ipcs -p | grep $qid | awk '{print \$NF}'/);
    next if not $process_pid;
    chomp($process_name = qx/ps -ef | grep $process_pid | grep -v grep | awk '{print \$NF}'/);
    $process_name =~ s/\s+//g;
    $process_name = 'PROCESS_DOWN' if not $process_name;
    $queues{$process_name} = 0 if not $queues{$process_name}; 
    $queues{$process_name} += $messages;
}

for my $process (keys %queues) {
    my $string = sprintf qq/  {\n    "process_name": "%s",\n    "message": %d\n  }/, $process, $queues{$process};
    push(@body, $string);
}

my $output = sprintf "[\n%s\n]", join(",\n", @body);

say $output;
