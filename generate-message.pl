#!/usr/bin/perl

my $msg = qq{

SerEE v1.1
Cmds:
>rXX  read 1 byte @ address XX (2 bytes, ltl-endian)
      retns r1Y on success (Y is binary result byte)
>wXXY write value Y @ address XX
      retns w1 on success
>t    DESTRUCTIVE self-test
      emits 'OK' on success

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

print "welcome_msg:\n\taddwf\tPCL, F\n";

foreach my $i (split(//, $msg)) {
    if ($i =~ /^$/) {
	print "\tretlw\t0x0A\n";
	print "\tretlw\t0x0D\n";
    } else {
	print "\tretlw\t'$i'\n";
    }
}
print "\tretlw\t0\n";
