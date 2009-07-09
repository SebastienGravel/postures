/*
 *  panoViewer.h
 *  Panoscope
 *
 *  Created by Gideon May on 12-10-07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef PANOVIEWER
#define PANOVIEWER 1

#include <osg/ArgumentParser>
#include <osgGA/EventVisitor>
#include <osgUtil/UpdateVisitor>

#include <osgViewer/GraphicsWindow>
#include <osgViewer/View>
#include <osgViewer/Viewer>

class panoViewer : public osgViewer::Viewer
{
public:
    panoViewer();
    panoViewer(osg::ArgumentParser& arguments);
    void setupViewForPanoscope();
    
    virtual void requestRedraw();
    virtual void requestContinuousUpdate(bool needed=true);
    virtual void requestWarpPointer(float x,float y);
};


#endif
