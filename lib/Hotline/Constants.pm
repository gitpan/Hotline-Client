package Hotline::Constants;

## Copyright(c) 1998 by John C. Siracusa.  All rights reserved.  This program
## is free software; you can redistribute it and/or modify it under the same
## terms as Perl itself.

use strict;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS %HTLC_COLORS);

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(
HTLC_DEFAULT_NICK HTLC_DEFAULT_LOGIN HTLC_DEFAULT_ICON HTLC_EWOULDBLOCK
HTRK_TCPPORT HTRK_UDPPORT HTLS_TCPPORT HTXF_TCPPORT HTLC_COLORS
HTLC_NEWLINE HTLC_HANDSHAKE HTLC_CHECKBYTES HTLC_HEADER_CHANGE
HTLC_HEADER_CHAT HTLC_HEADER_LOGIN HTLC_HEADER_MSG HTLC_HEADER_NEWSPOST
HTLC_HEADER_GETUSERINFO HTLC_HEADER_KICK HTLC_HEADER_LISTFILES
HTLC_HEADER_OPENUSER HTLC_HEADER_CREATEUSER HTLC_HEADER_GETFILE
HTLC_HEADER_PUTFILE HTLC_HEADER_NEWFOLDER HTLC_HEADER_GETFILEINFO
HTLC_HEADER_GETUSERLIST HTLC_HEADER_GETNEWS HTLC_HEADER_CHANGEFILEINFO
HTLC_HEADER_DELETEFILE HTLC_HEADER_MOVEFILE HTLC_HEADER_PRIVCHAT_CREATE
HTLC_HEADER_PRIVCHAT_INVITE HTLC_HEADER_PRIVCHAT_DECLINE
HTLC_HEADER_PRIVCHAT_ACCEPT HTLC_HEADER_PRIVCHAT_CLOSE
HTLC_HEADER_PRIVCHAT_SUBJECT HTLC_DATA_ICON HTLC_DATA_NICKNAME
HTLC_DATA_OPTION HTLC_DATA_LOGIN HTLC_DATA_PASSWORD HTLC_DATA_SOCKET
HTLC_DATA_CHAT HTLC_DATA_MSG HTLC_DATA_NEWSPOST HTLC_DATA_LISTDIR
HTLC_DATA_FILE HTLC_DATA_DIRECTORY HTLC_DATA_RFLT HTLC_DATA_XFERSIZE
HTLC_DATA_BAN HTLC_DATA_PRIVCHAT_REF HTLC_DATA_PRIVCHAT_SUBJECT
HTLC_DATA_RENAMEFILE HTLC_DATA_DESTDIR HTLC_TASK_FILELIST HTLC_TASK_KICK
HTLC_TASK_LOGIN HTLC_TASK_SEND_MSG HTLC_TASK_NEWS HTLC_TASK_POST_NEWS
HTLC_TASK_USERINFO HTLC_TASK_USERLIST HTLS_HEADER_USERDISCONNECT
HTLS_HEADER_TASK HTLS_HEADER_AGREEMENT HTLS_HEADER_MSG
HTLS_HEADER_USERUPDATE HTLS_HEADER_CHAT HTLS_HEADER_NEWSPOST
HTLS_HEADER_POLITEQUIT HTLS_HEADER_PRIVCHAT_INVITE
HTLS_HEADER_PRIVCHAT_USERUPDATE HTLS_HEADER_PRIVCHAT_USERDISCONNECT
HTLS_HEADER_PRIVCHAT_SUBJECT HTLS_DATA_SOCKET HTLS_DATA_TASKERROR
HTLS_DATA_SERVERMSG HTLS_DATA_ICON HTLS_DATA_COLOR HTLS_DATA_NICKNAME
HTLS_DATA_USERLIST HTLS_DATA_NEWS HTLS_DATA_AGREEMENT HTLS_DATA_USERINFO
HTLS_DATA_CHAT HTLS_DATA_MSG HTLS_DATA_NEWSPOST HTLS_DATA_FILELISTITEM
HTLS_DATA_FILEICON HTLS_DATA_FILETYPE HTLS_DATA_FILECREATOR
HTLS_DATA_FILESIZE HTLS_DATA_FILENAME HTLS_DATA_FILECOMMENT
HTLS_DATA_XFERSIZE HTLS_DATA_XFERREF HTLS_DATA_PRIVCHAT_REF
HTLC_MAX_PATHLEN HTLS_DATA_PRIVCHAT_SUBJECT SIZEOF_HL_OUT_HDR
SIZEOF_HL_PROTO_HDR SIZEOF_HL_DATA_HDR SIZEOF_HL_SHORT_HDR
SIZEOF_HL_LONG_HDR SIZEOF_HL_FILELIST_HDR SIZEOF_HL_USERLIST_HDR
SIZEOF_HL_TASK_FILLER HTLC_TASK_FILEINFO HTLC_MACOS_TO_UNIX_TIME
HTLS_DATA_FILECTIME HTLS_DATA_FILEMTIME HTLC_TASK_SET_INFO
HTLC_HEADER_CHANGEFILEINFO HTLC_TASK_DELETEFILE HTLC_TASK_NEWFOLDER
HTLC_TASK_MOVEFILE HTLC_FOLDER_TYPE);

