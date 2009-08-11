# First, we must provide the path to SPIN:
export SPIN_PATH = $(HOME)/src/spinframework/trunk
#export SPIN_PATH = $(HOME)/src/spinframework

# the following file must be included:
include $(SPIN_PATH)/Makefile.include

all: $(OS)

Linux: panoViewer
Darwin: panoViewer panoViewer.app


########################################################
## YOU SHOULDN'T NEED TO CHANGE ANYTHING BEYONG HERE! ##
########################################################

vpath %.cpp . $(SPIN_PATH)/src/vess $(SPIN_PATH)/src/tinyxml

SPINOBJS =  vessThreads.o pdUtil.o osgUtil.o asUtil.o libloUtil.o \
	findNodeVisitor.o DebugVisitor.o  \
	tinystr.o tinyxml.o tinyxmlerror.o tinyxmlparser.o \
	asSceneManager.o asMediaManager.o asReferenced.o \
	asBasicNode.o asShape.o asModel.o asVideo.o asLightSource.o \
	asRay.o asContour.o asConstraints.o asRayIntersector.o \
	asPointer.o asMeasurementNode.o asToggle.o userNode.o \
	asDSPnode.o asSoundNode.o asSoundSpace.o asSoundConnection.o

SPIN_FLAGS += -g -O2 -DC_PLUSPLUS -D__cplusplus

SPIN_LIBS += -llo -L$(SPIN_PATH)/src/osgWrappers


###################################################################
# GENERIC COMPILATION RULE

%.o:%.cpp
	@echo "--------------- compiling $@ ---------------" 
	$(CXX) $(OSG_INCLUDE) $(WX_CXXFLAGS) $(SPIN_FLAGS) $(SPIN_INCLUDE) -c $< -o $@

###################################################################
# TARGETS:

panoViewer: $(SPINOBJS) panoViewer.o panoViewerApp.o
	@echo "\n--------------- linking $@: ---------------" 
	$(CXX) -o $@ $^ $(SPIN_LIBS) -lSPIN $(OSG_LIBS)

panoViewer.app: panoViewer
	@echo "\n--------------- building $@: ---------------" 
	-mkdir $@    
	-mkdir $@/Contents
	-mkdir $@/Contents/Frameworks
	-mkdir $@/Contents/libs
	-mkdir $@/Contents/MacOS
	-mkdir $@/Contents/Resources
	-mkdir $@/Contents/Resources/English.lproj
	sed -e "s/IDENTIFIER/`echo ./ | sed -e 's,\.\./,,g' | sed -e 's,/,.,g'`/" \
	-e "s/EXECUTABLE/$</" \
	-e "s/VERSION/0.9/" \
	panoViewer.plist.in >$@/Contents/Info.plist
	echo -n 'APPL????' > $@/Contents/PkgInfo
	cp panoViewer $@/Contents/MacOS
	install_name_tool -change libSPIN.dylib @executable_path/../libs/libSPIN.dylib $@/Contents/MacOS/panoViewer
	cp $(SPIN_PATH)/src/osgWrappers/libSPIN.dylib $@/Contents/libs
	-cp -R /Library/Frameworks/osg* $@/Contents/Frameworks
	-cp -R /Library/Frameworks/OpenThreads.framework $@/Contents/Frameworks
	-cp -R /Library/Application\ Support/OpenSceneGraph/PlugIns $@/Contents
	cp logo_panoViewer.icns $@/Contents/Resources
	$(SPIN_PATH)/src/vess/dylibbundler -of -b -x $@/Contents/MacOS/panoViewer -d $@/Contents/libs

########################################################
install:
	@echo "make install NOT YET DONE. Where do we install to??"


########################################################
clean:
	-rm -f panoViewer *.o
