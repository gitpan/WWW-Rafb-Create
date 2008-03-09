package WWW::Rafb::Create;

use warnings;
use strict;

our $VERSION = '0.001';

use Carp;
use URI;
use LWP::UserAgent;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw(
    uri
    error
    response
    timeout
    ua
);

use overload q|""| => sub { shift->uri };

sub new {
    my $class = shift;
    croak "Must have even number of arguments to the constructor"
        if @_ & 1;

    my %args = @_;
    
    unless ( $args{timeout} ) {
        $args{timeout} = 30;
    }
    unless ( $args{ua} ) {
        $args{ua} = LWP::UserAgent->new(
            timeout => $args{timeout},
            agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US;'
                        . ' rv:1.8.1.12) Gecko/20080207 Ubuntu/7.10 (gutsy)'
                        . ' Firefox/2.0.0.12',

        );
    }

    my $self = bless {}, $class;
    $self->$_( $args{$_} ) for qw(ua timeout);
    return $self;
}

sub paste {
    my $self = shift;
    my %args = ( text => shift );

    return $self->_set_error(
        "Missing, undefined or empty first argument (the text to paste)"
    ) unless defined $args{text} and length $args{text};

    if ( @_ ) {
        croak "Must have ether one or even number of arguments to paste()"
            if @_ & 1;

        %args = ( @_, text => $args{text} );
        $args{ +lc } = delete $args{ $_ } for keys %args;

        %args = (
            lang        => 'plain text',
            tabs    => 'no',
            %args,
        );
        $args{cvt_tabs} = lc delete $args{tabs};
        $args{lang}     = lc delete $args{lang};

        return $self->_set_error( 'Missing or undefined `text` argument' )
            unless defined $args{text};

        return $self->_set_error('Invalid `lang` was specified')
            unless exists $self->_make_valid_languages->{ $args{lang} };

        return $self->_set_error('Invalid `tabs` was specified')
            unless exists $self->_make_valid_tabs->{ $args{cvt_tabs} };
    }
    else {
        @args{ qw( lang          cvt_tabs  desc  nick) }
        = (        'plain text', 'no',     '',   '' );
    }

    @args{ qw(lang cvt_tabs) } = (
        $self->_make_valid_languages->{ delete $args{lang} },
        $self->_make_valid_tabs->{ delete $args{cvt_tabs} },
    );

    $self->$_(undef) for qw(error uri);

    my %form = ( %args, submit  => 'Paste', );
    my $uri = URI->new('http://rafb.net/paste/paste.php');

    my $response = $self->response( $self->ua->post( $uri, \%form ) );

    if ( $response->code == 302 ) {
        my $paste_uri = URI->new($response->header('Location'));
        if ( $paste_uri eq 'http://rafb.net/p/toofast.html' ) {
            return $self->_set_error('Pasting too fast (Flood protection)');
        }
        else {
            return $self->uri( $paste_uri );
        }
    }
    else {
        return $self->_set_error(
            'Request failed: ' . $response->status_line
        );
    }
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub _make_valid_languages {
    return {
        c89     => 'C89',
        c       => 'C',
        'c++'   => 'C++',
        'c#'    => 'C#',
        'java'  => 'Java',
        pascal  => 'Pascal',
        perl    => 'Perl',
        php     => 'PHP',
        'pl/i'  => 'PL/I',
        python  => 'Python',
        ruby    => 'Ruby',
        sql     => 'SQL',
        vb      => 'VB',
        'plain text wrap'   => 'Plain Text Wrap',
        'plain text'        => 'Plain Text',
    };
}

sub _make_valid_tabs {
    return {
        'no' => 'No',
        map { $_ => $_ } 2..6, 8
    };
}

1;
__END__

=head1 NAME

WWW::Rafb::Create - create new pastes on http://rafb.net

=head1 SYNOPSIS

    use WWW::Rafb::Create;

    my $paster = WWW::Rafb::Create->new;

    $paster->paste( $text )
        or die $paster->error;

    print "Your paste can be found on $paster\n";


=head1 DESCRIPTION

The module provides means to create new pastes on L<http://rafb.net> paste
site.

The L<WWW::Rafb> module offers a similiar functionality. However, it does
not pass the test suite, and the author does not seem to care (last update
was close to a year ago). As well, the module seems to have a bit of an
"uncomfortable" interface, including not being able to paste text from
a scalar easily.

=head1 CONSTRUCTOR

=head2 new

    my $paster = WWW::Rafb::Create->new;

    my $paster = WWW::Rafb::Create->new(
        timeout => 10,
    );

    my $paster = WWW::Rafb::Create->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new yummy juicy WWW::Rafb::Create
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for pasting. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for pasting, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Rafb::Create>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 paste

    $paster->paste( 'lotsa text' )
        or die $paster->error;

    $paster->paste(
        'lotsa text',
        nick => 'Zoffix',
        desc => 'some text',
        tabs => 8,
        lang => 'Perl',
    ) or die $paster->error;

Instructs the object to create a new paste on L<http://rafb.net/paste/>.
On success returns an L<URI> object pointing to a newly created paste, but
you don't have to store it, see C<uri()> method which is also overloaded
for this module. On failure returns either C<undef> or an empty list
depending on the context and the reason for error will be available via
C<error()> method.

Takes one mandatory argument, as well as several key/value
optional arguments. The first argument is a scalar contaning the text you
want to paste. The optional key/value arguments are as follows:

=head3 nick

    $paster->paste( 'text', nick => 'Zoffix' )

B<Optional>. Takes a scalar contaning the nick of the poster. B<By default>
is not specified resulting in C<Anonymous> as nick.

=head3 desc

    $paster->paste( 'text', desc => 'some description' )

B<Optional>. Takes a scalar contaning the description of the paste.
B<By default> is not specified (no description).

=head3 tabs

    $paster->paste( 'text', tabs => '8' )

B<Optional>. Takes a scalar contaning either C<no>, C<2>, C<3>, C<4>, C<5>
C<6> or C<8>. Tells the pastebin to convert any tab characters to spaces,
each tab should be replaced by spaces. The number of spaces per tab
is specified as the value of C<tabs> argument. The C<no> value tells that
no conversion should be done. B<Defaults to:> C<no>

=head3 lang

    $paster->paste( 'text', lang => 'Perl' )

B<Optional>. Takes a scalar contaning a language "code" specifying the
language of the paste (effectively turning appropriate syntax highlights
on it). B<Defaults to:> C<'plain text'>. Possible language codes are
I<case-insensitive> and are as follows, the left side represents the
code to be used for C<lang> argument and the right side is the language's
name:

        c89                 => 'C (C89)',
        c                   => 'C (C99)',
        'c++'               => 'C++',
        'c#'                => 'C#',
        'java'              => 'Java',
        pascal              => 'Pascal',
        perl                => 'Perl',
        php                 => 'PHP',
        'pl/i'              => 'PL/I',
        python              => 'Python',
        ruby                => 'Ruby',
        sql                 => 'SQL',
        vb                  => 'Visual Basic',
        'plain text wrap'   => 'Word wrapped text',
        'plain text'        => 'Plain Text',

=head2 error

    $paster->paste( 'lotsa text' )
        or die $paster->error;

If C<paste()> method fails it will return either C<undef> or an empty
list depending on the context and the reason for the error will be available
via C<error()> method. Takes no arguments, returns a human readable error
message describing why C<paste()> failed.

=head2 uri

    printf "Paste is at: %s\n", $paster->uri;

    # or

    print "Paste is at: $paster\n";

Must be called after a successfull call to C<paste()>. Takes no arguments,
returns a L<URI> object pointing to a newly created paste. The module
provides overload, thus instead of calling the C<uri()> method or storing
the value of C<paster()> method you could simply use C<WWW::Rafb::Create>
object in a string.

=head2 response

    my $http_response_obj = $paster->response;

Must be called after a call to C<paste()>. Takes no arguments, returns
a L<HTTP::Response> object obtained when a new was created. You can use
this if you want to further investigate why C<paste()> method failed.

=head2 timeout

    my $timeout = $paster->timeout;

Takes no arguments, returns whatever you've specified in the C<timeout>
argument in the constructor (C<new()>) or its default if you didn't
specify anything.

=head2 ua

    my $ua = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'MOOO!' );

Returns an L<LWP::UserAgent> object used for pasting by the module. Takes
one optional argument which should be an L<LWP::UserAgent> object. If
called with an argument the L<LWP::UserAgent> object you specify will be
used in any subsequent pasting.

=head1 SEE ALSO

L<LWP::UserAgent>, L<HTTP::Response>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-rafb-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Rafb-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Rafb::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Rafb-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Rafb-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Rafb-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Rafb-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
