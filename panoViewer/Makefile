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



DEPS = cppintrospection-3.0
CPPFLAGS += -g -I/usr/include/boost $(shell python-config --cflags) `pkg-config --cflags $(DEPS)`
LDFLAGS += -llo -lSPIN -lboost_python $(shell python-config --libs) `pkg-config --libs $(DEPS)`

ifeq ($(shell uname -s),Darwin)
  #export MACOSX_DEPLOYMENT_TARGET=10.5
  #export SDKROOT=/Developer/SDKs/MacOSX10.5.sdk
  
  CPPFLAGS += -I/opt/local/include
  CPPFLAGS += -D__USE_OSX_AGL_IMPLEMENTATION__
  #FRAMEWORKS = OpenThreads osg osgGA osgSim osgDB \
           osgManipulator osgText osgUtil osgFX osgParticle osgViewer 
  #LDFLAGS += -lpthread $(patsubst %,-framework %,$(FRAMEWORKS)) 
  LDFLAGS += -lpthread \
          -lOpenThreads -losg -losgGA -losgSim -losgDB \
          -losgManipulator -losgText -losgUtil -losgFX -losgParticle -losgViewer
  #LDFLAGS += -isysroot $(SDKROOT)
  #LDFLAGS += -L/usr/local/lib -F/Library/Frameworks -L/opt/local/lib -L$(SDKROOT)/usr/X11R6/lib
  LDFLAGS += -L/usr/local/lib -L/opt/local/lib

else #linux


  LDFLAGS += -lc -lm -ldl -lGL -lX11 -lpthread \
          -lOpenThreads -losg -losgGA -losgSim -losgDB \
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
