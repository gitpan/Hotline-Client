package Hotline::User;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use strict;

sub new
{
  my($class, @args) = @_;

  my($data) = join('', @args);

  my($self);

  if(@args == 5)
  {
    $self =
    {
      'SOCKET'    => $args[0],
      'NICK'      => $args[1],
      'LOGIN'     => $args[2],
      'ICON'      => $args[3],
      'COLOR'     => $args[4],
      'INFO'      => undef
    };
  }
  elsif(@args == 1)
  {
    my(@bytes) = split('', $data);
    my($nick_len) = unpack("S", join('', @bytes[6 .. 7]));

    $self =
    {
      'SOCKET'    => unpack("S", join('', @bytes[0 .. 1])),
      'ICON'      => unpack("S", join('', @bytes[2 .. 3])),
      'COLOR'     => unpack("S", join('', @bytes[4 .. 5])),
      'NICK'      => join('', @bytes[8 .. (8 + $nick_len)]),
      'LOGIN'     => undef,
      'INFO'      => undef
    };
  }
  else
  {
    $self =
    {
      'SOCKET'    => undef,
      'NICK'      => undef,
      'LOGIN'     => undef,
      'ICON'      => undef,
      'COLOR'     => undef,
      'INFO'      => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub socket
{
  $_[0]->{'SOCKET'} = $_[1]  if($_[1] =~ /^\d+$/);
  return $_[0]->{'SOCKET'};
}

sub nick
{
  $_[0]->{'NICK'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'NICK'};
}

sub login
{
  $_[0]->{'LOGIN'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'LOGIN'};
}

sub icon
{
  $_[0]->{'ICON'} = $_[1]  if($_[1] =~ /^-?\d+$/);
  return $_[0]->{'ICON'};
}

sub color
{
  $_[0]->{'COLOR'} = $_[1]  if($_[1] =~ /^\d+$/);
  return $_[0]->{'COLOR'};
}

sub info
{
  $_[0]->{'INFO'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'INFO'};
}

1;
