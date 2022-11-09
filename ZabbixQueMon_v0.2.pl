#!/usr/bin/perl -w
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
use 5.010;

my $queue_id_command = q/ipcs -q | awk '{print $2" "$6}' | grep -vi message/;
my $body = "";
my %ques = ();

for(split "\n", `$queue_id_command`) {
    next if /^\D/;
    my ($qid, $messages) = split;
    chomp(my $process_pid = qx/ipcs -p | grep $qid | awk '{print \$NF}'/);
    next if not $process_pid;
    chomp(my $process_name = qx/ps -ef | grep $process_pid| grep -v grep | awk '{print \$NF}'/);
    $process_name =~ s/\n+//g;
    $process_name = "PROCESS_DOWN" if !$process_name;

    if (not $ques{$process_name}) {
        $ques{$process_name} = 0;
    }

    $ques{$process_name} += $messages;

}

for (keys %ques) {
    $body .= qq/    {"process_name": "${_}", "message": ${ques{$_}}},\n/;
}

$body = substr $body, 0, length($body) -2;
$body = sprintf "[\n${body}\n]";

say $body;
