package Geo::ShapeFile::Point;

use 5.008;
use strict;
use warnings;
use Data::Dumper;

use overload
	'==' => 'eq',
	'eq' => 'eq',
	'""' => 'stringify',
;

my %config = (
	comp_includes_z		=> 1,
	comp_includes_m		=> 1,
);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( ); 
our @EXPORT = qw( ); 
our $VERSION = substr q$Revision: 1.3 $, 10;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {@_};

    bless($self, $class);

    return $self;
}

sub var {
	my $self = shift;
	my $var = shift;

	if(@_) {
		return $self->{$var} = shift;
	} else {
		return $self->{$var};
	}
}

sub X { shift()->var('X',@_); }
sub Y { shift()->var('Y',@_); }
sub Z { shift()->var('Z',@_); }
sub M { shift()->var('M',@_); }

sub import {
	my $self = shift;
	my %args = @_;

	foreach(keys %args) { $config{$_} = $args{$_}; }
}

sub eq {
	my $left = shift;
	my $right = shift;

	if($config{comp_includes_z} && (defined $left->Z || defined $right->Z)) {
		return 0 unless $left->Z == $right->Z;
	}
	if($config{comp_includes_m} && (defined $left->M || defined $right->M)) {
		return 0 unless $left->M == $right->M;
	}
	return ($left->X == $right->X && $left->Y == $right->Y);
}

sub stringify {
	my $self = shift;

	my @foo = ();
	foreach(qw/X Y Z M/) {
		if(defined $self->$_()) {
			push(@foo,"$_=".$self->$_());
		}
	}
	my $r = "Point(".join(',',@foo).")";
}

1;
__END__
=head1 NAME

Geo::ShapeFile::Point - Geo::ShapeFile utility class.

=head1 SYNOPSIS

  use Geo::ShapeFile::Point;
  use Geo::ShapeFile;

  my $point = new Geo::ShapeFile::Point(X => 12345, Y => 54321);

=head1 ABSTRACT

  This is a utility class, used by Geo::ShapeFile.

=head1 DESCRIPTION

This is a utility class, used by Geo::ShapeFile to represent point data,
you should see the Geo::ShapeFile documentation for more information.

=head2 EXPORT

Nothing.

=head2 IMPORT NOTE

This module uses overloaded operators to allow you to use == or eq to compare
two point objects.  By default points are considered to be equal only if their
X, Y, Z, and M attributes are equal.  If you want to exclude the Z or M
attributes when comparing, you should use comp_includes_z or comp_includes_m 
when importing the object.  Note that you must do this before you load the
Geo::ShapeFile module, or it will pass it's own arguments to import, and you
will get the default behavior:

  DO:

  use Geo::ShapeFile::Point comp_includes_m => 0, comp_includes_z => 0;
  use Geo::ShapeFile;

  DONT:

  use Geo::ShapeFile;
  use Geo::ShapeFile::Point comp_includes_m => 0, comp_includes_z => 0;
  (Geo::ShapeFile alread imported Point for you)

=head1 METHODS

=over 4

=item new(X => $x, Y => $y)

Creates a new Geo::ShapeFile::Point object, takes a has consisting of X, Y, Z,
and/or M values to be assigned to the point.

=item X() Y() Z() M()

Set/retrieve the X, Y, Z, or M values for this object.

=back

=head1 SEE ALSO

Geo::ShapeFile

=head1 AUTHOR

Jason Kohles, E<lt>jason@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002,2003 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
