#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree.pm,v 1.4 2003/09/05 09:12:15 honkbude Exp $
#

package Solaris::DeviceTree;

use 5.006;
use strict;
use warnings;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use base qw( Exporter );
use vars qw( $VERSION @EXPORT );

@EXPORT = qw();
$VERSION = '0.01';
our @ISA = qw( Solaris::DeviceTree::Node Solaris::DeviceTree::Util );

use Carp;
use English;
use Solaris::DeviceTree::Node;
use Solaris::DeviceTree::Util;
use Solaris::DeviceTree::MinorNode;


use Data::Dumper;




=pod

=head1 NAME

Solaris::DeviceTree - Perl interface to the Solaris devicetree

=head1 SYNOPSIS

  use Solaris::DeviceTree
  my $tree = new Solaris::DeviceTree;
  my @children = $tree->children;

=head1 DESCRIPTION

The C<Solaris::DeviceTree> module implements access to the Solaris device
information. The information is collected from the kernel via access to
C<libdevinfo>, the contents of the file C</etc/path_to_inst> and
the filesystem entries below C</dev> and C</devices>. The devicetree is
presented as a hierarchical collection of node. Each node contains
the unified information from all available resources.

=head2 EXPORT

=head2 PROPERTIES

Each node of the devicetree has the following properties:

=head2 METHODS

The following methods are available:

=over 4

=item $devtree = Solaris::DeviceTree->new

=item $devtree = Solaris::DeviceTree->new( use => [ qw( libdevinfo path_to_inst filesystem ) ] );

The constructor returns a reference to a C<Solaris::DeviceTree> object which
itself implements the C<Solaris::DeviceTree::Node> interface. The instance returned
represents the root-node of the devicetree.

=cut

sub new {
  my ($pkg, %params) = @_;

  my %sources;
  foreach my $source (@{$params{use}}) {
    if( $source eq 'libdevinfo' ) {
      # The modules are loaded on demand to decrease loading time in
      # the average case.
      require Solaris::DeviceTree::Libdevinfo;
      $sources{libdevinfo} = Solaris::DeviceTree::Libdevinfo->new;
    } elsif( $source eq 'path_to_inst' ) {
      require Solaris::DeviceTree::PathToInst;
      $sources{path_to_inst} = Solaris::DeviceTree::PathToInst->new;
    } elsif( $source eq 'filesystem' ) {
      require Solaris::DeviceTree::Filesystem;
      $sources{filesystem} = Solaris::DeviceTree::Filesystem->new;
    } else {
      croak "The specified source '$source' for the devicetree in unknown.";
    }
  }

  my $this = $pkg->_new_node();
  $this->{_sources} = \%sources;
  $this->{_child_initialized} = 0;

  return $this;
}

=pod

=item $devtree->DESTROY;

This methos removes all internal data structures which are associated
with this object.

=cut

sub DESTROY {
  my $this = shift;
}

=pod

=item @children = $devtree->child_nodes

This method returns a list with all children.

=cut

sub child_nodes {
  my ($this, %options) = @_;

  if( !$this->{_child_initialized} ) {
    my %child_nodes;
    foreach my $source (keys %{$this->{_sources}}) {
      my @source_child_nodes = $this->{_sources}->{$source}->child_nodes;
      foreach my $child (@source_child_nodes) {
        my $nodeid = $child->node_name;
        $nodeid .= "@" . $child->bus_addr if( defined $child->bus_addr && $child->bus_addr ne "" );
        $child_nodes{$nodeid}->{$source} = $child;
#print "Source: $source Node-ID: $nodeid Path: ", $child->devfs_path, "\n";
      }
    }
  
    foreach my $nodeid (keys %child_nodes) {
      my $child_node = $this->_new_node( parent => $this );
      $child_node->{_sources} = $child_nodes{$nodeid};
    }
    $this->{_child_initialized} = 1;
  }
  return $this->SUPER::child_nodes( %options );
}

sub sources {
  my ($this, %options) = @_;

  return keys %{$this->{_sources}};
}

=pod

