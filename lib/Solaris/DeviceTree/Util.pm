
package Solaris::DeviceTree::Util;

use 5.006;
use strict;
use warnings;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use base qw( Exporter );
use vars qw( $VERSION @EXPORT);

@EXPORT = qw();
$VERSION = '0.01';

use Carp;
use English;

=pod

=head1 NAME

Solaris::DeviceTree::Util - Mixin class devicetrees


=head1 DESCRIPTION

This class acts as a mixin class for several methods which are
available to all subclasses of L<Solaris::DeviceTree>.


=head2 METHODS

The following methods are available:

=over 4

=cut

# -> TODO: This should be integrated in find_nodes.
sub __allNodesFlat {
  my $this = shift;
  if( !exists $this->{_allNodes} ) {
    $this->{_allNodes} = [ $this, map { $_->allNodesFlat } $this->child_nodes ];
  }
  return @{$this->{_allNodes}};
}

# -> TODO: Is this still needed?
# This method return all minor nodes from the whole subtree
sub __allMinorNodes {
  my $this = shift;

  if( !exists $this->{_allMinorNodes} ) {
    my @allMinorNodes = $this->minorNodes;
    foreach my $child ($this->child_nodes) {
      push @allMinorNodes, $child->allMinorNodes();
    }
    $this->{_allMinorNodes} = \@allMinorNodes;
  }
  return @{$this->{_allMinorNodes}};
}


# -> TODO: is this still needed?
# This method returns all nodes which have minor nodes of type "disk".
# Alternatively we could check for nodes with the prom-property "device_type"
# "block" and look for bound driver instances. Additionally, a path-transfer
# from obp-pathes to Solaris-pathes would be necessary.
# However, both methods should be equivalent.
sub __allBoundDiskNodes {
  my $this = shift;

  if( !exists $this->{_diskNodes} ) {
    my @allDiskNodes =
      map { $_->node() }
      grep { defined $_->nodetype &&
             $_->nodetype =~ /ddi_block.*channel/ &&
             defined $_->spectype() &&
             $_->spectype() eq "block" }
      $this->allMinorNodes();
    my %disks;
    @disks{@allDiskNodes} = @allDiskNodes;
    $this->{_diskNodes} = [ values %disks ];
  }
  return @{$this->{_diskNodes}};
}

=pod

=item if( $node->is_network_node ) { ... }

This method returns true if the node represents a network card.

=cut

sub is_network_node {
  my ($this) = @_;

  my $is_network_node = undef;

  # Check properties if we have any
  my $prom_prop = $this->prom_props;
  if( defined $prom_prop ) {
    my $device_prop = $prom_prop->{device_type};
    if( defined $device_prop ) {
      $is_network_node = $device_prop->string eq 'network';
    }
  }

  if( !defined $is_network_node ) {
    # Use driver names to check if it is a network component. However, this list
    # might be updated, so return undef (=don't know) else.
    my @known_network_drivers = ( qw( tr le qe hme eri dmfe qfe ge ce ) );
    my %known; @known{@known_network_drivers} = (1 x scalar @known_network_drivers);
  
    my $driver_name = $this->driver_name;
    $is_network_node = (defined $driver_name && exists $known{$driver_name});
  }

  return $is_network_node;
}

=pod

=item if( $node->is_block_node ) { ... }

This method returns true if the node represents a block device
(which is essentially a disk).

=cut

# -> TODO: Check for transfer nodes here!!
sub is_block_node {
  my ($this) = @_;

  my $is_block_node = undef;

  # Check properties if we have any
  my $prom_prop = $this->prom_props;
  if( defined $prom_prop ) {
    my $device_prop = $prom_prop->{device_type};
    if( defined $device_prop ) {
      $is_block_node = $device_prop->string eq 'block';
    }
  }

  if( !defined $is_block_node ) {
    # Use driver names to check if it is a network component. However, this list
    # might be updated, so return undef (=don't know) else.
    my @known_block_drivers = ( qw( sd ssd ) );
    my %known; @known{@known_block_drivers} = (1 x scalar @known_block_drivers);
  
    my $driver_name = $this->driver_name;
    $is_block_node = (defined $driver_name && exists $known{$driver_name});
  }
  
  return $is_block_node;
}

=pod

