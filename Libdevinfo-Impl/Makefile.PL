use ExtUtils::MakeMaker;

$VERSION = '0.01';

WriteMakefile(
    'NAME'		=> 'Solaris::DeviceTree::Libdevinfo::Impl',
    'VERSION_FROM'	=> 'Makefile.PL', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> '-ldevinfo',
    'OBJECT'		=> 'Impl.o Impl_wrap.o',
);
