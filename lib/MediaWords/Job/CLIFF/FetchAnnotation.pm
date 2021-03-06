package MediaWords::Job::CLIFF::FetchAnnotation;

#
# Fetch story's CLIFF annotation
#
# Start this worker script by running:
#
# ./script/run_in_env.sh mjm_worker.pl lib/MediaWords/Job/CLIFF/FetchAnnotation.pm
#

use strict;
use warnings;

use Moose;
with 'MediaWords::AbstractJob';

use Modern::Perl "2015";
use MediaWords::CommonLibs;

use MediaWords::DB;
use MediaWords::Job::CLIFF::UpdateStoryTags;
use MediaWords::Util::Annotator::CLIFF;

use Readonly;
use Data::Dumper;

# Run job
sub run($;$)
{
    my ( $self, $args ) = @_;

    my $db = MediaWords::DB::connect_to_db();

    my $stories_id = $args->{ stories_id } + 0 or die "'stories_id' is not set.";

    my $story = $db->find_by_id( 'stories', $stories_id );
    unless ( $story->{ stories_id } )
    {
        die "Story with ID $stories_id was not found.";
    }

    # Annotate story with CLIFF
    my $cliff = MediaWords::Util::Annotator::CLIFF->new();
    eval { $cliff->annotate_and_store_for_story( $db, $stories_id ); };
    if ( $@ )
    {
        die "Unable to process story $stories_id with CLIFF: $@\n";
    }

    # Add job for CLIFF tags aggregation
    MediaWords::Job::CLIFF::UpdateStoryTags->add_to_queue( { stories_id => $stories_id } );

    return 1;
}

no Moose;    # gets rid of scaffolding

# Return package name instead of 1 or otherwise worker.pl won't know the name of the package it's loading
__PACKAGE__;
