package Geo::ShapeFile::Shape;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Geo::ShapeFile;
use Geo::ShapeFile::Point;
use Data::HexDump;
use Data::Dumper;

our @ISA = qw(Exporter Geo::ShapeFile);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Geo::ShapeFile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] ); 
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ); 
our @EXPORT = qw( ); 
our $VERSION = substr q$Revision: 1.3 $, 10;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};

    bless($self, $class);

    return $self;
}

sub parse_shp {
	my $self = shift;

	$self->{source} = $self->{shp_data} = shift;

	$self->extract_ints('big','shp_record_number','shp_content_length');
	$self->extract_ints('little','shp_shape_type');

	my $parser = "parse_shp_".$self->type($self->{shp_shape_type});
	if($self->can($parser)) {
		$self->$parser();
	} else {
		croak "Can't parse shape_type ".$self->{shp_shape_type};
	}

	if(length($self->{shp_data})) {
		carp length($self->{shp_data})." byte".
			((length($self->{shp_data})>1)?'s':'')." remaining in buffer ".
			"after parsing ".$self->shape_type_text()." #".
			$self->shape_id();
		carp HexDump $self->{shp_data};
	}
}

sub parse_shp_Null {
	my $self = shift;
}

sub parse_shp_Point {
	my $self = shift;

	$self->extract_doubles('shp_X', 'shp_Y');
	$self->{shp_points} = [new Geo::ShapeFile::Point(
		X => $self->{shp_X},
		Y => $self->{shp_Y},
	)];
	$self->{shp_num_points} = 1;
}
#  Point
# Double        X       // X coordinate
# Double        Y       // Y coordinate

sub parse_shp_PolyLine {
	my $self = shift;

	$self->extract_bounds();
	$self->extract_parts_and_points();
}
#  PolyLine
# Double[4]             Box         // Bounding Box
# Integer               NumParts    // Number of parts
# Integer               NumPoints   // Number of points
# Integer[NumParts]     Parts       // Index to first point in part
# Point[NumPoints]      Points      // Points for all parts

sub parse_shp_Polygon {
	my $self = shift;

	$self->extract_bounds();
	$self->extract_parts_and_points();
}
#  Polygon
# Double[4]                     Box                     // Bounding Box
# Integer                       NumParts        // Number of Parts
# Integer                       NumPoints       // Total Number of Points
# Integer[NumParts]             Parts           // Index to First Point in Part
# Point[NumPoints]              Points          // Points for All Parts

sub parse_shp_MultiPoint {
	my $self = shift;

	$self->extract_bounds();
	$self->extract_ints('little','shp_num_points');
	$self->extract_points($self->{shp_num_points},'shp_points');
}
#  MultiPoint
# Double[4]                     Box                     // Bounding Box
# Integer                       NumPoints       // Number of Points
# Point[NumPoints]      Points          // The points in the set

sub parse_shp_PointZ {
	my $self = shift;

	$self->parse_shp_Point();
	$self->extract_doubles('shp_Z', 'shp_M');
	$self->{shp_points}->[0]->Z($self->{shp_Z});
	$self->{shp_points}->[0]->M($self->{shp_M});
}
#  PointZ
# Point +
# Double Z
# Double M

sub parse_shp_PolyLineZ {
	my $self = shift;

	$self->parse_shp_PolyLine();
	$self->extract_z_data();
	$self->extract_m_data();
}
#  PolyLineZ
# PolyLine +
# Double[2]             Z Range
# Double[NumPoints]     Z Array
# Double[2]             M Range
# Double[NumPoints]     M Array

sub parse_shp_PolygonZ {
	my $self = shift;

	$self->parse_shp_Polygon();
	$self->extract_z_data();
	$self->extract_m_data();
}
#  PolygonZ
# Polygon +
# Double[2]             Z Range
# Double[NumPoints]     Z Array
# Double[2]             M Range
# Double[NumPoints]     M Array

sub parse_shp_MultiPointZ {
	my $self = shift;

	$self->parse_shp_MultiPoint();
	$self->extract_z_data();
	$self->extract_m_data();
}
#  MultiPointZ
# MultiPoint +
# Double[2]         Z Range
# Double[NumPoints] Z Array
# Double[2]         M Range
# Double[NumPoints] M Array

