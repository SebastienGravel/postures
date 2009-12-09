/*
 *  panoViewer.cpp
 *  Panoscope
 *
 *  Created by Gideon May on 12-10-07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */


#include <stdio.h>
#include <iostream>

#include <osg/DeleteHandler>
#include <osg/io_utils>

#include <osgUtil/GLObjectsVisitor>
#include <osgDB/Registry>
#include <osgDB/ReadFile>
#include <osgGA/TrackballManipulator>

#include <osgViewer/Viewer>
#include <osgViewer/Renderer>
#include <osgViewer/CompositeViewer>

#include <osgViewer/Renderer>
#include <osgViewer/View>
#include <osgViewer/GraphicsWindow>

#include <osg/io_utils>

#include <osg/TextureCubeMap>
#include <osg/TextureRectangle>
#include <osg/TexMat>

#include <osgUtil/Optimizer>
#include <osgUtil/IntersectionVisitor>

#include <sstream>


#include "panoViewer.h"

#define TEXTURE_SIZE    1024


panoViewer::panoViewer()
{
    
}

panoViewer::panoViewer(osg::ArgumentParser& arguments): osgViewer::Viewer(arguments)
{
    
    
}

static osg::Geometry* create3DSphericalDisplayDistortionMesh(const osg::Vec3& origin, const osg::Vec3& widthVector, const osg::Vec3& heightVector, double sphere_radius, double collar_radius)
{
    osg::Vec3d center(0.0,0.0,0.0);
    osg::Vec3d eye(0.0,0.0,0.0);
    
    double distance = sqrt(sphere_radius*sphere_radius - collar_radius*collar_radius);
    
    bool centerProjection = false;

    osg::Vec3d projector = eye - osg::Vec3d(0.0,0.0, distance);
    
    projector = osg::Vec3d(0.0, 0.0, -2.5);
    
    osg::notify(osg::INFO)<<"create3DSphericalDisplayDistortionMesh : Projector position = "<<projector<<std::endl;
    osg::notify(osg::INFO)<<"create3DSphericalDisplayDistortionMesh : distance = "<<distance<<std::endl;


    // create the quad to visualize.
    osg::Geometry* geometry = new osg::Geometry();

    geometry->setSupportsDisplayList(false);

    osg::Vec3 xAxis(widthVector);
    float width = widthVector.length();
    xAxis /= width;

    osg::Vec3 yAxis(heightVector);
    float height = heightVector.length();
    yAxis /= height;
    
    int noSteps = 50;

    osg::Vec3Array* vertices = new osg::Vec3Array;
    osg::Vec3Array* texcoords0 = new osg::Vec3Array;
    osg::Vec2Array* texcoords1 = new osg::Vec2Array;
    osg::Vec4Array* colors = new osg::Vec4Array;

    osg::Vec3 bottom = origin;
    osg::Vec3 dx = xAxis*(width/((float)(noSteps-1)));
    osg::Vec3 dy = yAxis*(height/((float)(noSteps-1)));
    
    osg::Vec3d screenCenter = origin + widthVector*0.5f + heightVector*0.5f;
//    float screenRadius = heightVector.length() * 0.5f;
    float screenRadius = heightVector.length() * 0.75f;

    osg::Vec3 cursor = bottom;
    int i,j;
    
    
    if (centerProjection)
    {
        for(i=0;i<noSteps;++i)
        {
            osg::Vec3 cursor = bottom+dy*(float)i;
            for(j=0;j<noSteps;++j)
            {
                osg::Vec2 delta(cursor.x() - screenCenter.x(), cursor.y() - screenCenter.y());
                double theta = atan2(-delta.y(), delta.x());
                double phi = osg::PI_2 * delta.length() / screenRadius;
                if (phi > osg::PI_2) phi = osg::PI_2;

                phi *= 2.0;
                
                if (theta<0.0) theta += 2.0*osg::PI;

                // osg::notify(osg::NOTICE)<<"theta = "<<theta<< "phi="<<phi<<std::endl;

                osg::Vec3 texcoord(sin(phi) * cos(theta),
                                   sin(phi) * sin(theta),
                                   cos(phi));

                vertices->push_back(cursor);
                colors->push_back(osg::Vec4(1.0f,1.0f,1.0f,1.0f));
                texcoords0->push_back(texcoord);
                texcoords1->push_back( osg::Vec2(theta/(2.0*osg::PI), 1.0f - phi/osg::PI_2) );

                cursor += dx;
            }
            // osg::notify(osg::NOTICE)<<std::endl;
        }
    }
    else
    {
        for(i=0;i<noSteps;++i)
        {
            osg::Vec3 cursor = bottom+dy*(float)i;
            for(j=0;j<noSteps;++j)
            {
                osg::Vec2 delta(cursor.x() - screenCenter.x(), cursor.y() - screenCenter.y());
                double theta = atan2(-delta.y(), delta.x());
                double phi = osg::PI_2 * delta.length() / screenRadius;
                if (phi > osg::PI_2) phi = osg::PI_2;
                if (theta<0.0) theta += 2.0*osg::PI;

                // osg::notify(osg::NOTICE)<<"theta = "<<theta<< "phi="<<phi<<std::endl;
                
                double f = distance * sin(phi);
                double e = distance * cos(phi) + sqrt( sphere_radius*sphere_radius - f*f);
                double l = e * cos(phi);
                double h = e * sin(phi);
                double z = l - distance;
                
                osg::Vec3 texcoord(h * cos(theta) / sphere_radius,
                                   h * sin(theta) / sphere_radius,
                                   z / sphere_radius);

                vertices->push_back(cursor);
                colors->push_back(osg::Vec4(1.0f,1.0f,1.0f,1.0f));
                texcoords0->push_back(texcoord);
                texcoords1->push_back( osg::Vec2(theta/(2.0*osg::PI), 1.0f - phi/osg::PI_2) );

                cursor += dx;
            }
            // osg::notify(osg::NOTICE)<<std::endl;
        }
    }
    
    // pass the created vertex array to the points geometry object.
    geometry->setVertexArray(vertices);

    geometry->setColorArray(colors);
    geometry->setColorBinding(osg::Geometry::BIND_PER_VERTEX);

    geometry->setTexCoordArray(0,texcoords0);
    geometry->setTexCoordArray(1,texcoords1);

    for(i=0;i<noSteps-1;++i)
    {
        osg::DrawElementsUShort* elements = new osg::DrawElementsUShort(osg::PrimitiveSet::QUAD_STRIP);
        for(j=0;j<noSteps;++j)
        {
            elements->push_back(j+(i+1)*noSteps);
            elements->push_back(j+(i)*noSteps);
        }
        geometry->addPrimitiveSet(elements);
    }
    
    return geometry;
}

