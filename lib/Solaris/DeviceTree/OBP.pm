
package Solaris::DeviceTree::OBP;

use strict;
use warnings;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw( resolve_path ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

our @ISA = qw( Exporter );

use Carp;

=pod

=head1 NAME

Solaris::DeviceTree::OBP - Manipulation of OBP pathes

=head1 SYNOPSIS

  use Solaris::DeviceTree::OBP( :DEFAULT );
  my $tree = new Solaris::DeviceTree;
  $bootpath = $tree->find_prop( devfs_path => '/chosen', prom_prop_name => 'bootpath' );
  $resolved_path = resolve_path( aliases => $tree->aliases, $bootpath->data( type => 'string' ) );

=head1 DESCRIPTION

The C<Solaris::DeviceTree::OBP> module implements functions for manipulating
OBP pathes according to L<IEEE 1275>.

=head2 EXPORT

The following functions are exported on demand:

=cut

# SplitComponent - Split OBP path component into parts
sub _split_component {
  my $component = shift;
  my $hex = '[0-9a-f]';
  my ($node_name, $unit_addr1, $unit_addr2, $arg) =
    ( $component =~ /
          ([^@]+)		# the part before '@' or all if no '@'
          (?:@(${hex}+)		# address part before ','
          (?:,(${hex}+)?)?)?	# address part after ','
          (?::(.*))*		# everything after ':'
        /xo);
  return [ node_name => $node_name,
           unit_addr1 => $unit_addr1,
           unit_addr2 => $unit_addr2,
           arg => $arg ];
}

# Main functions

sub _left_split {
  my ($string, $char) = @_;

  my ($initial, $remainder) = ($string =~ /^([^${char}]*)${char}?(.*)$/);
  return ($initial, $remainder);
}

sub _right_split {
  my ($string, $char) = @_;

  my ($initial, $remainder);
  if( $string =~ /$char/ ) {
    ($initial, $remainder) = ($string =~ /^(.*)${char}([^${char}]*)$/);
  } else {
    $initial = $string;
    $remainder = "";
  }
  return ($initial, $remainder);
}

=pod

=head3 $p = resolve_path( aliases => $aliases, path => "/path" );

This functions transforms the specified path in an alias-free
path using the path resolution procedure described in
C<1275.pdf - 4.3.1 Path resolution procedure> according to the specified
reference to an alias mapping.

=cut

# 1275.pdf - 4.3.1 Path resolution procedure (top level procedure)
sub resolve_path {
  my %options = @_;

  if( !exists $options{path} || !exists $options{aliases} ) {
    carp "The options 'path' and 'aliases' must be specified";
  }
  my $path_name = $options{path};
  my $aliases = $options{aliases};

  # If the pathname does not begin with "/", and its first node name
  # component is an alias, replace the alias with its expansion.
  if( $path_name !~ m[^/] ) {
    my ($head, $tail) = _left_split( $path_name, '/' );
    my ($alias_name, $alias_args) = _left_split( $head, ':' );
    if( exists $aliases->{ $alias_name } ) {
      $alias_name = $aliases->{ $alias_name };
      if( $alias_args ne '' ) {
        my ($alias_head, $alias_tail) = _right_split( $alias_name, '/' );
        my $dead_args;
        ($alias_tail, $dead_args) = _right_split( $alias_tail, ':' );
        if( $alias_head ne '' ) {
          $alias_tail = $alias_head . '/' . $alias_tail;
        }
        $alias_name = $alias_tail . ':' . $alias_args;
      }
      if( $tail eq '' ) {
        $path_name = $alias_name;
      } else {
        $path_name = $alias_name . '/' . $tail;
      }
    }
  }
  $path_name;
}

=pod

=head1 EXAMPLES

In the following example the resolved physical pathname of the
device last booted from is printed:

  use Solaris::DeviceTree::OBP( :DEFAULT );
  my $tree = new Solaris::DeviceTree;
  $bootpath = $tree->find_prop( devfs_path => '/chosen', prom_prop_name => 'bootpath' );
  $resolved_path = resolve_path( aliases => $tree->aliases, $bootpath->data( type => 'string' ) );
  print "Last boot from $resolved_path\n";


=head1 AUTHOR

Dagobert Michelsen, E<lt>dam@baltic-online.deE<gt>


=head1 SEE ALSO

=over 4

=item OPEN FIRMWARE HOME PAGE

  L<http://playground.sun.com/1275/home.html>

=cut

=cut

1;
