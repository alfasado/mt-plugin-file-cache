package FileCache;
use strict;
use Cache::FileCache;

use vars qw( $f );

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub filecache {
    my ( $this, $tts ) = @_;
    if ( $tts || ! $f ) {
        my $namespace = MT->config( 'FileCacheNameSpace' ) || 'movabletype';
        my $default_expires_in = $tts || MT->config( 'FileCacheDefaultExpires' ) || 600;
        my $root = MT->config( 'FileCacheCacheDir' ) || '/tmp';
        $f = new Cache::FileCache( { namespace => $namespace,
                                     default_expires_in => $default_expires_in,
                                     cache_root => $root } );
    }
    return $f if $f;
}

sub get {
    my ( $this, $key ) = @_;
    if (! $key ) { return undef };
    if ( my $value = MT->request( 'filecache:' . $key ) ) {
        $value;
    }
    my $f = $this->filecache();
    my $value = $f->get( $key );
    MT->request( 'filecache:' . $key, $value );
    return $value;
}

sub set {
    my ( $this, $key, $value, $tts ) = @_;
    if (! $key ) { return undef };
    my $f = $this->filecache( $tts );
    my $res = $f->set( $key, $value, $tts );
    if (! $tts ) {
        MT->request( 'filecache:' . $key, $value );
    }
    $res;
}

sub add {
    my ( $this, $key, $value, $tts ) = @_;
    if (! $key ) { return undef };
    my $f = $this->filecache( $tts );
    return $f->set( $key, $value, $tts )
    unless defined $f->get( $key );
}

sub incr {
    my ( $this, $key, $incr ) = @_;
    if (! $key ) { return undef };
    my $f = $this->filecache();
    if (! $incr ) { $incr = 1 };
    my $value = $f->get( $key ) || 0;
    $value += $incr;
    $f->set( $key, $value );
}

sub decr {
    my ( $this, $key, $decr ) = @_;
    if (! $key ) { return undef };
    my $f = $this->filecache();
    if (! $decr ) { $decr = 1 };
    my $value = $f->get( $key ) || 0;
    $value -= $decr;
    $f->set( $key, $value );
}

sub delete {
    my ( $this, $key ) = @_;
    if (! $key ) { return undef };
    my $f = $this->filecache();
    $f->remove( $key );
}

sub get_multi {
    my $this = shift;
    my @keys = @_;
    my $f = $this->filecache();
    my %values;
    for my $key ( @keys ) {
        my $value = $f->get( $key );
        $values{ $key } = $value;
    }
    return \%values;
}

sub flush_all {
    my $this = shift;
    my $opt = shift;
    my $f = $this->filecache();
    if ( $opt && $opt->{ force } ) {
        my $namespace = $f->{ _Options_Hash_Ref }->{ namespace };
        my $cache_root = $f->{ _Options_Hash_Ref }->{ cache_root };
        my $dir = File::Spec->catdir( $cache_root, $namespace );
        return File::Path::rmtree( $dir, { keep_root => 1 } );
    } else {
        return $f->purge();
    }
}

1;