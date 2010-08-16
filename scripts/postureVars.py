#
# To include these variables in other scripts, you add the following:
#
# import os
# execfile(os.path.join(os.path.dirname(__file__), "postures.py"))
#
# Then, you can access the variables like this:
#
# posture.user
#

class postures:

    user = "posture"

    srcPath = "/home/%s/src" % (user)
    posturesPath = "%s/postures/trunk" % (srcPath)
    ntaPath = "/home/%s/content/nta" % (user)
    spinwidgetsPath = "%s/spinwidgets" % (srcPath)
    spinPath = "%s/spinframework/trunk" % (srcPath)
    
    #pd = "%s/pd-0.41-4/bin/pd" % (srcPath)
    pd = "/usr/local/bin/pd"

    pdheadset = "%s -jack -r 16000 -inchannels 3 -outchannels 3" % (pd)
    pdstereo = "%s -jack -r 48000 -inchannels 2 -outchannels 2" % (pd)
    pdnoaudio = "%s -noaudio" % (pd)

    spinEditor = "%s %s/patches/spinEdit.pd %s/milhouseTest.pd" % (pdnoaudio, spinwidgetsPath, ntaPath)



