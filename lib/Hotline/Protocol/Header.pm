package Hotline::Protocol::Header;

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

    $self =
    {
      'TYPE' => join('', @bytes[0 .. 3]),
      'SEQ'  => join('', @bytes[4 .. 7]),
      'TASK' => join('', @bytes[8 .. 11]),
      'LEN'  => join('', @bytes[12 .. 15]),
      'LEN2' => join('', @bytes[16 .. 19])
    };
  }
  else
  {
    $self =
    {
      'TYPE' => 0x00000000,
      'SEQ'  => 0x00000000,
      'TASK' => 0x00000000,
      'LEN'  => 0x00000000,
      'LEN2' => 0x00000000
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

sub seq
{
  $_[0]->{'SEQ'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'SEQ'};
}

sub task
{
  $_[0]->{'TASK'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'TASK'};
}

sub len
{
  $_[0]->{'LEN'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'LEN'};
}

sub len2
{
  $_[0]->{'LEN2'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'LEN2'};
}

sub header
{
  my($header) = pack("N", $_[0]->{'TYPE'}) . 
                pack("N", $_[0]->{'SEQ'}) .
		pack("N", $_[0]->{'TASK'}) .
		pack("N", $_[0]->{'LEN'}) .
		pack("N", $_[0]->{'LEN2'});

  return $header;
}

1;
