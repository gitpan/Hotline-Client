package Hotline::Shared;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use IO;
use Carp;
use POSIX qw(F_GETFL F_SETFL O_NONBLOCK);

use strict;
use vars qw(@ISA @EXPORT);

require   Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(_encode _write _read _hexdump _debug _set_blocking);

sub _debug
{
  if($Hotline::Client::DEBUG)
  {
    print STDERR join('', @_);
  }
}

sub _encode
{
  my($data) = join('', @_);

  my($i, $char, @chars, $enc, $n);
  
  @chars = split('', $data);

  foreach $char (@chars)
  {
    $n = unpack("c", $char);
    $n = 255 - $n;
    $enc .= pack("c", $n);
  }
  
  return $enc;
}

sub _write
{
  my($fh, $data_ref, $length) = @_;
  
  my($written, $offset, $orig_len);
  
  $offset = 0;
  $orig_len = $length;
  
  while($length) # Handle partial writes
  {
    $written = syswrite($fh, $$data_ref, $length, $offset);
    die "System write error: $!\n"  unless(defined($written));
    $length -= $written;
    $offset += $written;
  }
  
  return $orig_len;
}

sub _read
{
  my($fh, $data_ref, $length) = @_;
  return sysread($fh, $$data_ref, $length);
}

sub _set_blocking
{
  my($fh, $blocking) = @_;

  if($IO::VERSION >= 1.19) # The easy way, with the IO module
  {
    $fh->blocking($blocking);
  }
  else # The hard way...not 100% successful :-/
  {
    my($flags) = fcntl($fh, F_GETFL, 0);

    defined($flags) || croak "Can't get flags for socket: $!\n";

    if($blocking)
    {
      fcntl($fh, F_SETFL, $flags & ~O_NONBLOCK) ||
        croak "Can't make socket blocking: $!\n";
    }
    else
    {
      fcntl($fh, F_SETFL, $flags | O_NONBLOCK) ||
        croak "Can't make socket nonblocking: $!\n";
    }     
  }
}

sub _hexdump
{
  my($data) = join('', @_);

  my(@bytes) = split('',$data);

  my($ret, $hex, $ascii, $i);

  for($i = 0; $i <= $#bytes; $i++)
  {
    if($i > 0)
    {
      if($i % 4 == 0)
      {
        $hex .= ' ';
      }

      if($i % 16 == 0)
      {
        $ret .= "$hex$ascii\n";
        $ascii = $hex = '';
      }
    }

    $hex .= sprintf("%02x ", ord($bytes[$i]));
    
    $ascii .= sprintf("%c",
                           (ord($bytes[$i]) > 31 and ord($bytes[$i]) < 127) ?
                             ord($bytes[$i]) : 46);
  }

  if(length($hex) < 50)
  {
    $hex .= ' ' x (50 - length($hex));
  }

  $ret .= "$hex  $ascii\n";
  
  $ret;
}

1;
