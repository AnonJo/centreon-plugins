#
# Copyright 2022 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package database::redis::mode::commands;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_output {
    my ($self, %options) = @_;
    
    return 'Number of commands processed: ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' ', cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'processed-commands', nlabel => 'commands.processed.count', set => {
                key_values => [ { name => 'total_commands_processed', diff => 1 } ],
                output_template => '%s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'ops-per-sec', nlabel => 'commands.processed.persecond', set => {
                key_values => [ { name => 'instantaneous_ops_per_sec' } ],
                output_template => '%.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'redis_database_' . $self->{mode} . '_' . $options{custom}->get_connection_info() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{custom}->get_info();
    $self->{global} = {
        total_commands_processed    => $results->{total_commands_processed},
        instantaneous_ops_per_sec   => $results->{instantaneous_ops_per_sec}
    };
}

1;

__END__

=head1 MODE

Check commands number

=over 8

=item B<--warning-processed-commands>

Warning threshold for number of commands processed by the server

=item B<--critical-processed-commands>

Critical threshold for number of commands processed by the server

=item B<--warning-ops-per-sec>

Warning threshold for number of commands processed per second

=item B<--critical-ops-per-sec>

Critical threshold for number of commands processed per second

=back

=cut