/*
 *
 *
 *
 */

void panoViewer::setupViewForPanoscope()
{
    double radius = 1.8;
    double collar = -0.4;
    unsigned int screenNum = 0;
    osg::Image * intensityMap = NULL;
    
    osg::notify(osg::INFO)<<"View::setUpViewFor3DSphericalDisplay(rad="<<radius<<", cllr="<<collar<<", sn="<<screenNum<<", im="<<intensityMap<<")"<<std::endl;
    osg::GraphicsContext::WindowingSystemInterface* wsi = osg::GraphicsContext::getWindowingSystemInterface();
    if (!wsi) 
    {
        osg::notify(osg::NOTICE)<<"Error, no WindowSystemInterface available, cannot create windows."<<std::endl;
        return;
    }


    osg::GraphicsContext::ScreenIdentifier si;
    si.readDISPLAY();
    
    // displayNum has not been set so reset it to 0.
    if (si.displayNum<0) si.displayNum = 0;

    si.screenNum = screenNum;

    unsigned int width, height;
    wsi->getScreenResolution(si, width, height);


    osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits;
    traits->hostName = si.hostName;
    traits->displayNum = si.displayNum;
    traits->screenNum = si.screenNum;
    traits->x = 0;
    traits->y = 0;
    traits->width = width;
    traits->height = height;
    traits->windowDecoration = false;
    traits->doubleBuffer = true;
    traits->sharedContext = 0;
    

    osg::ref_ptr<osg::GraphicsContext> gc = osg::GraphicsContext::createGraphicsContext(traits.get());
    if (!gc)
    {
        osg::notify(osg::NOTICE)<<"GraphicsWindow has not been created successfully."<<std::endl;
        return;
    }

    int tex_width = TEXTURE_SIZE;
    int tex_height = TEXTURE_SIZE;

    int camera_width = tex_width;
    int camera_height = tex_height;

    osg::TextureCubeMap* texture = new osg::TextureCubeMap;

    texture->setTextureSize(tex_width, tex_height);
    texture->setInternalFormat(GL_RGB);
    texture->setFilter(osg::Texture::MIN_FILTER,osg::Texture::LINEAR);
    texture->setFilter(osg::Texture::MAG_FILTER,osg::Texture::LINEAR);
    
#if 0    
    osg::Camera::RenderTargetImplementation renderTargetImplementation = osg::Camera::SEPERATE_WINDOW;
    GLenum buffer = GL_FRONT;
#else
    osg::Camera::RenderTargetImplementation renderTargetImplementation = osg::Camera::FRAME_BUFFER_OBJECT;
    GLenum buffer = GL_FRONT;
#endif

    // front face
    {
        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setName("Front face camera");
        camera->setGraphicsContext(gc.get());
        camera->setViewport(new osg::Viewport(0,0,camera_width, camera_height));
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setAllowEventFocus(false);
        // tell the camera to use OpenGL frame buffer object where supported.
        camera->setRenderTargetImplementation(renderTargetImplementation);

        // attach the texture and use it as the color buffer.
        camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::POSITIVE_Y);

        // addSlave(camera.get(), osg::Matrixd(), osg::Matrixd());
        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(180.0f), 1.0,0.0,0.0));
    }

    // back face
    {
        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setName("Back face camera");
        camera->setGraphicsContext(gc.get());
        camera->setViewport(new osg::Viewport(0,0,camera_width, camera_height));
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setAllowEventFocus(false);
        
        // tell the camera to use OpenGL frame buffer object where supported.
        camera->setRenderTargetImplementation(renderTargetImplementation);
        
        // attach the texture and use it as the color buffer.
        camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::NEGATIVE_Y);
        
        // addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(180.0f), 1.0,0.0,0.0));
        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd());
    }
    
    // top face
    {
        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setName("Top face camera");
        camera->setGraphicsContext(gc.get());
        camera->setViewport(new osg::Viewport(0,0,camera_width, camera_height));
        GLenum buffer = traits->doubleBuffer ? GL_BACK : GL_FRONT;
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setAllowEventFocus(false);

        // tell the camera to use OpenGL frame buffer object where supported.
        camera->setRenderTargetImplementation(renderTargetImplementation);

        // attach the texture and use it as the color buffer.
        camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::POSITIVE_Z);
        // camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::NEGATIVE_Z);

        // addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(-90.0f), 1.0,0.0,0.0));
        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(90.0f), 1.0,0.0,0.0));
    }
    
    // bottom face
    {
        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setGraphicsContext(gc.get());
        camera->setName("Bottom face camera");
        camera->setViewport(new osg::Viewport(0,0,camera_width, camera_height));
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setAllowEventFocus(false);
        
        // tell the camera to use OpenGL frame buffer object where supported.
        camera->setRenderTargetImplementation(renderTargetImplementation);
        
        // attach the texture and use it as the color buffer.
        camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::NEGATIVE_Z);
        // camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::POSITIVE_Z);
        
        // addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(90.0f), 1.0,0.0,0.0) * osg::Matrixd::rotate(osg::inDegrees(180.0f), 0.0,0.0,1.0));
        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(-90.0f), 1.0,0.0,0.0) * osg::Matrixd::rotate(osg::inDegrees(180.0f), 0.0,0.0,1.0));
    }
    
    
    // left face
    {
        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setName("Left face camera");
        camera->setGraphicsContext(gc.get());
        camera->setViewport(new osg::Viewport(0,0,camera_width, camera_height));
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setAllowEventFocus(false);

        // tell the camera to use OpenGL frame buffer object where supported.
        camera->setRenderTargetImplementation(renderTargetImplementation);

        // attach the texture and use it as the color buffer.
        camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::NEGATIVE_X);
        // camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::POSITIVE_X);

        // addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(-90.0f), 0.0,1.0,0.0) * osg::Matrixd::rotate(osg::inDegrees(-90.0f), 0.0,0.0,1.0));
        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(-90.0f), 0.0,1.0,0.0) * osg::Matrixd::rotate(osg::inDegrees(90.0f), 0.0,0.0,1.0));
    }

    // right face
    {
        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setName("Right face camera");
        camera->setGraphicsContext(gc.get());
        camera->setViewport(new osg::Viewport(0,0,camera_width, camera_height));
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setAllowEventFocus(false);

        // tell the camera to use OpenGL frame buffer object where supported.
        camera->setRenderTargetImplementation(renderTargetImplementation);

        // attach the texture and use it as the color buffer.
        camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::POSITIVE_X);
        // camera->attach(osg::Camera::COLOR_BUFFER, texture, 0, osg::TextureCubeMap::NEGATIVE_X);

        // addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(90.0f), 0.0,1.0,0.0 ) * osg::Matrixd::rotate(osg::inDegrees(90.0f), 0.0,0.0,1.0));
        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd::rotate(osg::inDegrees(90.0f), 0.0,1.0,0.0 ) * osg::Matrixd::rotate(osg::inDegrees(-90.0f), 0.0,0.0,1.0));
    }


    
    getCamera()->setProjectionMatrixAsPerspective(90.0f, 1.0, 1, 1000.0);

    // distortion correction set up.
    {
        osg::Geode* geode = new osg::Geode();
        geode->addDrawable(create3DSphericalDisplayDistortionMesh(osg::Vec3(0.0f,0.0f,0.0f), osg::Vec3(width,0.0f,0.0f), osg::Vec3(0.0f,height,0.0f), radius, collar));

        // new we need to add the texture to the mesh, we do so by creating a 
        // StateSet to contain the Texture StateAttribute.
        osg::StateSet* stateset = geode->getOrCreateStateSet();
        stateset->setTextureAttributeAndModes(0, texture,osg::StateAttribute::ON);
        stateset->setMode(GL_LIGHTING,osg::StateAttribute::OFF);

        if (intensityMap)
        {
            stateset->setTextureAttributeAndModes(1, new osg::Texture2D(intensityMap), osg::StateAttribute::ON);
        }
        
        int stretch_x = width * 4 / 3 - width;

        osg::ref_ptr<osg::Camera> camera = new osg::Camera;
        camera->setGraphicsContext(gc.get());
        camera->setClearMask(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
        camera->setClearColor( osg::Vec4(0.1,0.1,1.0,1.0) );
        camera->setViewport(new osg::Viewport(-stretch_x / 2, 0, width + stretch_x, height));
        GLenum buffer = traits->doubleBuffer ? GL_BACK : GL_FRONT;
        camera->setDrawBuffer(buffer);
        camera->setReadBuffer(buffer);
        camera->setReferenceFrame(osg::Camera::ABSOLUTE_RF);
        camera->setAllowEventFocus(false);
        //camera->setInheritanceMask(camera->getInheritanceMask() & ~osg::CullSettings::CLEAR_COLOR & ~osg::CullSettings::COMPUTE_NEAR_FAR_MODE);
        //camera->setComputeNearFarMode(osg::CullSettings::DO_NOT_COMPUTE_NEAR_FAR);
        
        camera->setProjectionMatrixAsOrtho2D(0,width,0,height);
        camera->setViewMatrix(osg::Matrix::identity());

        // add subgraph to render
        camera->addChild(geode);
        
        camera->setName("DistortionCorrectionCamera");

        addSlave(camera.get(), osg::Matrixd(), osg::Matrixd(), false);
    }

	//getCamera()->setComputeNearFarMode(osg::CullSettings::DO_NOT_COMPUTE_NEAR_FAR);
    getCamera()->setNearFarRatio(0.0001f);
    
    if (getLightingMode()==osg::View::HEADLIGHT)
    {
        // set a local light source for headlight to ensure that lighting is consistent across sides of cube.
        getLight()->setPosition(osg::Vec4(0.0f,0.0f,0.0f,1.0f));
    }
}