sub parse_shp_PointM {
	my $self = shift;

	$self->parse_shp_Point();
	$self->extract_doubles('shp_M');
	$self->{shp_points}->[0]->M($self->{shp_M});
}
#  PointM
# Point +
# Double M // M coordinate

sub parse_shp_PolyLineM {
	my $self = shift;

	$self->parse_shp_PolyLine();
	$self->extract_m_data();
}
#  PolyLineM
# PolyLine +
# Double[2]             MRange      // Bounding measure range
# Double[NumPoints]     MArray      // Measures for all points

sub parse_shp_PolygonM {
	my $self = shift;

	$self->parse_shp_Polygon();
	$self->extract_m_data();
}
#  PolygonM
# Polygon +
# Double[2]             MRange      // Bounding Measure Range
# Double[NumPoints]     MArray      // Measures for all points

sub parse_shp_MultiPointM {
	my $self = shift;

	$self->parse_shp_MultiPoint();
	$self->extract_m_datextract_m_data();
}
#  MultiPointM
# MultiPoint
# Double[2]         MRange      // Bounding measure range
# Double[NumPoints] MArray      // Measures

sub parse_shp_MultiPatch {
	my $self = shift;

	$self->extract_bounds();
	$self->extract_parts_and_points();
	$self->extract_z_data();
	$self->extract_m_data();
}
# MultiPatch
# Double[4]           BoundingBox
# Integer             NumParts
# Integer             NumPoints
# Integer[NumParts]   Parts
# Integer[NumParts]   PartTypes
# Point[NumPoints]    Points
# Double[2]           Z Range
# Double[NumPoints]   Z Array
# Double[2]           M Range
# Double[NumPoints]   M Array

sub extract_bounds {
	my $self = shift;

	$self->extract_doubles(qw/shp_x_min shp_y_min shp_x_max shp_y_max/);
}

sub extract_ints {
	my $self = shift;
	my $end = shift;
	my @what = @_;

	my $template = ($end =~ /^l/i)?'V':'N';

	$self->extract_and_unpack(4, $template, @what);
	foreach(@what) {
		$self->{$_} = $self->{$_};
	}
}

sub extract_count_ints {
	my $self = shift;
	my $count = shift;
	my $end = shift;
	my $label = shift;

	my $template = ($end =~ /^l/i)?'V':'N';

	my $tmp = substr($self->{shp_data},0,($count*4),'');
	my @tmp = unpack($template."[$count]",$tmp);
		
	$self->{$label} = [@tmp];
}

sub extract_doubles {
	my $self = shift;
	my @what = @_;

	$self->extract_and_unpack(8, 'd', @what);
}

sub extract_count_doubles {
	my $self = shift;
	my $count = shift;
	my $label = shift;

	my $tmp = substr($self->{shp_data},0,$count*8,'');
	my @tmp = unpack("d[$count]",$tmp);

	$self->{$label} = [@tmp];
}

sub extract_points {
	my $self = shift;
	my $count = shift;
	my $label = shift;

	my $data = substr($self->{shp_data},0,$count*16,'');
	my @ps = unpack("d*",$data);

	my @p = (); # points
	while(@ps) {
		push(@p, new Geo::ShapeFile::Point(X => shift(@ps), Y => shift(@ps)));
	}
	$self->{$label} = [@p];
}

sub extract_and_unpack {
	my $self = shift;
	my $size = shift;
	my $template = shift;
	my @what = @_;

	foreach(@what) {
		my $tmp = substr($self->{shp_data},0,$size,'');
		$self->{$_} = unpack($template,$tmp);
	}
}

sub num_parts { shift()->{shp_num_parts}; }
sub parts {
	my $self = shift;

	my $parts = $self->{shp_parts};
	if(wantarray) {
		if($parts) {
			return @{$parts};
		} else {
			return ();
		}
	} else {
		return $parts;
	}
}

sub num_points { shift()->{shp_num_points}; }
sub points {
	my $self = shift;

	my $points = $self->{shp_points};
	if(wantarray) {
		if($points) {
			return @{$points};
		} else {
			return ();
		}
	} else {
		return $points;
	}
}

