#include <string>
#include <iostream>

#include <osgViewer/Viewer>
#include <osgViewer/ViewerEventHandlers>
#include <osgGA/TrackballManipulator>
#include <osgGA/NodeTrackerManipulator>
#include <osgGA/StateSetManipulator>

#include <osgDB/ReadFile>
#include <osg/Timer>

#include "ViewerManipulator.h"
#include "spinUtil.h"
#include "spinContext.h"
#include "panoViewer.h"
//#include "osgUtil.h"

using namespace std;

extern pthread_mutex_t pthreadLock;


// *****************************************************************************
// *****************************************************************************
// *****************************************************************************
int main(int argc, char **argv)
{
	std::cout <<"\npanoViewer launching..." << std::endl;

	spinContext &spin = spinContext::Instance();
	//spin.setMode(spinContext::LISTENER_MODE);

	std::string id = getHostname();


	// *************************************************************************

	// get arguments:
	osg::ArgumentParser arguments(&argc,argv);

	// set up the usage document, which a user can acess with -h or --help
	arguments.getApplicationUsage()->setDescription(arguments.getApplicationName()+" is a panoscope viewer for the SPIN Framework.");
	arguments.getApplicationUsage()->setCommandLineUsage(arguments.getApplicationName()+" [options]");
	arguments.getApplicationUsage()->addCommandLineOption("-h or --help", "Display this information");

	arguments.getApplicationUsage()->addCommandLineOption("-id <uniqueID>", "Specify an ID for this viewer (Default is hostname: '" + id + "')");

	arguments.getApplicationUsage()->addCommandLineOption("-sceneID <uniqueID>", "Specify the scene ID to listen to (Default: '" + spin.id + "')");
	arguments.getApplicationUsage()->addCommandLineOption("-serverAddr <addr>", "Set the receiving address for incoming OSC messages (Default: " + spin.rxAddr + ")");
	arguments.getApplicationUsage()->addCommandLineOption("-serverPort <port>", "Set the receiving port for incoming OSC messages (Default: " + spin.rxPort + ")");


	// *************************************************************************
	// PARSE ARGS:

	// if user request help write it out to cout.
	if (arguments.read("-h") || arguments.read("--help"))
	{
		arguments.getApplicationUsage()->write(std::cout);
		return 1;
	}

	osg::ArgumentParser::Parameter param_id(id);
	arguments.read("-id", param_id);
	osg::ArgumentParser::Parameter param_spinID(spin.id);
	arguments.read("-sceneID", param_spinID);
	osg::ArgumentParser::Parameter param_spinAddr(spin.rxAddr);
	arguments.read("-serverAddr", param_spinAddr);
	osg::ArgumentParser::Parameter param_spinPort(spin.rxPort);
	arguments.read("-serverPort", param_spinPort);



	// For testing purposes, we allow loading a scene with a commandline arg:
	osg::ref_ptr<osg::Node> argScene = osgDB::readNodeFiles(arguments);


	// *************************************************************************
	// construct the viewer:
	// (note, this constructor gets rid of some additional args)

	panoViewer viewer = panoViewer(arguments);
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

	if (!spin.start())
	{
        std::cout << "ERROR: could not start SPIN listener thread" << std::endl;
        exit(1);
	}
	
	spin.sceneManager->setGraphical(true);
	
	// register a user
	spin.registerUser(id.c_str());
	
	// *************************************************************************
	// create a camera manipulator

	osg::ref_ptr<ViewerManipulator> manipulator;
	if (spin.user.valid())
	{
		manipulator = new ViewerManipulator(spin.user.get());
		
		manipulator->setPicker(false);
		manipulator->setMover(true);

		viewer.setCameraManipulator(manipulator.get());
	}
	

	// *************************************************************************
	// set up any initial scene elements:

	if (argScene.valid()) {
		std::cout << "Loading sample model" << std::endl;
		spin.sceneManager->worldNode->addChild(argScene.get());
	}



	// *************************************************************************
	// start threads:

	viewer.setSceneData(spin.sceneManager->rootNode.get());
	viewer.setupViewForPanoscope();

	viewer.realize();
	
	// ask for refresh:
	spin.sendSceneMessage("s", "refresh", LO_ARGS_END);
	
	osg::Timer_t lastTick = osg::Timer::instance()->tick();
	osg::Timer_t frameTick = lastTick;

	// program loop:
	while( !viewer.done() )
	{
		
		if (spin.isRunning())
		{
	    	frameTick = osg::Timer::instance()->tick();
	    	if (osg::Timer::instance()->delta_s(lastTick,frameTick) > 5) // every 5 seconds
	    	{
			    spin.sendInfoMessage("/ping/user", "s", (char*) id.c_str(), LO_ARGS_END);
	    		lastTick = frameTick;
	    	}

	    	// We now have to go through all the nodes, and check if we need to update the
	    	// graph. Note: this cannot be done as a callback in a traversal - dangerous.
	    	// In the callback, we have simply flagged what needs to be done (eg, set the
	    	// newParent symbol).
	    	pthread_mutex_lock(&pthreadLock);
	    	spin.sceneManager->updateGraph();
	    	pthread_mutex_unlock(&pthreadLock);

	    	pthread_mutex_lock(&pthreadLock);
	    	viewer.frame();
	    	pthread_mutex_unlock(&pthreadLock);

		} else {
			if (manipulator.valid())
			{
				viewer.setCameraManipulator(NULL);
				manipulator.release();
			}
			viewer.setDone(true);
		}
	}
	
	std::cout << "panoViewer done." << std::endl;
	
    return 0;
}
