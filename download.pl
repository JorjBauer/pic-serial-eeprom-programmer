#!/usr/bin/perl

use strict;
use warnings;
use Device::SerialPort;
use Fcntl;
use Carp;

#############################
# NOTES:
#   fast_verify doesn't work.
#
#
#############################


$|=1;

#my $dev = "/dev/tty.usbserial";
my $dev = "/dev/tty.KeySerial1";

# Set up the serial port
my $quiet = 1;
my $port = Device::SerialPort->new($dev, $quiet, undef)
    || die "Unable to open serial port";
$port->user_msg(1);
$port->error_msg(1);
$port->databits(8);
$port->baudrate(9600);
$port->parity("none");
$port->stopbits(1);
$port->handshake("none");

my $baud = $port->baudrate;
my $parity = $port->parity;
my $data = $port->databits;
my $stop = $port->stopbits;
my $hshake = $port->handshake;
print "$baud ${data}/${parity}/${stop} handshake: $hshake\n";

#do_destructive_test($port);
do_download($port, "out.bin");
#do_write($port, "file.bin");
#do_verify($port, "file.bin");
#do_fast_verify($port, "file.bin");

$port->write_drain();
$port->close();

exit 0;

sub do_destructive_test {
    my ($p) = @_;

    print "Performing (destructive) self-test...\n";
    die "Failed to send '>t' command"
	unless ($p->write('>t') == 2);
    sleep 1;

    my $ret = read_byte($p);
    die "Test failed ('$ret' instead of 't')"
	unless ($ret eq 't');
    $ret = read_byte($p);
    die "Test failed"
	unless ($ret eq 'O');
    $ret = read_byte($p);
    die "Test failed"
	unless ($ret eq 'K');

    print "Self-test passed\n";
}

sub do_write {
    my ($p, $file) = @_;

    my $fh;
    open($fh, "file.bin") || die "Unable to open $file: $!";

    $p->purge_all();

    my $address = 0;
    my $buf;

    while ( sysread($fh, $buf, 1) ) {
	my $b = unpack('C', $buf); # $b is now the decimal value of the byte

	print sprintf("Address 0x%X: 0x%X\n", $address, $b);

	$p->write('>w' . chr($address & 0xFF) . chr($address >> 8) . chr($b));
	my $ret = read_byte($p);
	die "failed to read 'write' command confirmation"
	    unless ($ret eq 'w');
	$ret = read_byte($p);
	die "failed to write a byte at address $address [$ret]"
	    unless ($ret eq '1');

	# Verify the data, one byte at a time.
	$p->write('>r' . chr($address & 0xFF) . chr($address >> 8));
	$ret = read_byte($p);
	die "failed to read validation 'read' command confirmation"
	    unless ($ret eq 'r');
	$ret = read_byte($p);
	die "failed to read byte at address $address [$ret]"
	    unless ($ret eq '1');
	$ret = read_byte($p);
	die (sprintf "failed to validate byte at address $address [%d vs $b]",
	$ret)
	    unless ($ret eq chr($b));

	$address++;
    }
}

sub read_byte {
    my ($p) = @_;

    my $counter = 500000;
   
    my ($count, $data);
    do { 
	croak "Failed to read"
	    if ($counter == 0);
	$counter--;
	($count, $data) = $p->read(1);
    } while ($count == 0);

    return $data;
}

sub read_two_bytes {
    my ($p) = @_;

    my $counter = 500000;
    my $length = 0;

    my ($count, $data, @ret);
    while ($length < 2) {
	croak "Failed to read"
	    if ($counter == 0);
	$counter--;
	($count, $data) = $p->read(1);
	next if ($count == 0);

	$ret[$length] = $data;
	$length += $count;
    }

    return @ret;
}

sub do_fast_verify {
    my ($p, $file) = @_;

    my $fh;
    open($fh, "file.bin") || die "Unable to open $file: $!";

    $p->purge_all();

    my $address = 0;
    my $buf;
    my @buf;

    while ( sysread($fh, $buf, 1) ) {
	$buf[$address] = unpack('C', $buf); # array of decimal values of bytes
	$address++;
    }

    my $len = $address-1;

    # Send a 'read all' command for that number of bytes
    my $s = length(@buf);

    $s += 257; # debugging - loop off by one in .asm file
    
    die "Failed to write '>R'"
	unless ($p->write('>R' . chr($s & 0xFF) . chr($s >> 8)) == 4);

    my $ret = read_byte($p);
    die "Test failed ('$ret' instead of 'R')"
	unless ($ret eq 'R');

    print "Fast-verifying $len bytes\n";

    $address = 0;
    while ($address < $len) {
	print ".";
	my $ret = read_byte($p);
	die "verification failed at byte $address (want $buf[$address], got $ret)"
	    unless ($ret eq chr($buf[$address]));
	$address++;
    }
    print "fast-verify complete\n";
}

sub do_download {
    my ($p, $file) = @_;
    print "Downloading...\n";

    my $fh;
    open($fh, ">$file") || die "Unable to open $file: $!";
    select($fh); $|=1; select(STDOUT);

    $p->purge_all();

    my $address = 0;
    while ($address < 0x8000) {
	print sprintf("address: 0x%X\n", $address);
	die "Failed to write '>r'"
	    unless ($p->write('>r' . chr($address & 0xFF) . chr($address >> 8)) == 4);

	my $ret = read_byte($p);
	die "expected 'r', got '$ret'"
	    unless ($ret eq 'r');

	$ret = read_byte($p);
	die "expected '1', got '$ret'"
	    unless ($ret eq '1');

	$ret = read_byte($p);
	print $fh $ret;

	$address++;
    }
    close $fh;
}


sub do_verify {
    my ($p, $file) = @_;

    print "Verifying...\n";

    my $fh;
    open($fh, "file.bin") || die "Unable to open $file: $!";

    $p->purge_all();

    my $address = 0;
    my $buf;

    while ( sysread($fh, $buf, 1) ) {
	print ".";
	my $b = unpack('C', $buf); # $b is now the decimal value of the byte
#	print sprintf("Address 0x%X: 0x%X\n", $address, $b);

	die "Failed to write '>r'"
	    unless ($p->write('>r' . chr($address & 0xFF) . chr($address >> 8)) == 4);

	my @ret = read_two_bytes($p);
	die "failed to read 'read' command confirmation"
	    unless ($ret[0] eq 'r' && $ret[1] eq '1');

	my $ret = read_byte($p);
	die "failed to verify at address $address [want $buf ($b), got $ret]"
	    unless ($ret eq chr($b));

	$address++;
    }
}

