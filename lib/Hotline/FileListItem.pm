package Hotline::FileListItem;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use strict;

sub new
{
  my($class, $data) = @_;
  my($self);

  if(defined($data))
  {
    my(@bytes) = split('', $data);

    my($name_len) = unpack("L", join('', @bytes[16 .. 19]));

    $self =
    {
      'TYPE'     => join('', @bytes[0 .. 3]),
      'CREATOR'  => join('', @bytes[4 .. 7]),
      'SIZE'     => unpack("L", join('', @bytes[8 .. 11])),
      'UNKNOWN'  => join('', @bytes[12 .. 15]),
      'NAME'     => join('', @bytes[20 .. (20 + $name_len)])
    };
  }
  else
  {
    $self =
    {    
      'TYPE'     => undef,
      'CREATOR'  => undef,
      'SIZE'     => 0x00000000,
      'UNKNOWN'  => 0x00000000,
      'NAME'     => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub type
{
  $_[0]->{'TYPE'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'TYPE'};
}

sub creator
{
  $_[0]->{'CREATOR'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'CREATOR'};
}

sub size
{
  $_[0]->{'SIZE'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'SIZE'};
}

sub name
{
  $_[0]->{'NAME'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'NAME'};
}

1;
