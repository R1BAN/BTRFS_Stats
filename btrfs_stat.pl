#!/usr/bin/perl

use strict;
use warnings;

my $btrfsPath = "/mnt/btrfs";

if ( -d $btrfsPath."/.btrfs/" ) {
 #Get root subvolume ID
 my @rootsub = split /\n/,`sudo btrfs subvolume show $btrfsPath/`;
 my $rootSubvol = 0;
 for (my $i=0; $i < @rootsub; $i++) {
  if ( $rootsub[$i] =~ /Subvolume ID:.*(\d+)/ ) {$rootSubvol = $1}
 }
 my %subvolumes;
 $subvolumes{$rootSubvol} = "Root";
 #Get subvolumes list
 my $subvols = `sudo btrfs subvolume list $btrfsPath`;
 my @lines = split /\n/, $subvols;
 for (my $i=0; $i < @lines; $i++) {
  my $line = $lines[$i];
  $line =~ /^ID (\d+) .*(\d{4}\.[0-9.-]*\d{2})$/;
  $subvolumes{$1} = $2;
 }
 #Get spaces
 my @spaces = split /\n/, `sudo btrfs qgroup show $btrfsPath/`;
 my (%rfer, %excl);
 for (my $i=0; $i<@spaces; $i++) {
  if ($spaces[$i] =~ /^0\/\d+ /) {
   my $line = $spaces[$i];
   $line =~ /^\d+\/(\d+) *([0-9.]+[BKMGT]).{0,2} *([0-9.]+[BKMGT])/;
   $rfer{$1} = $2;
   $excl{$1} = $3;
  }
 }
# { #Text output
#  my $count = 1;
#  my @subs = keys %subvolumes;
#  for my $i (sort { $subvolumes{$b} cmp $subvolumes{$a} } @subs) {
#   print $count++."\t".$subvolumes{$i}."\t".$rfer{$i}."\t".$excl{$i}."\n";
#  }
# }
 { #JSON output
  my $time = `date +"%H:%M %d.%m.%Y"`;
  $time =~ s/\n//;
  print "{ \"time\": \"$time\",\n \"subvols\": [\n";
  my $count = 1;
  my @subs = keys %subvolumes;
  for my $i (sort { $subvolumes{$b} cmp $subvolumes{$a} } @subs) {
   print "  { \"seq\": \"".$count++."\", \"name\": \"$subvolumes{$i}\", \"rfer\": \"$rfer{$i}\", \"excl\": \"$excl{$i}\"}";
   print "," unless ($count == @subs+1);
   print " ]" if ($count == @subs+1);
   print "\n";
  }  
  print " }\n";
 }
}
