#include <string>
#include <iostream>

#include <osgViewer/Viewer>
#include <osgViewer/ViewerEventHandlers>
#include <osgGA/TrackballManipulator>
#include <osgGA/NodeTrackerManipulator>
#include <osgGA/StateSetManipulator>

#include <osgDB/ReadFile>
#include <osg/Timer>

#include <osg/Fog>
#include <osgParticle/PrecipitationEffect>


#include <spin/viewermanipulator.h>
#include <spin/spinapp.h>
#include <spin/spinclientcontext.h>
#include <spin/spinutil.h>
#include <spin/scenemanager.h>

#include "panoViewer.h"

extern pthread_mutex_t sceneMutex;


// *****************************************************************************
// *****************************************************************************
// *****************************************************************************
int main(int argc, char **argv)
{

	spin::spinClientContext spinListener;
	spin::spinApp &spin = spin::spinApp::Instance();

    bool hideCursor=false;
    double maxFrameRate = 60;
    unsigned int screenNum = 0;
    bool fullscreen = false;

	std::string userID;
    std::string sceneID = spin.getSceneID();

    bool fog = false;
    bool snow = false;

	// *************************************************************************

	// get arguments:
	osg::ArgumentParser arguments(&argc,argv);

	// set up the usage document, which a user can acess with -h or --help
	arguments.getApplicationUsage()->setDescription(arguments.getApplicationName()+" is a panoscope viewer for the SPIN Framework.");
	arguments.getApplicationUsage()->setCommandLineUsage(arguments.getApplicationName()+" [options]");
	
    spinListener.addCommandLineOptions(&arguments);

	arguments.getApplicationUsage()->addCommandLineOption("--user-id <uniqueID>", "Specify an ID for this viewer (Default is the localhost name)");
    arguments.getApplicationUsage()->addCommandLineOption("--hide-cursor", "Hide the mouse cursor");
	arguments.getApplicationUsage()->addCommandLineOption("--framerate <num>", "Set the maximum framerate (Default: not limited)");
	arguments.getApplicationUsage()->addCommandLineOption("--fullscreen", "Enable fullscreen");


	// *************************************************************************
	// PARSE ARGS:


    if (!spinListener.parseCommandLineOptions(&arguments))
        return 0;
    
    osg::ArgumentParser::Parameter param_userID(userID);
    arguments.read("--user-id", param_userID);
    if (not userID.empty())
        spin.setUserID(userID);


    while (arguments.read("--hide-cursor")) hideCursor=true;
	while (arguments.read("--framerate",maxFrameRate)) {}
	while (arguments.read("--screen",screenNum)) {}
    while (arguments.read("--fullscreen")) fullscreen=true;
    
    while (arguments.read("--fog")) fog=true;
    while (arguments.read("--snow")) snow=true;

	// *************************************************************************

	// For testing purposes, we allow loading a scene with a commandline arg:
	osg::ref_ptr<osg::Node> argScene = osgDB::readNodeFiles(arguments);


	// *************************************************************************
	// construct the viewer:
	// (note, this constructor gets rid of some additional args)

	osgPano::panoViewer viewer = osgPano::panoViewer(arguments);
	//osgViewer::Viewer viewer = osgViewer::Viewer(arguments);

	//viewer.setThreadingModel(osgViewer::Viewer::SingleThreaded);
	//viewer.setThreadingModel(osgViewer::Viewer::CullDrawThreadPerContext);
	viewer.setThreadingModel(osgViewer::Viewer::CullThreadPerCameraDrawThreadPerContext);


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
	
	spin.sceneManager_->setGraphical(true);
	
	

	// *************************************************************************
	// set up any initial scene elements:

	if (argScene.valid()) {
		std::cout << "Loading sample model" << std::endl;
		spin.sceneManager_->worldNode->addChild(argScene.get());
	}



	// *************************************************************************
	// set up viewer:

	viewer.setSceneData(spin.sceneManager_->rootNode.get());
	viewer.setupViewForPanoscope(screenNum, fullscreen);
    viewer.setNearFar(0.001,1000);

    //viewer.setClearColor(osg::Vec4(1.0,1.0,1.0,0.0));
    viewer.setClearColor(osg::Vec4(0.0,0.0,0.0,0.0));
    //viewer.setClearColor(osg::Vec4(0.8,0.8,0.8,0.0));

	
	
	osgViewer::ViewerBase::Windows windows;
    osgViewer::ViewerBase::Windows::iterator wIter;
    viewer.getWindows(windows);
    for (wIter=windows.begin(); wIter!=windows.end(); wIter++)
    {
        (*wIter)->setWindowName("panoviewer " + spin.getUserID() + "@" + spin.getSceneID());
		if (hideCursor) (*wIter)->useCursor(false);
    }


    // *************************************************************************
    // SNOW & FOG

    if (snow)
    {
        osg::ref_ptr<osgParticle::PrecipitationEffect> precipitationEffect = new osgParticle::PrecipitationEffect;

	    // initializes a bunch of parameters
        precipitationEffect->setParticleSize(0.02);

	    // override some specific params:
	
        precipitationEffect->setMaximumParticleDensity(1000);
        precipitationEffect->setParticleColor(osg::Vec4(1.0,1.0,1.0,1.0));
	    //precipitationEffect->setWind(osg::Vec3(-0.5,0.0,0.0));

        precipitationEffect->setParticleSpeed(0.25);

	    // near/far clipping
	    //precipitationEffect->setNearTransition(0);
        precipitationEffect->setFarTransition(10);
	
        precipitationEffect->getFog()->setDensity(0.005);
        //precipitationEffect->getFog()->setColor(osg::Vec4(0.3,0.3,0.325,0.5));
        //precipitationEffect->getFog()->setColor(osg::Vec4(1.0,1.0,1.0,0.0));
        precipitationEffect->getFog()->setColor(osg::Vec4(0.8,0.8,0.8,0.0));

	    // volume (world coords); particle system repeats in tiled volumetric cells
        //precipitationEffect->setCellSize(osg::Vec3(5,5,5));

	
        spin.sceneManager_->rootNode->addChild(precipitationEffect.get());
        spin.sceneManager_->rootNode->getOrCreateStateSet()->setAttributeAndModes(precipitationEffect->getFog());
    }

	if (fog)
	{
  	    float fog_density = 0.005;
        //osg::Vec4d fog_colour = osg::Vec4(0.5, 0.5, 0.5, 0.0);
        osg::Vec4d fog_colour = osg::Vec4(1.0,1.0,1.0,0.0);
	
        osg::Fog* fog = new osg::Fog();
        fog->setMode(osg::Fog::EXP);
        fog->setColor(fog_colour);
	    fog->setStart(-100.f);
        fog->setDensity(fog_density);

	    osg::StateSet *worldStateSet = spin.sceneManager_->worldNode->getOrCreateStateSet();
	    worldStateSet->setMode(GL_FOG, osg::StateAttribute::ON);
        worldStateSet->setAttribute(fog,osg::StateAttribute::ON);
	}
	

	// *************************************************************************
	// create a camera manipulator

	osg::ref_ptr<spin::ViewerManipulator> manipulator = new spin::ViewerManipulator();
	manipulator->setPicker(false);
	manipulator->setMover(true);
	viewer.setCameraManipulator(manipulator.get());


	
    // *************************************************************************
    // start threads:
	viewer.realize();

    // Try to subscribe with the current (default or manually specified) TCP
    // subscription information. 
    spinListener.subscribe();

	// ask for refresh:
	spin.SceneMessage("s", "refresh", LO_ARGS_END);


	osg::Timer_t lastFrameTick = osg::Timer::instance()->tick();

	double minFrameTime = 1.0 / maxFrameRate;
	
	std::cout << std::endl <<"STARTING panoViewer..." << std::endl;
	
    // program loop:
	while( !viewer.done() )
	{
		
		if (spinListener.isRunning())
		{
/*
            pthread_mutex_lock(&sceneMutex);
			viewer.frame();
			pthread_mutex_unlock(&sceneMutex);
*/


	    
			//OpenThreads::Thread::microSleep(5);
            	
            
			double dt = osg::Timer::instance()->delta_s(lastFrameTick, osg::Timer::instance()->tick());

			if (dt > minFrameTime)
			{
                /*
				pthread_mutex_lock(&sceneMutex);
				viewer.frame();
				pthread_mutex_unlock(&sceneMutex);
			    */

                viewer.advance();
			    viewer.eventTraversal();
			    pthread_mutex_lock(&sceneMutex);
			    spin.sceneManager_->update();
                viewer.updateTraversal();
			    viewer.renderingTraversals();
			    pthread_mutex_unlock(&sceneMutex);

				// save time when the last time a frame was rendered:
				lastFrameTick = osg::Timer::instance()->tick();
				dt = 0;
			}

			unsigned int sleepTime;

			if (!recv) sleepTime = static_cast<unsigned int>(1000000.0*(minFrameTime-dt));
			else sleepTime = 0;
            if (sleepTime > 100) sleepTime = 100;

            // only sleep if there weren't any messages 
			if (!recv) OpenThreads::Thread::microSleep(sleepTime);
			

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
