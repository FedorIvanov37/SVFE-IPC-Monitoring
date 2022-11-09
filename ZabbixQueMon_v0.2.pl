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

my $queue_id_command = q/ipcs -q | awk '{print $2" "$6}' | grep -vi message/;
my @body;
my %ques;

for(split "\n", `$queue_id_command`) {
    next if /^\D/;
    my ($qid, $messages) = split;
    chomp(my $process_pid = qx/ipcs -p | grep $qid | awk '{print \$NF}'/);
    next if not $process_pid;
    chomp(my $process_name = qx/ps -ef | grep $process_pid | grep -v grep | awk '{print \$NF}'/);
    $process_name =~ s/\s+//g;
    $process_name = 'PROCESS_DOWN' if not $process_name;
    $ques{$process_name} = 0 if not $ques{$process_name}; 
    $ques{$process_name} += $messages;
}

for my $process (keys %ques) {
    my $string = sprintf qq/\t{"process_name": "%s", "message": %d}/, $process, $ques{$process};
    push(@body, $string);
}

printf "[\n%s\n]\n", join(",\n", @body);