%EXPORT_TAGS = ('ALL' => \@EXPORT_OK);

%HTLC_COLORS = (0 => 'gray',
                1 => 'black',
                2 => 'red',
                3 => 'pink');

# Hotline gives times relative to Mac OS epoch.  Add this constant to the
# times returned by Hotline to get the time since the unix epoch.
use constant HTLC_MACOS_TO_UNIX_TIME => -2082830400;

use constant HTLC_FOLDER_TYPE     => 'fldr';

use constant HTLC_DEFAULT_NICK    => 'guest';
use constant HTLC_DEFAULT_LOGIN   => 'guest';
use constant HTLC_DEFAULT_ICON    => 410;

use constant HTLC_EWOULDBLOCK     => 2; # Can be anything > 1, really

use constant HTLC_MAX_PATHLEN     => 255;

# Arbitrary unique task type constants
use constant HTLC_TASK_KICK       => 1;
use constant HTLC_TASK_LOGIN      => 2;
use constant HTLC_TASK_SEND_MSG   => 3;
use constant HTLC_TASK_NEWS       => 4;
use constant HTLC_TASK_POST_NEWS  => 5;
use constant HTLC_TASK_USERINFO   => 6;
use constant HTLC_TASK_USERLIST   => 7;
use constant HTLC_TASK_FILELIST   => 8;
use constant HTLC_TASK_FILEINFO   => 9;
use constant HTLC_TASK_SET_INFO   => 10;
use constant HTLC_TASK_DELETEFILE => 11;
use constant HTLC_TASK_NEWFOLDER  => 12;
use constant HTLC_TASK_MOVEFILE   => 13;

use constant HTRK_TCPPORT => 5498;
use constant HTRK_UDPPORT => 5499;
use constant HTLS_TCPPORT => 5500;
use constant HTXF_TCPPORT => 5501;

use constant HTLC_NEWLINE    => "\015";

use constant HTLC_HANDSHAKE  => pack("c12", 84, 82, 84, 80, 72, 79, 84, 76, 0, 1, 0, 2);
use constant HTLC_CHECKBYTES => pack("c8", 84, 82, 84, 80, 0, 0, 0, 0);

use constant HTLC_HEADER_CHANGE                 => 0x00000130;
use constant HTLC_HEADER_CHAT                   => 0x00000069;
use constant HTLC_HEADER_LOGIN                  => 0x0000006B;
use constant HTLC_HEADER_MSG                    => 0x0000006C;
use constant HTLC_HEADER_NEWSPOST               => 0x00000067;
use constant HTLC_HEADER_GETUSERINFO            => 0x0000012F;
use constant HTLC_HEADER_KICK                   => 0x0000006E;
use constant HTLC_HEADER_LISTFILES              => 0x000000C8;
use constant HTLC_HEADER_OPENUSER               => 0x00000160;
use constant HTLC_HEADER_CREATEUSER             => 0x0000015E;
use constant HTLC_HEADER_GETFILE                => 0x000000CA;
use constant HTLC_HEADER_PUTFILE                => 0x000000CB;
use constant HTLC_HEADER_NEWFOLDER              => 0x000000CD;
use constant HTLC_HEADER_GETFILEINFO            => 0x000000CE;
use constant HTLC_HEADER_GETUSERLIST            => 0x0000012C;
use constant HTLC_HEADER_GETNEWS                => 0x00000065;
use constant HTLC_HEADER_CHANGEFILEINFO         => 0x000000CF;
use constant HTLC_HEADER_DELETEFILE             => 0x000000CC;
use constant HTLC_HEADER_MOVEFILE               => 0x000000D0;
use constant HTLC_HEADER_PRIVCHAT_CREATE        => 0x00000070;
use constant HTLC_HEADER_PRIVCHAT_INVITE        => 0x00000071;
use constant HTLC_HEADER_PRIVCHAT_DECLINE       => 0x00000072;
use constant HTLC_HEADER_PRIVCHAT_ACCEPT        => 0x00000073;
use constant HTLC_HEADER_PRIVCHAT_CLOSE         => 0x00000074;
use constant HTLC_HEADER_PRIVCHAT_SUBJECT       => 0x00000078;