=item $node = $devtree->parent_node

Returns the parent node for the object. If the object is toplevel,
then C<undef> is returned.

=cut

# This is inherited from ::Node

=pod

=item $node = $devtree->root_node

Returns the root node of the tree.

=cut

# This is inherited from ::Node

=pod

=item @siblings = $devtree->sibling_nodes

Returns the list of siblings for the object. A sibling is a child
from our parent, but not ourselves.

=cut

# This is inherited from ::Node

=pod

=item $path = $devtree->devfs_path

Returns the physical path assocatiated with this node.

=cut

# -> TODO: Include features to select specific sources,
#          avoid sanity checks, list available sources etc.

BEGIN {

for my $scalar_method (qw( devfs_path node_name binding_name bus_addr driver_name controller target lun slice )) {
  eval qq{
    sub $scalar_method {
      my (\$this, \%params) = \@_;
    
      my \$$scalar_method;
    
      # Unify information from all sources
      my \$selected_source;
      foreach my \$source (keys \%{\$this->{_sources}}) {
#print "Source: \$source\\n";
        my \$source_${scalar_method} = \$this->{_sources}->{\$source}->$scalar_method;
#print "P: \$source_${scalar_method}\\n";
        if( !defined \$$scalar_method ) {
          \$$scalar_method = \$source_${scalar_method};
          \$selected_source = \$source;
        } else {
          if( defined \$$scalar_method && defined \$source_${scalar_method} &&
              \$$scalar_method ne \$source_${scalar_method} ) {
            warn "Differing values for $scalar_method:\\n" .
              "  \$source: " . \$source_${scalar_method} . "\\n" .
              "  \$selected_source: " . \$$scalar_method . "\\n";
          }
        }
          
      }
      \$$scalar_method;
    }
  };
}
}

sub compatible_names {
  my ($this) = @_;
  foreach my $source (keys %{$this->{_sources}}) {
    my @compatible_names = $this->{_sources}->{$source}->compatible_names;
    return @compatible_names if( @compatible_names );
  }
  return ();
}

sub driver_ops {
  my ($this) = @_;
  foreach my $source (keys %{$this->{_sources}}) {
    my %driver_ops = $this->{_sources}->{$source}->driver_ops;
    return %driver_ops if( %driver_ops );
  }
  return ();
}

sub state {
  my ($this) = @_;
  foreach my $source (keys %{$this->{_sources}}) {
    my %state = $this->{_sources}->{$source}->state;
    return %state if( %state );
  }
  return ();
}

sub props {
  my ($this, %options) = @_;

  if( !exists $this->{_props} ) {
    my $old_source;
    foreach my $source (keys %{$this->{_sources}}) {
      my $props = $this->{_sources}->{$source}->props;
      if( defined $props ) {
        if( defined $this->{_props} ) {
          warn "Differing values for properties from sources $source and $old_source.\n";
        } else {
          $this->{_props} = $props;
          $old_source = $source;
        }
      }
    }
  }

  return $this->{_props};
}

sub prom_props {
  my ($this, %options) = @_;

  if( !exists $this->{_prom_props} ) {
    my $old_source;
    foreach my $source (keys %{$this->{_sources}}) {
      my $prom_props = $this->{_sources}->{$source}->prom_props;
      if( defined $prom_props ) {
        if( defined $this->{_prom_props} ) {
          warn "Differing values for prom_properties from sources $source and $old_source.\n";
        } else {
          $this->{_prom_props} = $prom_props;
          $old_source = $source;
        }
      }
    }
  }

  return $this->{_prom_props};
}

=pod

=item $nodename = $devtree->node_name;

Returns the name of the node.


=item $bindingname = $devtree->binding_name;

Returns the binding name for this node. The binding name
is the name used by the system to select a driver for the device.


=item $busadr = $devtree->bus_addr;

Returns the address on the bus for this node. C<undef> is returned
if a bus address has not been assigned to the device. A zero-length
string may be returned and is considered a valid bus address.


=item @compat_names = $devtree->compatible_names;

