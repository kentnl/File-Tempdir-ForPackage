use strict;
use warnings;

package File::Tempdir::ForPackage;
BEGIN {
  $File::Tempdir::ForPackage::AUTHORITY = 'cpan:KENTNL';
}
{
  $File::Tempdir::ForPackage::VERSION = '0.1.0';
}

# ABSTRACT: Easy temporary directories associated with packages.

use Moo;
use Sub::Quote qw( quote_sub );


has package => (
  is      => 'ro',
  default => quote_sub q| scalar [ caller() ]->[0] |,
);

has with_version   => ( is => 'ro', default => quote_sub q{ undef } );
has with_timestamp => ( is => 'ro', default => quote_sub q{ undef } );
has with_pid       => ( is => 'ro', default => quote_sub q{ undef } );
has num_random     => (
  is  => 'ro',
  isa => (
    ## no critic ( RequireInterpolationOfMetachars )
    quote_sub q|require File::Temp;|
      . q| die "num_random ( $_[0] ) must be >= " . File::Temp::MINX() |
      . q| if $_[0] < File::Temp::MINX(); |
  ),
  default => quote_sub q{ 8 },
);
has _preserve => ( is => 'rw', default => quote_sub q{ undef } );

has _dir => ( is => 'lazy', clearer => 1, predicate => 1 );

sub preserve {
  my ( $self, @args ) = @_;
  if ( not @args ) {
    $self->_preserve(1);
    return 1;
  }
  else {
    if ( not $args[0] ) {
      $self->_preserve(0);
      return;
    }
    else {
      $self->_preserve(1);
      return 1;
    }
  }
}

sub _clean_pkg {
  my ($package) = @_;
  $package =~ s/::/-/gsmx;
  $package =~ s/[^\w-]+/_/gsmx;
  return $package;
}

sub _clean_ver {
  my ($ver) = @_;
  return 'versionundef' if not defined $ver;
  $ver =~ s/[^v\d_.]+/_/gsmx;
  return $ver;
}

sub _build__dir {
  my ($self) = shift;
  require File::Temp;

  my $template = q{perl-};
  $template .= _clean_pkg( $self->package );

  if ( $self->with_version ) {
    $template .= q{-} . _clean_ver( $self->package->VERSION );
  }
  if ( $self->with_timestamp ) {
    $template .= q{-} . time;
  }
  if ( $self->with_pid ) {
    ## no critic ( ProhibitPunctuationVars )
    $template .= q{-} . $$;
  }
  $template .= q{-} . ( 'X' x $self->num_random );

  my $dir = File::Temp::tempdir( $template, TMPDIR => 1, );
  return $dir;
}

sub dir {
  my ($self) = shift;
  return $self->_dir;
}

sub cleanse {
  my ($self) = shift;
  return $self unless $self->_has_dir;
  if ( not $self->_preserve ) {
    require File::Path;
    File::Path::rmtree( $self->_dir, 0, 0 );
  }
  $self->_clear_dir;
  return $self;
}

sub run_once_in {
  my ( $self, $options, $code ) = @_;
  $code = $options unless defined $code;
  require File::pushd;
  {
    my $marker = File::pushd::pushd( $self->dir );
    $code->( $self->dir );
  }

  # Dir POP.
  $self->cleanse;
  return $self;
}

sub DEMOLISH {
  my ( $self, $in_g_d ) = @_;
  $self->cleanse;
  return;
}

no Moo;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

File::Tempdir::ForPackage - Easy temporary directories associated with packages.

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This is mostly an interface wrapper for File::Temp::tempdir, stealing code from File::Tempdir;

=over 4

=item * I constantly forget how File::Tempdir works

=item * I often want a tempdir with the name of the package working with it enshrined in the path

=item * I constantly forget the magic glue syntax to get a folder inside a System Tempdir with a custom prefix and a user defined length of random characters.

=back

And this is designed to solve this simply.

use File::TempDir::ForPackage;

  my $tempdir = File::TempDir::ForPackage->new( package => __PACKAGE__ , use_version => 1 );
  my $dir = $tempdir->dir();

do shit in `$dir`
$dir on Linux will be something like /tmp/perl-Some-Package-maybewith-a-VERSION-AFG14561/
so if it crashes and leaves a tempdir behind, you will know who left that tempdir behind and have a way of cleaning it up.

When $tempdir is destroyed, $dir will be cleaned;

Additionally:

  $dir->run_once_in(sub{
    ...
  });

Is there for people who don't trust scope auto-cleansing and want to know when the dir is reaped.

Additionally, this code can be run in a tight loop creating and destroying lots of similary named tempdirs without risk of conflict.

  for my $i ( 0 .. 30  ) {
    $dir->run_once_in(sub {
      system 'find $PWD';
    });
  }

This emits something like:

  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-PzH4BD
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-5h8nkG
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-UXKt4S
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-Lqg2aW
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-DkNeq6
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-jRI_zF
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-j0_Gt1
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-iX1ddT
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-ZmvikK
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-QNGOUF
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-6wssvL
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-ZmwZxl
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-wIzRTs
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-xetCym
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-8Y0vyX
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-Zlqt6X
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-U5Z_Sa
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-sKmow1
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-rUND95
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-XjPSGF
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-ec8sZZ
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-_4NBwX
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-xM9i6l
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-p3FhJf
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-Zv0sso
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-rP8cAi
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-iade0x
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-fsDDPy
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-FeCcfZ
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-ta5yfg
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-rdcQhF

Except of course, with a package of your choosing, and possibly that packages version.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

