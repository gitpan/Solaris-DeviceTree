
package Solaris::DeviceTree::Node;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use base qw( Exporter );
use vars qw( $VERSION @EXPORT);

@EXPORT = qw();
$VERSION = '0.01';

=pod

=head1 NAME

Solaris::DeviceTree::Node - Base functions for devicetrees


=head1 DESCRIPTION

This class acts as a base class for subclasses of L<Solaris::DeviceTree>
to provide default values for all attributes and properties. It should
not be necessary to instantiate objects of this class directly.

=cut

# This constructor is called from classes implementing the node interface.
sub _new_node {
  my ($class, %params) = @_;

  my $parent = $params{parent};

  my $this = bless {
    _parent => $parent,
    _child_nodes => [],
  }, ref( $class ) || $class;

  if( defined $parent ) {
    push @{$parent->{_child_nodes}}, $this;
  }

  return $this;
}

=pod

=head2 METHODS

The following methods are available:

=over 4

=item $parent = $node->parent_node;

Returns the parent node for this node. If this is the root
node, then C<undef> is returned.

=cut

sub parent_node {
  my $this = shift;
  return $this->{_parent};
}

=pod

=item @childs = $node->child_nodes;

This method returns a list with all children.

=cut

sub child_nodes {
  my ($this, %options) = @_;

  return @{$this->{_child_nodes}};
}

=pod

=item $node = $node->root_node

Returns the root node of the tree.

=cut

sub root_node {
  my $this = shift;

  my $root = $this;
  while( defined $root->parent_node ) {
    $root = $root->parent_node;
  }
  return $root;
}

=pod

=item @siblings = $node->sibling_nodes

Returns the list of siblings for this object. A sibling is a child
from our parent, but not ourselves.

=cut

sub sibling_nodes {
  my $this = shift;

  my $parent = $this->parent_node;

  # Read all siblings including $this
  my @siblings = defined $parent ? $parent->child_nodes : ();

  # Strip out current node
  @siblings = grep { $_ ne $this } @siblings;

  return @siblings;
}

=pod

=item $path = $node->devfs_path

Returns the physical path assocatiated with this node.

=cut

sub devfs_path { return undef; }

=pod

=item $nodename = $node->node_name;

Returns the name of the node used in the pysical path.

=pod

=cut

sub node_name { return undef; }

=pod

=item $bindingname = $node->binding_name;

Returns the binding name of the driver for the node.

=cut

sub binding_name { return undef; }

=pod

=item $drivername = $node->driver_name;

Returns the driver name for the node.

=cut

sub driver_name { return undef; }

=pod

=item $busaddr = $node->bus_addr;

Returns the address on the bus for this node.

=cut

sub bus_addr { return undef; }

=pod

=item $inst = $node->instance;

Returns the instance number of the bound driver for this node.
C<undef> is returned if no instance number has been assigned.

=cut

sub instance { return undef; }

sub compatible_names { return (); }
sub devid { return undef; }
sub driver_ops { return (); }
sub is_pseudo_node { return undef; }
sub is_sid_node { return undef; }
sub is_prom_node { return undef; }
sub nodeid { return undef; }
sub state { return (); }
sub props { return undef; }
sub prom_props { return undef; }
sub minor_nodes { return undef; }

sub controller {
  my ($this, %args) = @_;

  if( exists $args{_controller} ) {
    $this->{_controller} = $args{_controller};
  }
  return (exists $this->{_controller} ? $this->{_controller} : undef);
}

sub target {
  my ($this, %args) = @_;

  if( exists $args{_target} ) {
    $this->{_target} = $args{_target};
  }
  return (exists $this->{_target} ? $this->{_target} : undef);
}

sub lun {
  my ($this, %args) = @_;

  if( exists $args{_lun} ) {
    $this->{_lun} = $args{_lun};
  }
  return (exists $this->{_lun} ? $this->{_lun} : undef);
}

sub slice {
  my ($this, %args) = @_;

  if( exists $args{_slice} ) {
    $this->{_slice} = $args{_slice};
  }
  return (exists $this->{_slice} ? $this->{_slice} : undef);
}

sub rmt {
  my ($this, %args) = @_;

  if( exists $args{_rmt} ) {
    $this->{_rmt} = $args{_rmt};
  }
  return (exists $this->{_rmt} ? $this->{_rmt} : undef);
}

=pod


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

=cut

1;
