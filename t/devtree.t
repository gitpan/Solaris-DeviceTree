# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use strict;
use warnings;

BEGIN { plan tests => 24 };

#system( "env" );

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
  die "Cannot found devtree. It should be at\n  $devtree\nbut it's not there.";
}

# Tests 1-12 - tree printing
checkrun( "$devtree -p" );
checkrun( "$devtree --print" );
checkrun( "$devtree -pv" );
checkrun( "$devtree --print --all" );
checkrun( "$devtree -pw" );
checkrun( "$devtree --print --attr" );
checkrun( "$devtree -po" );
checkrun( "$devtree --print --prop" );
checkrun( "$devtree -pr" );
checkrun( "$devtree --print --promprop" );
checkrun( "$devtree -pm" );
checkrun( "$devtree --print --minor" );

# Tests 13-16 - aliases
checkrun( "$devtree -a" );
checkrun( "$devtree --aliases" );
checkrun( "$devtree --aliases=disk" );
checkrun( "$devtree -a disk" );

# Tests 17-18 - disks
checkrun( "$devtree -d" );
checkrun( "$devtree --disks" );

# Tests 19-20 - tapes
checkrun( "$devtree -t" );
checkrun( "$devtree --tapes" );

# Tests 21-22 - networks
checkrun( "$devtree -n" );
checkrun( "$devtree --networks" );

# Tests 23-24 - boot information
checkrun( "$devtree -b" );
checkrun( "$devtree --bootinfo" );


exit 0;
