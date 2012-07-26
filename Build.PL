
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "Module::Build" => "0.4001",
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4001"
  },
  "dist_abstract" => "Easy temporary directories associated with packages.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "File-Tempdir-ForPackage",
  "dist_version" => "0.1.1",
  "license" => "perl",
  "module_name" => "File::Tempdir::ForPackage",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::Path" => 0,
    "File::Temp" => 0,
    "File::pushd" => 0,
    "Moo" => 0,
    "Sub::Quote" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
