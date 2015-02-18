package GBV::App::SeeAlso::Example;

use parent Plack::App::SeeAlso;

our $ShortName = 'Example Server';
our $Description = 'Example SeeAlso server always returns a sample response';

sub query {
    my ($self, $id) = @_;
    [ $id, ["example"], ["example"], ["http://example.org/"] ];
}

1;
