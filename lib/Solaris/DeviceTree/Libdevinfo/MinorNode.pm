
package Solaris::DeviceTree::Libdevinfo::MinorNode;

use 5.006;
use strict;
use warnings;
use Solaris::DeviceTree::Libdevinfo::Impl;

=pod

=head1 NAME

Solaris::DeviceTree::Libdevinfo::MinorNode - Minor node of the Solaris devicetree

=head1 SYNOPSIS

  use Solaris::DeviceTree::Libdevinfo;
  $tree = new Solaris::DeviceTree::Libdevinfo;
  @disks = $tree->find_nodes( type => 'disk' );
  @minor = @disks->minor_nodes;


=head1 DESCRIPTION

This class implements a minor node in the libdevinfo devicetree.
This is an internal class to C<Solaris::DeviceTree::Libdevinfo>. There should be
no need to generate instances of this class in an application explicitly.
Instances are generated only from L<Solaris::DeviceTree::Libdevinfo::minor_nodes()>.


=head1 METHODS

The following methods are available:


=over 4

=item $minor = new
  Solaris::DeviceTree::Libdevinfo::MinorNode($minor_data, $devinfo_node);

The constructor takes a SWIG-pointer to the C data structure
of a minor node C<di_minor_t> and a backreference to the
C<Solaris::DeviceTree::Libdevinfo> object which generates this
instance.

=cut

sub new {
  my ($class, $minor, $node) = @_;

  my $this = bless {
    _minor => $minor,
    _node => $node,	# if we need infos about the upper node
  }, ref( $class ) || $class;

  return $this;
}

=pod

=item $name = $minor->name;

Return the name of the minor node. This is used e.g. as suffix
of the device filename. For disks this is something like ':a' or
':a,raw'.

=cut

sub name {
  my $this = shift;
  return di_minor_name( $this->{_minor} );
}

=pod

=item $path = $minor->devfs_path;

Return the complete physical path including the minor node

=cut

sub devfs_path {
  my $this = shift;
  return $this->node->devfs_path . ":" . $this->name;
}

=pod

=item ($majnum,$minnum) = $minor->devt;

Returns the major and minor device number as a pair for the node.
The major numbers should be the same for all minor nodes return
by a L<Solaris::DeviceTree::Libdevinfo> node.

=cut

sub devt {
  my $this = shift;
  my $devt = di_minor_devt( $this->{_minor} );
  my ($major, $minor) = devt_majorminor( $devt );
  return ($major, $minor);
}

=pod

=item $type = $minor->nodetype

Returns the nodetype of the minor node. Legal return values
can be taken from <sys/sunddi.h>. With this call you
can differentiate between pseudo nodes, displays and stuff.

=cut

sub nodetype {
  my $this = shift;
  return di_minor_nodetype( $this->{_minor} );
}

=pod

=item $spectype = $minor->spectype

Returns the type of the minor node. Returns
  raw     for a raw device
  block   for a block device

=cut

sub spectype {
  my $this = shift;

  my $result;
  my $spectype = di_minor_spectype( $this->{_minor} );
  if( $spectype == $S_IFCHR ) {
    $result = "raw";
  } elsif( $spectype == $S_IFBLK ) {
    $result = "block";
  }
  return $result;
}

=pod

=item if( $minor->is_raw_device ) { ... }

Returns true if the minor node is a raw device

=cut

sub is_raw_device {
  my $this = shift;
  return di_minor_spectype( $this->{_minor} ) == $S_IFCHR;
}

=pod

=item if( $minor->is_block_device ) { ... }

Returns true if the minor node is a block device

=cut

sub is_block_device {
  my $this = shift;
  return di_minor_spectype( $this->{_minor} ) == $S_IFBLK;
}

=pod

=item $node = $minor->node;

Returns the associated Solaris::DevinfoTree node.
One Solaris::DevinfoTree node can have multiple minor nodes.

=cut

sub node {
  my $this = shift;
  return $this->{_node};
}

=pod

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

  L<Solaris::DeviceTree::Libdevinfo>

=cut

1;