=item @network_nodes = $node->network_nodes

This method returns all nodes for network cards in the tree.

=cut

sub network_nodes {
  my ($this) = @_;

  my @nodes = $this->find_nodes( func => sub { $_->is_network_node } );
  return @nodes;
}

=pod

=item @block_nodes = $node->block_nodes

This method returns all nodes for disks in the tree.

=cut

sub block_nodes {
  my ($this) = @_;

  my @nodes = $this->find_nodes( func => sub { $_->is_block_node } );
  return @nodes;
}


# -- Special search methods --

=pod

=item $node = $node->find_nodes( devfs_path => '/pci@1f,0/pci@1f,2000' );

This method returns nodes matching certain criteria. Currently it is
possible to match against a physical path or to specify a subroutine
where the node is returned if the subroutine returns true. As in
Perl L<grep> C<$_> is locally bound to the node being checked.

In a scalar context the method returns only the first node found.
In an array context the method returns all matching nodes.

  $node = $node->find_nodes( devfs_path => '/pci@1f,0/pci@1f,2000' );
  @nodes = $node->find_nodes( func => sub { $_->is_network_node } );

=cut

# -> TODO> Wildcard matching

sub find_nodes {
  my ($this, %options) = @_;

  my @result = ($this);

  foreach my $name (keys %options) {
    if( $name eq 'func' ) {
      local $_ = $this;
      if( !$options{$name}->() ) {
        @result = ();
        last;
      }
    } elsif( $name eq 'devfs_path' ) {
      # -> TODO: This can be done more efficient when recursing is skipped
      # on wrong nodes.
      if( $options{$name} ne $this->devfs_path ) {
        @result = ();
        last;
      }
    # -> TODO: Do all properties here
    } else {
      warn "Unknown property '$name' at find_nodes.\n";
    }
  }

  if( scalar @result > 0 && !wantarray ) {
    # Only one node is requested. Take shortcut and return the newly
    # found node.
    return $this;
  }

  if( wantarray ) {
    # We want all results. Recurse down into the tree.
    return (@result, map { $_->find_nodes( %options ) } $this->child_nodes );
  } else {
    # This node wasn't right. Check all nodes and stop if we found one.
    my $result;
    foreach my $node ($this->child_nodes) {
      $result = $node->find_nodes( %options );
      last if( defined $result );
    }
    return $result;
  }
}

=pod

=item my $prop = $node->find_prop( devfs_path => '/aliases', prop_name => 'disk' );

This method picks a node by criteria from the devicetree and
then selects either a property or a prom property depending on the
options given. At least one of

  prop_name
  prom_prop_name

must be specified. All options valid for find_nodes are also applicable
to this method.

=cut

# -> TODO: The return value should be formatted properly.
sub find_prop {
  my ($this, %options) = @_;

  my %find_options = %options;
  delete $find_options{prop_name};
  delete $find_options{prom_prop_name};
  my $node = $this->find_nodes( %find_options );

  if( exists $options{prop_name} ) {
    my $prop_name = $options{prop_name};
    my $props = $node->props;
    return exists $props->{$prop_name} ? $props->{$prop_name} : undef;
  } elsif( exists $options{prom_prop_name} ) {
    my $prom_prop_name = $options{prom_prop_name};
    my $prom_props = $node->prom_props;
    return exists $prom_props->{$prom_prop_name} ? $prom_props->{$prom_prop_name} : undef;
  } else {
    croak "Mandatory option 'prop_name' or 'prom_prop_name' not specified";
  }
}

=pod

=item find_minor_node( name => ':a' );

=cut

sub find_minor_node {
  my ($this, %options) = @_;

  if( exists $options{name} ) {
    foreach my $minor (@{$this->minor_nodes}) {
      return $minor if( $minor->name eq $options{name} );
    }
  } else {
    croak "Mandatory option 'name' in find_minor_node is missing.";
  }
}

