#!/usr/bin/perl

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use Test::More;

use T;

################################################################

chdir $FindBin::Bin;

rmtree $gnupg;
mkpath $gnupg;
chmod 0700, $gnupg;

ok -d $gnupg, "created gnupg home $gnupg";
is 0777 & (stat _)[2], 0700, 'permissions on gnupg home';

rmtree $work;
mkpath $work;
ok -d $work, 'created working directory';

mkpath $testbin;
symlink "../../regpg" => $regpg;
ok -l $regpg, 'regpg on test exec path';

################################################################

done_testing;
exit;
