#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest tests => 13;

use Cwd ();
my $cwd = Cwd::cwd();
my $tmp = File::Spec->catdir($cwd, 't', '_tmp');

use DistGen;

my $dist = DistGen->new(dir => $tmp);

$dist->add_file('t/special_ext.st', <<'---');
#!perl 
use Test::More tests => 2;
ok(1, 'first test in special_ext');
ok(1, 'second test in special_ext');
---

$dist->add_file('t/another_ext.at', <<'---');
#!perl 
use Test::More tests => 2;
ok(1, 'first test in another_ext');
ok(1, 'second test in another_ext');
---

$dist->regen;

chdir($dist->dirname) or die "Can't chdir to '@{[$dist->dirname]}': $!";

#########################

use_ok 'Module::Build';

my $mb = Module::Build->subclass(
   code => q#
        sub ACTION_testspecial { 
            shift->generic_test(type => 'special');
        }

        sub ACTION_testanother { 
            shift->generic_test(type => 'another');
        }
  #
  )->new(
      module_name => $dist->name,
      test_types  => {
          special => '.st',
          another => '.at',
      },
  );


ok $mb;

my $special_output = uc(stdout_of(
    sub {$mb->dispatch('testspecial', verbose => 1)}
));

like($special_output, qr/^OK 1 - FIRST TEST IN SPECIAL_EXT/m,
    'saw expected output from first test');
like($special_output, qr/^OK 2 - SECOND TEST IN SPECIAL_EXT/m,
    'saw expected output from second test');

my $another_output = uc(stdout_of(
    sub {$mb->dispatch('testanother', verbose => 1)}
));

ok($another_output, 'we have some test output');

like($another_output, qr/^OK 1 - FIRST TEST IN ANOTHER_EXT/m,
    'saw expected output from first test');
like($another_output, qr/^OK 2 - SECOND TEST IN ANOTHER_EXT/m,
    'saw expected output from second test');


my $all_output = uc(stdout_of(
    sub {$mb->dispatch('testall', verbose => 1)}
));

like($all_output, qr/^OK 1 - FIRST TEST IN SPECIAL_EXT/m,
    'expected output from basic.t');
like($all_output, qr/^OK 2 - SECOND TEST IN SPECIAL_EXT/m,
    'expected output from basic.t');

like($all_output, qr/^OK 1 - FIRST TEST IN ANOTHER_EXT/m);
like($all_output, qr/^OK 2 - SECOND TEST IN ANOTHER_EXT/m);

# we get a third one from basic.t
is(scalar(@{[$all_output =~ m/(OK 1)/mg]}), 3 );
is(scalar(@{[$all_output =~ m/(OK)/mg]}),   8 );

chdir($cwd) or die "Can't chdir to '$cwd': $!";
$dist->remove;

# vim:ts=4:sw=4:et:sta