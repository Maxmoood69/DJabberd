package DJabberd::RosterItem;
use strict;
use Carp qw(croak);
use DJabberd::Util qw(exml);
use DJabberd::Subscription;

use fields (
            'jid',
            'name',
            'groups',        # arrayref of group names
            'subscription',  # DJabberd::Subscription object
            'remove',        # bool: if client requested rosteritem be removed
            'ver',
            );

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    if (@_ == 1) {
        $self->{jid} = $_[0];
    } else {
        my %opts = @_;
        $self->{jid}          = delete $opts{'jid'} or croak "No JID";
        $self->{name}         = delete $opts{'name'};
        $self->{groups}       = delete $opts{'groups'};
        $self->{remove}       = delete $opts{'remove'};
        $self->{subscription} = delete $opts{'subscription'};
        $self->{ver}          = delete $opts{'ver'};
        croak("unknown ctor fields: " . join(', ', keys %opts)) if %opts;
    }
    $self->{ver} .= 'e0' if(exists $self->{ver} && defined $self->{ver} && $self->{ver} eq '0');

    unless (ref $self->{jid}) {
        $self->{jid} = DJabberd::JID->new($self->{jid})
            or croak("Invalid JID");
    }

    $self->{groups}       ||= [];

    # convert subscription name to an object
    if ($self->{subscription} && ! ref $self->{subscription}) {
        $self->{subscription} = DJabberd::Subscription->new_from_name($self->{subscription});
    }

    $self->{subscription} ||= DJabberd::Subscription->none;
    return $self;
}

sub jid {
    my $self = shift;
    return $self->{jid};
}

sub name {
    my $self = shift;
    return $self->{name};
}

sub groups {
    my $self = shift;
    return @{ $self->{groups} };
}

sub subscription {
    my $self = shift;
    return $self->{subscription};
}

sub set_subscription {
    my ($self, $sb) = @_;
    $self->{subscription} = $sb;
}

sub add_group {
    my ($self, $group) = @_;
    push @{ $self->{groups} }, $group;
}

sub ver {
    my $self = shift;
    return $self->{ver};
}

sub remove {
    my $self = shift;
    return $self->{remove};
}

sub as_xml {
    my $self = shift;
    my $xml = "<item jid='" . exml($self->{jid}->as_bare_string) . "' " . ($self->{remove} ?
                                                                           "subscription='remove' " :
                                                                           $self->{subscription}->as_attributes);
    if (defined $self->{name}) {
        $xml .= " name='" . exml($self->{name}) . "'";
    }
    if(@{ $self->{groups} }) {
        $xml .= ">";
        foreach my $g (@{ $self->{groups} }) {
            $xml .= "<group>" . exml($g) . "</group>";
        }
        $xml .= "</item>";
    } else {
        $xml .= '/>';
    }
    return $xml;
}

sub as_query {
    my $self = shift;
    my $ver = ($self->ver)?" ver='".$self->ver."'":'';
    return "<query xmlns='jabber:iq:roster'$ver>".$self->as_xml."</query>";
}

1;
