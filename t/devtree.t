# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use strict;
use warnings;

BEGIN { plan tests => 24 };

system( "/usr/bin/env" );

# Use the right perl for the scripts, because the scripts have
# not been installed and therefore the header with the execution
# program is wrong.

my $perl = $ENV{'_'};
print "Perl: $perl\n";

sub checkrun {
  my ($cmd, %args) = @_;

  system $cmd . ' >/dev/null 2>/dev/null';

  my $exit_value  = ($? >> 8);
  my $signal_num  = ($? & 127);
  my $dumped_core = ($? & 128);

  $args{'exit_value'} ||= 0;
  $args{'signal_num'} ||= 0;
  $args{'dumped_core'} ||= 0;

  if( $exit_value != $args{'exit_value'} ||
      $signal_num != $args{'signal_num'} ||
      $dumped_core != $args{'dumped_core'} ) {
    ok( 0 );
  } else {
    ok( 1 );
  }
}

my $devtree = $ENV{'PWD'} . '/' . $ENV{'REGRESSION_TEST'};
$devtree =~ s!/[^/]+/[^/]+$!/scripts/devtree!;

if( ! -x $devtree ) {
  die "Cannot find devtree. It should be at\n  $devtree\nbut it's not there.";
}

# Tests 1-12 - tree printing
checkrun( "$perl $devtree -p" );
checkrun( "$perl $devtree --print" );
checkrun( "$perl $devtree -pv" );
checkrun( "$perl $devtree --print --all" );
checkrun( "$perl $devtree -pw" );
checkrun( "$perl $devtree --print --attr" );
checkrun( "$perl $devtree -po" );
checkrun( "$perl $devtree --print --prop" );
checkrun( "$perl $devtree -pr" );
checkrun( "$perl $devtree --print --promprop" );
checkrun( "$perl $devtree -pm" );
checkrun( "$perl $devtree --print --minor" );

# Tests 13-16 - aliases
checkrun( "$perl $devtree -a" );
checkrun( "$perl $devtree --aliases" );
checkrun( "$perl $devtree --aliases=disk" );
checkrun( "$perl $devtree -a disk" );

# Tests 17-18 - disks
checkrun( "$perl $devtree -d" );
checkrun( "$perl $devtree --disks" );

# Tests 19-20 - tapes
checkrun( "$perl $devtree -t" );
checkrun( "$perl $devtree --tapes" );

# Tests 21-22 - networks
checkrun( "$perl $devtree -n" );
checkrun( "$perl $devtree --networks" );

# Tests 23-24 - boot information
checkrun( "$perl $devtree -b" );
checkrun( "$perl $devtree --bootinfo" );


exit 0;