sub get_part {
	my $self = shift;
	my $index = shift;

	$index -= 1; # shift to a 0 index

	my @parts = $self->parts;
	my @points = $self->points;
	my $beg = $parts[$index] || 0;
	my $end = $parts[$index+1] || 0;
	$end -= 1;
	if($end < 0) { $end = $#points; }

	return @points[$beg .. $end];
}

sub shape_type {
	my $self = shift;

	return $self->{shp_shape_type};
}

sub shape_id {
	my $self = shift;
	return $self->{shp_record_number};
}

sub extract_z_data {
	my $self = shift;

	$self->extract_doubles('shp_z_min','shp_z_max');
	$self->extract_count_doubles($self->{shp_num_points}, 'shp_z_data');
}

sub extract_m_data {
	my $self = shift;

	$self->extract_doubles('shp_m_min','shp_m_max');
	$self->extract_count_doubles($self->{shp_num_points}, 'shp_m_data');
}

sub extract_parts_and_points {
	my $self = shift;

	$self->extract_ints('little','shp_num_parts','shp_num_points');
	$self->extract_count_ints($self->{shp_num_parts},'little','shp_parts');
	$self->extract_points($self->{shp_num_points},'shp_points');
}

sub x_min { shift()->{shp_x_min}; }
sub x_max { shift()->{shp_x_max}; }
sub y_min { shift()->{shp_y_min}; }
sub y_max { shift()->{shp_y_max}; }
sub z_min { shift()->{shp_z_min}; }
sub z_max { shift()->{shp_z_max}; }
sub m_min { shift()->{shp_m_min}; }
sub m_max { shift()->{shp_m_max}; }

sub has_point {
	my $self = shift;
	my $point = shift;

	return 0 unless $self->bounds_contains_point($point);

	foreach($self->points) {
		return 1 if $_ == $point;
		#if($point->X == $_->X && $point->Y == $_->Y) { return 1; }
	}

	return 0;
}

sub get_segments {
	my $self = shift;
	my $part = shift;

	my @points = $self->get_part($part);
	my @segments = ();
	for(0 .. $#points-1) {
		push(@segments,[$points[$_],$points[$_+1]]);
	}
	return @segments;
}

1;
__END__
=head1 NAME

Geo::ShapeFile::Shape - Geo::ShapeFile utility class.

=head1 SYNOPSIS

  use Geo::ShapeFile::Shape;

  my $shape = new Geo::ShapeFile::Shape;
  $shape->parse_shp($shape_data);

=head1 ABSTRACT

  This is a utility class for Geo::ShapeFile that represents shapes.

=head1 DESCRIPTION

This is the Geo::ShapeFile utility class that actually contains shape data
for an individual shape from the shp file.

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item new()

Creates a new Geo::ShapeFile::Shape object, takes no arguments and returns
the created object.  Normally Geo::ShapeFile does this for you when you call
it's get_shp_record() method, so you shouldn't need to create a new object.
(Eventually this module will have support for _creating_ shapefiles rather
than just reading them, then this method will become important.

=item num_parts()

Returns the number of parts that make up this shape.

=item num_points()

Returns the number of points that make up this shape.

=item points()

Returns an array of Geo::ShapeFile::Point objects that contains all the points
in this shape.  Note that because a shape can contain multiple segments, which
may not be directly connected, you probably don't want to use this to retrieve
points which you are going to plot.  If you are going to draw the shape, you
probably want to use get_part() to retrieve the individual parts instead.

=item get_part($part_index);

Returns the specified part of the shape.  This is the information you want if
you intend to draw the shape.  You can iterate through all the parts that make
up a shape like this:

  for(1 .. $obj->num_parts) {
    my $part = $obj->get_part($_);
    # ... do something here, draw a map maybe
  }

=item shape_type()

Returns the numeric type of this shape, use Geo::ShapeFile::type() to determine
the human-readable name from this type.

=item shape_id()

Returns the id number for this shape, as contained in the shp file.

=item x_min() x_max() y_min() y_max()

=item z_min() z_max() m_min() m_max()

Returns the minimum/maximum ranges of the X, Y, Z, or M values for this shape,
as contained in it's header information.

=item has_point($point)

Returns true if the point provided is one of the points in the shape.  Note
that this does a simple comparison with the points that make up the shape, it
will not find a point that falls along a connecting line between two points in
the shape.  See the Geo::ShapeFile::Point documentation for a note about how
to exclude Z and/or M data from being considered when matching points.

=item get_segments($part)

Returns an array consisting of array hashes, which contain the points for
each segment of a multi-segment part.

=back

=head1 SEE ALSO

Geo::ShapeFile

=head1 AUTHOR

Jason Kohles, E<lt>jason@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
