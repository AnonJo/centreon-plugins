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

package network::cisco::firepower::fxos::snmp::mode::components::memoryunit;

use strict;
use warnings;
use network::cisco::firepower::fxos::snmp::mode::components::resources qw($map_operability);

my $mapping = {
    dn          => { oid => '.1.3.6.1.4.1.9.9.826.1.50.11.1.2' }, # cfprMemoryUnitDn
    operability => { oid => '.1.3.6.1.4.1.9.9.826.1.50.11.1.18', map => $map_operability } # cfprMemoryUnitOperability
};
my $mapping_stats = {
    dn          => { oid => '.1.3.6.1.4.1.9.9.826.1.50.12.1.2' }, # cfprMemoryUnitEnvStatsDn
    temperature => { oid => '.1.3.6.1.4.1.9.9.826.1.50.12.1.7' }  # cfprMemoryUnitEnvStatsTemperatureAvg
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, map({ oid => $_->{oid} }, values(%$mapping), values(%$mapping_stats));
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking memory units');
    $self->{components}->{memoryunit} = { name => 'memory units', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'memoryunit'));

    my $results = { map(%{$self->{results}->{ $_->{oid} }}, values(%$mapping)) };
    my $results_stats = { map(%{$self->{results}->{ $_->{oid} }}, values(%$mapping_stats)) };

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($oid !~ /^$mapping->{operability}->{oid}\.(.*)$/);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $1);

        next if ($self->check_filter(section => 'memoryunit', instance => $result->{dn}));
        $self->{components}->{memoryunit}->{total}++;

        my $result_stats = $self->compare_dn(
            regexp => "^$result->{dn}/",
            lookup => 'dn',
            results => $results_stats,
            mapping => $mapping_stats
        );

        $self->{output}->output_add(
            long_msg => sprintf(
                "memory unit '%s' status is '%s' [temperature: %s C].",
                $result->{dn},
                $result->{operability},
                defined($result_stats->{temperature}) ? $result_stats->{temperature} : '-'
            )
        );
        $exit = $self->get_severity(label => 'operability', section => 'memoryunit', instance => $result->{dn}, value => $result->{operability});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "memory unit '%s' status is '%s'",
                    $result->{dn},
                    $result->{operability}
                )
            );
        }

        next if (!defined($result_stats->{temperature}));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'memoryunit.temperature', instance => $result->{dn}, value => $result_stats->{temperature});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "memory unit '%s' temperature is %s C",
                    $result->{dn},
                    $result_stats->{temperature}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.memoryunit.temperature.celsius',
            unit => 'C',
            instances => $result->{dn},
            value => $result_stats->{temperature},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
