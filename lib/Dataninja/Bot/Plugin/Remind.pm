package Dataninja::Bot::Plugin::Remind;
use Moose;
use DateTime;
use DateTime::Format::Natural;
extends 'Dataninja::Bot::Plugin::Base';

around 'command_setup' => sub {
    my $orig = shift;
    my $self = shift;

    # remind {{{
    $self->command(remind => sub {
            my $command_args = shift;
            my ($nick, $desc, $time) =
                ($command_args =~ /(\S+)? \s+ (.+) \s+>\s+ (.+)/x);
            return "format: remind NICK (message) > when"
                unless defined $nick and defined $desc and defined $time;
            my %numbers = (
                one       => 1,
                two       => 2,
                three     => 3,
                four      => 4,
                five      => 5,
                six       => 6,
                seven     => 7,
                eight     => 8,
                nine      => 9,
                ten       => 10,
                eleven    => 11,
                twelve    => 12,
                thirteen  => 13,
                fourteen  => 14,
                fifteen   => 15,
                sixteen   => 16,
                seventeen => 17,
                eighteen  => 18,
                nineteen  => 19,
                twenty    => 20,
                thirty    => 30,
                fourty    => 40,
                fifty     => 50,
                sixty     => 60,
                seventy   => 70,
                eighty    => 80,
                ninty     => 90,
                ninety    => 90,
            );

            foreach my $word (keys %numbers) {
                $time =~ s/\b$word\b/$numbers{$word}/ge;
                $time =~ s/\ba\s+few\b/3/ge;
                $time =~ s/\bseveral\b/8/ge;
                $time =~ s/\ban?\b/1/ge;
            }

#    $time .= ' from now' if ($prep eq 'in');

            $nick = $self->nick if $nick eq 'me';
            my $reminder = Dataninja::Model::Reminder->new;

            my $parser = DateTime::Format::Natural->new(time_zone => 'America/New_York', prefer_future => 1);
            my $when_to_remind = $parser->parse_datetime($time);
            $when_to_remind->set_time_zone('UTC');

            if (!$parser->success) {
                return "huh? see http://tinyurl.com/dtfn-examples";
            }

            return "must authenticate yourself as Doc Brown to do that"
            if DateTime->compare($when_to_remind->clone(time_zone => 'America/New_York'), DateTime->now) < 0;

            my ($ok, $error) = $reminder->create(
                remindee    => $nick,
                description => $desc,
                channel     => $self->channel,
                network     => $self->network,
                maker       => $self->nick,
                moment      => $when_to_remind
            );

            return $error unless $ok;
            $when_to_remind->set_time_zone('America/New_York');
            return sprintf('will remind at: %s %s %s [id: %s]',
                $when_to_remind->ymd,
                $when_to_remind->hms,
                $when_to_remind->time_zone->name,
                $reminder->id);
    });
# }}}

    $self->command(cancel => sub {
            my $requested_id = shift;
            return "invalid ID" if $requested_id =~ /\D/;

            my $reminders = Dataninja::Model::ReminderCollection->new;
            $reminders->limit(column => 'id', value => $requested_id);

            my $reminder = $reminders->first;

            if (defined $reminder) {
                return "that reminder wasn't for you!" if $self->nick ne $reminder->maker;
                return "you don't need to worry about that"
                if $reminder->reminded or $reminder->canceled;
                $reminder->set_canceled(1);
                return "canceled";
            }

# catchall
            return "could not find a reminder with that ID";

    });
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