void panoViewer::requestRedraw()
{
}

void panoViewer::requestContinuousUpdate(bool)
{
}

void panoViewer::requestWarpPointer(float x,float y)
{
    osg::notify(osg::INFO)<<"View::requestWarpPointer("<<x<<","<<y<<")"<<std::endl;
    
    float local_x, local_y;
    const osg::Camera* camera = getCameraContainingPosition(x, y, local_x, local_y);
    if (camera)
    {
        const osgViewer::GraphicsWindow* gw = dynamic_cast<const osgViewer::GraphicsWindow*>(camera->getGraphicsContext());
        if (gw)
        {
            getEventQueue()->mouseWarped(x,y);
            if (gw->getEventQueue()->getCurrentEventState()->getMouseYOrientation()==osgGA::GUIEventAdapter::Y_INCREASING_DOWNWARDS)
            {
                local_y = gw->getTraits()->height - local_y;
            }
            const_cast<osgViewer::GraphicsWindow*>(gw)->getEventQueue()->mouseWarped(local_x,local_y);
            const_cast<osgViewer::GraphicsWindow*>(gw)->requestWarpPointer(local_x, local_y);
        }
    }
    else
    {
        osg::notify(osg::INFO)<<"View::requestWarpPointer failed no camera containing pointer"<<std::endl;
    }
}



