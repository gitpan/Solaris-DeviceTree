
package Solaris::DeviceTree::Libdevinfo::Property;

use 5.006;
use strict;
use warnings;
use Solaris::DeviceTree::Libdevinfo::Impl;

=pod

=head1 NAME

Solaris::DeviceTree::Libdevinfo::Property - Property of a node of the Solaris devicetree

=head1 SYNOPSIS
  use Solaris::DeviceTree::Libdevinfo;
  $tree = new Solaris::DeviceTree::Libdevinfo;
  @disks = $tree->find_nodes( type => 'disk' );
  @props = @disks->properties;


=head1 DESCRIPTION


=head1 METHODS

The following methods are available:

=over 4

=item $minor = new Solaris::DeviceTree::Libdevinfo::Property($minor_data, $devinfo_node);

The constructor takes a SWIG-pointer to the C data structure
of a minor node C<di_minor_t> and a backreference to the
C<Solaris::DeviceTree::Libdevinfo> object which generates this
instance.

=cut

sub new {
  my $pkg = shift @_;
  my $prop = shift @_;

  my $this = bless {
    prop => $prop
  }, $pkg;

  return $this;
}

sub name {
  my $this = shift @_;
  return di_prop_name( $this->{prop} );
}

sub devt {
  my $this = shift @_;
  my $devt = di_prop_devt( $this->{prop} );

  my @result = undef;
  if( !isDDI_DEV_T_NONE( $devt ) ) {
    my ($major, $minor) = devt_majorminor( $devt );
    @result = ($major, $minor);
  }
  return @result;
}

sub type {
  my $this = shift @_;

  my $prop = $this->{prop};
  my $type = di_prop_type( $prop );
  my @types = qw( Boolean Int String Byte Unknown Undefined );
  return $types[ $type ];
}

# -> TODO: let the user choose how to output the data: packed string,
# plaintext, hex characters.
# Accessor should be same as in PromProperty
sub data {
  my $this = shift @_;

  my $prop = $this->{prop};
  my $type;
  my @data;

  $type = di_prop_type( $prop );

  if( $type == $DI_PROP_TYPE_BOOLEAN ) {
    # boolean data. Existence means 'true'
    @data = ("true");
  } elsif( $type == $DI_PROP_TYPE_INT ) {
    # integer array data. Use helper function.
    my $handle = newIntHandle();
    my $count = di_prop_ints( $prop, $handle );
    my $index;
    for( $index = 0; $index < $count; $index++ ) {
      push @data, getIndexedInt( $handle, $index );
    }
    freeIntHandle( $handle );
  } elsif( $type == $DI_PROP_TYPE_STRING ) {
    # string array data. Use helper function.
    my $handle = newStringHandle();
    my $count = di_prop_strings( $prop, $handle );
    my $index;
    for( $index = 0; $index < $count; $index++ ) {
      push @data, getIndexedString( $handle, $index );
    }
    freeStringHandle( $handle );
  } elsif( $type == $DI_PROP_TYPE_BYTE ||
        $type == $DI_PROP_TYPE_UNKNOWN ) {
    # byte or unknown data. Which one doesn't matter because we always use
    # 'di_prop_bytes' to read the data.
    my $handle = newUCharTHandle();
    my $count = di_prop_bytes( $prop, $handle );
    my $index;
    for( $index = 0; $index < $count; $index++ ) {
      push @data, getIndexedByte( $handle, $index );
    }
    freeUCharTHandle( $handle );
  } elsif( $type == $DI_PROP_TYPE_UNDEF_IT ) {
    # the data was explicitly marked 'undefined'
    @data = undef;
  }

  return wantarray ? @data : join( " ", @data );
}

=pod

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

  L<Solaris::DeviceTree::Libdevinfo>, L<libdevinfo>, L<di_prop_bytes>.

=cut

1;
