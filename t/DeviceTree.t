# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use strict;
use warnings;

BEGIN { plan tests => 92 };

sub test_all_nodes {
  my ($tree, $testfunc) = @_;
  my @child_nodes = ($tree);
  while( @child_nodes ) {
    local $_ = shift @child_nodes;
    if( !$testfunc->() ) {
      warn "Function has not succeeded for node ", $_->devfs_path, "\n";
      return 0;
    }
    push @child_nodes, $_->child_nodes;
  }
  return 1;
}

# This contains 21 tests for the tree applied for all kinds of trees
sub test_Solaris_DeviceTree {
  my $tree = shift;

  # Test 1 - traverse the tree to all childs and see if there is at most instance per child
  my %seen_childs;
  ok( test_all_nodes( $tree, sub {
      return 0 if( exists $seen_childs{$_} );
      $seen_childs{$_} = 1;
    } ), 1 );
  
  # Test 2 - traverse the tree to all childs and see if there is at most instance per path
  # (helps finding corrupted child generation).
  # This test includes checking the 'devfs_path' method.
  my %seen_pathes;
  ok( test_all_nodes( $tree, sub {
      return 0 if( exists $seen_pathes{$_->devfs_path} );
      $seen_childs{$_->devfs_path} = 1;
    } ), 1 );
  
  # Test 3 - test if we have at least three levels and at least 10 nodes total
  {
    my %level;
    my @child_nodes = ($tree);
    $level{$tree} = 1;
    my $maxlevel = 1;
    my $nodecount = 1;
    while( @child_nodes ) {
      my $node = shift @child_nodes;
      $nodecount++;
      my @children = $node->child_nodes;
      foreach my $child (@children) {
        $level{$child} = $level{$node} + 1;
        $maxlevel = $level{$child} if( $level{$child} > $maxlevel );
      }
      push @child_nodes, @children;
    }
    ok( $maxlevel >= 3 && $nodecount >= 10 );
  }
  
  # Test 4 - check topology of tree according to parent/child relationship of root node
  {
    my @child_nodes = ($tree);
    my $parent_ok = 1;
    ok( !defined $tree->parent_node );
  
  # Test 5 - continue test 5 for the rest of the tree
    while( @child_nodes ) {
      my $parent = shift @child_nodes;
      my @children = $parent->child_nodes;
      foreach my $child (@children) {
        $parent_ok = 0 if( $parent ne $child->parent_node );
      }
      push @child_nodes, @children;
    }
    ok( $parent_ok, 1 );
  }
  
  # Test 6 - check for correct root node reference from all nodes
  ok( test_all_nodes( $tree, sub { $tree eq $_->root_node } ), 1 );
  
  # Test 7 - check siblings for all nodes
  {
    my @child_nodes = ($tree);
    my $siblings_ok = 1;
    while( @child_nodes ) {
      my $node = shift @child_nodes;
      foreach my $sibling ($node->sibling_nodes) {
        $siblings_ok = 0 if( $node eq $sibling );
        $siblings_ok = 0 if( $node->parent_node ne $sibling->parent_node );
      }
      push @child_nodes, $node->child_nodes;
    }
    ok( $siblings_ok, 1 );
  }
  
  # Test 8 - check node_name
  ok( test_all_nodes( $tree, sub { $_->node_name; 1 } ), 1 );
  
  # Test 9 - binding_name
  ok( test_all_nodes( $tree, sub { $_->binding_name; 1 } ), 1 );
  
  # Test 10 - bus_addr
  ok( test_all_nodes( $tree, sub { $_->bus_addr; 1 } ), 1 );
  
  # Test 11 - compatible_names
  ok( test_all_nodes( $tree, sub { $_->compatible_names; 1 } ), 1 );
  
  # Test 12 - devid
  ok( test_all_nodes( $tree, sub { $_->devid; 1 } ), 1 );
  
  # Test 13 - driver_name
  ok( test_all_nodes( $tree, sub { $_->driver_name; 1 } ), 1 );
  
  # Test 14 - driver_ops
  ok( test_all_nodes( $tree, sub { $_->driver_ops; 1 } ), 1 );
  
  # Test 15 - instance
  ok( test_all_nodes( $tree, sub { $_->instance; 1 } ), 1 );
  
  # Test 16 - state
  ok( test_all_nodes( $tree, sub { $_->state; 1 } ), 1 );
  
  # Test 17 - nodeid
  ok( test_all_nodes( $tree, sub { $_->nodeid; 1 } ), 1 );
  
  # Test 18 - is_pseudo_node, is_sid_node, is_prom_node
  ok( test_all_nodes( $tree, sub {
      $_->is_pseudo_node;
      $_->is_sid_node;
      $_->is_prom_node;
      1
    } ), 1 );
  
  # Test 19 - props
  # -> TODO
  ok( test_all_nodes( $tree, sub { $_->props; 1 } ), 1 );
  
  # Test 20 - prom_props
  # -> TODO
  ok( test_all_nodes( $tree, sub { $_->prom_props; 1 } ), 1 );
  
  # Test 21 - minor_nodes
  # -> TODO
  ok( test_all_nodes( $tree, sub { $_->minor_nodes; 1 } ), 1 );
  
}

{
  # Test 1 - load the module
  require Solaris::DeviceTree::Libdevinfo;
  ok( 1 );

  # Test 2 - make a tree
  my $tree = Solaris::DeviceTree::Libdevinfo->new;
  ok( 1 );

  # Test 3-23 - test the tree
  test_Solaris_DeviceTree( $tree );
}

{
  # Test 24 - load the module
  require Solaris::DeviceTree::PathToInst;
  ok( 1 );

  # Test 25 - make a tree
  my $tree = Solaris::DeviceTree::PathToInst->new;
  ok( 1 );

  # Test 26-46 - test the tree
  test_Solaris_DeviceTree( $tree );
}

{
  # Test 47 - load the module
  require Solaris::DeviceTree::Filesystem;
  ok( 1 );

  # Test 48 - make a tree
  my $tree = Solaris::DeviceTree::Filesystem->new;
  ok( 1 );

  # Test 49-69 - test the tree
  test_Solaris_DeviceTree( $tree );
}

{
  # Test 70 - load the module
  require Solaris::DeviceTree;
  ok( 1 );

  # Test 71 - make a tree
  my $tree = Solaris::DeviceTree->new( use => [ qw( libdevinfo path_to_inst filesystem ) ], );
  ok( 1 );

  # Test 72-92 - test the tree
  test_Solaris_DeviceTree( $tree );
}

exit 0;
