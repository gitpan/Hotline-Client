package Hotline::Client;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use Carp;
use IO::Socket;
use Hotline::User;
use Hotline::Task;
use Hotline::Shared;
use Hotline::FileListItem;
use Hotline::FileInfoItem;
use Hotline::Protocol::Packet;
use Hotline::Protocol::Header;
use Hotline::Constants
  qw(HTLC_CHECKBYTES HTLC_DEFAULT_LOGIN HTLC_DEFAULT_NICK
     HTLC_DEFAULT_ICON HTLC_DATA_CHAT HTLC_DATA_ICON HTLC_DATA_LOGIN
     HTLC_DATA_MSG HTLC_DATA_NICKNAME HTLC_DATA_OPTION HTLC_DATA_LISTDIR
     HTLC_DATA_PASSWORD HTLC_DATA_SOCKET HTLC_EWOULDBLOCK
     HTLC_HANDSHAKE HTLC_HEADER_CHANGE HTLC_HEADER_CHAT
     HTLC_HEADER_GETNEWS HTLC_HEADER_GETUSERINFO
     HTLC_HEADER_GETUSERLIST HTLC_HEADER_KICK HTLC_HEADER_LOGIN
     HTLC_HEADER_MSG HTLC_HEADER_NEWSPOST HTLC_NEWLINE HTLC_TASK_KICK
     HTLC_TASK_LOGIN HTLC_TASK_SEND_MSG HTLC_TASK_NEWS HTLC_TASK_POST_NEWS
     HTLC_TASK_USERINFO HTLC_TASK_USERLIST HTLS_DATA_NEWSPOST
     HTLS_HEADER_AGREEMENT HTLS_HEADER_CHAT HTLS_HEADER_MSG
     HTLS_HEADER_NEWSPOST HTLS_HEADER_POLITEQUIT HTLC_HEADER_LISTFILES
     HTLS_HEADER_PRIVCHAT_INVITE HTLS_HEADER_PRIVCHAT_SUBJECT
     HTLS_HEADER_PRIVCHAT_USERDISCONNECT HTLC_MAX_PATHLEN
     HTLS_HEADER_PRIVCHAT_USERUPDATE HTLS_HEADER_TASK HTLC_TASK_FILELIST
     HTLS_HEADER_USERDISCONNECT HTLS_HEADER_USERUPDATE HTLS_TCPPORT
     SIZEOF_HL_LONG_HDR SIZEOF_HL_PROTO_HDR SIZEOF_HL_SHORT_HDR
     SIZEOF_HL_TASK_FILLER HTLC_TASK_FILEINFO HTLC_HEADER_GETFILEINFO
     HTLC_DATA_FILE HTLC_DATA_DIRECTORY HTLC_TASK_SET_INFO
     HTLC_DATA_RENAMEFILE HTLC_DATA_DESTDIR HTLC_HEADER_CHANGEFILEINFO
     HTLS_DATA_FILECOMMENT HTLC_HEADER_DELETEFILE HTLC_TASK_DELETEFILE
     HTLC_HEADER_NEWFOLDER HTLC_TASK_NEWFOLDER HTLC_HEADER_MOVEFILE
     HTLC_TASK_MOVEFILE);

use strict;

$Hotline::Client::VERSION = '0.50';
$Hotline::Client::DEBUG   = 0;

1;

sub version { return $Hotline::Client::VERSION }

sub new
{
  my($class) = shift;
  my($self);

  $self =
  {
    'NICK'        => undef,
    'LOGIN'       => undef,
    'COLOR'       => undef,
    'SERVER_ADDR' => undef,

    'SOCKET'      => undef,
    'BLOCKING'    => 1,
    'SERVER'      => undef,
    'SEQNUM'      => 1,

    'USERLIST'    => undef,
    'NEWS'        => undef,
    'FILES'       => undef,
    'AGREEMENT'   => undef,

    'HANDLERS'  =>
    {
      'AGREEMENT'     => undef,
      'CHAT'          => undef,
      'CHAT_ACTION'   => undef,
      'COLOR'         => undef,
      'NEW_FOLDER'    => undef,
      'DELETE_FILE'   => undef,
      'EVENT'         => undef,
      'FILELIST'      => undef,
      'FILEINFO'      => undef,
      'ICON'          => undef,
      'JOIN'          => undef,
      'KICK'          => undef,
      'LEAVE'         => undef,
      'LOGIN'         => undef,
      'MOVE_FILE'     => undef,
      'MSG'           => undef,
      'SERVER_MSG'    => undef,
      'NEWS'          => undef,
      'NICK'          => undef,
      'POST_NEWS'     => undef,
      'QUIT'          => undef,
      'SEND_MSG'      => undef,
      'SET_INFO'      => undef,
      'TASKERROR'     => undef,
    },
    
    'DEFAULT_HANDLERS' => 1,
    'EVENT_TIMING'     => 1,
    'PATH_SEPARATOR'   => ':',
    'LAST_ACTIVITY'    => time(),
    'TASKS'            => undef
  };

  bless  $self, $class;
  return $self;
}

sub server
{
  my($self) = shift;

  if(defined($self))
  {
    return $self->{'SERVER_ADDR'};
  }
  return(undef);
}

