#!/usr/bin/env python
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
from twisted.application.internet import MulticastServer
import pprint
import socket


#TODO: listenMultiple = True to MulticastPort constructor

class MulticastServerUDP(DatagramProtocol):
    def startProtocol(self):
        print 'Started Listening'
        # Join a specific multicast group, which is the IP we will respond to
        
        #self.transport.socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        #self.transport.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.transport.joinGroup('224.0.0.1')
        #print(dir())
        #if hasattr(socket, "SO_REUSEPORT"):
        #    print("REUSEPORT: %s" % (self.transport.socket.getsockopt(socket.SO_DEBUG, socket.SO_REUSEPORT)))
        #print("REUSEADDR: %s" % (self.transport.socket.getsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR)))
        #print("BROADCAST: %s" % (self.transport.socket.getsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST)))

    def datagramReceived(self, datagram, address):
        # The uniqueID check is to ensure we only service requests from
        # ourselves
        if datagram == 'UniqueID':
            print "Server Received:" + repr(datagram)
            self.transport.write("data", address)


if __name__ == "__main__":
    # Note that the join function is picky about having a unique object
    # on which to call join.  To avoid using startProtocol, the following is
    # sufficient:
    #reactor.listenMulticast(8005, MulticastServerUDP()).join('224.0.0.1')

    # Listen for multicast on 224.0.0.1:8005
    reactor.listenMulticast(8005, MulticastServerUDP(), listenMultiple=True)
    reactor.run()


