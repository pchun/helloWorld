#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use File::Copy;
use Getopt::Long;

our %args;
GetOptions(\%args,
   'help',
   'commit'
);

usage() if $args{'help'};

my @missing = grep {not $args{$_}} qw();
if (@missing)
{
   print "missing required argument(s): ".join(", ", @missing)."\n\n";
   usage();
}

##############################################################################
#### point this to where CMP download logs for CallSource is located  ####
##############################################################################
my $dir = 'C:\Documents and Settings\pchun\Desktop\CMP_Logs\CMPdownloads\CallSource';
my $revert_dir = 'C:\temp';

# main start -----------------------------------------------------------------

my @campaign_list = qw (80 139 305 309 485 6340 18233 21430 35192
   38303 50019 55241 55283 57436 57479 59998 60090 66250 70841
   72270 73067 77540 250019);
my $end_date = '2010-04-30';

my %summary;
$summary{'backup_created'} = 0;
$summary{'log_files_processed'} = 0;
$summary{'warning_count'} = 0;
my @revert_backup;

my $start_file = $end_date . ".txt";
chdir($dir) or die "\nCheck your directory!\n\nCan't change directory to '$dir' $!\n";
unless ((-e $start_file) && (-r $start_file)){
   die "Check your start date of $end_date or the file $start_file! $!\n";
}
# read in list of all CMP log files, YYYY-MM-DD format
my @cmp_log_files = grep { /\d{4}-\d{2}-\d{2}\.txt/ } glob "*.txt";

print "Removing " . scalar @campaign_list . " campaigns ("
   .join(",", @campaign_list) . ")\n";
# process logs from most recent to the target date
foreach my $log_file (sort {$b cmp $a} @cmp_log_files) {
   remove_campaignIDs($log_file, \@campaign_list);
   $summary{'log_files_processed'} += 1;
   if ($log_file =~ m/$start_file/) {
      last;
   }
}

print "\n";
print "# of campaign IDs: " . scalar @campaign_list . "\n";
print "# of files processed: $summary{'log_files_processed'}\n";
print "# of backups created: $summary{'backup_created'}\n";
print "# of warnings: $summary{'warning_count'}\n";

unless ($args{'commit'}) {
   print "\nTest run!!! - issue COMMIT\n\n";
   &usage();
}

if (@revert_backup) {
   chdir($revert_dir) or die "Error while creating revert script $!\n";
   open FILE, ">", "revert_backup_files.sh"
      or die "Error creating file revert_backup_files.sh\n";
   binmode FILE;
   print FILE @revert_backup;
   close FILE;
   print "# Revert file created: revert_backup_files.sh in $revert_dir\n";
}

# ----------------------------------------------------------------------------

sub remove_campaignIDs {
   my ($log_file, $campaign_list_ref) = @_;
   my $need_backup = 0;
   
   print "\n-$log_file\n";
   open FILE, "<", $log_file or die "Error reading file $log_file.\n";
   my @log_file_lines = <FILE>;
   close FILE;
   
   my @edited_content;
   for my $line (@log_file_lines) {
      chomp($line);
      $line .= "\n";
      push @edited_content, $line;
      if ($line > 2147483648) {
         # maximum CMP can handle
         print "WARNING!!: invalid campaignID ($line)!!\n";
         $summary{'warning_count'} += 1;
      }
      for my $campaignID (@$campaign_list_ref) {
         if ($line =~ m/^\b$campaignID\b/) {
            $need_backup = 1;
            print "    Removed: $campaignID\n";
            pop @edited_content;
            last;
         }
      }
   }
   
   if ($need_backup) {
      if ($args{'commit'}) {
         backup_log_file($log_file);
         open FILE, ">", $log_file or die "Error writing to file $log_file.\n";
         binmode FILE; # CMP Logs are in UNIX format
         print FILE @edited_content;
         close FILE;
      }
   } else {
      print "    Removed: None\n    Backup File: N\\A\n";
   }
}

sub backup_log_file {
   my ($log_file) = @_;
   my $backup_file_name = $log_file . "." . get_timestamp();
   print "    Backup File: $backup_file_name\n";
   unless (copy($log_file, $backup_file_name)) {
      print "Error while backing up $log_file ($!)";
   }
   # create revert backup script for rollback
   push @revert_backup, "mv $backup_file_name $log_file\n";
   $summary{'backup_created'} += 1;
}

sub get_timestamp {
   my ($sec, $min, $hr, $day, $mon, $year) = localtime;
   
   sprintf("%04d%02d%02d_%02d%02d%02d",
            1900 + $year, $mon +1, $day, $hr, $min, $sec);
}

sub usage {
    print <<END;
usage: $0 --commit

   commit   no commit (i.e., creates backup, edits files, etc)
            unless this is specified
   
   This script removes targeted campaign IDs from CallSource CMP log files.
   Other than specifying directory path in the script for variable \$dir,
   no arguments are required as this is specifically written for specific DSR.
   
END
   ;
   exit(1);
}

