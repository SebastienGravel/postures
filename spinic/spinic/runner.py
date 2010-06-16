#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Spinic SPIN + Lunch + Scenic integration.
"""
import sys
import os
from twisted.internet import gtk2reactor
gtk2reactor.install()
from twisted.internet import reactor
import gtk

__version__ = "0.1.0"
PACKAGE_DATA = "./data"
APP_NAME = "spinic"
GLADE_FILE_NAME = "spinic.glade"

class Gui(object):
    """
    Main application (arguably God) class
     * Contains the main GTK window
    """
    def __init__(self):
        gtkbuilder_file = os.path.join(PACKAGE_DATA, GLADE_FILE_NAME)
        if not os.path.isfile(gtkbuilder_file):
            print "Could not find the glade file."
            sys.exit(1)
        self.builder = gtk.Builder()
        self.builder.add_from_file(gtkbuilder_file)
        self.window = self.builder.get_object("main_window")
        if self.window is None:
            raise RuntimeError("Could not get the window widget.")
        self.window.connect('delete-event', self.on_main_window_deleted)
        self.window.show()
   
    def on_main_window_deleted(self, *args):
        """
        Destroy method causes appliaction to exit
        when main window closed
        """
        reactor.stop()

def run():
    gui = Gui()
    reactor.run()