sub connect
{
  my($self, $server) = @_;

  my($address, $port);
  
  if(($address = $server) =~ s/^([^ :]+)(?:[: ](\d+))?$/$1/)
  {
    $port = $2 || HTLS_TCPPORT;
  }
  else
  {
    croak("Bad server address: $server\n");
  }
  
  $self->{'SERVER'} = 
    IO::Socket::INET->new(PeerAddr =>$address,
                          PeerPort =>$port,
                          Timeout  =>5,
                          Proto    =>'tcp') || return(undef);

  return(undef)  unless($self->{'SERVER'});

  $self->{'SERVER'}->autoflush(1);

  $self->{'SERVER_ADDR'} = "$address";
  
  $self->{'SERVER_ADDR'} .= ":$port"
    if($port !=  HTLS_TCPPORT);

  return(1);
}

sub disconnect
{
  my($self) = shift;
  
  if($self->{'SERVER'} && $self->{'SERVER'}->opened())
  {
    $self->{'SERVER'}->close();
    return(1);
  }
  return(undef);
}

sub blocking
{
  my($self, $blocking) = @_;
 
  return $self->{'BLOCKING'}  unless(defined($blocking));
  $self->{'BLOCKING'} = (($blocking) ? 1 : 0);
  return $self->{'BLOCKING'};
}

sub path_separator
{
  my($self, $separator) = @_;
  $self->{'PATH_SEPARATOR'} = $separator  if($separator =~ /^.$/);
  return $self->{'PATH_SEPARATOR'};
}

sub event_timing
{
  my($self, $secs) = @_;
  
  if(defined($secs))
  {
    croak "Bad argument to event_timing()\n"  if($secs =~ /[^0-9.]/);
    $self->{'EVENT_TIMING'} = $secs;
  }

  return $self->{'EVENT_TIMING'};
}

sub last_activity
{
  my($self) = shift;
  return $self->{'LAST_ACTIVITY'};
}

sub login
{
  my($self, %args) = @_;

  my($nick, $login, $password, $icon);
  my($proto_header, $data, $response, $task_num);

  my($server) = $self->{'SERVER'};
  
  unless($server->opened())
  {
    croak("login() called before connect()");
  }

  $nick  = $args{'Nickname'} || HTLC_DEFAULT_NICK;
  $login = $args{'Login'}    || HTLC_DEFAULT_LOGIN;
  $icon  = $args{'Icon'}     || HTLC_DEFAULT_ICON;
  $password = $args{'Password'};

  $self->{'NICK'}  = $nick;
  $self->{'LOGIN'} = $login;
  $self->{'ICON'}  = $icon;

  _write($server, \HTLC_HANDSHAKE, length(HTLC_HANDSHAKE));
  _read($server, \$response, 8);

  if($response ne HTLC_CHECKBYTES)
  {
    croak("Handshake failed.  Not a hotline server?");
  }

  my($enc_login)    = _encode($login);
  my($enc_password) = _encode($password);

  $proto_header = new Hotline::Protocol::Header;
  
  $proto_header->type(HTLC_HEADER_LOGIN);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_PROTO_HDR + 
                     length($enc_login) +
                     length($enc_password) +
                     length($nick));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0004) .                 # Num atoms

          pack("n", HTLC_DATA_LOGIN) .        # Atom type
          pack("n", length($enc_login)) .     # Atom length
          $enc_login .                        # Atom data

          pack("n", HTLC_DATA_PASSWORD) .     # Atom type
          pack("n", length($enc_password)) .  # Atom length
          $enc_password .                     # Atom data

          pack("n", HTLC_DATA_NICKNAME) .     # Atom type
          pack("n", length($nick)) .          # Atom length
          $nick .                             # Atom data

          pack("n", HTLC_DATA_ICON) .         # Atom type
          pack("n", 2) .                      # Atom length
          pack("n", $icon);                   # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: LOGIN - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Hotline::Task($task_num, HTLC_TASK_LOGIN, time());
  }
  else { return(undef) }
  
  $self->req_userlist();
  $self->req_news();

  return($task_num);
}

