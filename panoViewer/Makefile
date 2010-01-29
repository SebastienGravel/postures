# First, we must provide the path to SPIN:
export SPIN_PATH = $(HOME)/src/spinframework-0.3.0

# the following file must be included:
include $(SPIN_PATH)/Makefile.include

all: $(OS)

Linux: panoViewer
Darwin: panoViewer 
#Darwin: panoViewer panoViewer.app
apps: panoViewer.app

########################################################
## YOU SHOULDN'T NEED TO CHANGE ANYTHING BEYONG HERE! ##
########################################################

SPIN_FLAGS += -g -O2 -DC_PLUSPLUS -D__cplusplus

DEV_LDFLAGS = -L. -Wl,-rpath,. -L$(SPIN_PATH)/src/osgWrappers -Wl,-rpath,$(SPIN_PATH)/src/spin -Wl,-rpath,$(SPIN_INSTALL_PREFIX)/lib

SPIN_LIBS += -llo -lSPIN

ifdef SHARED_VIDEO_LIB
  SPIN_LIBS += -lshared_video
endif



###################################################################
# GENERIC COMPILATION RULE

%.o:%.cpp
	@echo "--------------- compiling $@ ---------------" 
	$(CXX) $(OSG_INCLUDE) $(SPIN_FLAGS) $(SPIN_INCLUDE) -c $< -o $@

###################################################################
# TARGETS:

panoViewer: panoViewer.o panoViewerApp.o
	@echo "\n--------------- linking $@: ---------------" 
	$(CXX) -o $@ $^ $(SPIN_LIBS) $(OSG_LIBS)

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
	-cp panoViewer ${SPIN_INSTALL_PREFIX}/bin


########################################################
clean:
	-rm -f panoViewer *.o
