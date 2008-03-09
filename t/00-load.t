#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::Rafb::Create' );
}

diag( "Testing WWW::Rafb::Create $WWW::Rafb::Create::VERSION, Perl $], $^X" );
use WWW::Rafb::Create;
my $o = WWW::Rafb::Create->new( timeout => 10 );

isa_ok($o,'WWW::Rafb::Create');
can_ok($o, qw(    uri
    error
    response
    timeout
    ua
    new
    paste
    _set_error
    _make_valid_languages
    _make_valid_tabs));

is($o->timeout, 10, '->timeout');