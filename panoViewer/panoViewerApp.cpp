#include <string>
#include <iostream>

#include <osgViewer/Viewer>
#include <osgViewer/ViewerEventHandlers>
#include <osgGA/TrackballManipulator>
#include <osgGA/NodeTrackerManipulator>
#include <osgGA/StateSetManipulator>

#include <osgDB/ReadFile>
#include <osg/Timer>

#include <spinFramework/ViewerManipulator.h>
#include <spinFramework/spinApp.h>
#include <spinFramework/spinClientContext.h>
#include <spinFramework/spinUtil.h>
#include <spinFramework/spinClientContext.h>
#include <spinFramework/SceneManager.h>

#include "panoViewer.h"

extern pthread_mutex_t sceneMutex;


// *****************************************************************************
// *****************************************************************************
// *****************************************************************************
int main(int argc, char **argv)
{
	std::cout << std::endl <<"panoViewer launching..." << std::endl;

	spinClientContext spinListener;
	spinApp &spin = spinApp::Instance();

    bool hideCursor=false;
    double maxFrameRate = 60;

	std::string userID;
    std::string sceneID = spin.getSceneID();
	std::string rxHost = lo_address_get_hostname(spin.getContext()->lo_rxAddrs_[0]);
	std::string rxPort = lo_address_get_port(spin.getContext()->lo_rxAddrs_[0]);
	std::string syncPort = lo_address_get_port(spin.getContext()->lo_syncAddr);

	// *************************************************************************

	// get arguments:
	osg::ArgumentParser arguments(&argc,argv);

	// set up the usage document, which a user can acess with -h or --help
	arguments.getApplicationUsage()->setDescription(arguments.getApplicationName()+" is a panoscope viewer for the SPIN Framework.");
	arguments.getApplicationUsage()->setCommandLineUsage(arguments.getApplicationName()+" [options]");
	arguments.getApplicationUsage()->addCommandLineOption("-h or --help", "Display this information");
	arguments.getApplicationUsage()->addCommandLineOption("--user-id <uniqueID>", "Specify an ID for this viewer (Default is the localhost name)");
	arguments.getApplicationUsage()->addCommandLineOption("--scene-id <uniqueID>", "Specify the scene ID to listen to (Default: '" + spin.getSceneID() + "')");
	arguments.getApplicationUsage()->addCommandLineOption("--server-addr <host> <port>", "Set the receiving address for incoming OSC messages (Default: <local host name> " + rxPort + ")");
	arguments.getApplicationUsage()->addCommandLineOption("--hide-cursor", "Hide the mouse cursor");
	arguments.getApplicationUsage()->addCommandLineOption("--framerate <num>", "Set the maximum framerate (Default: not limited)");


	// *************************************************************************
	// PARSE ARGS:

	// if user request help write it out to cout.
	if (arguments.read("-h") || arguments.read("--help"))
	{
		arguments.getApplicationUsage()->write(std::cout);
		return 1;
	}

    osg::ArgumentParser::Parameter param_userID(userID);
    arguments.read("--user-id", param_userID);
    if (not userID.empty())
        spin.setUserID(userID);

    osg::ArgumentParser::Parameter param_spinID(sceneID);
    arguments.read("--scene-id", param_spinID);
    spin.setSceneID(sceneID);

	while (arguments.read("--server-addr", rxHost, rxPort)) {
        spinListener.lo_rxAddrs_[0] = lo_address_new(rxHost.c_str(), rxPort.c_str());
    }
    // FIXME:2010-08-16:aalex:Is using the --sync-port option like that ok?
	//while (arguments.read("--sync-port", syncPort)) {
	//	spinListener.lo_syncAddr = lo_address_new(rxHost.c_str(), syncPort.c_str());
	//}

    while (arguments.read("--hide-cursor")) hideCursor=true;
	while (arguments.read("--framerate",maxFrameRate)) {}


	// *************************************************************************

	// For testing purposes, we allow loading a scene with a commandline arg:
	osg::ref_ptr<osg::Node> argScene = osgDB::readNodeFiles(arguments);


	// *************************************************************************
	// construct the viewer:
	// (note, this constructor gets rid of some additional args)

	osgPano::panoViewer viewer = osgPano::panoViewer(arguments);
	//osgViewer::Viewer viewer = osgViewer::Viewer(arguments);

	viewer.setThreadingModel(osgViewer::Viewer::SingleThreaded);

	viewer.addEventHandler(new osgViewer::StatsHandler);
	viewer.addEventHandler(new osgViewer::ThreadingHandler);
	viewer.addEventHandler(new osgViewer::WindowSizeHandler);

	viewer.addEventHandler(new osgViewer::LODScaleHandler);
	
	viewer.addEventHandler(new osgViewer::HelpHandler(arguments.getApplicationUsage()));
	viewer.addEventHandler( new osgGA::StateSetManipulator(viewer.getCamera()->getOrCreateStateSet()) );

	//viewer.setLightingMode(osg::View::NO_LIGHT);
	viewer.setLightingMode(osg::View::HEADLIGHT);
	//viewer.setLightingMode(osg::View::SKY_LIGHT);



	// *************************************************************************
	// any option left unread are converted into errors to write out later.
	arguments.reportRemainingOptionsAsUnrecognized();

	// report any errors if they have occured when parsing the program aguments.
	if (arguments.errors())
	{
		arguments.writeErrorMessages(std::cout);
		return 1;
	}

	// get details on keyboard and mouse bindings used by the viewer.
	viewer.getUsage(*arguments.getApplicationUsage());


	// *************************************************************************
	// start the listener thread:

	if (!spin.getContext()->start())
	{
        std::cout << "ERROR: could not start SPIN listener thread" << std::endl;
        exit(1);
	}
	
	spin.sceneManager->setGraphical(true);
	
	

	// *************************************************************************
	// set up any initial scene elements:

	if (argScene.valid()) {
		std::cout << "Loading sample model" << std::endl;
		spin.sceneManager->worldNode->addChild(argScene.get());
	}



	// *************************************************************************
	// set up viewer:

	viewer.setSceneData(spin.sceneManager->rootNode.get());
	viewer.setupViewForPanoscope();
    viewer.setNearFar(0.01,10000);

    viewer.setClearColor(osg::Vec4(0.0,0.0,0.0,0.0));

	
	
	osgViewer::ViewerBase::Windows windows;
    osgViewer::ViewerBase::Windows::iterator wIter;
    viewer.getWindows(windows);
    for (wIter=windows.begin(); wIter!=windows.end(); wIter++)
    {
        (*wIter)->setWindowName("panoviewer " + spin.getUserID() + "@" + spin.getSceneID());
		if (hideCursor) (*wIter)->useCursor(false);
    }


	// *************************************************************************
	// create a camera manipulator

	osg::ref_ptr<ViewerManipulator> manipulator = new ViewerManipulator();
	manipulator->setPicker(false);
	manipulator->setMover(true);
	viewer.setCameraManipulator(manipulator.get());


	
    // *************************************************************************
    // start threads:
	viewer.realize();
	
	// ask for refresh:
	spin.SceneMessage("s", "refresh", LO_ARGS_END);


	osg::Timer_t lastFrameTick = osg::Timer::instance()->tick();

	double minFrameTime = 1.0 / maxFrameRate;
	
	// program loop:
	while( !viewer.done() )
	{
		
		if (spinListener.isRunning())
		{

			
            pthread_mutex_lock(&sceneMutex);
			viewer.frame();
			pthread_mutex_unlock(&sceneMutex);
		    
			OpenThreads::Thread::microSleep(5);
            	
            /*
			double dt = osg::Timer::instance()->delta_s(lastFrameTick, osg::Timer::instance()->tick());

			if (dt > minFrameTime)
			{
				pthread_mutex_lock(&sceneMutex);
				viewer.frame();
				pthread_mutex_unlock(&sceneMutex);

				// save time when the last time a frame was rendered:
				lastFrameTick = osg::Timer::instance()->tick();
				dt = 0;
			}

			unsigned int sleepTime;

			sleepTime = static_cast<unsigned int>(1000000.0*(minFrameTime-dt));
			if (sleepTime > 100) sleepTime = 100;

            // only sleep if there weren't any messages 
			if (!recv) OpenThreads::Thread::microSleep(sleepTime);
			*/
		} else {
			if (manipulator.valid())
			{
				viewer.setCameraManipulator(NULL);
				manipulator.release();
			}
			viewer.setDone(true);
		}
	}

    spinListener.stop();
	
	std::cout << "panoViewer done." << std::endl;
	
    return 0;
}
