/*
 *  panoViewer.h
 *  Panoscope
 *
 */

#ifndef PANOVIEWER
#define PANOVIEWER 1

#include <osg/ArgumentParser>
#include <osgGA/EventVisitor>
#include <osgUtil/UpdateVisitor>

#include <osgViewer/GraphicsWindow>
#include <osgViewer/View>
#include <vector>

#define TEXTURE_SIZE    1024

typedef std::vector< osg::ref_ptr<osg::Camera> > CameraList;

namespace osgPano {
    class OSG_EXPORT panoViewer : public virtual osgViewer::Viewer
    {
    public:
        panoViewer();
        panoViewer(osg::ArgumentParser& arguments);
        void setupViewForPanoscope(unsigned int screenNum);
        
        /** Set the near and far clipping plane, disables the automatic update of the clipping planes */
        void setNearFar(float near, float far);
       
        void setClearColor(osg::Vec4 v);
 
        virtual void requestRedraw();
        virtual void requestContinuousUpdate(bool needed=true);
        virtual void requestWarpPointer(float x,float y);
    private:
        CameraList _cameras;
    };
    
    
}

#endif
