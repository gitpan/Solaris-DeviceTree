#
# $Source: /cvsroot/devicetool/Solaris-DeviceTree/Makefile.PL,v $
# $Id: Makefile.PL,v 1.4 2003/11/28 15:30:21 honkbude Exp $
#

use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is Solaris
my ($sys, $rel) = (POSIX::uname())[0,2];

if( $sys ne "SunOS" || $rel !~ /^(5.7|5.8|5.9)$/ ) {
  warn("WARNING: Solaris::DeviceTree has been tested on Solaris 7, 8, 9\n",
       "It may not work on $sys $rel\n\n");
}

WriteMakefile(
  'NAME'		=> 'Solaris::DeviceTree',
  'VERSION_FROM'	=> 'lib/Solaris/DeviceTree.pm',
  'EXE_FILES'		=> [ 'scripts/devtree' ],
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM	=> 'lib/Solaris/DeviceTree.pm',
    AUTHOR		=> 'Dagobert Michelsen <dm@baltic-online.de>') : ()),
);
