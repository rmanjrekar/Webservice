package BankDetails::India;
use strict;
use warnings;
use Data::Dumper;
use CHI;
use Carp qw (croak);
use LWP::UserAgent;
use Moose;
use Sereal qw(encode_sereal decode_sereal);
use Digest::MD5 qw(md5_hex);
use JSON;
use XML::Simple;
use Cwd;

our $VERSION = '1.0';

has user_agent => (
    is => 'ro',
    lazy => 1,
    builder => '_build_user_agent',
);
 
sub _build_user_agent {
    my $self = shift;
    return LWP::UserAgent->new;
}

has api_url => (
    isa => 'Str',
    is => 'ro',
    default => 'https://ifsc.razorpay.com/',
);

sub ping_api {
    my ($self) = @_;
    my $response = $self->user_agent->get($self->api_url);
    return ($response->code == 200) ? 1 : 0;
}

has 'cache_data' => (
    is      => 'rw',
    isa     => 'CHI::Driver',
    builder => '_build_cache_data',
);

my $cwd = getcwd();
sub _build_cache_data {
    my $cache = CHI->new(driver => 'File', 
                    namespace => 'BankDetailsIndiaIFSC',
                    root_dir => $cwd . '/cache/');
    return $cache;
}

sub get_all_data_by_ifsc {
    my ($self, $ifsc_code) = @_;
    $ifsc_code = uc($ifsc_code);
    return $self->get_response($self->api_url, $ifsc_code);
}

sub get_bank_name_by_ifsc {
    my ($self, $ifsc_code) = @_;

    $ifsc_code = uc($ifsc_code); 

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'BANK'};
}

sub get_address_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'ADDRESS'};
}

sub get_contact_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'CONTACT'};
}

sub get_state_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'STATE'};
}

sub get_district_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'DISTRICT'};
}

sub get_city_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'CITY'};
}

sub get_micr_code_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'MICR'};
}

sub get_imps_value {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'IMPS'};
}

sub get_neft_value {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'NEFT'};
}

sub get_rtgs_value {
    my ($self, $ifsc_code) = @_;
 
    $ifsc_code = uc($ifsc_code);
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'RTGS'};
}

sub download_json {
    my ($self, $ifsc_code, $file_name) = @_;
    return if ( !$self->ping_api );
    my $request_url = $self->api_url.$ifsc_code;
    my $response = $self->user_agent->get($request_url);
    $file_name ||= "bankdetails_$ifsc_code.json";
    open(my $fh, '>', $file_name) or die $!;
    print $fh $response->decoded_content;
    close($fh);
}

sub download_xml {
    my ($self, $ifsc_code, $file_name) = @_;
    return if ( !$self->ping_api );
    my $request_url = $self->api_url.$ifsc_code;
    my $response = $self->user_agent->get($request_url);
    my $response_data = decode_json($response->decoded_content);
    $self->_convert_json_boolean($response_data);
    my $xml = XMLout($response_data, RootName => 'data', NoAttr => 1);
    $file_name ||= "bankdetails_$ifsc_code.xml";
    open(my $fh, '>', $file_name) or die $!;
    print $fh $xml;
    close($fh);
}

sub get_response {
    my ($self, $endpoint, $ifsc) = @_;
print "\n\nBefore\n\n";
    return if ( !$self->ping_api || !defined $endpoint || length $endpoint <= 0);
print "\nAfter\n\n";
    my $request_url = $endpoint.$ifsc;
    my $cache_key = md5_hex(encode_sereal($ifsc));
    my $response_data;
    my $cache_response_data = $self->cache_data->get($cache_key);
    if (defined $cache_response_data) {
        $response_data = decode_sereal($cache_response_data);
    } else {
print "\n\nInside\n\n";
        my $response = $self->user_agent->get($request_url);
        my $response_content;

        if ($response->is_success) {
            $response_content = $response->decoded_content;
        } else {
            croak "Failed to fetch data: " . $response->status_line;
        }
        $response_data = decode_json($response_content);
        $self->_convert_json_boolean($response_data);
        $self->cache_data->set($cache_key, encode_sereal($response_data));
    }
    return $response_data;
}

sub _convert_json_boolean {
    my ( $self, $data ) = @_;

    if (ref($data) eq 'HASH') {
        foreach my $key (keys %$data) {
            if (ref($data->{$key}) eq 'JSON::PP::Boolean') {
                $data->{$key} = $data->{$key} ? 1 : 0;
            } elsif (ref($data->{$key}) eq 'HASH' || ref($data->{$key}) eq 'ARRAY') {
                $self->_convert_json_boolean($data->{$key});
            }
        }
    } elsif (ref($data) eq 'ARRAY') {
        for (my $i = 0; $i < scalar(@$data); $i++) {
            if (ref($data->[$i]) eq 'JSON::PP::Boolean') {
                $data->[$i] = $data->[$i] ? 1 : 0;
            } elsif (ref($data->[$i]) eq 'HASH' || ref($data->[$i]) eq 'ARRAY') {
                $self->_convert_json_boolean($data->[$i]);
            }
        }
    }
}

1;
