#!/usr/bin/env python
"""
This example demonstrate how to use lunch master as a library.
"""
if __name__ == "__main__": # just a reminder
    from twisted.internet import gtk2reactor
    gtk2reactor.install() # has to be done before importing reactor
from twisted.internet import reactor
from twisted.internet import task
from lunch import commands
from lunch import master
from lunch import gui

# example data
has_them = False
counter = 0

class ProcessLauncher(object):
    """
    Process launching with Lunch + a window.
    """
    def __init__(self):
        unique_master_id = "spinic"
        log_dir = master.DEFAULT_LOG_DIR
        
        master.start_logging()
        pid_file = master.write_master_pid_file(identifier=unique_master_id, directory=log_dir)
        self.lunch_master = master.Master(log_dir=log_dir, pid_file=pid_file, verbose=True)
        self.lunch_gui = gui.start_gui(self.lunch_master)
        
        self._example_looping_call = None
        self._start_example()
    
    def _start_example(self):
        global has_them
        global counter
        self.lunch_master.add_command(commands.Command("xeyes", identifier="xeyes"))
        self.lunch_master.add_command(commands.Command("xlogo", identifier="xlogo"))
        self.lunch_master.add_command(commands.Command("xcalc", identifier="xcalc"))
        self.lunch_master.add_command(commands.Command("xterm -hold -e /bin/bash -c \"echo %d\"" % (counter), identifier="xterm"))

        counter += 1
        has_them = True
        
        def _test():
            global has_them
            global counter
            if not has_them:
                print("Adding them again!")
                self.lunch_master.add_command(commands.Command("xeyes", identifier="xeyes"))
                self.lunch_master.add_command(commands.Command("xlogo", identifier="xlogo"))
                self.lunch_master.add_command(commands.Command("xcalc", identifier="xcalc"))
                self.lunch_master.add_command(commands.Command("xterm -hold -e /bin/bash -c \"echo %d\"" % (counter), identifier="xterm"))
                counter += 1
                has_them = True
            else:
                print("Removing them.")
                self.lunch_master.remove_command("xeyes")
                self.lunch_master.remove_command("xlogo")
                self.lunch_master.remove_command("xcalc")
                self.lunch_master.remove_command("xterm")
                has_them = False
                
        self._example_looping_call = task.LoopingCall(_test)
        self._example_looping_call.start(3.0, False)

