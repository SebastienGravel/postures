ifeq ($(shell uname -s),Darwin)
    OS:=Darwin
else
    OS:=Linux
endif

all: $(OS)

Linux: panoViewer
Darwin: panoViewer 
#Darwin: panoViewer panoViewer.app
apps: panoViewer.app

########################################################
## YOU SHOULDN'T NEED TO CHANGE ANYTHING BEYONG HERE! ##
########################################################




#CPPFLAGS += -g -O2 -DC_PLUSPLUS -D__cplusplus 
CPPFLAGS += -g -I/usr/include/boost $(shell python-config --cflags)
LDFLAGS += -llo -lSPIN 

ifeq ($(shell uname -s),Darwin)
  export MACOSX_DEPLOYMENT_TARGET=10.5
  export SDKROOT=/Developer/SDKs/MacOSX10.5.sdk
  
  CPPFLAGS += -D__USE_OSX_AGL_IMPLEMENTATION__
  FRAMEWORKS = OpenThreads osg osgGA osgSim osgDB \
           osgManipulator osgText osgUtil osgFX osgParticle osgViewer osgIntrospection
  LDFLAGS += -lpthread $(patsubst %,-framework %,$(FRAMEWORKS)) 
  #LDFLAGS += -lpthread \
          -lOpenThreads -losg -losgGA -losgSim -losgDB -losgIntrospection \
          -losgManipulator -losgText -losgUtil -losgFX -losgParticle -losgViewer
  LDFLAGS += -isysroot $(SDKROOT)
  LDFLAGS += -L/usr/local/lib -F/Library/Frameworks -L/opt/local/lib -L$(SDKROOT)/usr/X11R6/lib

else #linux


  LDFLAGS += -lc -lm -ldl -lGL -lX11 -lpthread \
          -lOpenThreads -losg -losgGA -losgSim -losgDB -losgIntrospection \
          -losgManipulator -losgText -losgUtil -losgFX -losgParticle -losgViewer
  LDFLAGS += -L/usr/local/lib/osgPlugins \
          -L/usr/local/lib64\
          -L/usr/local/lib64/osgPlugins \
          -L/usr/X11R6/lib 
endif


###################################################################
# TARGETS:

%.o:%.cpp
	@echo "--------------- compiling $@ ---------------" 
	$(CXX) $(CPPFLAGS) -c $< -o $@

panoViewer: panoViewer.o panoViewerApp.o
	@echo "\n--------------- linking $@: ---------------" 
	$(CXX) -o $@ $^ $(LDFLAGS)

########################################################
install:
	-cp panoViewer /usr/local/bin


########################################################
clean:
	-rm -f panoViewer *.o
