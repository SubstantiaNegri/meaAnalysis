#!/usr/bin/perl

my $linecount = @ARGV[0]; #parse linecount from cmd argument

sub jobTimeCalc {
	$jobtimeSec = (1/10e8)*$linecount**3 + (1/10e3)*$linecount**2 + (1/10e0)*$linecount;
	$jobtimeMin = int($jobtimeSec/60)+1;
	print "$jobtimeMin";
}

jobTimeCalc();