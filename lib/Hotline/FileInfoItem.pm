package Hotline::FileInfoItem;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use strict;

sub new
{
  my($class) = shift;

  my($self) =
  {
    'ICON'    => undef,
    'TYPE'    => undef,
    'CREATOR' => undef,
    'SIZE'    => undef,
    'NAME'    => undef,
    'COMMENT' => undef,
    'CTIME'   => undef,
    'MTIME'   => undef
  };

  bless  $self, $class;
  return $self;
}

sub icon
{
  $_[0]->{'TYPE'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'TYPE'};
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

sub comment
{
  $_[0]->{'COMMENT'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'COMMENT'};
}

sub ctime
{
  $_[0]->{'CTIME'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'CTIME'};
}

sub mtime
{
  $_[0]->{'MTIME'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'MTIME'};
}

1;
