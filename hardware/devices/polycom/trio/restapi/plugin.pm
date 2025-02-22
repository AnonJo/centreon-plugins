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

package hardware::devices::polycom::trio::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'calls-summary' => 'hardware::devices::polycom::trio::restapi::mode::callssummary',
        'calls-rt'      => 'hardware::devices::polycom::trio::restapi::mode::callsrt',
        'device'        => 'hardware::devices::polycom::trio::restapi::mode::device',
        'network'       => 'hardware::devices::polycom::trio::restapi::mode::network',
        'paired'        => 'hardware::devices::polycom::trio::restapi::mode::paired',
        'registration'  => 'hardware::devices::polycom::trio::restapi::mode::registration'
    };

    $self->{custom_modes}->{api} = 'hardware::devices::polycom::trio::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Polycom Trio (8300, 8500, 8800) through HTTP/REST API.

=over 8

=back

=cut
