#!/usr/bin/perl -w
#
# File:           IP.pm 
#
# Summary:        
#
# Author:         Jonathan Schatz
# E-Mail:         jon@divisionbyzero.com
# Org:            
#
# Orig-Date:      26-Mar-01 at 01:43:09
# Last-Mod:       03-Apr-01 at 21:06:23 by 

# -*- EOF -*-
package Sys::IP;
use strict;
use vars qw($VERSION @ISA @EXPORT $IFCONFIG_BINARY);
require Exporter;
use Sys::Hostname;
@ISA = qw(Exporter);
@EXPORT= qw($IFCONFIG_BINARY ip ips interfaces);
$VERSION = 1.0 ;

#----------------------------------------------------------------------------#
#we want to die if a system isn't explicitly supported
#BEGIN {
#  grep /$^O/, SUPPORTED() or die "$^O isn't supported by Sys:IP yet.\n";
#}

BEGIN {
  #these are the os's that are supported at this time
  my @Supported  = ('openbsd','freebsd','linux','irix','solaris','darwin','MSWin32');
  grep /$^O/, @Supported 
  or die "$^O isn't supported by Sys:IP yet.\n";
}

#----------------------------------------------------------------------------# 
#this is where ifconfig lives on systems that i had access too
my %ifconfigLocation = (   'linux' => '/sbin/ifconfig',
			'openbsd' => '/sbin/ifconfig',
			'freebsd' => '/sbin/ifconfig',
			'irix' => '/usr/etc/ifconfig',
			'solaris' => '/sbin/ifconfig',
			'darwin' => '/sbin/ifconfig'
		    );

#----------------------------------------------------------------------------#
#these are the os's that are supported at this time
sub SUPPORTED {
  return ('openbsd', 'freebsd', 'linux', 'irix', 'solaris', 'darwin', 'MSWin32');
}

#----------------------------------------------------------------------------#
#you can override $IFCONFIG_BINARY if your ifconfig program's location
#differs from the standard ones listed above
$IFCONFIG_BINARY = $ifconfigLocation{$^O};

#----------------------------------------------------------------------------#
sub ip {
  #ok, this will be the default use. we'll take out the loopback entry, and
  #return the ip address of the first interface that comes up
  #afterwards. This should be fine for most people, since most machines only
  #have one ip address
  if($^O eq 'MSWin32') {
    #this will change once i can get a win32 machine to fix this code
    return(getWin32InterfaceInfo());
  }
  else {
    my %ifInfo = getUnixInterfaceInfo();
    foreach my $key (sort keys %ifInfo) {
      #we don't want the loopback
      next if ($ifInfo{$key} eq '127.0.0.1');
      #now we return the first one that comes up
      return ($ifInfo{$key});
    }
    #we get here if loopback is the only active device
    return undef;
  }
}
#----------------------------------------------------------------------------# 
sub ips {
  #ips() returns all ip addresses on a machine this is a hack. i don't know
  #how win32 handles multiple ip addresses, so this is broken until i can
  #get a testing machine (or until someone fixes it for me)
  if ($^O eq 'MSWin32') {
    return (getWin32InterfaceInfo());
  }
  else {
    my %ifInfo = getUnixInterfaceInfo();
    my @ips = '';
    foreach my $key (keys %ifInfo) {
      push @ips, $ifInfo{$key};
    }
    return @ips;
  }
}
#----------------------------------------------------------------------------# 
sub interfaces {
  #interfaces returns a hash of interface:ip address pairs.
  #
  #again, the ms code will be fixed when i get a test machine setup
  if ($^O eq 'MSWin32') {
    return ('MSWin32', getWin32InterfaceInfo());
  }
  else {
    return getUnixInterfaceInfo();
  }
}
#----------------------------------------------------------------------------#
sub getWin32InterfaceInfo {
  #this is shamefully stolen from the original Sys::HostIP. I've got to find
  # a win32 machine to test and clean this up on, but for the time being
  # we'll just use it (since i assume it works already).
  #
  #begin code that i didn't write:
  #
  #check ipconfig.exe (Whichdoes all the work of checking the registry,
  #probably more efficiently than I could.)
  my $nocannon= (split /\./, (my $cannon = hostname))[0];
  my $ip;
  return $ip= $1 if `ipconfig`=~ /(\d+\.\d+\.\d+\.\d+)/;
  
  # check nbtstat.exe 
  # (Which does all the work of checking WINS,
  # more easily than Win32::AdminMisc::GetHostAddress().)
  return $ip= $1 if `nbtstat -a $nocannon`=~ /(\d+\.\d+\.\d+\.\d+)/;
  
  # check /etc/hosts entries 
  if(open HOST, "<$ENV{SystemRoot}\\System32\\drivers\\etc\\hosts")
    {
      while(<HOST>)
	{
	  last if /\b$cannon\b/i and /(\d+\.\d+\.\d+\.\d+)/ and $ip= $1;
	}
      close HOST;
      return $ip if $ip;
    }
  
  # check /etc/lmhosts entries 
  # (It will only be here if the file has been modified since the
  # last WINS refresh, which is unlikely, but might as well try.)
  if(open HOST, "<$ENV{SystemRoot}\\System32\\drivers\\etc\\lmhosts")
    {
      while(<HOST>)
	{
	  last if /\b$nocannon\b/i and /(\d+\.\d+\.\d+\.\d+)/ and $ip= $1;
	}
      close HOST;
      return $ip if $ip;
    }
}