use constant HTLC_DATA_ICON                     => 0x0068;
use constant HTLC_DATA_NICKNAME                 => 0x0066;
use constant HTLC_DATA_OPTION                   => 0x006D;
use constant HTLC_DATA_LOGIN                    => 0x0069;
use constant HTLC_DATA_PASSWORD                 => 0x006A;
use constant HTLC_DATA_SOCKET                   => 0x0067;
use constant HTLC_DATA_CHAT                     => 0x0065;
use constant HTLC_DATA_MSG                      => 0x0065;
use constant HTLC_DATA_NEWSPOST                 => 0x0065;
use constant HTLC_DATA_LISTDIR                  => 0x00CA;
use constant HTLC_DATA_FILE                     => 0x00C9;
use constant HTLC_DATA_DIRECTORY                => 0x00CA;
use constant HTLC_DATA_RFLT                     => 0x00CB;
use constant HTLC_DATA_XFERSIZE                 => 0x006C;
use constant HTLC_DATA_BAN                      => 0x0071;
use constant HTLC_DATA_PRIVCHAT_REF             => 0x0072;
use constant HTLC_DATA_PRIVCHAT_SUBJECT         => 0x0073;
use constant HTLC_DATA_RENAMEFILE               => 0x00D3;
use constant HTLC_DATA_DESTDIR                  => 0x00D4;

use constant HTLS_HEADER_USERDISCONNECT         => 0x0000012E;
use constant HTLS_HEADER_TASK                   => 0x00010000;
use constant HTLS_HEADER_AGREEMENT              => 0x0000006D;
use constant HTLS_HEADER_MSG                    => 0x00000068;
use constant HTLS_HEADER_USERUPDATE             => 0x0000012D;
use constant HTLS_HEADER_CHAT                   => 0x0000006A;
use constant HTLS_HEADER_NEWSPOST               => 0x00000066;
use constant HTLS_HEADER_POLITEQUIT             => 0x0000006F;
use constant HTLS_HEADER_PRIVCHAT_INVITE        => 0x00000071;
use constant HTLS_HEADER_PRIVCHAT_USERUPDATE    => 0x00000075;
use constant HTLS_HEADER_PRIVCHAT_USERDISCONNECT => 0x00000076;
use constant HTLS_HEADER_PRIVCHAT_SUBJECT       => 0x00000077;

use constant HTLS_DATA_SOCKET                   => 0x0067;
use constant HTLS_DATA_TASKERROR                => 0x0064;
use constant HTLS_DATA_SERVERMSG                => 0x006D;
use constant HTLS_DATA_ICON                     => 0x0068;
use constant HTLS_DATA_COLOR                    => 0x0070;
use constant HTLS_DATA_NICKNAME                 => 0x0066;
use constant HTLS_DATA_USERLIST                 => 0x012C;
use constant HTLS_DATA_NEWS                     => 0x0065;
use constant HTLS_DATA_AGREEMENT                => 0x0065;
use constant HTLS_DATA_USERINFO                 => 0x0065;
use constant HTLS_DATA_CHAT                     => 0x0065;

use constant HTLS_DATA_MSG                      => 0x0065;
use constant HTLS_DATA_NEWSPOST                 => 0x0065;
use constant HTLS_DATA_FILELISTITEM             => 0x00C8;
use constant HTLS_DATA_FILEICON                 => 0x00D5;
use constant HTLS_DATA_FILETYPE                 => 0x00CD;
use constant HTLS_DATA_FILECREATOR              => 0x00CE;
use constant HTLS_DATA_FILESIZE                 => 0x00CF;
use constant HTLS_DATA_FILENAME                 => 0x00C9;
use constant HTLS_DATA_FILECTIME                => 0x00D0;
use constant HTLS_DATA_FILEMTIME                => 0x00D1;
use constant HTLS_DATA_FILECOMMENT              => 0x00D2;
use constant HTLS_DATA_XFERSIZE                 => 0x006C;
use constant HTLS_DATA_XFERREF                  => 0x006B;
use constant HTLS_DATA_PRIVCHAT_REF             => 0x0072;
use constant HTLS_DATA_PRIVCHAT_SUBJECT         => 0x0073;

use constant SIZEOF_HL_OUT_HDR                  => 22;
use constant SIZEOF_HL_PROTO_HDR                => 20;
use constant SIZEOF_HL_DATA_HDR                 => 4;
use constant SIZEOF_HL_SHORT_HDR                => 6;
use constant SIZEOF_HL_LONG_HDR                 => 8;
use constant SIZEOF_HL_FILELIST_HDR             => 24;
use constant SIZEOF_HL_USERLIST_HDR             => 12;
use constant SIZEOF_HL_TASK_FILLER              => 2;

1;
