package Hotline::Protocol::Packet;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use POSIX qw(EWOULDBLOCK EAGAIN);

use Hotline::User;
use Hotline::Shared;
use Hotline::FileListItem;
use Hotline::Protocol::Header;
use Hotline::Constants
  qw(HTLC_EWOULDBLOCK HTLC_NEWLINE HTLS_DATA_AGREEMENT HTLS_DATA_CHAT
     HTLS_DATA_COLOR HTLS_DATA_ICON HTLS_DATA_MSG HTLS_DATA_NEWS
     HTLS_DATA_NEWSPOST HTLS_DATA_NICKNAME HTLS_DATA_SERVERMSG HTLS_DATA_SOCKET
     HTLS_DATA_TASKERROR HTLS_DATA_USERINFO HTLS_DATA_USERLIST HTLS_HEADER_TASK
     SIZEOF_HL_PROTO_HDR HTLS_DATA_FILELISTITEM HTLS_DATA_FILETYPE
     HTLS_DATA_FILECREATOR HTLS_DATA_FILESIZE HTLS_DATA_FILENAME
     HTLS_DATA_FILECOMMENT HTLS_DATA_FILEICON HTLS_DATA_FILECTIME
     HTLS_DATA_FILEMTIME);

use strict;

sub new
{
  my($class) = shift;
  my($self);

  $self =
  {
    'PROTO_HEADER' => undef,

    'USERLIST'     => undef,
    'FILELIST'     => undef,
    'USERINFO'     => undef,
    'NEWS'         => undef,

    'SOCKET'       => undef,
    'ICON'         => undef,
    'COLOR'        => undef,
    'NICK'         => undef,
    'TASKERROR'    => undef,
    'DATA'         => undef,

    'FILE_ICON'    => undef,
    'FILE_TYPE'    => undef,
    'FILE_CREATOR' => undef,
    'FILE_SIZE'    => undef,
    'FILE_NAME'    => undef,
    'FILE_COMMENT' => undef,
    'FILE_CTIME'   => undef,
    'FILE_MTIME'   => undef,

    'TYPE'         => undef
  };

  bless  $self, $class;
  return $self;
}

sub clear
{
  my($self) = shift;

  $self->{'PROTO_HEADER'} = 
  
  $self->{'USERLIST'}     =
  $self->{'FILELIST'}     =
  $self->{'USERINFO'}     =
  $self->{'NEWS'}         = 
  
  $self->{'SOCKET'}       =
  $self->{'ICON'}         =
  $self->{'COLOR'}        =
  $self->{'NICK'}         = 
  $self->{'TASKERROR'}    =  
  $self->{'DATA'}         = 

  $self->{'FILE_ICON'}    =
  $self->{'FILE_TYPE'}    =
  $self->{'FILE_CREATOR'} =
  $self->{'FILE_SIZE'}    =
  $self->{'FILE_NAME'}    =
  $self->{'FILE_COMMENT'} =
  $self->{'FILE_CTIME'}   =
  $self->{'FILE_MTIME'}   =

  $self->{'TYPE'} = undef;
}

