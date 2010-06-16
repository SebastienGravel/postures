#!/usr/bin/env python
"""
Prototype that receives OSC messages from a SPIN server.

The SPIN Framework is designed so multiple processes can share state over a network via OpenSoundControl (OSC) messages. By default, these messages are sent using multicast UDP to the address of 224.0.0.1, which is known as the the all-hosts group. Most network interfaces are already members of this multicast group, so a typical client application need only to start a UDP listener on the appropriate port to discover messages related to SPIN.
"""
import sys
from twisted.internet import reactor
from twisted.internet import error
from txosc import osc
from txosc import dispatch
from txosc import async

class SpinicOscInterface(object):
    """
    Example that receives UDP OSC messages.
    """
    def __init__(self, receive_port=54323):
        self.receive_port = receive_port
        self.receiver = dispatch.Receiver()
        try:
            self._datagram_protocol = reactor.listenMulticast(self.receive_port, async.MulticastDatagramServerProtocol(self.receiver), listenMultiple=True) 
        except error.CannotListenError, e:
            print(e)
            print("Giving up!")
            sys.exit(1)
        print("Listening on osc.udp://localhost:%s" % (self.receive_port))
        # adding callbacks:
        self.receiver.addCallback("/ping/SPIN", self.ping_spin_handler)
        self.receiver.addCallback("/SPIN/*", self.spin_any_handler)
        self.receiver.addCallback("/SPIN/*/*", self.spin_any_any_handler)
        self.receiver.fallback = self.fallback_handler

    def spin_any_handler(self, message, address):
        """
        /SPIN/*
        """
        print("spin_any: Got %s from %s" % (message, address))
    
    def spin_any_any_handler(self, message, address):
        """
        /SPIN/*
        """
        #print("spin_any_any: Got %s from %s" % (message, address))
        tokens = message.address.split("/")
        spin = tokens[1]
        obj = tokens[2]
        print("%s/%s: %s" % (spin, obj, message.arguments))
    
    def ping_spin_handler(self, message, address):
        """
        When SPIN launches, it periodically sends a ping on the infoPort:
        /ping/SPIN spinID rxAddr rxPort txAddr txPort syncPort
        """
        print("ping_spin: Got %s from %s" % (message, address))
    
    def fallback_handler(self, message, address):
        """
        Fallback.
        """
        print("fallback: Got %s from %s" % (message, address))