# -> TODO: This should be transformed into a new method find_minor_node
# This method returns the canonical minor node for the given parameters.
# Valid parameters are:
#   physicalPath	a physical path with minor node extension (e.g. .../sd@0,0:d)
#   name		the name of a minor node bound to the current node
#   <none>		the first lexicographic minor node for this node
sub __minor {
  my ($this, %options) = @_;

  if( exists $options{physicalPath} ) {
    my ($path, $minorName) = ($options{physicalPath} =~ /^([^:]*)(?::(.*))?$/);
    my $node = $this->nodeByDevfsPath( $path );
    return undef if( !defined $node );
    my $minor;
    if( defined $minorName ) {
      $minor = $node->minor( name => $minorName );
    } else {
      $minor = $node->minor;
    }
    return $minor;
  } elsif( exists $options{name} ) {
    foreach my $minorNode ($this->minorNodes) {
      return $minorNode if( $minorNode->name eq $options{name} );
    }
    return undef;
  } else {
    my $minor = (sort { $a->name cmp $b->name } $this->minorNodes)[ 0 ];
    return $minor;
  }
}

# -> TODO: Is this still needed?
# This function checks, if there is a minor node defined for this node.
# The following named parameters are valid:
#   physicalPath
sub __hasMinorNode {
  my ($this, %options) = @_;

  if( exists $options{physicalPath} ) {
    # Search the node given by physical path
    my ($path, $minorName) = ($options{physicalPath} =~ /^([^:]*)(?::(.*))?$/);
    my $node = $this->nodeByDevfsPath( $path );
    return 0 if( !defined $node || !defined $minorName );
    return $node->hasMinorNode( name => $minorName );
  }
  if( exists $options{name} ) {
    foreach my $minorNode ($this->minorNodes) {
      return 1 if( $minorNode->name eq $options{name} );
    }
    return 0;
  }
  return 0;
}


=pod

=item my $solaris_path = $node->solaris_path

This method converts between an OBP device path and a Solaris device
path.

The conversion is quite complex. As a first step the IOCTLS
  OPROMDEV2PROMNAME (OIOC | 15)   /* Convert devfs path to prom path */
  OPROMPROM2DEVNAME (OIOC | 16)   /* Convert devfs path to prom path */
might be taken. However, some older machines are not aware of that. It would
be optimal to use devfs_dev_to_prom_name from libdevinfo, but that one is
static and reprogramming that one is *not* fun.

=cut


# This method takes an obp path in an OBP::Path object and returns a
# solaris path.
# In other words: a path containing only prom nodes is transformed to
# a path containing pseudo nodes.
#   $promPath is a reference to an OBP::Path::Component array
# This method returns an OBP::Path object. The returned object might or
# might not point to a node in the obp tree.
sub __solarisPath {
  my ($this, $promPath) = @_;
  $promPath = new OBP::Path( string => $promPath ) if( !ref( $promPath ) );
  return $promPath if( @{$promPath->components} == 0 );

  my $pc;	# leftmost path component, the one to check against
  $pc = shift @{$promPath->components};

#print "Matching ", $pc->string, " ", $this->devfsPath, "\n";
  my @children = $this->children(
    nodename => $pc->node, busaddress => $pc->busaddress );
  if( @children == 0 ) {
    # no direct match found
    # Check if we have a transfer node.

    # The mapping might or might not lead to different pathes.
    # Examples:
    #   Ultra 10   IDE disk:    disk -> dad
    #              ATAPI cdrom: cdrom -> sd
    #              SCSI disk:   disk -> sd
    #   Ultra 1:   SCSI disk:   sd -> sd
    @children = $this->children(
      nodename => $pc->node, busaddress => undef, instance => undef );
    if( @children == 0 ) {
      # No transfer node found. Because we can't find the next node in the
      # device tree we guess that the path stays the same and return what we have. 
      return new OBP::Path( components => [ $pc, @{$promPath->components} ] );
    } elsif( @children == 1 ) {
      # we found the transfer node. Continue with the node specified in the
      # driverName attribute but leave the address and args (if any) the same.
      my $transferNode = $children[ 0 ];
      my @target = $this->children(
        nodename => $transferNode->driverName, busaddress => $pc->busaddress );
      if( @target == 0 ) {
        # We have a transfer node but no node to continue. Return the corrected
        # node and leave the rest as is.
        return new OBP::Path( components => [
          new OBP::Path::Component(
            node => $transferNode->driverName,
            adr => $pc->adr,
            subadr => $pc->subadr,
            arg => $pc->arg,
          ),
          @{$promPath->components}
        ] );
      } elsif( @target == 1 ) {
        # Everything fine. Prepend the found note after node transferal to
        # the result of the continued search.
        my $contnode = $target[ 0 ];
        return new OBP::Path( components => [
          new OBP::Path::Component( string => $contnode->nodeName . "@" . $contnode->busAddress . ( defined $pc->arg ? ':' . $pc->arg : '' ) ),
          @{$contnode->solarisPath( $promPath )->components}
        ] );
      } else {
        warn "Found more than one node after node transfer. This should not happen.";
      }
    } else {
      # This is a very ugly situation. We have a valid prefix and we don't
      # know yet how to continue correctly. Both might be valid Solaris pathes.
      # It is unfortunately possible (is it?) that one path can be continued
      # and the other can not. So all pathes should be tried and compared here.
      # -> TODO
      warn "  Found more than one transfer node:\n    " . 
        join( "\n    ", map { $_->devfsPath } @children ) . "\n";
      my $match = $children[ 0 ];
      return new OBP::Path( components => [ $pc, @{$match->solarisPath( $promPath )->components} ] );
    }
  } elsif( @children == 1 ) {
    # found exact match. Continue with the next node.
    my $match = $children[ 0 ];
    return new OBP::Path( components => [ $pc, @{$match->solarisPath( $promPath )->components} ] );
  } else {
    # -> TODO: Wildcard match
    warn "Wildcard match. Just taking the first match.";
    my $match = $children[ 0 ];
    return new OBP::Path( components => [ $pc, @{$match->solarisPath( $promPath )->components} ] );
  }
}

