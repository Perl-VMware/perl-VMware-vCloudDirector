#!/usr/bin/env perl
#
#
use strict;
use warnings;

use Method::Signatures;
use Const::Fast;
use Path::Tiny;
use XML::Hash::XS;
use HTML::Entities;
use Data::Dump;
use Data::Printer;

# ------------------------------------------------------------------------
const my $lib_type_base => path('lib/VMware/vCloudDirector/Object');
$lib_type_base->mkpath;

const my $lib_type_prefix => 'VMware::vCloudDirector::Object';
const my $lib_base_class  => 'VMware::vCloudDirector::ObjectBase';

# ------------------------------------------------------------------------
my $type_set = {};
my $elem_set = {};

# ------------------------------------------------------------------------
sub list {
    return () unless ( defined( $_[0] ) );
    return @{ $_[0] } if ( ref( $_[0] ) eq 'ARRAY' );
    return $_[0];
}

# ----------------------------------------------------------------------
func massage_typename ($name) {
    $name =~ s/^vcloud://;
    $name =~ s/Type$//;
    return $name;
}

# ----------------------------------------------------------------------
func extract_doc_string ($thing) {
    my $docstr;
    foreach my $ann ( list($thing) ) {
        if ( ref($ann) ) {
            foreach my $doc ( list( $ann->{'xs:documentation'} ) ) {
                if ( ref($doc) ) {
                    if ( exists( $doc->{'xml:lang'} ) ) {
                        $docstr = $doc->{content};
                        last;
                    }
                }
                else { $docstr = $doc; }
            }
        }
        else {
            $docstr = $ann;
        }
    }

    if ( defined($docstr) ) {
        decode_entities($docstr);
        $docstr =~ s/\n/ /g;
        $docstr =~ s/^\s+//g;
        $docstr =~ s/\s+$//g;
        $docstr =~ s/\s{2,}/ /g;
        $docstr =~ tr/'//d;
    }
    else { $docstr = ''; }
    return $docstr;
}

# ----------------------------------------------------------------------
func make_type ($thing) {
    return unless defined($thing);
    if ( exists( $type_set->{ massage_typename($thing) } ) ) {
        return ( sprintf( '%s::%s', $lib_type_prefix, massage_typename($thing) ) );
    }

    if    ( $thing eq 'xs:string' )           { return 'Str'; }
    elsif ( $thing eq 'xs:boolean' )          { return 'Bool'; }
    elsif ( $thing eq 'xs:dateTime' )         { return 'DateTime'; }
    elsif ( $thing eq 'xs:double' )           { return 'Num'; }
    elsif ( $thing eq 'xs:float' )            { return 'Num'; }
    elsif ( $thing eq 'xs:hexBinary' )        { return 'Str'; }
    elsif ( $thing eq 'xs:int' )              { return 'Int'; }
    elsif ( $thing eq 'xs:integer' )          { return 'Int'; }
    elsif ( $thing eq 'xs:long' )             { return 'Int'; }
    elsif ( $thing eq 'xs:short' )            { return 'Int'; }
    elsif ( $thing eq 'xs:normalizedString' ) { return 'Str'; }
    elsif ( $thing eq 'xs:hexBinary' )        { return 'Str'; }
    elsif ( $thing eq 'xs:anyType' )          { return 'Item'; }
    elsif ( $thing eq 'xs:anyURI' )           { return 'URI'; }

    return;
}

# ----------------------------------------------------------------------
func build_type_parent ($name, $hash) {
    foreach my $section ( list( $hash->{'xs:complexContent'} ) ) {
        my $base  = $section->{'xs:extension'}{base};
        my $class = make_type($base);
        return "extends '$class';" if ( defined($class) );
    }
    return "extends '$lib_base_class';";
}

# ----------------------------------------------------------------------
func build_type_header ($name, $hash) {
    my $out = sprintf( "package %s::%s;\n\n", $lib_type_prefix, $name );
    $out .= sprintf( "#ABSTRACT %s\n\n", extract_doc_string( $hash->{'xs:annotation'} ) );
    $out .= join( "\n",
        'use strict;',
        'use warnings;',
        'use namespace::autoclean;',
        '',
        '# VERSION',
        '# AUTHORITY',
        '',
        'use Moose;',
        'use Method::Signatures;',
        '',
        build_type_parent( $name, $hash ),
        '',
        '# ----------------------------------------------------------------------',
        '',
        '' );
    return $out;
}

# ----------------------------------------------------------------------
func build_type_content ($name, $hash) {
    my @stuff = list( $hash->{'xs:complexContent'} );
    my $str   = Data::Dump::dump( \@stuff );
    $str =~ s/^/## /mg;
    $str .= "\n\n";

    my $ret = '';
    foreach my $thing (@stuff) {
        foreach my $elem ( list( $thing->{'xs:extension'}{'xs:sequence'}{'xs:element'} ) ) {
            next unless ( $elem->{name} );
            $ret .= sprintf(
                "has %s => (is => 'ro', isa => '%s', documentation => '%s');\n",
                $elem->{name},
                ( make_type( $elem->{type} ) || 'Str' ),
                ( extract_doc_string( $elem->{'xs:annotation'} ) || '' )
            );
        }
    }
    return ( $ret . "\n\n" . $str );
}

# ----------------------------------------------------------------------
func build_type_footer ($name, $hash) {
    return join( "\n",
        '', '# ----------------------------------------------------------------------',
        '', '__PACKAGE__->meta->make_immutable;',
        '', '1;', '', );
}

# ----------------------------------------------------------------------
func process_types ($type_set) {
    foreach my $type ( values %{$type_set} ) {
        my $name    = massage_typename( $type->{name} );
        my $fp      = $lib_type_base->child( $name . '.pm' );
        my $header  = build_type_header( $name, $type );
        my $content = build_type_content( $name, $type );
        my $footer  = build_type_footer( $name, $type );
        $fp->spew( $header, $content, $footer );
    }
}

# ----------------------------------------------------------------------

while ( my $fn = shift ) {
    my $xml  = path($fn)->slurp;
    my $hash = xml2hash $xml;
    foreach my $fragment ( list( $hash->{'xs:complexType'} ) ) {
        my $name = massage_typename( $fragment->{name} );
        if ( exists( $type_set->{$name} ) ) {
            warn "Type $name duplicated\n";
        }
        else {
            $type_set->{$name} = $fragment;
        }
    }
    foreach my $fragment ( list( $hash->{'xs:element'} ) ) {
        my $name = $fragment->{name};
        if ( exists( $elem_set->{$name} ) ) {
            warn "Element $name duplicated\n";
        }
        else {
            $elem_set->{$name} = $fragment;
        }
    }
}

process_types($type_set);

#p($type_set);
#p($elem_set);