#----------------------------------------------------------------------------# 

sub getUnixInterfaceInfo {
  my %ifInfo;
  my ($ip, $interface) = undef;
  #this is an attempt to fix tainting problems
  local %ENV;
  # $BASH_ENV must be unset to pass tainting problems if your system uses
  # bash as /bin/sh
  if ($ENV{'BASH_ENV'}) {
    $ENV{'BASH_ENV'} = undef;
  }
  #now we set the local $ENV{'PATH'} to be only the path to ifconfig
  my $newpath = $ifconfigLocation{$^O};
  $newpath =~s/\/\w+$//;
  $ENV{'PATH'} = $newpath;

  my @ifconfig = `$ifconfigLocation{$^O} -a`;
  foreach my $line (@ifconfig) {
    #output from 'ifconfig -a' looks something like this on every *nix i
    #could get my hand on except linux (this one's actually from OpenBSD):
    #
    #gershiwin:~# /sbin/ifconfig -a
    #lo0: flags=8009<UP,LOOPBACK,MULTICAST>
    #        inet 127.0.0.1 netmask 0xff000000 
    #lo1: flags=8008<LOOPBACK,MULTICAST>
    #xl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST>
    #        media: Ethernet autoselect (100baseTX full-duplex)
    #        status: active
    #        inet 10.0.0.2 netmask 0xfffffff0 broadcast 10.0.0.255
    #sl0: flags=c010<POINTOPOINT,LINK2,MULTICAST>
    #sl1: flags=c010<POINTOPOINT,LINK2,MULTICAST>
    #
    #in linux it's a little bit different:
    #
    #[jschatz@nooky Sys-IP]$ /sbin/ifconfig 
    # eth0      Link encap:Ethernet  HWaddr 00:C0:4F:60:6F:C2  
    #          inet addr:10.0.3.82  Bcast:10.0.255.255  Mask:255.255.0.0
    #          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
    #          Interrupt:19 Base address:0xec00 
    # lo        Link encap:Local Loopback  
    #          inet addr:127.0.0.1  Mask:255.0.0.0
    #          UP LOOPBACK RUNNING  MTU:3924  Metric:1
    #
    # so the regexen involved here have to deal with the following: 1)
    # there's no ':' after an interface's name in linux 2) in linux, it's
    # "inet addr:127.0.0.1" instead of "inet 127.0.0.1" hence the somewhat
    # hairy regexen /(^\w+(?:\d)?(?:\:\d)?)/ (which also handles aliased ip
    # addresses , ie eth0:1) and /inet(?:addr\:)?(\d+\.\d+\.\d+\.\d+)/
    #
    #so we parse through the list returned. if the line starts with some
    #letters followed (possibly) by an number and a colon, then we've got an
    #interface. if the line starts with a space, then it's the info from the
    #interface that we just found, and we stick the contents into %ifInfo
    if ( ($line =~/^\s+/) && ($interface) ) {
      $ifInfo{$interface} .= $line;
    }
    elsif (($interface) = ($line =~/(^\w+(?:\d)?(?:\:\d)?)/)) {
      $line =~s/\w+\d(\:)?\s+//;
      $ifInfo{$interface} = $line;
    }
  }
    foreach my $key (keys %ifInfo) {
      #now we want to get rid of all the other crap in the ifconfig
      #output. we just want the ip address. perhaps a future version can
      #return even more useful results (netmask, etc).....
      if (my ($ip) = ($ifInfo{$key} =~/inet (?:addr\:)?(\d+\.\d+\.\d+\.\d+)/)) {
	$ifInfo{$key} = $ip;
      }
      else {
	#ok, no ip address here, which means this interface isn't
	#active. some os's (openbsd for instance) spit out ifconfig info for
	#inactive devices. this is pretty much worthless for us, so we
	#delete it from the hash
	delete $ifInfo{$key};
      }
    }
  #now we do some cleanup by deleting keys that have no associated info
  #(some os's like openbsd list inactive interfaces when 'ifconfig -a' is
  #used, and we don't care about those
  return %ifInfo;
} 
1;
__END__

=pod

=head1 NAME

Sys::IP - Returns all ip addresses from the local machine in various forms

=head1 SYNOPSIS

=over 4

use Sys::IP;

my $ip = ip();

my @ips = ips();

my %interfaces = interfaces();

=back 4

=head1 DESCRIPTION

  Sys::IP is a rewrite of the original Sys::IP that supports man *NIX systems. The win32 code has been taken from the old SYS::IP, and the unix code was written from scratch. Sys::IP runs on a variety of *NIX flavors (currently freebsd, openbsd, linux, solaris, irix, and darwin). More support will be added when I get more machines to test on :-)

=head1 FUNCTIONS

=item ip()

This returns a scalar containing the first non-localhost (127.0.0.1) ip address that exists on the local machine.

=item ips()

This returns a list of all ip addresses that exist on the local machine.

=item interfaces()

This returns a hash of all interface/ip address pairs that exist on the local machine

=head1 BUGS

  The interfaces() function doesn't work on Win32 systems. Support is planned when I find some spare time.

=head1 AUTHOR

Jonathan Schatz, jon@divisionbyzero.com

=cut
