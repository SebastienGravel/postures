#include <string>
#include <iostream>

#include <osgViewer/Viewer>
#include <osgViewer/ViewerEventHandlers>
#include <osgGA/TrackballManipulator>
#include <osgGA/NodeTrackerManipulator>
#include <osgGA/StateSetManipulator>

#include <osgDB/ReadFile>
#include <osg/Timer>


#include "spinUtil.h"
#include "spinContext.h"
#include "panoViewer.h"
#include "osgUtil.h"

using namespace std;

extern pthread_mutex_t pthreadLock;


// global:
// we store userNode in a global ref_ptr so that it can't be deleted
static osg::ref_ptr<ReferencedNode> userNode;




void registerUser(spinContext *spin)
{
	if (!userNode.valid())
	{
        std::cout << "ERROR: could not register user" << std::endl;
        exit(1);
	}
	
	
	// Send a message to the server to create this node (assumes that the server
	// is running). If not, it will send a 'userRefresh' method upon startup
	// that will request that this function is called again
	spin->sendSceneMessage("sss", "createNode", userNode->id->s_name, "UserNode", LO_ARGS_END);

	std::cout << "  Registered user '" << userNode->id->s_name << "' with SPIN" << std::endl;

}

int panoViewer_liblo_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{

    // make sure there is at least one argument (ie, a method):
	if (!argc) return 0;

	spinContext *spin = (spinContext*)user_data;
	if (!spin) return 0;

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

	if (theMethod=="userRefresh")
	{
		registerUser(spin);
	}


	return 1;
}



// *****************************************************************************
// *****************************************************************************
// *****************************************************************************
int main(int argc, char **argv)
{
	std::cout <<"\npanoViewer launching..." << std::endl;

	spinContext *spin = new spinContext();

	std::string id = getHostname();


	// *************************************************************************

	// get arguments:
	osg::ArgumentParser arguments(&argc,argv);

	// set up the usage document, which a user can acess with -h or --help
	arguments.getApplicationUsage()->setDescription(arguments.getApplicationName()+" is a panoscope viewer for the SPIN Framework.");
	arguments.getApplicationUsage()->setCommandLineUsage(arguments.getApplicationName()+" [options]");
	arguments.getApplicationUsage()->addCommandLineOption("-h or --help", "Display this information");

	arguments.getApplicationUsage()->addCommandLineOption("-id <uniqueID>", "Specify an ID for this viewer (Default is hostname: '" + id + "')");

	arguments.getApplicationUsage()->addCommandLineOption("-sceneID <uniqueID>", "Specify the scene ID to listen to (Default: '" + spin->id + "')");
	arguments.getApplicationUsage()->addCommandLineOption("-serverAddr <addr>", "Set the receiving address for incoming OSC messages (Default: " + spin->rxAddr + ")");
	arguments.getApplicationUsage()->addCommandLineOption("-serverPort <port>", "Set the receiving port for incoming OSC messages (Default: " + spin->rxPort + ")");


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
	osg::ArgumentParser::Parameter param_spinID(spin->id);
	arguments.read("-sceneID", param_spinID);
	osg::ArgumentParser::Parameter param_spinAddr(spin->rxAddr);
	arguments.read("-serverAddr", param_spinAddr);
	osg::ArgumentParser::Parameter param_spinPort(spin->rxPort);
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

	if (!spin->start())
	{
        std::cout << "ERROR: could not start SPIN listener thread" << std::endl;
        exit(1);
	}
	
	spin->sceneManager->setGraphical(true);

	// register an extra OSC callback so that we can spy on OSC messages:
	std::string OSCpath = "/SPIN/" + spin->id;
	lo_server_thread_add_method(spin->sceneManager->rxServ, OSCpath.c_str(), NULL, panoViewer_liblo_callback, (void*)spin);

	
	// Add a UserNode to the local scene and use it to feed a NodeTracker for
	// the viewer's camera. We expect that this node will be created in the
	// sceneManager and that updates will be generated. 
	userNode = spin->sceneManager->getOrCreateNode(id.c_str(), "UserNode");
	
	// send userNode info to spin
	registerUser(spin);
	
	

	// *************************************************************************
	// create a camera manipulator

	
	osgGA::TrackballManipulator *manipulator = new osgGA::TrackballManipulator();
	manipulator->setMinimumDistance ( 0.0001 );
	//manipulator->setHomePosition( osg::Vec3(0,0,0), osg::Vec3(0,1,0), osg::Vec3(0,0,1), false );
	manipulator->setHomePosition( osg::Vec3(0,-0.0001,0), osg::Vec3(0,0,0), osg::Vec3(0,0,1), false );

	
	/*
	osgGA::NodeTrackerManipulator *manipulator = new osgGA::NodeTrackerManipulator();
	manipulator->setTrackerMode(  osgGA::NodeTrackerManipulator::NODE_CENTER_AND_ROTATION );
	manipulator->setRotationMode( osgGA::NodeTrackerManipulator::ELEVATION_AZIM );
	manipulator->setMinimumDistance( 0.0001 );
//	manipulator->setHomePosition( osg::Vec3(0,-1,0), osg::Vec3(0,0,0), osg::Vec3(0,0,1), false );
	manipulator->setHomePosition( osg::Vec3(0,-0.0001,0), osg::Vec3(0,0,0), osg::Vec3(0,0,1), false );
//	manipulator->setHomePosition( osg::Vec3(0,1,0), osg::Vec3(0,0,0), osg::Vec3(0,0,1), false );
	manipulator->setTrackNode(userNode->getAttachmentNode());
	*/
	
	viewer.setCameraManipulator(manipulator);

	// *************************************************************************
	// set up any initial scene elements:

	if (argScene.valid()) {
		std::cout << "Loading sample model" << std::endl;
		spin->sceneManager->worldNode->addChild(argScene.get());
	}



	// *************************************************************************
	// start threads:

	viewer.setSceneData(spin->sceneManager->rootNode.get());
	viewer.setupViewForPanoscope();

	viewer.realize();
	
	osg::Timer_t lastTick = osg::Timer::instance()->tick();
	osg::Timer_t frameTick = lastTick;

	// program loop:
	while( !viewer.done() && spin->isRunning() )
	{
		frameTick = osg::Timer::instance()->tick();
		if (osg::Timer::instance()->delta_s(lastTick,frameTick) > 5) // every 5 seconds
		{
			spin->sendInfoMessage("/ping/user", "s", (char*) id.c_str(), LO_ARGS_END);
			lastTick = frameTick;
		}

		// TODO: move this into the callback, and do it only when userNode sends
		// a global6DOF message:
		osg::Matrix m = osg::computeLocalToWorld(userNode->currentNodePath);
		osg::Vec3 rot = QuatToEuler(m.getRotate());
		manipulator->setCenter(m.getTrans());
		manipulator->setRotation(osg::Quat( rot.x()+osg::PI_2,osg::X_AXIS, rot.y(),osg::Y_AXIS, rot.z(),osg::Z_AXIS) );
		
		
		// We now have to go through all the nodes, and check if we need to update the
		// graph. Note: this cannot be done as a callback in a traversal - dangerous.
		// In the callback, we have simply flagged what needs to be done (eg, set the
		// newParent symbol).
		pthread_mutex_lock(&pthreadLock);
		spin->sceneManager->updateGraph();
		pthread_mutex_unlock(&pthreadLock);


		pthread_mutex_lock(&pthreadLock);
		viewer.frame();
		pthread_mutex_unlock(&pthreadLock);
	}


	return 0;
}
