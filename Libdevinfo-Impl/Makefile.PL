use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Compile only if we have 
my ($sys, $rel) = (POSIX::uname())[0,2];

$VERSION = '0.01';

if( $sys ne "SunOS" || $rel !~ /^(5.7|5.8|5.9)$/ ) {
  warn("WARNING: Solaris::DeviceTree has been tested on Solaris 7, 8, 9\n",
       "Skipping libdevinfo interface on $sys $rel" );
  WriteMakefile(
  );
} else {
  WriteMakefile(
    'NAME'		=> 'Solaris::DeviceTree::Libdevinfo::Impl',
    'VERSION_FROM'	=> 'Makefile.PL', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> '-ldevinfo',
    'OBJECT'		=> 'Impl.o Impl_wrap.o',
  );
}
