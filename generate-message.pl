#!/usr/bin/perl

my $msg = qq{

SerEE v1.2
Commands:
>rXX  read 1 byte @ address XX (2 bytes, little-endian)
      returns r1Y on success (Y is binary result byte)
>RXX  read XX (2 bytes, little-endian) bytes, starting @ addr 0
      returns a dump of all bytes};

my $msg2 = qq{
>wXXY write value Y @ address XX
      returns w1 on success
>t    DESTRUCTIVE self-test
      emits 'OK' on success or 'FAIL' on failure

};

# Returns count double on the length...
my $numrets = 0;
foreach my $i (split(//, $msg)) {
    $numrets++ 
	if ($i =~ /^$/);
}
if (length($msg)+1 >= 255-$numrets) {
    my $len = length($msg)+1+$numrets;
    die "Message too long ($len)\n";
}
my $numrets2 = 0;
foreach my $i (split(//, $msg2)) {
    $numrets2++ 
	if ($i =~ /^$/);
}
if (length($msg2)+1 >= 255-$numrets2) {
}

print "\torg\t0x40\nwelcome_msg2:\n\taddwf\tPCL, F\n";
foreach my $i (split(//, $msg2)) {
    if ($i =~ /^$/) {
	print "\tretlw\t0x0A\n";
	print "\tretlw\t0x0D\n";
    } else {
	print "\tretlw\t'$i'\n";
    }
}
print "\tretlw\t0\n\n";

print "\torg\t0x100\nwelcome_msg:\n\taddwf\tPCL, F\n";

foreach my $i (split(//, $msg)) {
    if ($i =~ /^$/) {
	print "\tretlw\t0x0A\n";
	print "\tretlw\t0x0D\n";
    } else {
	print "\tretlw\t'$i'\n";
    }
}
print "\tretlw\t0\n";

