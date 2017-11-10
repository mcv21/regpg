#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

my $k1 = 'regpg-one@testing.example';
my $k2 = 'regpg-two@testing.example';
my $kd = 'dummy@this-key-is.invalid';

sub checklist {
	my %k = @_;
	works 'list keys', '' => $regpg, qw(lskeys);
	for my $k (@{$k{like}}) {
		my $qk = quotemeta $k;
		like $stdout, qr{$qk}, "list contains $k";
	}
	for my $k (@{$k{unlike}}) {
		my $qk = quotemeta $k;
		unlike $stdout, qr{$qk}, "list omits $k";
	}
}

works 'add key one', '' => $regpg, 'addkey', $k1;
is $stdout, '', 'add stdout is quiet';
like $stderr, qr{imported}, 'add stderr is noisy';

subtest 'list keys (one)' => sub {
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

works 'import key two', '' => $regpg, 'addkey', $k2;

subtest 'list keys (both)' => sub {
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

gpg_batch_yes;
works 'delete key one', '' => $regpg, 'delkey', $k1;
unlink $gpgconf;

subtest 'list keys (two)' => sub {
	checklist like => [ $k2 ],
	    unlike => [ $k1, $kd ];
};

my $so = $stdout;
my $se = $stderr;
subtest 'ls synonym', => sub {
	works 'ls', '' => $regpg, 'ls';
	is $stdout, $so, 'stdout matches';
	is $stderr, $se, 'stderr matches';
};

subtest 'add synonym', => sub {
	works 'add', '' => $regpg, 'add', $k1;
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'del synonym', => sub {
	gpg_batch_yes;
	works 'del', '' => $regpg, 'del', $k2;
	unlink $gpgconf;
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

subtest 'del all', => sub {
	gpg_batch_yes;
	works 'del', '' => $regpg, 'del', $k1;
	unlink $gpgconf;
	checklist like => [ ],
	    unlike => [ $k1, $k2, $kd ];
	ok -z 'pubring.gpg', 'empty keyring';
};

subtest 'dummy re-init of empty keyring', => sub {
	works 'add', '' => $regpg, 'add', '-v', $k1;
	like $stderr, qr{--delete-key}, 'delete dummy key';
	like $stderr, qr{0xA3F96E2C6131531B}, 'dummy key id';
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

subtest 'add both', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'add', '' => $regpg, 'add', $k1, $k2;
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'addself', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	local $ENV{USER} = 'testing.example';
	works 'addself', '' => $regpg, 'addself';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

my $pubkey = qr{-----BEGIN PGP PUBLIC KEY BLOCK-----};
subtest 'export all', => sub {
	works 'export keys',
	    '' => $regpg, 'exportkey';
	is $stderr, '', 'export stderr is quiet';
	like $stdout, $pubkey, 'exported public key';
	spew 'export', $stdout;
};
subtest 'export one', => sub {
	works 'export key one',
	    '' => $regpg, 'exportkey', $k1;
	is $stderr, '', 'export stderr is quiet';
	like $stdout, $pubkey, 'exported public key';
	spew 'one', $stdout;
};
subtest 'export two', => sub {
	works 'export key two',
	    '' => $regpg, 'exportkey', $k2;
	is $stderr, '', 'export stderr is quiet';
	like $stdout, $pubkey, 'exported public key';
	spew 'two', $stdout;
};

subtest 'importkey pipe', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'importkey',
	    slurp('export') => $regpg, 'importkey';
	like $stderr, qr{imported}, 'import stderr is noisy';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};
subtest 'importkey file', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'importkey',
	    '' => $regpg, 'importkey', 'export';
	like $stderr, qr{imported}, 'import stderr is noisy';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};
subtest 'importkey files', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'importkey',
	    '' => $regpg, qw(importkey one two);
	like $stderr, qr{imported}, 'import stderr is noisy';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

unlink 'export';

done_testing;
exit;
