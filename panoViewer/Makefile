# First, we must provide the path to SPIN:
export SPIN_PATH = $(HOME)/src/spinframework/trunk

# the following file must be included:
include $(SPIN_PATH)/Makefile.include

# binary name:
APP_NAME = panoViewer


########################################################
## YOU SHOULDN'T NEED TO CHANGE ANYTHING BEYONG HERE! ##
########################################################

all: $(APP_NAME)

vpath %.cpp . $(SPIN_PATH)/src/vess $(SPIN_PATH)/src/tinyxml

SPINOBJS =  vessThreads.o pdUtil.o osgUtil.o asUtil.o libloUtil.o \
	findNodeVisitor.o DebugVisitor.o  \
	tinystr.o tinyxml.o tinyxmlerror.o tinyxmlparser.o \
	asSceneManager.o asMediaManager.o asReferenced.o \
	asBasicNode.o asShape.o asModel.o asVideo.o asLightSource.o \
	asRay.o asContour.o asConstraints.o asRayIntersector.o \
	asPointer.o asMeasurementNode.o asToggle.o userNode.o \
	asDSPnode.o asSoundNode.o asSoundSpace.o asSoundConnection.o

SPIN_FLAGS += -g -O2 -DC_PLUSPLUS -D__cplusplus -DASDEBUG

SPIN_LIBS += -L$(SPIN_PATH)/src/osgWrappers


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


########################################################
install:
	@echo "make install NOT YET DONE. Where do we install to??"


########################################################
clean:
	-rm -f $(APP_NAME) *.o 
