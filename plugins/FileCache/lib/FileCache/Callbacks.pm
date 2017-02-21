package FileCache::Callbacks;
use strict;

sub build_file_filter {
    my ( $cb, %args ) = @_;
    if (! MT->config( 'RebuildUpdateEntryOnly' ) ) {
        return 1;
    }
    my $entry = $args{ Entry };
    my $template = $args{ Template };
    my $file = $args{ File };
    if (! -f $file ) {
        return 1;
    }
    if ( $entry ) {
        my $entry_mod = $entry->modified_on;
        my $template_mod = $template->modified_on;
        my $mod = ( stat( $file ) )[ 9 ];
        $mod = MT::Util::epoch2ts( $entry->blog, $mod );
        if ( ( $mod > $template_mod ) && ( $mod > $entry_mod ) ) {
            return undef;
        }
    }
    return 1;
}

1;