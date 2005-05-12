use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'			=> 'Geo::ShapeFile',
	'VERSION_FROM'	=> 'ShapeFile.pm', # finds $VERSION
	'PREREQ_PM'		=> {
		'Carp'				=> 0,
		'IO::File'			=> 0,
		'Math::Trig'		=> 0,
	}, # e.g., Module::Name => 1.1
	($] >= 5.005 ? (
		ABSTRACT_FROM		=> 'ShapeFile.pm',
		AUTHOR				=> 'Jason Kohles <email@jasonkohles.com>',
	) : ()),
);
