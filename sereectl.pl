#!/usr/bin/perl

use strict;
use warnings;
use Device::SerialPort;
use Fcntl;
use Carp;
use Getopt::Std;

$|=1;

our ($opt_d, $opt_r, $opt_R, $opt_h, $opt_f, $opt_q, $opt_t, $opt_w, $opt_v, $opt_V);

getopts('d:hf:qrRtwvV');

# Must have a serial port.
usage() if ($opt_h || !$opt_d);

# Can't mix download and upload operations
usage() if ( ($opt_r || $opt_R) && ($opt_w) );

# Can't mix selftest with other modes
usage() if ($opt_t && ($opt_r || $opt_R || $opt_w || $opt_v || $opt_V));

# download and fast download together don't make sense
usage() if ($opt_r && $opt_R);

# Set up the serial port
my $port = open_serial();

if ($opt_t) {
    do_destructive_test($port);
}
if ($opt_r) {
    do_download($port, $opt_f);
}
if ($opt_R) {
    do_fast_download($port, $opt_f);
}
if ($opt_w) {
    do_write($port, $opt_f);
}
if ($opt_v) {
    do_verify($port, $opt_f);
}
if ($opt_V) {
    do_fast_verify($port, $opt_f);
}

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
    open($fh, $file) || die "Unable to open $file: $!";

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
	ord($ret))
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
    open($fh, $file) || die "Unable to open $file: $!";

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

sub do_fast_download {
    my ($p, $file) = @_;
    print "Fast downloading...\n";

    my $fh;
    open($fh, ">", $file) || die "Unable to open $file: $!";

    $p->purge_all();

    # Send a 'read all' command for 0x8000 bytes
    my $len = 0x8000;
    die "Failed to write '>R'"
	unless ($p->write('>R' . chr($len & 0xFF) . chr($len >> 8)) == 4);

    my $ret = read_byte($p);
    die "Test failed ('$ret' instead of 'R')"
	unless ($ret eq 'R');


    my $address = 0;
    while ($address < $len) {
	if ($address % 256 == 0) {
	    print ".";
	}
	my $ret = read_byte($p);
	print $fh $ret;
	$address++;
    }
    print "\nfast-read complete\n";
    close $fh;
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
    open($fh, $file) || die "Unable to open $file: $!";

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

sub open_serial {
    my $port = Device::SerialPort->new($opt_d, $opt_q ? 1 : 0, undef)
	|| die "Unable to open serial port";
    $port->user_msg(1);
    $port->error_msg(1);
    $port->databits(8);
    $port->baudrate(19200);
    $port->parity("none");
    $port->stopbits(1);
    $port->handshake("none");
    
    my $baud = $port->baudrate;
    my $parity = $port->parity;
    my $data = $port->databits;
    my $stop = $port->stopbits;
    my $hshake = $port->handshake;
    print "$baud ${data}/${parity}/${stop} handshake: $hshake\n"
	unless ($opt_q);
    return $port;
}

sub usage {
    print "At least a serial port and one action must be specified.\n\n";

    print $0, "\n";
    print "\t-h            this help message\n\n";
    print "\t-d <device>   serial port to use\n";
    print "\t-q            open serial port quietly\n";
    print "\t-f <file>     file argument for action commands\n";
    print "\n";
    print "\t-r            download (read) from EEPROM to specified file\n";
    print "\t-R            fast download (read) from EEPROM to specified file\n";
    print "\t-t            perform destructive self-test\n";
    print "\t-w            write specified file to EEPROM\n";
    print "\t-v            verify that EEPROM contains contents of file\n";
    print "\t-V            fast verify that EEPROM contains contents of file\n";
    print "\n";
    print "Read and verify operations may be specified together, but\n";
    print "may not be mixed with write. The self-test operation may\n";
    print "only be specified by itself; this runs the EEPROM programmer's\n";
    print "built-in self test, which overwrites part of the EEPROM.\n";
    print "\n";
    exit(-1);
}
