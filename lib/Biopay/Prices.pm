package Biopay::Prices;
use Moose;
use Dancer::Plugin::CouchDB;
use Dancer ':syntax';
use Try::Tiny;
use methods;

method fuel_price {
    my $cb = shift;
    if ($cb) {
        return $self->doc( sub {
                my $doc = shift;
                $cb->($doc->{price_per_litre});
            }
        );
    }
    return $self->doc->{price_per_litre} || die "No price per litre found!";
}

method set_fuel_price {
    my $doc = $self->doc;
    $doc->{price_per_litre} = shift;
    couchdb->save_doc($doc);
}

method annual_membership_price {
    my $cb = shift;
    die "Callback for annual_membership_price is not implemented!" if $cb;
    return $self->doc->{annual_membership_price}
        || die "No annual membership price found!";
}

method signup_price {
    my $cb = shift;
    die "Callback for signup_price is not implemented!" if $cb;
    return $self->doc->{signup_price}
        || die "No signup_price found!";
}

method doc {
    my $cb = shift;

    my $cv = couchdb->open_doc("prices");
    if ($cb) {
        return $cv->cb(
            sub {
                my $cv2 = shift;
                my $doc = $cv2->recv;
                $cb->($doc);
            }
        );
    }

    return try { $cv->recv }
    catch {
        if ($_ =~ m/^404/) {
            die "Could not load the 'prices' doc! Make sure it exists.";
        }
        else { die "Failed to load 'prices' doc: $_" }
    };
}
