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

package storage::overland::neo::snmp::mode::components::library;

use strict;
use warnings;

my $map_state = {
    0 => 'initializing',  1 => 'online',  2 => 'offline'
};

my $mapping = {
    lstLibraryState => { oid => '.1.3.6.1.4.1.3351.1.3.2.3.2.1.6', map => $map_state  }
};
my $oid_libraryStatusEntry = '.1.3.6.1.4.1.3351.1.3.2.3.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_libraryStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking libraries');
    $self->{components}->{library} = { name => 'libraries', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'library'));

    # there is no instance for the table. Weird. Need to manage the two cases.
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_libraryStatusEntry}})) {
        next if ($oid !~ /^$mapping->{lstLibraryState}->{oid}(?:\.(.*)|$)/);
        my $instance = defined($1) ? $1 : undef;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_libraryStatusEntry}, instance => $instance);

        # we set a 1 to do some filters
        $instance = '1' if (!defined($instance));
        next if ($self->check_filter(section => 'library', instance => $instance));

        $self->{components}->{library}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "library '%s' status is '%s' [instance = %s]",
                $instance,
                $result->{lstLibraryState},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'library', instance => $instance, value => $result->{lstLibraryState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("library '%s' status is '%s'", $instance, $result->{lstLibraryState})
            );
        }
    }
}

1;
