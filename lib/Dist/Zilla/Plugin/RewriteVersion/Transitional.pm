use strict;
use warnings;
package Dist::Zilla::Plugin::RewriteVersion::Transitional;
# git description: 41ab571

# ABSTRACT: ease the transition to [RewriteVersion] in your distribution
# KEYWORDS: plugin version rewrite munge module
# vim: set ts=8 sw=4 tw=78 et :
{ our $VERSION = '0.001'; } # TRIAL
use Moose;
extends 'Dist::Zilla::Plugin::RewriteVersion';

use Moose::Util::TypeConstraints;
use Dist::Zilla::Util;
use namespace::autoclean;

has fallback_version_provider => (
    is => 'ro', isa => 'Str',
);

has _fallback_version_provider_args => (
    is => 'ro', isa => 'HashRef[Str]',
);

has _fallback_version_provider_obj => (
    is => 'ro',
    isa => role_type('Dist::Zilla::Role::VersionProvider'),
    lazy => 1,
    default => sub {
        my $self = shift;
        Dist::Zilla::Util->expand_config_package_name($self->fallback_version_provider)->new(
            zilla => $self->zilla,
            plugin_name => 'via [RewriteVersion::Transitional]',
            %{ $self->_fallback_version_provider_args },
        );
    },
);

around BUILDARGS => sub
{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig(@_);

    my %extra_args = %$args;
    delete @extra_args{qw(zilla plugin_name fallback_version_provider skip_version_provider)};

    return +{ %$args, _fallback_version_provider_args => \%extra_args };
};

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        map { $_ => $self->$_ } qw(fallback_version_provider _fallback_version_provider_args),
    };

    return $config;
};

around provide_version => sub
{
    my $orig = shift;
    my $self = shift;

    return if $self->skip_version_provider;

    my $version = $self->$orig(@_);
    return $version if defined $version;

    $self->log_debug([ 'no version found in environment or file; falling back to %s', $self->fallback_version_provider ]);
    return $self->_fallback_version_provider_obj->provide_version;
};

around rewrite_version => sub
{
    my $orig = shift;
    my $self = shift;
    my ($file, $version) = @_;

    # TODO!
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RewriteVersion::Transitional - ease the transition to [RewriteVersion] in your distribution

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your F<dist.ini>:

    [RewriteVersion::Transitional]
    fallback_version_provider = Git::NextVersion
    version_regexp = ^v([\d._]+)$

=head1 DESCRIPTION

=for stopwords BumpVersionAfterRelease OurPkgVersion PkgVersion

This is a L<Dist::Zilla> plugin that subclasses
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>, to allow plugin
bundles to transition from L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion> or
L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion> to
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> without having to
manually edit the F<dist.ini> or any F<.pm> files.

=head2 Determining the distribution version

As with L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>, the version
can be overridden with the C<V> environment variable, or provided through some
other means by setting C<skip_version_provider = 1>.  Then, the
L<Dist::Zilla/main module> in the distribution is checked for a C<$VERSION>
assignment.  If one is not found, then the plugin named by the
C<fallback_version_provider> is instantiated (with any extra configuration
options provided) and called to determine the version.

=head2 Munging the modules

When used in a distribution where the F<.pm> file(s) does not contain a
C<$VERSION> declaration, this plugin will add one. If one is already present,
it leaves it alone, acting just as
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> would.

You would then use L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
to increment the C<$VERSION> in the F<.pm> files in the repository, as normal.

=head1 CONFIGURATION OPTIONS

Configuration is the same as in
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>, with the addition of:

=head2 fallback_version_provider

Specify the name (in abbreviated form) of the plugin to use as a version
provider if the version was not already set with the C<V> environment
variable.  Not used if
L<Dist::Zilla::Plugin::RewriteVersion/skip_version_provider> is true.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-RewriteVersion-Transitional>
(or L<bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion>

=item *

L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>

=item *

L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