sub read_parse
{
  my($self, $fh, $blocking) = @_;

  my($data, $length, $atom_count, $atom_type, $atom_len, $read_err,
     $nick, $socket, $icon, $user_type, $name, $color, $read);

  $blocking = 1  unless(defined($blocking));

  $self->clear();

  unless($fh->opened())
  {
    $self->{'TYPE'} = 'DISCONNECTED';
    return(1);
  }

  $read = _read($fh, \$data, SIZEOF_HL_PROTO_HDR);
  $read_err = 0 + $!; # Get the numerical value of the magical $!

  # EWOULDBLOCK only applies if we're in non-blocking mode, and
  # $! is only meaningful when sysread() returns undef
  if(!$blocking && !defined($read) &&
     ($read_err == EWOULDBLOCK || $read_err == EAGAIN))
  {
    return(HTLC_EWOULDBLOCK);
  }

  # Unix Perl: when sysread() returns 0, we've been disconneted
  # MacPerl: when sysread() returns undef and we're either in
  # blocking i/o mode or there was some sort of error, we've 
  # been disconnected.
  if((defined($read) && $read == 0) ||
     (!defined($read) && ($blocking || $read_err)))
  {
    $self->clear();
    $self->{'TYPE'} = 'DISCONNECTED';
    return(1);
  }

  _debug("Packet data:\n", _hexdump($data));

  $self->{'PROTO_HEADER'} = new Hotline::Protocol::Header($data);

  $length = unpack("i", $self->{'PROTO_HEADER'}->len());
  $self->{'TYPE'} = unpack("i", $self->{'PROTO_HEADER'}->type());

  if($self->{'TYPE'} == HTLS_HEADER_TASK)
  {
    $self->{'TASK_NUM'} = unpack("N", $self->{'PROTO_HEADER'}->seq());
  }

  $length -= _read($fh, \$atom_count, 2);
  $atom_count = unpack("S", $atom_count);

  _debug("Atom count: $atom_count\n");

  for(; $atom_count != 0; $atom_count--)
  {
    if($length < 4)
    {
      $length -= _read($fh, \$data, $length);
      _debug("Slurped up < 4 bytes, length = $length\n");
      return(1);
    }

    $length -= _read($fh, \$atom_type, 2);
    $length -= _read($fh, \$atom_len, 2);

    _debug("Atom type:\n",  _hexdump($atom_type));
    _debug("Atom length:\n", _hexdump($atom_len));

    $atom_type = unpack("S", $atom_type);
    $atom_len = unpack("S", $atom_len);

    if($atom_type == HTLS_DATA_USERLIST)
    {
      my($user_data, $user);

      $length -= _read($fh, \$user_data, $atom_len);

      $user = new Hotline::User($user_data);

      _debug(" Nick: ", $user->nick(), "\n",
             " Icon: ", $user->icon(), "\n",
            "Socket: ", $user->socket(), "\n",
            " Color: ", $user->color(), "\n");

      $self->{'USERLIST'}->{$user->socket()} = $user;
    }
    elsif($atom_type == HTLS_DATA_FILELISTITEM)
    {
      my($file_data, $file);

      $length -= _read($fh, \$file_data, $atom_len);

      $file = new Hotline::FileListItem($file_data);

      _debug("   Type: ", $file->type(), "\n",
             "Creator: ", $file->creator(), "\n",
             "   Size: ", $file->size(), "\n",
             "   Name: ", $file->name(), "\n");

      push(@{$self->{'FILELIST'}}, $file);
    }
    elsif($atom_type == HTLS_DATA_SOCKET)
    {
      $length -= _read($fh, \$socket, $atom_len);

      _debug("Socket: ", _hexdump($socket));

      # Older versions of the Hotline server sent socket numbers
      # in 4 bytes.  Newer versions send it in 2.  Nice.
      if($atom_len == 4)
      {
        $self->{'SOCKET'} = unpack("N", $socket);
      }
      else
      {
        $self->{'SOCKET'} = unpack("S", $socket);
      }
    }
    elsif($atom_type == HTLS_DATA_ICON)
    {
      $length -= _read($fh, \$icon, $atom_len);

      _debug("Icon: ", _hexdump($icon));

      $self->{'ICON'} = unpack("S", $icon);
    }
    elsif($atom_type == HTLS_DATA_COLOR)
    {
      $length -= _read($fh, \$color, $atom_len);

      _debug("Color: ", _hexdump($color));

      $self->{'COLOR'} = unpack("S", $color);
    }
    elsif($atom_type == HTLS_DATA_NICKNAME)
    {
      $length -= _read($fh, \$nick, $atom_len);

      _debug("Nick: ", _hexdump($nick));

      $self->{'NICK'} = $nick;
    }
    elsif($atom_type == HTLS_DATA_TASKERROR)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Task error:\n", _hexdump($data));

      $data =~ s/@{[HTLC_NEWLINE]}/\n/osg;
      $self->{'TASKERROR'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILEICON)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File icon:\n", _hexdump($data));

      $self->{'FILE_ICON'} = unpack("n", $data);
    }
    elsif($atom_type == HTLS_DATA_FILETYPE)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File type:\n", _hexdump($data));

      $self->{'FILE_TYPE'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILECREATOR)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File creator:\n", _hexdump($data));

      $self->{'FILE_CREATOR'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILESIZE)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File size:\n", _hexdump($data));

      $self->{'FILE_SIZE'} = unpack("N", $data);
    }
    elsif($atom_type == HTLS_DATA_FILENAME)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File name:\n", _hexdump($data));

      $self->{'FILE_NAME'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILECOMMENT)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File comment:\n", _hexdump($data));

      $self->{'FILE_COMMENT'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILECTIME)
    {
      $length -= _read($fh, \$data, $atom_len);

      $data =~ s/^....//;
      _debug("File ctime:\n", _hexdump($data));

      $self->{'FILE_CTIME'} = unpack("N", $data);
    }
    elsif($atom_type == HTLS_DATA_FILEMTIME)
    {
      $length -= _read($fh, \$data, $atom_len);

      $data =~ s/^....//;
      _debug("File mtime:\n", _hexdump($data));

      $self->{'FILE_MTIME'} = unpack("N", $data);
    }
    elsif($atom_type == HTLS_DATA_MSG       ||
          $atom_type == HTLS_DATA_NEWS      ||
          $atom_type == HTLS_DATA_AGREEMENT ||
          $atom_type == HTLS_DATA_USERINFO  ||
          $atom_type == HTLS_DATA_CHAT      ||
          $atom_type == HTLS_DATA_MSG       ||
          $atom_type == HTLS_DATA_SERVERMSG ||
          $atom_type == HTLS_DATA_NEWSPOST)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Data:\n", _hexdump($data));

      $data =~ s/@{[HTLC_NEWLINE]}/\n/osg;
      $self->{'DATA'} = $data;
    }
    else
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Default data:\n", _hexdump($data));
      $self->{'DATA'} = $data;
    }
  }

  if($length > 0)
  {
    _debug("Left-over length!\n");

    while($length > 0)
    {
      $length -= _read($fh, \$data, $length);
      _debug("Left over data:\n", _hexdump($data));
    }
  }
 
  return(1);
}

1;
