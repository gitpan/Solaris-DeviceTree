
package Solaris::DeviceTree::PathToInst;

use 5.006;
use strict;
use warnings;
use Carp;
use English;

use Data::Dumper;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw() ], );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

use base qw( Exporter );
#use vars qw( $_ROOT_NODE );

our @ISA = qw( Solaris::DeviceTree::Node Solaris::DeviceTree::Util );
our $_ROOT_NODE;

use Solaris::DeviceTree::Node;
use Solaris::DeviceTree::Util;
#use Solaris::DeviceTree::OFW::Node;

=pod

=head1 NAME

Solaris::DeviceTree::PathToInst - Perl interface to /etc/path_to_inst

=head1 SYNOPSIS

  use Solaris::DeviceTree::PathToInst;
  $node = new Solaris::DeviceTree::PathToInst;
  @children = $node->child_nodes;

=head1 DESCRIPTION

The C<Solaris::DeviceTree::PathToInst> module implements access to the
Solaris driver configuration file C</etc/path_to_inst> via a hierarchical
tree structure. The API of this class contains all methods from the
C<Solaris::DeviceTree> applicable to this context.

=head1 METHODS

The following methods are available:

=over 4

=item $node = new Solaris::DeviceTree::PathToInst;

=item $node = new Solaris::DeviceTree::PathToInst( filename => '/a/etc/path_to_inst' );

The constructor takes a location of a path_to_inst file as data source
and returns a reference to the root node object. If no path_to_inst
file is given the file from the running system at /etc/path_to_inst is read.

=cut

sub new {
  my ($pkg, %params) = @_;

  $params{filename} ||= '/etc/path_to_inst';

  if( !defined $_ROOT_NODE ) {
    # -> TODO: Localizing filehandles
    open PTI, $params{filename} || croak "Could not open " . $params{filename}. "\n";

    $_ROOT_NODE = $pkg->_new_node;
    $_ROOT_NODE->{_file} = $params{filename},
    $_ROOT_NODE->{_physical_name} = undef;
    $_ROOT_NODE->{_instance_number} = undef;
    $_ROOT_NODE->{_binding_name} = undef;

    while( <PTI> ) {
      chomp;
      s/#.*//;		# strip comments
      next if /^$/;	# skip empty lines

      # According to path_to_inst(4) a line looks like this:
      #   "physical name" instance number "driver binding name"
      my ($physical_name, $instance_number, $driver_binding_name) =
        /^"([^"]+)"\s+(\d+)\s+"([^"]+)"$/;

      my @path_components = split( m!/!, $physical_name );

      # All physical names are absolute. Get rid of the first empty entry
      shift @path_components;

      $_ROOT_NODE->_insert( physical_path => $physical_name,
        path_components => \@path_components,
        instance => $instance_number, driver => $driver_binding_name );
    }
    close PTI;

  }
  return $_ROOT_NODE;
}

# Special constructor for internal nodes
sub _new_child {
  my ($parent, %params) = @_;

  if( defined $parent && !defined ref( $parent ) ) {
    croak "The specified parent must be an object.";
  }
  my $this = $parent->_new_node( parent => $parent );
  $this->{_physical_name} = $params{physical_name};
  $this->{_node_name} = $params{node_name};
  $this->{_binding_name} = $params{binding_name};
  $this->{_instance_number} = $params{instance_number};
  $this->{_bus_addr} = $params{bus_addr};

#print "_new_child: ", $params{physical_name} || "", " ", $params{node_name} || "", " ", $params{bus_addr} || "", "\n";
  return $this;
}

# This internal method inserts the node specified by the components in
# 'physical_path' with the attributes 'instance' and 'driver' as child
# for the given object.
sub _insert {
  my ($this, %params) = @_;

  my @path_components = @{$params{path_components}};
  my $physical_path = $params{physical_path};
  my $instance = $params{instance};
  my $driver = $params{driver};

  # $component is the node from the argument processed now
  my $component = shift @path_components;
  my ($node_name, $bus_addr) = ($component =~ /^([^@]*)(?:@(.*))?$/);

  # Find the node in the devicetree being processed
  my $node;
  foreach my $child (@{$this->{_child_nodes}}) {
    if( $child->{_node_name} eq $node_name &&
        $child->{_bus_addr} eq $bus_addr ) {
      $node = $child;
      last;
    }
  }
  if( !defined $node ) {
    # The node was not found. Generate it.
    $node = $this->_new_child( node_name => $node_name, bus_addr => $bus_addr );
  }

  if( @path_components > 0 ) {
    # There are still components in the path. Traverse further.
    $node->_insert( physical_path => $physical_path,
      path_components => \@path_components,
      instance => $instance, driver => $driver );
  } else {
    # We have found the final node. Set the attributes accordingly.
    $node->{_physical_name} = $physical_path;
    $node->{_instance} = $instance;
    $node->{_driver_name} = $driver;
#print "Inserting: ", $physical_path || "", " ", $node_name || "", " ", $bus_addr || "", "\n";
  }
  $node;
}

# Overwrite method of base class
sub root_node {
  my $this = shift;

  # Since we have a singleton the same reference to the object is
  # always returned.
  return $_ROOT_NODE;
}

=pod

=item $path = $node->devfs_path

Returns the physical path assocatiated with this node.

=cut

sub devfs_path {
  my $this = shift;

  # Handle special case: root node has undefined physical name meaning '/'
  return $this->{_physical_name} || '/';
}

=pod

=item $nodename = $node->node_name;

Returns the name of the node. The value is used to build the physical
path. It is undefined for the root node and defined for all other nodes.

=pod

=cut

sub node_name {
  my $this = shift;
  return $this->{_node_name};
}

=pod

=item $bindingname = $node->binding_name;

Returns the binding name of the driver for the node.

=cut

sub binding_name {
  my $this = shift;
  return $this->{_binding_name};
}

=pod

=item $drivername = $node->driver_name;

Returns the driver name for the node.

=cut

sub driver_name {
  my $this = shift;
  return $this->{_driver_name};
}

=pod

=item $busaddr = $node->bus_addr;

Returns the address on the bus for this node. C<undef> is returned
if a bus address has not been assigned to the device. A zero-length
string may be returned and is considered a valid bus address.

=cut

sub bus_addr {
  my $this = shift;
  return $this->{_bus_addr};
}

=pod

=item $inst = $node->instance;

Returns the instance number for this node of the bound driver.
C<undef> is returned if no instance number has been assigned.

=cut

sub instance {
  my $this = shift;
  return $this->{_instance};
}


# Default implementations should go into the mixin class Solaris::DeviceTree::Util
#sub compatible_names { return (); }
#sub devid { return undef; }
#sub driver_ops { return (); }
#sub nodeid { return undef; }

=pod

=back

=head1 IMPLEMENTATION DETAILS

Because the methods are all read-only the object is implemented as
singleton and the same reference gets returned every time.


=head1 BUGS

  * The singleton implementation keeps only one instance of
    this class. If multiple calls to the constructor are issued
    with different filenames the returned values are always from
    the path_to_inst initially specified.

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

  * L<path_to_inst (4)>

=cut

1;
