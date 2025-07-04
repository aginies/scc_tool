#!/usr/bin/perl -w
# aginies@suse.com
# QUICK SCRIPT TO GET VERSION OF A PACKAGE FOR A PRODUCT
# FROM SCC
# perl-JSON perl-Text-Table must be installed
#
use strict;
use warnings;
use File::Temp qw(tempfile);
binmode STDOUT, ":utf8";
use utf8;
use JSON;
use Data::Dumper;

my $debug = 1;
my $URL = "";
my $BASEURL = "https://scc.suse.com/api/package_search/";

# NEED TO GET THE PACKAGE NAME TO SEARCH (PRODUCT ID is optionnal)
if (!$ARGV[0]) { 
    print "\n";
    print " First arg must be the package to find!\n";
    print " Second arg could be Product ID (optionnal)\n";
    print " IE: qemu-kvm version for SLE15SP4 and SLE15SP5\n";
    print "./get_version_from_scc.pl qemu-kvm 2582,2421 \n\n";
    print "HPC SLE15SP6: aarch64 2613 | x86_64 2614 \n";
    print "HPC SLE15SP5: aarch64 2469 | x86_64 2470 \n";
    print "SLE16: aarch64 2931 | 2930 x86_64\n";
    print "SLE15SP7: aarch64 2790 | x86_64 2793 \n";
    print "SLE15SP6: aarch64 2606 | x86_64 2608 \n";
    print "SLE15SP5: aarch64 2462 | x86_64 2465 \n";
    print "\n ";
    exit 0;
}

# USER ENTER PRODUCT ID
my $productid;
if ($ARGV[1]) { 
    $productid = $ARGV[1];
} else {    
    $URL = $BASEURL . "products";
    my (undef, $tmpproduct_file) = tempfile(SUFFIX => 'data.json');
    my $cmdp = "curl -s -X GET \"$URL\" -H \"accept: application/json\" -H \"Accept: application/vnd.scc.suse.com.v4+json\"";
    system("$cmdp > $tmpproduct_file");
    
    my $jsonp;
    {
	local $/; #Enable 'slurp' mode
	open my $fh, "<", $tmpproduct_file;
	$jsonp = <$fh>;
	close $fh;
    }
    my $datap = decode_json($jsonp);
    
    # SHOW ALL PRODUCTS AVAILABLE IN SCC
    my $arefp = $datap->{data};
    for my $element (@$arefp) {
	print "Product ID: $element->{id} | $element->{name} $element->{edition} ($element->{architecture})\n";
    }

    print "-----------------------------\n";
    print " Please enter Product ID:\n";
    print " [ENTER]\n";
    $productid = <STDIN>;
    chomp $productid;

    #sub check_var {
    #use Data::Dumper;
    #print Dumper($datap);
    #}
    #$debug and check_var;
}

# START TO DO THE QUERY TO GET THE PACKAGE VERSION
$URL = $BASEURL . "packages?product_id";
# curl -X GET "https://scc.suse.com/api/package_search/packages?product_id=1878&query=dracut" -H "accept: application/json" -H "Accept: application/vnd.scc.suse.com.v4+json"
my (undef, $tmp_file) = tempfile(SUFFIX => 'data.json');
my $cmd = "curl -s -X GET \"$URL=$productid&query=$ARGV[0]\" -H \"accept: application/json\" -H \"Accept: application/vnd.scc.suse.com.v4+json\"";
system("$cmd > $tmp_file");

my $json;
{
    local $/; #Enable 'slurp' mode
    open my $fh, "<", $tmp_file;
    $json = <$fh>;
    close $fh;
}
my $data = decode_json($json);

# THE OUTPUT
#         'data' => [
#                      {
#                       'name' => 'dracut',
#                       'arch' => 'x86_64',
#                       'version' => '044.2',
#                       'products' => [
#                                       {
#                                         'name' => 'SUSE Linux Enterprise Server',
#                                         'architecture' => 'x86_64',
#                                         'edition' => '12 SP5',
#                                         'id' => 1878,
#                                         'free' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
#                                         'identifier' => 'SLES/12.5/x86_64',
#                                         'type' => 'base'
#                                       }
#                                     ],
#                       'release' => '17.3.1',
#                       'id' => 19759909
#                     },

# SHOW THE RESULT
#
use Text::Table;
my $tb = Text::Table->new(
    "Identifier", "Name", "Version", ); # "Products",

$tb->load( [ "----------" , "----", "-------",] ); # "-------" ] );

my $aref = $data->{data};
for my $element (@$aref) {
    #print "$element->{products}->[0]->{name} $element->{products}->[0]->{edition}";
    #print "($element->{products}->[0]->{identifier}): ";
    #print " $element->{name}-$element->{version}-$element->{release}\n";
    #print Dumper $element;
    $tb->load(
        [
            $element->{products}->[0]->{identifier}, 
            $element->{name}, 
            "$element->{version}-$element->{release}",
            #            "$element->{products}->[0]->{name} $element->{products}->[0]->{architecture} $element->{products}->[0]->{edition}",
        ],
	);
    
}
print $tb;
