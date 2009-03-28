package Dataninja::Bot::Plugin::Twitter;
use Moose;
extends 'Dataninja::Bot::Plugin::Base';
use Net::Twitter;

sub get_latest_tweet {
    my $name = shift;

    my $text = eval {
        my $twitter = Net::Twitter->new(
            username => Jifty->config->app("twitteruser"),
            password => Jifty->config->app("twitterpass"),
        );
        my $responses = $twitter->user_timeline({id => $name});
        $responses->[0]{text};
    };

    return $@ ? "Unable to get ${name}'s latest status." : $text;
}

around 'command_setup' => sub {
    my $orig = shift;
    my $self = shift;

    $self->command(twitter => sub {
        my $command_args = shift;
        return "tweet: " . get_latest_tweet($command_args);
    });
};
# }}}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

