#include <string>
#include <iostream>

#include <osgViewer/Viewer>
#include <osgViewer/ViewerEventHandlers>
#include <osgGA/TrackballManipulator>
#include <osgGA/NodeTrackerManipulator>
#include <osgDB/ReadFile>
#include <osg/Timer>


#include "asUtil.h"
#include "vessThreads.h"
#include "asCameraManager.h"
#include "panoViewer.h"

using namespace std;

extern pthread_mutex_t pthreadLock;


int panoViewer_liblo_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	
    // make sure there is at least one argument (ie, a method):
	if (!argc) return 0;

	panoViewer *viewer = (panoViewer*)user_data;
    if (!viewer) return 0;

    
	// get the method (argv[0]):
    std::string theMethod;
	if (lo_is_string_type((lo_type)types[0]))
	{
		theMethod = string((char *)argv[0]);
	}
	else return 0;
    
	// parse the rest of the args:
	vector<float> floatArgs;
	vector<const char*> stringArgs;
	for (int i=1; i<argc; i++)
	{
		if (lo_is_numerical_type((lo_type)types[i]))
		{
			floatArgs.push_back( (float) lo_hires_val((lo_type)types[i], argv[i]) );
		} else {
			stringArgs.push_back( (const char*) argv[i] );
		}
	}	

	// try to find the node id:
	std::string nodeStr = string(path);
	nodeStr = nodeStr.substr(nodeStr.rfind("/")+1);
	t_symbol *s = gensym(nodeStr.c_str());
	osg::ref_ptr<asReferenced> n = s->s_thing;
	if (!n.valid())
	{
		std::cout << "panoViewer_liblo_callback: Could not find node: " << nodeStr << std::endl;
		return 0;
	}
	
	if ( (theMethod=="global6DOF") && (floatArgs.size()==6))
	{
//    	viewer->getCamera(0)->setViewMatrixAsLookAt(
		std::cout << "got camera update:" << floatArgs[0] << "," << floatArgs[1] << "," << floatArgs[2] << "  " << floatArgs[3] << "," << floatArgs[4] << "," << floatArgs[5] << std::endl;

	//    osg::Vec3 = dirVector
    	//viewer->getCamera(0)->setViewMatrixAsLookAt(osg::Vec3(floatArgs[0],floatArgs[1],floatArgs[2]), 
	}


	osgGA::NodeTrackerManipulator *manipulator = new osgGA::NodeTrackerManipulator();

	manipulator->setTrackerMode( osgGA::NodeTrackerManipulator::NODE_CENTER_AND_ROTATION );
	manipulator->setRotationMode( osgGA::NodeTrackerManipulator::ELEVATION_AZIM );
	manipulator->setMinimumDistance ( 0.0001 );
	manipulator->setHomePosition( osg::Vec3(0,-1,0), osg::Vec3(0,0,0), osg::Vec3(0,0,1), false );
	
	manipulator->setTrackNode(n->getAttachmentNode());
	viewer->setCameraManipulator(manipulator);

	return 1;
}



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

	std::string id = "defaultUser";


	// *************************************************************************

	// get arguments:
	osg::ArgumentParser arguments(&argc,argv);

	// set up the usage document, which a user can acess with -h or --help
	arguments.getApplicationUsage()->setDescription(arguments.getApplicationName()+" is a panoscope viewer for VESS.");
	arguments.getApplicationUsage()->setCommandLineUsage(arguments.getApplicationName()+" [options]");
	arguments.getApplicationUsage()->addCommandLineOption("-h or --help", "Display this information");

	arguments.getApplicationUsage()->addCommandLineOption("-id <uniqueID>", "Specify an ID for this viewer (Default: '" + vess->id + "')");	
	
	arguments.getApplicationUsage()->addCommandLineOption("-vessID <uniqueID>", "Specify the VESS scene ID to listen to (Default: '" + vess->id + "')");
	arguments.getApplicationUsage()->addCommandLineOption("-vessAddr <addr>", "Set the receiving address for incoming OSC messages (Default: " + vess->rxAddr + ")");
	arguments.getApplicationUsage()->addCommandLineOption("-vessPort <port>", "Set the receiving port for incoming OSC messages (Default: " + vess->rxPort + ")");


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
	osg::ArgumentParser::Parameter param_vessID(vess->id);
	arguments.read("-vessID", param_vessID);
	osg::ArgumentParser::Parameter param_vessAddr(vess->rxAddr);
	arguments.read("-vessAddr", param_vessAddr);
	osg::ArgumentParser::Parameter param_vessPort(vess->rxPort);
	arguments.read("-vessPort", param_vessPort);



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

	osgGA::TrackballManipulator *manipulator = new osgGA::TrackballManipulator();
	manipulator->setMinimumDistance ( 0.0001 );
	manipulator->setHomePosition( osg::Vec3(0,-1,0), osg::Vec3(0,0,0), osg::Vec3(0,0,1), false );
	
	viewer.setCameraManipulator(manipulator);
	
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


	// Add a userNode to the local scene and use it to feed a NodeTracker for
	// the viewer's camera. We expect that this node will be created in VESS and
	// that updates will be generated
	
	/*
	std::string OSCpath = "/vess/" + vess->id;
	
	lo_message msg;
	msg = lo_message_new();
	lo_message_add(msg, "ss", "createNode", "user1", "userNode");
    vess->sendMessage(OSCpath.c_str(), msg);
	 */
	
    std::string oscPattern = "/vess/" + vess->id + "/" + std::string(id);
    lo_server_thread_add_method(vess->sceneManager->rxServ, oscPattern.c_str(), NULL, panoViewer_liblo_callback, (void*)&viewer);

    
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
