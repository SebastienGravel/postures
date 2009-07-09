#include <string>
#include <iostream>

#include <osgViewer/Viewer>
#include <osgViewer/ViewerEventHandlers>
#include <osgGA/TrackballManipulator>
#include <osgDB/ReadFile>
#include <osg/Timer>


#include "asUtil.h"
#include "vessThreads.h"
#include "asCameraManager.h"
#include "panoViewer.h"

using namespace std;

extern pthread_mutex_t pthreadLock;



// *****************************************************************************
// *****************************************************************************
// *****************************************************************************
int main(int argc, char **argv)
{
	// Now make sure we can load the libAudioscape library:
	osgDB::Registry *reg = osgDB::Registry::instance();
	osgDB::DynamicLibrary::loadLibrary(reg->createLibraryNameForNodeKit("libSPIN"));

	std::cout <<"\npanoViewer launching..." << std::endl;

	vessListener *vess = new vessListener();


    std::string viewerID = "default";
    std::string viewerAddr = "224.0.0.1";
    //std::string viewerAddr = getMyIPAddress();
    std::string viewerPort = "54322";
    std::string resolutionString = "720x480";


	// *************************************************************************

	// get arguments:
	osg::ArgumentParser arguments(&argc,argv);

	// set up the usage document, which a user can acess with -h or --help
	arguments.getApplicationUsage()->setDescription(arguments.getApplicationName()+" is a panoscope viewer for VESS.");
	arguments.getApplicationUsage()->setCommandLineUsage(arguments.getApplicationName()+" [options]");
	arguments.getApplicationUsage()->addCommandLineOption("-h or --help", "Display this information");

	arguments.getApplicationUsage()->addCommandLineOption("-rxID <uniqueID>", "Specify the VESS scene ID to listen to (Default: '" + vess->id + "')");
	arguments.getApplicationUsage()->addCommandLineOption("-rxAddr <addr>", "Set the receiving address for incoming OSC messages (Default: " + vess->rxAddr + ")");
	arguments.getApplicationUsage()->addCommandLineOption("-rxPort <port>", "Set the receiving port for incoming OSC messages (Default: " + vess->rxPort + ")");

	arguments.getApplicationUsage()->addCommandLineOption("-viewerID <uniqueID>", "Specify a unique ID for the embedded asViewer (Default: '" + viewerID + "')");
	arguments.getApplicationUsage()->addCommandLineOption("-viewerAddr <addr>", "Specify the address for camera/view events (default: " + viewerAddr + ")");
	arguments.getApplicationUsage()->addCommandLineOption("-viewerPort <port>", "Specify the port for camera/view events (default: " + viewerPort + ")");


	// *************************************************************************
	// PARSE ARGS:

	// if user request help write it out to cout.
	if (arguments.read("-h") || arguments.read("--help"))
	{
		arguments.getApplicationUsage()->write(std::cout);
		return 1;
	}

	osg::ArgumentParser::Parameter param_rxID(vess->id);
	arguments.read("-rxID", param_rxID);
	osg::ArgumentParser::Parameter param_rxAddr(vess->rxAddr);
	arguments.read("-rxAddr", param_rxAddr);
	osg::ArgumentParser::Parameter param_rxPort(vess->rxPort);
	arguments.read("-rxPort", param_rxPort);

	osg::ArgumentParser::Parameter param_viewerID(viewerID);
	arguments.read("-viewerID", param_viewerID);
	osg::ArgumentParser::Parameter param_viewerAddr(viewerAddr);
	arguments.read("-viewerAddr", param_viewerAddr);
	osg::ArgumentParser::Parameter param_viewerPort(viewerPort);
	arguments.read("-viewerPort", param_viewerPort);
	osg::ArgumentParser::Parameter param_resolution(resolutionString);
	arguments.read("-resolution", param_resolution);


	// For testing purposes, we allow loading a scene with a commandline arg:
	osg::ref_ptr<osg::Node> argScene = osgDB::readNodeFiles(arguments);


	// *************************************************************************
	// construct the viewer:
	// (note, this constructor gets rid of some additional args)

	panoViewer viewer = panoViewer(arguments);
	//osgViewer::Viewer viewer = osgViewer::Viewer(arguments);
	

	// set the threading model for the viewer:
	/*
	while (arguments.read("-s")) { viewer.setThreadingModel(osgViewer::Viewer::SingleThreaded); }
	while (arguments.read("-g")) { viewer.setThreadingModel(osgViewer::Viewer::CullDrawThreadPerContext); }
	while (arguments.read("-d")) { viewer.setThreadingModel(osgViewer::Viewer::DrawThreadPerContext); }
	while (arguments.read("-c")) { viewer.setThreadingModel(osgViewer::Viewer::CullThreadPerCameraDrawThreadPerContext); }
	*/

	viewer.setCameraManipulator(new osgGA::TrackballManipulator());
	
	viewer.addEventHandler(new osgViewer::StatsHandler);
	viewer.addEventHandler(new osgViewer::ThreadingHandler);
	viewer.addEventHandler(new osgViewer::WindowSizeHandler);


	
	viewer.setThreadingModel(osgViewer::Viewer::SingleThreaded);
	
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
	// start the vessListener thread:

	vess->start();
	vess->sceneManager->isGraphical = true;



	// *************************************************************************
	// set up any initial scene elements:

	if (argScene.valid()) {
		std::cout << "Loading sample model" << std::endl;
		vess->sceneManager->worldNode->addChild(argScene.get());
	}


	
	// *************************************************************************
	// start threads:

	viewer.setSceneData(vess->sceneManager->rootNode.get());
	viewer.setupViewForPanoscope();

	viewer.realize();

	// program loop:
	while( !viewer.done() && vess->isRunning() )
	{
		// We now have to go through all the nodes, and check if we need to update the
		// graph. Note: this cannot be done as a callback in a traversal - dangerous.
		// In the callback, we have simply flagged what needs to be done (eg, set the
		// newParent symbol).
		pthread_mutex_lock(&pthreadLock);
		vess->sceneManager->updateGraph();
		pthread_mutex_unlock(&pthreadLock);
		
		
		pthread_mutex_lock(&pthreadLock);
		viewer.frame();
		pthread_mutex_unlock(&pthreadLock);
	}


	return 0;
}