Returns the list of names from compatible device for the current node.
See the discussion of generic names in L<Writing  Device Drivers> for
a description of how compatible names are used by Solaris to achieve
driver binding for the node.


=item $devid = $devtree->devid

Returns the device ID for the node, if it is registered. Otherwise, C<undef>
is returned.


=item $drivername = $devtree->driver_name;

Returns the name of the driver for the node or C<undef> if the node
is not bound to any driver.


=item @minor = @{$node->minor_nodes}

Returns a list of all minor nodes which are associated with this node.
The minor nodes are of class L<Solaris::DeviceTree::MinorNode>.

=cut

sub minor_nodes {
  my ($this, %options) = @_;

  if( !exists $this->{_minor_nodes} ) {
    # Unify information from all sources
    my %minor_nodes;
    my %minor_node_sources;
    foreach my $source (keys %{$this->{_sources}}) {
      my $mlist = $this->{_sources}->{$source}->minor_nodes;
      $mlist ||= [];
      foreach my $minor_node (@$mlist) {
        $minor_nodes{$minor_node->name} ||= 
          Solaris::DeviceTree::MinorNode->new(
            node => $this,
            name => $minor_node->name,
          );
        my $m = $minor_nodes{$minor_node->name};

        my ($d, $e) = $minor_node->devt;
        if( defined $d || defined $e ) {
          my ($a, $b) = $m->devt;
          if( defined $a || defined $b ) {
            my ($major, $minor) = $m->devt;
            my ($major2, $minor2) = $minor_node->devt;
            if( $major != $major2 || $minor != $minor2 ) {
              carp "Differing values for major and minor:\n" .
                "  " . $minor_node_sources{$minor_node->name}{devt} . ": (" . $major . "," . $minor . ")\n" .
                "  " . $source . ": (" . $major2 . "," . $minor2 . ")\n";
            }
          } else {
            $m->{_major} = $d;
            $m->{_minor} = $e;
            $minor_node_sources{$minor_node->name}{devt} = $source,
          }
        }
        if( defined $minor_node->nodetype ) {
          if( defined $m->nodetype ) {
            if( $minor_node->nodetype ne $m->nodetype ) {
              carp "Differing values for nodetype:\n" .
                "  " . $minor_node_sources{$minor_node->name}{nodetype} . ": " . $m->nodetype . "\n" .
                "  " . $source . ": " . $minor_node->nodetype . "\n";
            }
          } else {
            $m->{_nodetype} = $minor_node->nodetype;
            $minor_node_sources{$minor_node->name}{nodetype} = $source,
          }
        }
#print "spec0\n";
        if( defined $minor_node->spectype ) {
#print "spec1\n";
          if( defined $m->spectype ) {
            if( $minor_node->spectype ne $m->spectype ) {
              carp "Differing values for spectype:\n" .
                "  " . $minor_node_sources{$minor_node->name}{nodetype} . ": " . $m->nodetype . "\n" .
                "  " . $source . ": " . $minor_node->nodetype . "\n";
            }
          } else {
            $m->{_nodetype} = $minor_node->nodetype;
            $minor_node_sources{$minor_node->name}{nodetype} = $source,
          }
        }
#print "spec0\n";
        if( defined $minor_node->spectype ) {
#print "spec1\n";
          if( defined $m->spectype ) {
            if( $minor_node->spectype ne $m->spectype ) {
              carp "Differing values for spectype:\n" .
                "  " . $minor_node_sources{$minor_node->name}{spectype} . ": " . $m->spectype . "\n" .
                "  $source: " . $minor_node->spectype . "\n";
            }
          } else {
#print "Setting spectype for $source to ", $minor_node->spectype, "\n";
            $m->{_spectype} = $minor_node->spectype;
            $minor_node_sources{$minor_node->name}{spectype} = $source,
          }
        }
      }
    }
    $this->{_minor_nodes} = [ values %minor_nodes ];
# print Dumper( $this->{_minor_nodes} );
  }

  return $this->{_minor_nodes};
}

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

=head1 BUGS

 * As an additional feature access to the libcfgadm should be included.

=cut

1;
