use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is Solaris
my ($sys, $rel) = (POSIX::uname())[0,2];
if( $sys ne "SunOS" || $rel !~ /^(5.8|5.9)$/ ) {
  warn("WARNING: Solaris::DeviceTree has been tested on Solaris 8, 9\n",
       "It may not work on $sys $rel\n\n");
}

#my $VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
my $VERSION = 0.01;

WriteMakefile(
  'NAME'		=> 'Solaris::DeviceTree',
  'VERSION'		=> $VERSION,
  'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
  'EXE_FILES'		=> [ 'scripts/devtree' ],
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM	=> 'lib/Solaris/DeviceTree.pm', # retrieve abstract from module
    AUTHOR		=> 'Dagobert Michelsen <dm@baltic-online.de>') : ()),
);
