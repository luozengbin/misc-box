#!/bin/env perl
# pachi
#
# This script find out process currently swapped by /proc/$PID/status
use strict;
use warnings;
 
# When you want to debug, you should exec "export SCRIPT_DEBUG=1".
my $debug = $ENV{SCRIPT_DEBUG} ? 1 : 0;
 
my $proc_status = `grep VmSwap /proc/*/status | sort -k 2 -r`;
my @proc_status = split m{\n}, $proc_status;
my $proc_swaps  = [];
 
foreach my $status_line ( @proc_status ) {
    my $process_info = {};
 
    chomp $status_line;
    my @status_line     = split /\s+/, $status_line;
    my $proc_path       = $status_line[0];
    my $proc_swap_value = $status_line[1];
    my $pid             = ( split( /\//,$proc_path ) )[2];
 
    if ( ! -f "/proc/$pid/status" ) {
        # file not found! next.
        next;
    }
 
    # get process name by pid
    my $process_name_line = `grep Name /proc/$pid/status`;
    chomp $process_name_line;
    my @process_name_line       = split /\s+/, $process_name_line;
    my $process_name            = $process_name_line[1];
    $process_info->{name}       = $process_name;
    $process_info->{pid}        = $pid;
    $process_info->{swap_value} = $proc_swap_value;
 
    # Process information is stored in hash
    push @$proc_swaps ,$process_info;
 
}
 
# Print header
printf "--------------------+----------+---------------+\n";
printf "       Swap size classified by processes       |\n";
printf "--------------------+----------+---------------+\n";
printf "    Process Name    |   PID    |   Swap Size   |\n";
printf "--------------------+----------+---------------+\n";
 
# Print every process info
foreach my $proc_swap ( @$proc_swaps ) {
    printf ("%-20s|", "$proc_swap->{name}");
    printf ("%10s |", "$proc_swap->{pid}");
    printf ("%15s |", "$proc_swap->{swap_value}KB");
    printf "\n";
}
 
# Print footer
printf "\n";
 
exit 0;