# This should be integrated in find_node
sub __nodeByDevt {
  my ($this, $major, $minor) = @_;

  foreach my $minorNode ($this->allMinorNodes) {
    my ($tmaj, $tmin) = $minorNode->devt;
    if( $major == $tmaj && $minor == $tmin ) {
      return $minorNode->node;
    }
  }
  return undef;
}

# This should be completely obsolete with the overlay design
sub __devtInstanceMap {
  my ($this) = @_;

  my $devtInstanceMap = Solaris::DeviceTree::Libdevinfo::DevtInstanceMap->new;
  foreach my $minorNode ($this->allMinorNodes) {
    my ($major, $minor) = $minorNode->devt;
    $devtInstanceMap->insert( keys => [ qw( major minor instance ) ],
      major => $major,
      minor => $minor,
      instance => $minorNode->node->driverInstance,
    );
  }
  $devtInstanceMap;
}
  

# -- Utility functions --
# These methods transform information from the device node or tree
# to special formats.


=pod

=item %aliases = %{$node->aliases};

This method returns a hash reference which maps all aliases to their
corresponding pathes.

=cut

sub aliases {
  my $this = shift;

  my $alias_node = $this->find_nodes( devfs_path => '/aliases' );
  my %aliases;
  if( defined $alias_node ) {
    my $props = $alias_node->prom_props;
    foreach my $prop (keys %$props) {
      # The 'name' property is always present, but it is not an alias.
      # Skip it.
      next if( $prop eq 'name' );
      $aliases{$prop} = $props->{$prop}->string;
    }
  } else {
    die "The '/aliases'-node in the devicetree could not be found.";
  }
  return \%aliases;
}

=pod

=item $chosen_boot_device = $root->obp_chosen_boot_device;

This method returns the device from which the system has
most recently booted.

=cut

sub obp_chosen_boot_device {
  my $this = shift;
  return $this->find_prop( devfs_path => '/chosen', prom_prop_name => 'bootpath' );
}

=pod

=item @boot_devices = $root->obp_boot_devices;

This method returns a list with all boot devices entered in the obp.

=cut

sub obp_boot_devices {
  my $this = shift;
  my $prop = $this->find_prop( devfs_path => '/options', prom_prop_name => 'boot-device' );
  my @boot_devices = split /\s+/, $prop->string;
  return @boot_devices;
}

=pod

=item @diag_devices = $root->obp_diag_devices;

This methos returns a lst with all diag devices entered in the obp.

=cut

sub obp_diag_devices {
  my $this = shift;
  my $prop = $this->find_prop( devfs_path => '/options', prom_prop_name => 'diag-device' );
  my @diag_devices = split /\s+/, $prop->string;
  return @diag_devices;
}

=pod

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

=cut

1;
