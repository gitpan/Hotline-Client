package Hotline::Task;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use strict;

sub new
{
  my($class, @args) = @_;

  my($self);

  if(@args >= 3)
  {
    $self =
    {
      'NUM'     => $args[0],
      'TYPE'    => $args[1],
      'START'   => $args[2],
      'SOCKET'  => $args[3],
      'PATH'    => $args[4],
      'FINISH'  => undef,
      'ERROR'   => undef,
      'ERRTXT'  => undef
    };
  }
  else
  {
    $self =
    {
      'NUM'     => undef,
      'TYPE'    => undef,
      'SOCKET'  => undef,
      'PATH'    => undef,
      'START'   => undef,
      'FINISH'  => undef,
      'ERROR'   => undef,
      'ERRTXT'  => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub num
{
  $_[0]->{'NUM'} = $_[1]  if($_[1] =~ /^\d+$/);
  return $_[0]->{'NUM'};
}

sub type
{
  $_[0]->{'TYPE'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'TYPE'};
}

sub path
{
  $_[0]->{'PATH'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'PATH'};
}

sub socket
{
  $_[0]->{'SOCKET'} = $_[1]  if($_[1] =~ /^\d+$/);
  return $_[0]->{'SOCKET'};
}

sub start
{
  $_[0]->{'START'} = $_[1]  if($_[1] =~ /^\d+$/);
  return $_[0]->{'START'};
}

sub finish
{
  $_[0]->{'FINISH'} = $_[1]  if($_[1] =~ /^\d+$/);
  return $_[0]->{'FINISH'};
}

sub error
{
  $_[0]->{'ERROR'} = $_[1]  if(@_ == 2);
  return $_[0]->{'ERROR'};
}

sub error_text
{
  $_[0]->{'ERRTXT'} = $_[1]  if(@_ == 2);
  return $_[0]->{'ERRTXT'};
}

1;
