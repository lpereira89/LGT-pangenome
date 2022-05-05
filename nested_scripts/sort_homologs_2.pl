#!/usr/bin/env perl

use v5.16; 
use lib '/shared/dunning_lab/Shared/scripts/perl';                                    
use strict;
use warnings;

use Graph::Undirected;

my $g = Graph::Undirected->new;

while (<>) {
    chomp;
    $g->add_edge( split /\t/ );
}

for ( $g->connected_components() ) {
    say join ' ', @$_;
}
