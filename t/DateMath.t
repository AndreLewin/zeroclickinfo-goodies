#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::MockTime qw( :all );
use DDG::Test::Goodie;
use DDG::Test::Location;

zci answer_type => 'date_math';
zci is_cached   => 0;

sub build_structured_answer {
    my %result = @_;
    return 'DateMath', structured_answer => {
        meta => {
            signal => 'high',
        },
        data => {
            start_date => $result{start_date},
            actions => $result{actions},
            date_components => isa('ARRAY'),
            modifiers => isa('ARRAY'),
        },
        templates => {
            group => 'base',
            options => {
                content => 'DDH.date_math.content',
            },
        },
    };
}

sub build_test { test_zci(build_structured_answer(@_)) }

my $jan_1_2012 = 1325356200;
my $jan_1_2014 = 1388514600;
my %overjan = (
    start_date => $jan_1_2012,
    actions    => [
        {
            operation => '+',
            amount    => '32',
            type      => 'days',
        },
    ],
);
# my %overjan = ('02 Feb 2012', '01 Jan 2012 + 32 days');
my %first_sec = (
    start_date => $jan_1_2012,
    actions    => [
        {
            operation => '+',
            amount    => '1',
            type      => 'days',
        }
    ],
);

set_fixed_time("2014-01-12T10:00:00");

sub location_test {
    my ($package, %tests) = @_;
    my $location = test_location('in');
    my @location_tests;
    while (my ($query, $test) = each %tests) {
        push @location_tests, (
            DDG::Request->new(
                query_raw => $query,
                location => $location) => $test);
    };

    return ddg_goodie_test($package, @location_tests);
}

sub test_now {
    return build_test(start_date => 1389520800, @_);
}

sub new_action {
    my ($op, $amount, $type) = @_;
    return {
        operation => $op,
        amount    => $amount,
        type      => $type,
    };
}

sub actions {
    my @actions = map { new_action(@$_) } @_;
    return \@actions;
}

my %five_mins = (actions => actions(['+', '5', 'minutes']));
my %in_3_mins = (actions => actions(['+', '3', 'minutes']));
my %ago_3_mins = (actions => actions(['-', '3', 'minutes']));
my %in_3_days = (actions => actions(['+', '3', 'days']));
my %ago_3_days = (actions => actions(['-', '3', 'days']));

location_test([ qw( DDG::Goodie::DateMath ) ],
    # 2012 Jan tests
    'Jan 1 2012 plus 32 days'       => build_test(%overjan),
    'January 1 2012 plus 32 days'   => build_test(%overjan),
    'January 1, 2012 plus 32 days'  => build_test(%overjan),
    'January 1st 2012 plus 32 days' => build_test(%overjan),
    '32 days from January 1st 2012' => build_test(%overjan),
    # Relative (to today)
    '6 weeks ago' => test_now(
        actions    => actions(['-', '6', 'weeks']),
    ),
    '2 weeks from today' => test_now(
        actions => actions(['+', '2', 'weeks']),
    ),
    'in 3 weeks' => test_now(
        actions => actions(['+', '3', 'weeks']),
    ),
    'January 1st plus 32 days' => build_test(
        start_date => $jan_1_2014,
        actions => actions(['+', '32', 'days']),
    ),
    '5 minutes from now'       => test_now(%five_mins),
    'in 5 minutes'             => test_now(%five_mins),
    'in 5 minutes.'            => test_now(%five_mins),
    'time in 5 minutes'        => test_now(%five_mins),
    'twelve seconds ago'       => test_now(
        actions => actions(['-', '12', 'seconds'])
    ),
    '01 Jan + 12 hours'        => build_test(
        start_date => $jan_1_2014,
        actions    => actions(['+', '12', 'hours']),
    ),
    'date today plus 24 hours' => test_now(
        actions => [
            new_action('+', '24', 'hours'),
        ],
    ),
    # time form
    'time 3 days ago' => test_now(%ago_3_days),
    # Specifying time
    '01 Jan 2012 00:05:00 - 5 minutes' => build_test(
        start_date => 1325356500,
        actions => [
            new_action('-', '5', 'minutes'),
        ],
    ),
    '03 Mar 2015 07:07:07 GMT + 12 hours' => build_test(
        start_date => 1425366427,
        actions    => actions(['+', '12', 'hours']),
    ),
    # Misc
    '1 jan 2014 plus 2 weeks' => build_test(
        start_date => $jan_1_2014,
        actions    => actions(['+', '2', 'weeks']),
    ),
    '1st Jan 2012 - 3000 seconds'        => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['-', '3000', 'seconds']),
    ),
    '1st Jan 2012 subtract 3000 seconds' => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['-', '3000', 'seconds']),
    ),
    # / form
    '1/1/2012 plus 32 days'   => build_test(%overjan),
    '1/1/2012 add 5 weeks'    => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['+', '5', 'weeks']),
    ),
    '1/1/2012 PlUs 5 months'  => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['+', '5', 'months']),
    ),
    '1/1/2012 PLUS 5 years'   => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['+', '5', 'years']),
    ),
    '1 day from 1/1/2012'     => build_test(%first_sec),
    '1/1/2012 plus 1 day'     => build_test(%first_sec),
    '1/1/2012 plus 1 days'    => build_test(%first_sec),
    '01/01/2012 + 1 day'      => build_test(%first_sec),
    '1/1/2012 minus ten days' => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['-', '10', 'days']),
    ),
    '1/1/2012 + 1 second'     => build_test(
        start_date => $jan_1_2012,
        actions    => actions(['+', '1', 'seconds']),
    ),
    # Plurals
    'in 1 second'  => test_now(
        actions => actions(['+', '1', 'seconds']),
    ),
    'in 1 seconds' => test_now(
        actions => actions(['+', '1', 'seconds']),
    ),
    # Casing
    '3 Years Ago'          => test_now(
        actions => actions(['-', '3', 'years']),
    ),
    'Time Now + 3 Minutes' => test_now(%in_3_mins),
    # With wrapping
    'What time will it be in 3 minutes' => test_now(%in_3_mins),
    'What is the time in 3 minutes'     => test_now(%in_3_mins),
    'What was the time 3 minutes ago'   => test_now(%ago_3_mins),
    'What date will it be in 3 days'    => test_now(%in_3_days),
    'What will the date be in 3 days?'  => test_now(%in_3_days),
    'What date is it in 3 days'         => test_now(%in_3_days),
    'What time was it 3 days ago'       => test_now(%ago_3_days),
    'What date was it 3 days ago'       => test_now(%ago_3_days),
    'What date was it 3 days ago?'      => test_now(%ago_3_days),
    'What day was it 3 days ago?'       => test_now(%ago_3_days),
    # Specified relative
    'date 21st Jan'     => undef,
    'date January 1st'  => undef,
    'time 22nd April'   => undef,
    'date 3rd Jan 2015' => undef,
    'Jan 1st 2012'      => undef,
    # Should not trigger
    'yesterday'  => undef,
    'today'      => undef,
    'five years' => undef,
    'two months' => undef,
    '2 months'   => undef,
    '5 years'    => undef,
    'time ago'   => undef,
    'time now'   => undef,
    'date today' => undef,
);

done_testing;
