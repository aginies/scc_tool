#!/usr/bin/perl -w
use strict;
use warnings;
 
use File::Temp qw(tempfile);
binmode STDOUT, ":utf8";
use utf8;
use JSON;
my $debug = 1;
 
my $URL ="https://scc.suse.com/api/package_search/products";
# curl -X GET "https://scc.suse.com/api/package_search/packages?product_id=1878&query=dracut" -H "accept: application/json" -H "Accept: application/vnd.scc.suse.com.v4+json"
my (undef, $tmp_file) = tempfile(SUFFIX => 'data.json');

my $cmd = "curl -s -X GET \"$URL\" -H \"accept: application/json\" -H \"Accept: application/vnd.scc.suse.com.v4+json\"";
system("$cmd > $tmp_file");

my $json;
{
  local $/; #Enable 'slurp' mode
  open my $fh, "<", $tmp_file;
  $json = <$fh>;
  close $fh;
}
my $data = decode_json($json);

sub check_var {
    use Data::Dumper;
    print Dumper($data);
}
#$debug and check_var

my $aref = $data->{data};
for my $element (@$aref) {
    print "SCC ID: $element->{id} | $element->{name} $element->{version} ($element->{architecture})\n";
}