sub run
{
  my($self) = shift;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data_ref, $type, $ret);

  my($packet) = new Hotline::Protocol::Packet;

  _set_blocking($server, $self->{'BLOCKING'});

  while($ret = $packet->read_parse($server, $self->{'BLOCKING'}))
  {
    $type = $packet->{'TYPE'};

    if($ret == HTLC_EWOULDBLOCK) # Idle event
    {
      if(defined($self->{'HANDLERS'}->{'EVENT'}))
      {
        &{$self->{'HANDLERS'}->{'EVENT'}}($self, 1);
      }

      select(undef, undef, undef, $self->{'EVENT_TIMING'});
      next;
    }

    $self->{'LAST_ACTIVITY'} = time();

    if(defined($self->{'HANDLERS'}->{'EVENT'})) # Non-idle event
    {
      &{$self->{'HANDLERS'}->{'EVENT'}}($self, 0);
    }
      
    _debug("Packet type = $type\n");

    if($type == HTLS_HEADER_USERDISCONNECT)
    {
      # Hotline server *BUG* - you may get a "disconnect" packet for a
      # socket _before_ you get the "connect" packet for that socket!
      # In fact, the "connect" packet will never arrive in this case.

      if(defined($packet->{'SOCKET'}) &&
         defined($self->{'USERLIST'}->{$packet->{'SOCKET'}}))
      {
        my($user) = $self->{'USERLIST'}->{$packet->{'SOCKET'}};
  
        if(defined($self->{'HANDLERS'}->{'LEAVE'}))
        {
          &{$self->{'HANDLERS'}->{'LEAVE'}}($self, $user);
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {       
          print "USER LEFT: ", $user->nick(), "\n";
        }

        delete $self->{'USERLIST'}->{$packet->{'SOCKET'}};
      }
    }
    elsif($type == HTLS_HEADER_TASK)
    {
      my($task) = $self->{'TASKS'}->{$packet->{'TASK_NUM'}};

      my($task_type) = $task->type();

      $task->finish(time());

      if(defined($packet->{'TASKERROR'}))
      {
        $task->error(1);
        $task->error_text($packet->{'TASKERROR'});

        if(defined($self->{'HANDLERS'}->{'TASKERROR'}))
        {
          &{$self->{'HANDLERS'}->{'TASKERROR'}}($self, $task);
        }
        else
        {
          print "TASK ERROR(", $task->num(), ':', $task->type(),
                ") ", $task->error_text(), "\n";
        }
      }
      else
      {
        $task->error(0);

        if($task_type == HTLC_TASK_USERLIST && defined($packet->{'USERLIST'}))
        {
          $self->{'USERLIST'} = $packet->{'USERLIST'};

          if(defined($self->{'HANDLERS'}->{'USERLIST'}))
          {
            &{$self->{'HANDLERS'}->{'USERLIST'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET USER LIST: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_FILELIST)
        {
          my($path);

          $task->path("")  unless($task->path =~ /./);
          $path = $task->path();

          $self->{'FILES'}->{$path} = $packet->{'FILELIST'};

          if(defined($self->{'HANDLERS'}->{'FILELIST'}))
          {
            &{$self->{'HANDLERS'}->{'FILELIST'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET FILE LIST: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_NEWS && defined($packet->{'DATA'}))
        {
          my(@news) = split(/_{58}/, $packet->{'DATA'});

          $self->{'NEWS'} = \@news;
          
          if(defined($self->{'HANDLERS'}->{'NEWS'}))
          {
            &{$self->{'HANDLERS'}->{'NEWS'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET NEWS: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_USERINFO && defined($packet->{'DATA'}))
        {
          my($user) = $self->{'USERLIST'}->{$task->socket()};
          
          $user->info($packet->{'DATA'});

          if(defined($self->{'HANDLERS'}->{'USERINFO'}))
          {
            &{$self->{'HANDLERS'}->{'USERINFO'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET USER INFO: Task complete.\n";
          }

          _debug("USERINFO for: $packet->{'NICK'} (", $task->socket(), ")\n",
                 $packet->{'DATA'}, "\n");
        }
        elsif($task_type == HTLC_TASK_FILEINFO)
        {
          my($path, $file_info);

          $task->path("")  unless($task->path =~ /./);
          $path = $task->path();

          $file_info = $self->{'FILE_INFO'}->{$path} = new Hotline::FileInfoItem();
          
          $file_info->icon($packet->{'FILE_ICON'});
          $file_info->type($packet->{'FILE_TYPE'});
          $file_info->creator($packet->{'FILE_CREATOR'});
          $file_info->size($packet->{'FILE_SIZE'});
          $file_info->name($packet->{'FILE_NAME'});
          $file_info->comment($packet->{'FILE_COMMENT'});
          $file_info->ctime($packet->{'FILE_CTIME'});
          $file_info->mtime($packet->{'FILE_MTIME'});
        
          if(defined($self->{'HANDLERS'}->{'FILEINFO'}))
          {
            &{$self->{'HANDLERS'}->{'FILEINFO'}}($self, $task, $file_info);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "FILEINFO: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_LOGIN)
        {
          if(defined($self->{'HANDLERS'}->{'LOGIN'}))
          {
            &{$self->{'HANDLERS'}->{'LOGIN'}}($self);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "LOGIN: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_POST_NEWS)
        {
          if(defined($self->{'HANDLERS'}->{'POST_NEWS'}))
          {
            &{$self->{'HANDLERS'}->{'POST_NEWS'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "POST NEWS: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_SEND_MSG)
        {
          if(defined($self->{'HANDLERS'}->{'SEND_MSG'}))
          {
            &{$self->{'HANDLERS'}->{'SEND_MSG'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "SEND MSG: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_KICK)
        {
          if(defined($self->{'HANDLERS'}->{'KICK'}))
          {
            &{$self->{'HANDLERS'}->{'KICK'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "KICK: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_SET_INFO)
        {
          if(defined($self->{'HANDLERS'}->{'SET_INFO'}))
          {
            &{$self->{'HANDLERS'}->{'SET_INFO'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "SET INFO: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_DELETEFILE)
        {
          if(defined($self->{'HANDLERS'}->{'DELETE_FILE'}))
          {
            &{$self->{'HANDLERS'}->{'DELETE_FILE'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "DELETE FILE: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_NEWFOLDER)
        {
          if(defined($self->{'HANDLERS'}->{'NEW_FOLDER'}))
          {
            &{$self->{'HANDLERS'}->{'NEW_FOLDER'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "CREATE FOLDER: Task complete.\n";
          }
        }
        elsif($task_type == HTLC_TASK_MOVEFILE)
        {
          if(defined($self->{'HANDLERS'}->{'MOVE_FILE'}))
          {
            &{$self->{'HANDLERS'}->{'MOVE_FILE'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "MOVE FILE: Task complete.\n";
          }
        }
      }
      # Reclaim memory
      delete $self->{'TASKS'}->{$packet->{'TASK_NUM'}};
    }
    elsif($type == HTLS_HEADER_AGREEMENT)
    {
      if(defined($packet->{'DATA'}))
      {
        if(defined($self->{'HANDLERS'}->{'AGREEMENT'}))
        {
          &{$self->{'HANDLERS'}->{'AGREEMENT'}}($self, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "AGREEMENT:\n", $packet->{'DATA'}, "\n";
        }
      }
    }
    elsif($type == HTLS_HEADER_MSG)
    {
      my($user) = $self->{'USERLIST'}->{$packet->{'SOCKET'}};

      # User-to-user message
      if(defined($user) && defined($packet->{'DATA'}))
      {
        if(defined($self->{'HANDLERS'}->{'MSG'}))
        {
          &{$self->{'HANDLERS'}->{'MSG'}}($self, $user, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "MSG: ", $user->nick(), "(", 
                         $packet->{'SOCKET'}, ") ", 
                         $packet->{'DATA'}, "\n";
        }
      }
      elsif(defined($packet->{'DATA'})) # Server message
      {
        if(defined($self->{'HANDLERS'}->{'SERVER_MSG'}))
        {
          &{$self->{'HANDLERS'}->{'SERVER_MSG'}}($self, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "SERVER MSG: ", $packet->{'DATA'}, "\n";
        }
      }
    }
    elsif($type == HTLS_HEADER_USERUPDATE)
    {
      if(defined($packet->{'NICK'}) && defined($packet->{'SOCKET'}) &&
         defined($packet->{'ICON'}) && defined($packet->{'COLOR'}))
      {
        if(defined($self->{'USERLIST'}->{$packet->{'SOCKET'}}))
        {
          my($user) = $self->{'USERLIST'}->{$packet->{'SOCKET'}};

          if($user->nick() ne $packet->{'NICK'})
          {
            my($old_nick) = $user->nick();

            $user->nick($packet->{'NICK'});
            
            if(defined($self->{'HANDLERS'}->{'NICK'}))
            {
              &{$self->{'HANDLERS'}->{'NICK'}}($self, $user, $old_nick, $user->nick());
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "USER CHANGE: $old_nick is now known as ", $user->nick(), "\n";
            }
          }
          elsif($user->icon() ne $packet->{'ICON'})
          {
            my($old_icon) = $user->icon();

            $user->icon($packet->{'ICON'});
            
            if(defined($self->{'HANDLERS'}->{'ICON'}))
            {
              &{$self->{'HANDLERS'}->{'ICON'}}($self, $user, $old_icon, $user->icon());
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "USER CHANGE: ", $user->nick(),
                    " icon changed from $old_icon to ",
                    $user->icon(), "\n";
            }
          }
          elsif($user->color() ne $packet->{'COLOR'})
          {
            my($old_color) = $user->color();

            $user->color($packet->{'COLOR'});
            
            if(defined($self->{'HANDLERS'}->{'COLOR'}))
            {
              &{$self->{'HANDLERS'}->{'COLOR'}}($self, $user, $old_color, $user->color());
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "USER CHANGE: ", $user->nick(),
                    " color changed from $old_color to ",
                    $user->color(), "\n";
            }
          }
        }
        else
        {
          $self->{'USERLIST'}->{$packet->{'SOCKET'}} =
            new Hotline::User($packet->{'SOCKET'},
                              $packet->{'NICK'},
                              undef,
                              $packet->{'ICON'},
                              $packet->{'COLOR'});
        
          if(defined($self->{'HANDLERS'}->{'JOIN'}))
          {
            &{$self->{'HANDLERS'}->{'JOIN'}}($self, $self->{'USERLIST'}->{$packet->{'SOCKET'}});
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "JOINED:\n",
                  "  Nick: $packet->{'NICK'}\n",
                  "  Icon: $packet->{'ICON'}\n",
                  "Socket: $packet->{'SOCKET'}\n",
                  " Color: $packet->{'COLOR'}\n";
          }
        }
      }
    }
    elsif($type == HTLS_HEADER_CHAT)
    {
      if(defined($packet->{'DATA'}))
      {
        $packet->{'DATA'} =~ s/^\n//s;

        # Chat "action"
        if($packet->{'DATA'} =~ /^ \*\*\* /)
        {
          if(defined($self->{'HANDLERS'}->{'CHAT_ACTION'}))
          {
            &{$self->{'HANDLERS'}->{'CHAT_ACTION'}}($self, \$packet->{'DATA'});
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            $packet->{'DATA'} =~ s/^@{[HTLC_NEWLINE]}//os;
            print "CHAT ACTION: ", $packet->{'DATA'}, "\n";
          }        
        }
        else # Regular chat
        {
          if(defined($self->{'HANDLERS'}->{'CHAT'}))
          {
            &{$self->{'HANDLERS'}->{'CHAT'}}($self, \$packet->{'DATA'});
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "CHAT: ", $packet->{'DATA'}, "\n";
          }
        }
      }
    }
    elsif($type == HTLS_HEADER_NEWSPOST)
    {
      my($post) = $packet->{'DATA'};

      if(defined($post))
      {
        $post =~ s/@{[HTLC_NEWLINE]}/\n/osg;
        $post =~ s/_{58}//sg;

        if(defined($self->{'HANDLERS'}->{'NEWS'}))
        {
          &{$self->{'HANDLERS'}->{'NEWS'}}($self, \$post);
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "NEWS: New post made.\n";
        }
      }
    }
    elsif($type == HTLS_HEADER_POLITEQUIT ||
          $type eq 'DISCONNECTED')
    {
      if(defined($packet->{'DATA'}))
      {
        if(defined($self->{'HANDLERS'}->{'QUIT'}))
        {
          &{$self->{'HANDLERS'}->{'QUIT'}}($self, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "CONNECTION CLOSED: ", $packet->{'DATA'}, "\n";
        }
      }
      elsif($self->{'DEFAULT_HANDLERS'})
      {
        print "CONNECTION CLOSED\n";
      }

      $self->disconnect();
      return(0);
    }
    elsif($type == HTLS_HEADER_PRIVCHAT_INVITE)
    {
      # To do...
    }
    elsif($type == HTLS_HEADER_PRIVCHAT_USERUPDATE)
    {
      # To do...
    }
    elsif($type == HTLS_HEADER_PRIVCHAT_USERDISCONNECT)
    {
       # To do...
    }
    elsif($type == HTLS_HEADER_PRIVCHAT_SUBJECT)
    {
      # To do...
    }
  }

  _set_blocking($server, 1);
}

sub req_filelist
{
  my($self, $path) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data, $task_num, @path_parts, $data_length, $length, $save_path);

  if($path)
  {
    $path =~ s/$self->{'PATH_SEPARATOR'}$//;
    $save_path = $path;
    @path_parts = split($self->{'PATH_SEPARATOR'}, $path);
    $path =~ s/$self->{'PATH_SEPARATOR'}//g;
    
    if(length($path) > HTLC_MAX_PATHLEN)
    {
      croak("Maximum path length exceeded.");
    }

    # 2 null bytes, the 1 byte for length, and the length of the path part
    $data_length = (3 * scalar(@path_parts)) + length($path);
    $length = SIZEOF_HL_LONG_HDR + $data_length;
  }
  else
  {
    $length = 2; # Two null bytes
  }

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_LISTFILES);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();
  
  if($path)
  {
    $data .= pack("n", 0x0001) .              # Number of atoms
             pack("n", HTLC_DATA_LISTDIR) .   # Atom type
             pack("n", $data_length + 2);     # Atom length

    $data .= pack("n", scalar(@path_parts));  # Number of path parts

    my($path_part);

    foreach $path_part (@path_parts)          # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded.");
      }

      $data .= pack("n", 0x0000) .            # 2 null bytes
               pack("c", length($path_part)) .# Length
               $path_part;                    # Path part
    }
  }
  else
  {
    $data .=  pack("n", 0x0000);
  }

  _debug(_hexdump($data));
  
  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: FILELIST - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Hotline::Task($task_num, HTLC_TASK_FILELIST, time(), undef, $save_path);
    return($task_num);
  }
  else { return(undef) }
}

sub req_userinfo
{
  my($self, $socket) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data, $task_num);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_GETUSERINFO);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_LONG_HDR);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0001) .                 # Number of atoms

          pack("n", HTLC_DATA_SOCKET) .       # Atom type
          pack("n", 0x0002) .                 # Atom length
          pack("n", $socket);                 # Atom data

  _debug(_hexdump($data));
  
  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: USERINFO - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Hotline::Task($task_num, HTLC_TASK_USERINFO, time(), $socket);
    return($task_num);
  }
  else { return(undef) }
}

sub req_fileinfo
{
  return _file_action_simple($_[0], $_[1], HTLC_HEADER_GETFILEINFO, HTLC_TASK_FILEINFO, 'FILEINFO');
}

sub delete_file
{
  return _file_action_simple($_[0], $_[1], HTLC_HEADER_DELETEFILE, HTLC_TASK_DELETEFILE, 'DELETEFILE');
}

sub new_folder
{
  return _file_action_simple($_[0], $_[1], HTLC_HEADER_NEWFOLDER, HTLC_TASK_NEWFOLDER, 'NEWFOLDER');
}

sub _file_action_simple
{
  my($self, $path, $type, $task_type, $task_name) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened() && $path =~ /./);

  my($data, $task_num, @path_parts, $length, $save_path, $file, $dir_len);

  $path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_path = $path;
  @path_parts = split($self->{'PATH_SEPARATOR'}, $path);
  $path =~ s/$self->{'PATH_SEPARATOR'}//g;
   
  if(length($path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded.");
  }

  $file = pop(@path_parts);

  # File part: 2 bytes num atoms, 2 bytes for atom len,
  # 2 bytes for file name length
  $length = (2 + 2 + 2 + length($file));
    
  if(@path_parts)
  {
    $dir_len = length(join('', @path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @path_parts));
    $length += $dir_len;
  }

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type($type);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  $data .= pack("n", (@path_parts) ? 2 : 1) . # Number of atoms
           pack("n", HTLC_DATA_FILE) .        # Atom type
           pack("n", length($file)) .         # Atom length
           $file;                             # Atom data

  if(@path_parts)
  {
    $data .= pack("n", HTLC_DATA_DIRECTORY) . # Atom type
             pack("n", $dir_len + 2 + (3 * @path_parts)) .
                                              # Atom length
             pack("n", scalar(@path_parts));  # Num path parts

    my($path_part);

    foreach $path_part (@path_parts)          # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded.");
      }

      $data .= pack("n", 0x0000) .            # 2 null bytes
               pack("c", length($path_part)) .# Length
               $path_part;                    # Path part
    }
  }

  _debug(_hexdump($data));
  
  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: $task_name - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Hotline::Task($task_num, $task_type, time(), undef, $save_path);
    return($task_num);
  }
  else { return(undef) }
}

sub move
{
  my($self, $src_path, $dest_path) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened() && $src_path =~ /./ && $dest_path =~ /./);

  my($data, $task_num, $length, $num_atoms);
  my(@src_path_parts, $save_src_path, $src_file, $src_dir_len);
  my(@dest_path_parts, $save_dest_path, $dest_dir_len);

  # Source:

  $src_path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_src_path = $src_path;
  @src_path_parts = split($self->{'PATH_SEPARATOR'}, $src_path);
  $src_path =~ s/$self->{'PATH_SEPARATOR'}//g;
   
  if(length($src_path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded.");
  }

  $src_file = pop(@src_path_parts);

  # Source part: 2 bytes num atoms, 2 bytes for atom type,
  # 2 bytes for file name length
  $length = (2 + 2 + 2 + length($src_file));
    
  if(@src_path_parts)
  {
    $src_dir_len = length(join('', @src_path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @src_path_parts));
    $length += $src_dir_len;
  }

  # Destination:

  $dest_path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_dest_path = $dest_path;
  @dest_path_parts = split($self->{'PATH_SEPARATOR'}, $dest_path);
  $dest_path =~ s/$self->{'PATH_SEPARATOR'}//g;
   
  if(length($dest_path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded.");
  }
    
  if(@dest_path_parts)
  {
    $dest_dir_len = length(join('', @dest_path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @dest_path_parts));
    $length += $dest_dir_len;
  }

  # Build packet

  if(@src_path_parts && @dest_path_parts) { $num_atoms = 3 }
  else                                    { $num_atoms = 2 }

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_MOVEFILE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  $data .= pack("n", $num_atoms) .            # Number of atoms
           pack("n", HTLC_DATA_FILE) .        # Atom type
           pack("n", length($src_file)) .     # Atom length
           $src_file;                         # Atom data

  if(@src_path_parts)
  {
    $data .= pack("n", HTLC_DATA_DIRECTORY) . # Atom type
             pack("n", $src_dir_len + 2 + (3 * @src_path_parts)) .
                                              # Atom length
             pack("n", scalar(@src_path_parts));
                                              # Num path parts

    my($path_part);

    foreach $path_part (@src_path_parts)      # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded.");
      }

      $data .= pack("n", 0x0000) .            # 2 null bytes
               pack("c", length($path_part)) .# Length
               $path_part;                    # Path part
    }
  }

  if(@dest_path_parts)
  {
    $data .= pack("n", HTLC_DATA_DESTDIR) .   # Atom type
             pack("n", $dest_dir_len + 2 + (3 * @dest_path_parts)) .
                                              # Atom length
             pack("n", scalar(@dest_path_parts));
                                              # Num path parts

    my($path_part);

    foreach $path_part (@dest_path_parts)     # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded.");
      }

      $data .= pack("n", 0x0000) .            # 2 null bytes
               pack("c", length($path_part)) .# Length
               $path_part;                    # Path part
    }
  }

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: MOVE FILE - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Hotline::Task($task_num, HTLC_TASK_MOVEFILE, time(),
                         undef, [ $save_src_path, $save_dest_path ]);
    return($task_num);
  }
  else { return(undef) }
}

sub rename
{
  my($self, $path, $new_name) = @_;
  
  return undef  unless($path =~ /./ && $new_name =~ /./);
  return _change_file_info($self, $path, $new_name, undef);
}

sub comment
{
  my($self, $path, $comments) = @_;
  
  return undef  unless($path =~ /./);
  $comments = ""  unless(defined($comments));
  return _change_file_info($self, $path, undef, $comments);
}

sub _change_file_info
{
  my($self, $path, $name, $comments) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data, $task_num, @path_parts, $length, $save_path, $file,
     $dir_len, $num_atoms);

  $path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_path = $path;
  @path_parts = split($self->{'PATH_SEPARATOR'}, $path);
  $path =~ s/$self->{'PATH_SEPARATOR'}//g;
   
  if(length($path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded.");
  }

  $file = pop(@path_parts);

  # File part: 2 bytes for num atoms, 2 bytes for atom type,
  # 2 bytes for file name length
  $length = (2 + 2 + 2 + length($file));
    
  if(@path_parts)
  {
    $dir_len = length(join('', @path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @path_parts));
    $length += $dir_len;
  }

  if($name =~ /./)
  {
    # Name part: 2 bytes for atom type, 2 bytes for
    # atom len, and the new name
    $length += (2 + 2 + length($name));
  }

  if(defined($comments))
  {
    # Comments part: 2 bytes for atom type, 2 bytes for
    # atom len, length of the new comments, else 1 null
    # byte if removing comments.
    $length += 2 + 2;
    if($comments =~ /./) { $length += length($comments) }
    else                 { $length += 1                 }
  }

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_CHANGEFILEINFO);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();
  
  $num_atoms = (@path_parts) ? 2 : 1;
  $num_atoms++  if($name =~ /./);
  $num_atoms++  if(defined($comments));

  $data .= pack("n", $num_atoms) .            # Number of atoms
           pack("n", HTLC_DATA_FILE) .        # Atom type
           pack("n", length($file)) .         # Atom length
           $file;                             # Atom data

  if(@path_parts)
  {
    $data .= pack("n", HTLC_DATA_DIRECTORY).  # Atom type
             pack("n", $dir_len + 2 + (3 * @path_parts)) .
                                              # Atom length
             pack("n", scalar(@path_parts));  # Num path parts

    my($path_part);

    foreach $path_part (@path_parts)          # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded.");
      }

      $data .= pack("n", 0x0000) .            # 2 null bytes
               pack("c", length($path_part)) .# Length
               $path_part;                    # Path part
    }
  }

  if($name =~ /./)
  {
    $data .= pack("n", HTLC_DATA_RENAMEFILE) .# Atom type
             pack("n", length($name)) .       # Length
             $name;                           # Name
  }

  if(defined($comments))
  {
    $data .= pack("n", HTLS_DATA_FILECOMMENT);# Atom type
    
    if($comments =~ /./)
    {
      $data .=  pack("n", length($comments)). # Length
                $comments;                    # Comments
    }
    else # Remove comments
    {
      $data .=  pack("n", 0x0001) .           # Length
                pack("x")                     # Null byte
    }
  }

  _debug(_hexdump($data));
  
  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: SET INFO - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Hotline::Task($task_num, HTLC_TASK_SET_INFO, time(), undef, $save_path);
    return($task_num);
  }
  else { return(undef) }
}

sub post_news
{
  my($self, @post) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($post) = join('', @post);

  my($data, $task_num);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_NEWSPOST);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_SHORT_HDR + length($post));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0001) .                 # Number of atoms
          pack("n", HTLS_DATA_NEWSPOST) .     # Atom type
          pack("n", length($post)) .          # Atom length
          $post;                              # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: POST NEWS - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Hotline::Task($task_num, HTLC_TASK_POST_NEWS, time());
  }
  else { return(undef) }
  
  return($task_num);
}

sub news
{
  my($self) = shift;

  return $self->{'NEWS'}
}

sub req_news
{
  my($self) = shift;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data, $task_num);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_GETNEWS);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_TASK_FILLER);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0000);

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: NEWS - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Hotline::Task($task_num, HTLC_TASK_NEWS, time());
    return($task_num);
  }
  else { return(undef) }
}

sub user_by_nick
{
  my($self, $nick_match) = @_;

  my($socket, @users);

  eval { m/$nick_match/ };

  return undef  if($@ || !$self->{'USERLIST'} || $nick_match !~ /./);

  foreach $socket (sort { $a <=> $b } keys(%{$self->{'USERLIST'}}))
  {
    if($self->{'USERLIST'}->{$socket}->nick() =~ /^$nick_match$/)
    {
      if(wantarray())
      {
        push(@users, $self->{'USERLIST'}->{$socket});
      }
      else
      {
        return $self->{'USERLIST'}->{$socket};
      }
    }
  }

  if(@users) { return @users }
  else       { return undef  }
}

sub user_by_socket
{
  my($self, $socket) = @_;
  return $self->{'USERLIST'}->{$socket};
}

sub agreement { $_[0]->{'AGREEMENT'} }
sub userlist  { $_[0]->{'USERLIST'}  }
sub files     { $_[0]->{'FILES'}     }

sub icon
{
  my($self, $icon) = @_;

  return $self->{'ICON'}  unless($icon =~ /^-?\d+$/);
  
  return _update_user($self, $icon, $self->{'NICK'});
}

sub nick
{
  my($self, $nick) = @_;

  return $self->{'NICK'}  unless(defined($nick));
  
  return _update_user($self, $self->{'ICON'}, $nick);
}

sub _update_user
{
  my($self, $icon, $nick) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_CHANGE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((SIZEOF_HL_SHORT_HDR * 2) + length($nick));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0002) .                 # Num atoms

          pack("n", HTLC_DATA_ICON) .         # Atom type
          pack("n", 0x0002) .                 # Atom length
          pack("n", $icon) .                  # Atom data

          pack("n", HTLC_DATA_NICKNAME) .     # Atom type
          pack("n", length($nick)) .          # Atom length
          $nick;                              # Atom data

  $self->{'NICK'} = $nick;
  $self->{'ICON'} = $icon;

  _debug(_hexdump($data));

  if(_write($server, \$data, length($data)) == length($data))
  {
    return(1);
  }
  else { return(undef) }
}

sub req_userlist
{
  my($self) = shift;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data, $task_num);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_GETUSERLIST);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_TASK_FILLER);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0000);

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: USERLIST - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Hotline::Task($task_num, HTLC_TASK_USERLIST, time());
    return($task_num);
  }
  else { return(undef) }
}

sub kick
{
  my($self, $user_or_socket) = @_;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($socket, $task_num);
  
  if(ref($user_or_socket)) { $socket = $user_or_socket->socket() }
  else                     { $socket = $user_or_socket           }

  my($data);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_KICK);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_LONG_HDR);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0001) .                 # Num atoms

          pack("n", HTLC_DATA_SOCKET) .       # Atom type
          pack("n", 0x0002) .                 # Atom length
          pack("n", $socket);                 # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: KICK($socket) - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Hotline::Task($task_num, HTLC_TASK_KICK, time());
  }
  else { return(undef) }
}

sub msg
{
  my($self, $user_or_socket, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;

  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($socket);
  
  if(ref($user_or_socket)) { $socket = $user_or_socket->socket() }
  else                     { $socket = $user_or_socket           }
  
  my($data, $task_num);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_MSG);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((SIZEOF_HL_SHORT_HDR * 2) +
                     length($message));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0002) .                 # Num atoms

          pack("n", HTLC_DATA_SOCKET) .       # Atom type
          pack("n", 0x0002) .                 # Atom length
          pack("n", $socket) .                # Atom data

          pack("n", HTLC_DATA_MSG) .          # Atom type
          pack("n", length($message)) .       # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_write($server, \$data, length($data)) == length($data))
  {
    _debug("NEW TASK: MSG - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Hotline::Task($task_num, HTLC_TASK_SEND_MSG, time());
  }
  else { return(undef) }
  
  return($task_num);
}

sub chat_action
{
  my($self, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;
  
  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_CHAT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((SIZEOF_HL_SHORT_HDR  * 2) +
                     length($message));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0002) .                 # Num atoms

          pack("n", HTLC_DATA_OPTION) .       # Atom type
          pack("n", 0x0002) .                 # Atom length
          pack("n", 0x0001) .                 # Atom data

          pack("n", HTLC_DATA_CHAT) .         # Atom type
          pack("n", length($message)) .       # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  if(_write($server, \$data, length($data)) == length($data))
  {
    return(1);
  }
  else { return(undef) }
}

sub chat
{
  my($self, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;
  
  my($server) = $self->{'SERVER'};
  return(undef)  unless($server->opened());

  my($data);

  my($proto_header) = new Hotline::Protocol::Header;

  $proto_header->type(HTLC_HEADER_CHAT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_SHORT_HDR +
                     length($message));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0001) .                 # Num atoms

          pack("n", HTLC_DATA_CHAT) .         # Atom type
          pack("n", length($message)) .       # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  if(_write($server, \$data, length($data)) == length($data))
  {
    return(1);
  }
  else { return(undef) }
}

sub default_handlers
{
  my($self, $arg) = @_;
  $self->{'DEFAULT_HANDLERS'} = $arg  if(defined($arg));
  return $self->{'DEFAULT_HANDLERS'};
}

sub handlers
{
  my($self) = shift;
  return $self->{'HANDLERS'};
}

sub agreement_handler   { return _handler($_[0], $_[1], 'AGREEMENT')   }
sub chat_handler        { return _handler($_[0], $_[1], 'CHAT')        }
sub chat_action_handler { return _handler($_[0], $_[1], 'CHAT_ACTION') }
sub color_handler       { return _handler($_[0], $_[1], 'COLOR')       }
sub delete_file_handler { return _handler($_[0], $_[1], 'DELETE_FILE') }
sub event_loop_handler  { return _handler($_[0], $_[1], 'EVENT')       }
sub file_list_handler   { return _handler($_[0], $_[1], 'FILELIST')    }
sub file_info_handler   { return _handler($_[0], $_[1], 'FILEINFO')    }
sub icon_handler        { return _handler($_[0], $_[1], 'ICON')        }
sub join_handler        { return _handler($_[0], $_[1], 'JOIN')        }
sub leave_handler       { return _handler($_[0], $_[1], 'LEAVE')       }
sub kick_handler        { return _handler($_[0], $_[1], 'KICK')        }
sub login_handler       { return _handler($_[0], $_[1], 'LOGIN')       }
sub move_file_handler   { return _handler($_[0], $_[1], 'MOVE_FILE')   }
sub msg_handler         { return _handler($_[0], $_[1], 'MSG')         }
sub new_folder_handler  { return _handler($_[0], $_[1], 'NEW_FOLDER')  }
sub news_handler        { return _handler($_[0], $_[1], 'NEWS')        }
sub nick_handler        { return _handler($_[0], $_[1], 'NICK')        }
sub post_news_handler   { return _handler($_[0], $_[1], 'POST_NEWS')   }
sub quit_handler        { return _handler($_[0], $_[1], 'QUIT')        }
sub send_msg_handler    { return _handler($_[0], $_[1], 'SEND_MSG')    }
sub server_msg_handler  { return _handler($_[0], $_[1], 'SERVER_MSG')  }
sub set_info_handler    { return _handler($_[0], $_[1], 'SET_INFO')    }
sub task_error_handler  { return _handler($_[0], $_[1], 'TASKERROR')   }
sub user_info_handler   { return _handler($_[0], $_[1], 'USERINFO')    }
sub user_list_handler   { return _handler($_[0], $_[1], 'USERLIST')    }

sub debug
{
  my($self, $debug) = @_;
 
  if(@_ == 1 && ref($self) !~ /^Hotline::Client/)
  {
    $Hotline::Client::DEBUG = $self;
  }
  else
  {
    $Hotline::Client::DEBUG = $debug  if(@_ == 2);
  }
  return $Hotline::Client::DEBUG
}

sub _handler
{
  my($self, $code_ref, $type) = @_;
  
  if(defined($code_ref))
  {
    if(ref($code_ref) eq 'CODE')
    {
      $self->{'HANDLERS'}->{$type} = $code_ref;
    }
  }
  
  return $self->{'HANDLERS'}->{$type};
}

sub _next_seqnum
{
  my($self) = shift;

  return $self->{'SEQNUM'}++;
}

1;
