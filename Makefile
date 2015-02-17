#
# Tremulous Makefile
#
# Nov '98 by Zoid <zoid@idsoftware.com>
#
# Loki Hacking by Bernd Kreimeier
#  and a little more by Ryan C. Gordon.
#  and a little more by Rafael Barrero
#  and a little more by the ioq3 cr3w
#  and a little more by Tim Angus
#
# GNU Make required
#

COMPILE_PLATFORM=$(shell uname|sed -e s/_.*//|tr '[:upper:]' '[:lower:]')

ifeq ($(COMPILE_PLATFORM),darwin)
  # Apple does some things a little differently...
  COMPILE_ARCH=$(shell uname -p | sed -e s/i.86/x86/)
else
  COMPILE_ARCH=$(shell uname -m | sed -e s/i.86/x86/)
endif

BUILD_GAME_SO    = 0
BUILD_GAME_QVM   = 1
BUILD_PK3S       = 1

#############################################################################
#
# If you require a different configuration from the defaults below, create a
# new file named "Makefile.local" in the same directory as this file and define
# your parameters there. This allows you to change configuration without
# causing problems with keeping up to date with the repository.
#
#############################################################################
-include Makefile.local

ifndef PLATFORM
PLATFORM=$(COMPILE_PLATFORM)
endif
export PLATFORM

ifndef ARCH
ARCH=$(COMPILE_ARCH)
endif

ifeq ($(ARCH),powerpc)
  ARCH=ppc
endif
export ARCH

ifneq ($(PLATFORM),$(COMPILE_PLATFORM))
  CROSS_COMPILING=1
else
  CROSS_COMPILING=0

  ifneq ($(ARCH),$(COMPILE_ARCH))
    CROSS_COMPILING=1
  endif
endif
export CROSS_COMPILING

ifndef COPYDIR
COPYDIR="/usr/local/games/tremulous"
endif

ifndef MOUNT_DIR
MOUNT_DIR=src
endif

ifndef BUILD_DIR
BUILD_DIR=build
endif

ifndef GENERATE_DEPENDENCIES
GENERATE_DEPENDENCIES=1
endif

ifndef USE_CCACHE
USE_CCACHE=0
endif
export USE_CCACHE

ifndef USE_SDL
USE_SDL=1
endif

ifndef USE_OPENAL
USE_OPENAL=1
endif

ifndef USE_OPENAL_DLOPEN
USE_OPENAL_DLOPEN=0
endif

ifndef USE_CURL
USE_CURL=1
endif

ifndef USE_CURL_DLOPEN
  ifeq ($(PLATFORM),mingw32)
    USE_CURL_DLOPEN=0
  else
    USE_CURL_DLOPEN=1
  endif
endif

ifndef USE_CODEC_VORBIS
USE_CODEC_VORBIS=0
endif

ifndef USE_LOCAL_HEADERS
USE_LOCAL_HEADERS=1
endif

ifndef BUILD_MASTER_SERVER
BUILD_MASTER_SERVER=0
endif

#############################################################################

BD=$(BUILD_DIR)/debug-$(PLATFORM)-$(ARCH)
BR=$(BUILD_DIR)/release-$(PLATFORM)-$(ARCH)
MODPATH=zombie
CDIR=$(MOUNT_DIR)/client
SDIR=$(MOUNT_DIR)/server
RDIR=$(MOUNT_DIR)/renderer
CMDIR=$(MOUNT_DIR)/qcommon
UDIR=$(MOUNT_DIR)/unix
W32DIR=$(MOUNT_DIR)/win32
GDIR=$(MOUNT_DIR)/game
CGDIR=$(MOUNT_DIR)/cgame
NDIR=$(MOUNT_DIR)/null
UIDIR=$(MOUNT_DIR)/ui
JPDIR=$(MOUNT_DIR)/jpeg-6
TOOLSDIR=$(MOUNT_DIR)/tools
SDLHDIR=$(MOUNT_DIR)/SDL12
LIBSDIR=$(MOUNT_DIR)/libs
MASTERDIR=$(MOUNT_DIR)/master

# extract version info
VERSION=$(shell grep "\#define VERSION_NUMBER" $(CMDIR)/q_shared.h | \
  sed -e 's/[^"]*"\(.*\)"/\1/')

USE_SVN=
ifeq ($(wildcard .svn),.svn)
  SVN_REV=$(shell LANG=C svnversion .)
  ifneq ($(SVN_REV),)
    SVN_VERSION=$(VERSION)_SVN$(SVN_REV)
    USE_SVN=1
  endif
endif
ifneq ($(USE_SVN),1)
    SVN_VERSION=$(VERSION)
endif


#############################################################################
# SETUP AND BUILD -- LINUX
#############################################################################

## Defaults
LIB=lib

INSTALL=install
MKDIR=mkdir

ifeq ($(PLATFORM),linux)

  ifeq ($(ARCH),alpha)
    ARCH=axp
  else
  ifeq ($(ARCH),x86_64)
    LIB=lib64
  else
  ifeq ($(ARCH),ppc64)
    LIB=lib64
  else
  ifeq ($(ARCH),s390x)
    LIB=lib64
  endif
  endif
  endif
  endif

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes -pipe

  ifeq ($(USE_OPENAL),1)
    BASE_CFLAGS += -DUSE_OPENAL=1
    ifeq ($(USE_OPENAL_DLOPEN),1)
      BASE_CFLAGS += -DUSE_OPENAL_DLOPEN=1
    endif
  endif

  ifeq ($(USE_CURL),1)
    BASE_CFLAGS += -DUSE_CURL=1
    ifeq ($(USE_CURL_DLOPEN),1)
      BASE_CFLAGS += -DUSE_CURL_DLOPEN=1
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    BASE_CFLAGS += -DUSE_CODEC_VORBIS=1
  endif

  ifeq ($(USE_SDL),1)
    BASE_CFLAGS += -DUSE_SDL_VIDEO=1 -DUSE_SDL_SOUND=1 $(shell sdl-config --cflags)
  else
    BASE_CFLAGS += -I/usr/X11R6/include
  endif

  OPTIMIZE = -O3 -funroll-loops -fomit-frame-pointer

  ifeq ($(ARCH),x86_64)
    OPTIMIZE = -O3 -fomit-frame-pointer -funroll-loops \
      -falign-loops=2 -falign-jumps=2 -falign-functions=2 \
      -fstrength-reduce
    # experimental x86_64 jit compiler! you need GNU as
    HAVE_VM_COMPILED = true
  else
  ifeq ($(ARCH),x86)
    OPTIMIZE = -O3 -march=i586 -fomit-frame-pointer \
      -funroll-loops -falign-loops=2 -falign-jumps=2 \
      -falign-functions=2 -fstrength-reduce
    HAVE_VM_COMPILED=true
  else
  ifeq ($(ARCH),ppc)
    BASE_CFLAGS += -maltivec
    HAVE_VM_COMPILED=false
  endif
  endif
  endif

  ifneq ($(HAVE_VM_COMPILED),true)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  DEBUG_CFLAGS = $(BASE_CFLAGS) -g -O0

  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LDFLAGS=-lpthread
  LDFLAGS=-ldl -lm

  ifeq ($(USE_SDL),1)
    CLIENT_LDFLAGS=$(shell sdl-config --libs)
  else
    CLIENT_LDFLAGS=-L/usr/X11R6/$(LIB) -lX11 -lXext -lXxf86dga -lXxf86vm
  endif

  ifeq ($(USE_OPENAL),1)
    ifneq ($(USE_OPENAL_DLOPEN),1)
      CLIENT_LDFLAGS += -lopenal
    endif
  endif
 
  ifeq ($(USE_CURL),1)
    ifneq ($(USE_CURL_DLOPEN),1)
      CLIENT_LDFLAGS += -lcurl
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    CLIENT_LDFLAGS += -lvorbisfile -lvorbis -logg
  endif

  ifeq ($(ARCH),x86)
    # linux32 make ...
    BASE_CFLAGS += -m32
    LDFLAGS+=-m32
  endif

else # ifeq Linux

#############################################################################
# SETUP AND BUILD -- MAC OS X
#############################################################################

ifeq ($(PLATFORM),darwin)
  HAVE_VM_COMPILED=true
  BASE_CFLAGS=
  CLIENT_LDFLAGS=
  LDFLAGS=
  OPTIMIZE=
  ifeq ($(BUILD_MACOSX_UB),ppc)
    CC=gcc-3.3
    BASE_CFLAGS += -arch ppc -DSMP \
      -DMAC_OS_X_VERSION_MIN_REQUIRED=1020 -nostdinc \
      -F/Developer/SDKs/MacOSX10.2.8.sdk/System/Library/Frameworks \
      -I/Developer/SDKs/MacOSX10.2.8.sdk/usr/include/gcc/darwin/3.3 \
      -isystem /Developer/SDKs/MacOSX10.2.8.sdk/usr/include
    # when using the 10.2 SDK we are not allowed the two-level namespace so
    # in order to get the OpenAL dlopen() stuff to work without major
    # modifications, the controversial -m linker flag must be used.  this
    # throws a ton of multiply defined errors which cannot be suppressed.
    LDFLAGS += -arch ppc \
      -L/Developer/SDKs/MacOSX10.2.8.sdk/usr/lib/gcc/darwin/3.3 \
      -F/Developer/SDKs/MacOSX10.2.8.sdk/System/Library/Frameworks \
      -Wl,-syslibroot,/Developer/SDKs/MacOSX10.2.8.sdk,-m
    ARCH=ppc

    # OS X 10.2 sdk lacks dlopen() so ded would need libSDL anyway
    BUILD_SERVER=0

    # because of a problem with linking on 10.2 this will generate multiply
    # defined symbol errors.  The errors can be turned into warnings with
    # the -m linker flag, but you can't shut up the warnings
    USE_OPENAL_DLOPEN=1
  else
  ifeq ($(BUILD_MACOSX_UB),x86)
    CC=gcc-4.0
    BASE_CFLAGS += -arch i386 -DSMP \
      -mmacosx-version-min=10.4 \
      -DMAC_OS_X_VERSION_MIN_REQUIRED=1040 -nostdinc \
      -F/Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks \
      -I/Developer/SDKs/MacOSX10.4u.sdk/usr/lib/gcc/i686-apple-darwin8/4.0.1/include \
      -isystem /Developer/SDKs/MacOSX10.4u.sdk/usr/include
    LDFLAGS = -arch i386 -mmacosx-version-min=10.4 \
      -L/Developer/SDKs/MacOSX10.4u.sdk/usr/lib/gcc/i686-apple-darwin8/4.0.1 \
      -F/Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks \
      -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk
    ARCH=x86
    BUILD_SERVER=0
  else
    # for whatever reason using the headers in the MacOSX SDKs tend to throw
    # errors even though they are identical to the system ones which don't
    # therefore we shut up warning flags when running the universal build
    # script as much as possible.
    BASE_CFLAGS += -Wall -Wimplicit -Wstrict-prototypes
  endif
  endif

  ifeq ($(ARCH),ppc)
    OPTIMIZE += -faltivec -O3
  endif
  ifeq ($(ARCH),x86)
    OPTIMIZE += -march=prescott -mfpmath=sse
    # x86 vm will crash without -mstackrealign since MMX instructions will be
    # used no matter what and they corrupt the frame pointer in VM calls
    BASE_CFLAGS += -mstackrealign
  endif

  BASE_CFLAGS += -fno-strict-aliasing -DMACOS_X -fno-common -pipe

  # Always include debug symbols...you can strip the binary later...
  BASE_CFLAGS += -gfull

  ifeq ($(USE_OPENAL),1)
    BASE_CFLAGS += -DUSE_OPENAL=1
    ifneq ($(USE_OPENAL_DLOPEN),1)
      CLIENT_LDFLAGS += -framework OpenAL
    else
      BASE_CFLAGS += -DUSE_OPENAL_DLOPEN=1
    endif
  endif

  ifeq ($(USE_CURL),1)
    BASE_CFLAGS += -DUSE_CURL=1
    ifneq ($(USE_CURL_DLOPEN),1)
      CLIENT_LDFLAGS += -lcurl
    else
      BASE_CFLAGS += -DUSE_CURL_DLOPEN=1
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    BASE_CFLAGS += -DUSE_CODEC_VORBIS=1
    CLIENT_LDFLAGS += -lvorbisfile -lvorbis -logg
  endif

  ifeq ($(USE_SDL),1)
    BASE_CFLAGS += -DUSE_SDL_VIDEO=1 -DUSE_SDL_SOUND=1 -D_THREAD_SAFE=1 \
      -I$(SDLHDIR)/include
    # We copy sdlmain before ranlib'ing it so that subversion doesn't think
    #  the file has been modified by each build.
    LIBSDLMAIN=$(B)/libSDLmain.a
    LIBSDLMAINSRC=$(LIBSDIR)/macosx/libSDLmain.a
    CLIENT_LDFLAGS += -framework Cocoa -framework IOKit -framework OpenGL \
      $(LIBSDIR)/macosx/libSDL-1.2.0.dylib
  else
    # !!! FIXME: frameworks: OpenGL, Carbon, etc...
    #CLIENT_LDFLAGS += -L/usr/X11R6/$(LIB) -lX11 -lXext -lXxf86dga -lXxf86vm
  endif

  OPTIMIZE += -falign-loops=16

  ifneq ($(HAVE_VM_COMPILED),true)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  DEBUG_CFLAGS = $(BASE_CFLAGS) -g -O0

  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  SHLIBEXT=dylib
  SHLIBCFLAGS=-fPIC -fno-common
  SHLIBLDFLAGS=-dynamiclib $(LDFLAGS)

  NOTSHLIBCFLAGS=-mdynamic-no-pic

else # ifeq darwin


#############################################################################
# SETUP AND BUILD -- MINGW32
#############################################################################

ifeq ($(PLATFORM),mingw32)

ifndef WINDRES
WINDRES=windres
endif

  ARCH=x86

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes

  ifeq ($(USE_OPENAL),1)
    BASE_CFLAGS += -DUSE_OPENAL=1 -DUSE_OPENAL_DLOPEN=1
  endif

  ifeq ($(USE_CURL),1)
    BASE_CFLAGS += -DUSE_CURL=1
    ifneq ($(USE_CURL_DLOPEN),1)
      BASE_CFLAGS += -DCURL_STATICLIB
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    BASE_CFLAGS += -DUSE_CODEC_VORBIS=1
  endif

  OPTIMIZE = -O3 -march=i586 -fomit-frame-pointer -falign-loops=2 \
    -funroll-loops -falign-jumps=2 -falign-functions=2 -fstrength-reduce

  HAVE_VM_COMPILED = true

  DEBUG_CFLAGS=$(BASE_CFLAGS) -g -O0

  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  SHLIBEXT=dll
  SHLIBCFLAGS=
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  BINEXT=.exe

  LDFLAGS= -mwindows -lwsock32 -lgdi32 -lwinmm -lole32
  CLIENT_LDFLAGS=

  ifeq ($(USE_CURL),1)
    ifneq ($(USE_CURL_DLOPEN),1)
      CLIENT_LDFLAGS += $(LIBSDIR)/win32/libcurl.a
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    CLIENT_LDFLAGS += -lvorbisfile -lvorbis -logg
  endif

  ifeq ($(ARCH),x86)
    # build 32bit
    BASE_CFLAGS += -m32
    LDFLAGS+=-m32
  endif

  BUILD_SERVER = 0
  BUILD_CLIENT_SMP = 0

else # ifeq mingw32

#############################################################################
# SETUP AND BUILD -- FREEBSD
#############################################################################

ifeq ($(PLATFORM),freebsd)

  ifneq (,$(findstring alpha,$(shell uname -m)))
    ARCH=axp
  else #default to x86
    ARCH=x86
  endif #alpha test


  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes \
                -I/usr/X11R6/include

  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

  ifeq ($(USE_OPENAL),1)
    BASE_CFLAGS += -DUSE_OPENAL=1
    ifeq ($(USE_OPENAL_DLOPEN),1)
      BASE_CFLAGS += -DUSE_OPENAL_DLOPEN=1
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    BASE_CFLAGS += -DUSE_CODEC_VORBIS=1
  endif

  ifeq ($(USE_SDL),1)
    BASE_CFLAGS += $(shell sdl11-config --cflags) -DUSE_SDL_VIDEO=1 -DUSE_SDL_SOUND=1
  endif

  ifeq ($(ARCH),axp)
    BASE_CFLAGS += -DNO_VM_COMPILED
    RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3 -funroll-loops \
      -fomit-frame-pointer -fexpensive-optimizations
  else
  ifeq ($(ARCH),x86)
    RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3 -mtune=pentiumpro \
      -march=pentium -fomit-frame-pointer -pipe \
      -falign-loops=2 -falign-jumps=2 -falign-functions=2 \
      -funroll-loops -fstrength-reduce
    HAVE_VM_COMPILED=true
  else
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif
  endif

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LDFLAGS=-lpthread
  # don't need -ldl (FreeBSD)
  LDFLAGS=-lm

  CLIENT_LDFLAGS =

  ifeq ($(USE_SDL),1)
    CLIENT_LDFLAGS += $(shell sdl11-config --libs)
  else
    CLIENT_LDFLAGS += -L/usr/X11R6/$(LIB) -lGL -lX11 -lXext -lXxf86dga -lXxf86vm
  endif

  ifeq ($(USE_OPENAL),1)
    ifneq ($(USE_OPENAL_DLOPEN),1)
      CLIENT_LDFLAGS += $(THREAD_LDFLAGS) -lopenal
    endif
  endif

  ifeq ($(USE_CODEC_VORBIS),1)
    CLIENT_LDFLAGS += -lvorbisfile -lvorbis -logg
  endif


else # ifeq freebsd

#############################################################################
# SETUP AND BUILD -- NETBSD
#############################################################################

ifeq ($(PLATFORM),netbsd)

  ifeq ($(shell uname -m),i386)
    ARCH=x86
  endif

  LDFLAGS=-lm
  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)
  THREAD_LDFLAGS=-lpthread

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes
  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

  ifneq ($(ARCH),x86)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  BUILD_CLIENT = 0
  BUILD_GAME_QVM = 0

else # ifeq netbsd

#############################################################################
# SETUP AND BUILD -- IRIX
#############################################################################

ifeq ($(PLATFORM),irix)

  ARCH=mips  #default to MIPS

  BASE_CFLAGS=-Dstricmp=strcasecmp -Xcpluscomm -woff 1185 -mips3 \
    -nostdinc -I. -I$(ROOT)/usr/include -DNO_VM_COMPILED
  RELEASE_CFLAGS=$(BASE_CFLAGS) -O3
  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

  SHLIBEXT=so
  SHLIBCFLAGS=
  SHLIBLDFLAGS=-shared

  LDFLAGS=-ldl -lm
  CLIENT_LDFLAGS=-L/usr/X11/$(LIB) -lGL -lX11 -lXext -lm

else # ifeq IRIX

#############################################################################
# SETUP AND BUILD -- SunOS
#############################################################################

ifeq ($(PLATFORM),sunos)

  CC=gcc
  INSTALL=ginstall
  MKDIR=gmkdir
  COPYDIR="/usr/local/share/games/tremulous"

  ifneq (,$(findstring i86pc,$(shell uname -m)))
    ARCH=x86
  else #default to sparc
    ARCH=sparc
  endif

  ifneq ($(ARCH),x86)
    ifneq ($(ARCH),sparc)
      $(error arch $(ARCH) is currently not supported)
    endif
  endif


  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes -pipe

  ifeq ($(USE_SDL),1)
    BASE_CFLAGS += -DUSE_SDL_SOUND=1 $(shell sdl-config --cflags)
  else
    BASE_CFLAGS += -I/usr/openwin/include
  endif

  OPTIMIZE = -O3 -funroll-loops

  ifeq ($(ARCH),sparc)
    OPTIMIZE = -O3 -falign-loops=2 \
      -falign-jumps=2 -falign-functions=2 -fstrength-reduce \
      -mtune=ultrasparc -mv8plus -mno-faster-structs \
      -funroll-loops
  else
  ifeq ($(ARCH),x86)
    OPTIMIZE = -O3 -march=i586 -fomit-frame-pointer \
      -funroll-loops -falign-loops=2 -falign-jumps=2 \
      -falign-functions=2 -fstrength-reduce
    HAVE_VM_COMPILED=true
    BASE_CFLAGS += -m32
    LDFLAGS += -m32
    BASE_CFLAGS += -I/usr/X11/include/NVIDIA
  endif
  endif

  ifneq ($(HAVE_VM_COMPILED),true)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  DEBUG_CFLAGS = $(BASE_CFLAGS) -ggdb -O0

  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LDFLAGS=-lpthread
  LDFLAGS=-lsocket -lnsl -ldl -lm

  BOTCFLAGS=-O0

  ifeq ($(USE_SDL),1)
    CLIENT_LDFLAGS=$(shell sdl-config --libs) -L/usr/X11/lib -lGLU -lX11 -lXext
  else
    CLIENT_LDFLAGS=-L/usr/openwin/$(LIB) -L/usr/X11/lib -lGLU -lX11 -lXext
  endif

else # ifeq sunos

#############################################################################
# SETUP AND BUILD -- GENERIC
#############################################################################
  BASE_CFLAGS=-DNO_VM_COMPILED
  DEBUG_CFLAGS=$(BASE_CFLAGS) -g
  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared

endif #Linux
endif #darwin
endif #mingw32
endif #FreeBSD
endif #NetBSD
endif #IRIX
endif #SunOS

PK3EXT=pk3
QVMEXT=qvm

TARGETS =

ifneq ($(BUILD_GAME_SO),0)
  TARGETS += \
    $(B)/$(MODPATH)/cgame$(ARCH).$(SHLIBEXT) \
    $(B)/$(MODPATH)/game$(ARCH).$(SHLIBEXT) \
    $(B)/$(MODPATH)/ui$(ARCH).$(SHLIBEXT)
endif

ifneq ($(BUILD_GAME_QVM),0)
  ifneq ($(CROSS_COMPILING),1)
    TARGETS += \
      $(B)/$(MODPATH)/vm/cgame.$(QVMEXT) \
      $(B)/$(MODPATH)/vm/game.$(QVMEXT) \
      $(B)/$(MODPATH)/vm/ui.$(QVMEXT)
  endif
endif

ifneq ($(BUILD_PK3S),0)
  TARGETS += \
    $(B)/$(MODPATH)/zgfx.$(PK3EXT) \
    $(B)/$(MODPATH)/zicons.$(PK3EXT) \
    $(B)/$(MODPATH)/zmodels.$(PK3EXT) \
    $(B)/$(MODPATH)/zoverrides.$(PK3EXT) \
    $(B)/$(MODPATH)/zscripts.$(PK3EXT) \
    $(B)/$(MODPATH)/zsound.$(PK3EXT) \
    $(B)/$(MODPATH)/zui.$(PK3EXT) \
    $(B)/$(MODPATH)/zvms.$(PK3EXT)
endif

ifeq ($(USE_CCACHE),1)
  CC := ccache $(CC)
endif

ifdef DEFAULT_BASEDIR
  BASE_CFLAGS += -DDEFAULT_BASEDIR=\\\"$(DEFAULT_BASEDIR)\\\"
endif

ifeq ($(USE_LOCAL_HEADERS),1)
  BASE_CFLAGS += -DUSE_LOCAL_HEADERS=1
endif

ifeq ($(GENERATE_DEPENDENCIES),1)
  BASE_CFLAGS += -MMD
endif

ifeq ($(USE_SVN),1)
  BASE_CFLAGS += -DSVN_VERSION=\\\"$(SVN_VERSION)\\\"
endif

define DO_CC       
@echo "CC $<"
@$(CC) $(NOTSHLIBCFLAGS) $(CFLAGS) -o $@ -c $<
endef

define DO_SMP_CC
@echo "SMP_CC $<"
@$(CC) $(NOTSHLIBCFLAGS) $(CFLAGS) -DSMP -o $@ -c $<
endef

define DO_BOT_CC
@echo "BOT_CC $<"
@$(CC) $(NOTSHLIBCFLAGS) $(CFLAGS) $(BOTCFLAGS) -DBOTLIB -o $@ -c $<
endef

ifeq ($(GENERATE_DEPENDENCIES),1)
  DO_QVM_DEP=cat $(@:%.o=%.d) | sed -e 's/\.o/\.asm/g' >> $(@:%.o=%.d)
endif

define DO_SHLIB_CC
@echo "SHLIB_CC $<"
@$(CC) $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
@$(DO_QVM_DEP)
endef

define DO_AS
@echo "AS $<"
@$(CC) $(CFLAGS) -DELF -x assembler-with-cpp -o $@ -c $<
endef

define DO_DED_CC
@echo "DED_CC $<"
@$(CC) $(NOTSHLIBCFLAGS) -DDEDICATED $(CFLAGS) -o $@ -c $<
endef

define DO_WINDRES
@echo "WINDRES $<"
@$(WINDRES) -i $< -o $@
endef


#############################################################################
# MAIN TARGETS
#############################################################################

default: release
all: debug release

debug:
	@$(MAKE) targets B=$(BD) CFLAGS="$(CFLAGS) $(DEBUG_CFLAGS)"

release:
	@$(MAKE) targets B=$(BR) CFLAGS="$(CFLAGS) $(RELEASE_CFLAGS)"

# Create the build directories and tools, print out
# an informational message, then start building
targets: makedirs tools
	@echo ""
	@echo "Building Tremulous in $(B):"
	@echo "  CC: $(CC)"
	@echo ""
	@echo "  CFLAGS:"
	@for i in $(CFLAGS); \
	do \
		echo "    $$i"; \
	done
	@echo ""
	@echo "  Output:"
	@for i in $(TARGETS); \
	do \
		echo "    $$i"; \
	done
	@echo ""
	@$(MAKE) $(TARGETS)

makedirs:
	@if [ ! -d $(BUILD_DIR) ];then $(MKDIR) $(BUILD_DIR);fi
	@if [ ! -d $(B) ];then $(MKDIR) $(B);fi
	@if [ ! -d $(B)/$(MODPATH)/ ];then $(MKDIR) $(B)/$(MODPATH)/;fi
	@if [ ! -d $(B)/$(MODPATH)/cgame ];then $(MKDIR) $(B)/$(MODPATH)/cgame;fi
	@if [ ! -d $(B)/$(MODPATH)/game ];then $(MKDIR) $(B)/$(MODPATH)/game;fi
	@if [ ! -d $(B)/$(MODPATH)/ui ];then $(MKDIR) $(B)/$(MODPATH)/ui;fi
	@if [ ! -d $(B)/$(MODPATH)/qcommon ];then $(MKDIR) $(B)/$(MODPATH)/qcommon;fi
	@if [ ! -d $(B)/$(MODPATH)/vm ];then $(MKDIR) $(B)/$(MODPATH)/vm;fi

#############################################################################
# QVM BUILD TOOLS
#############################################################################

Q3LCC=$(TOOLSDIR)/q3lcc$(BINEXT)
Q3ASM=$(TOOLSDIR)/q3asm$(BINEXT)

ifeq ($(CROSS_COMPILING),1)
tools:
	@echo QVM tools not built when cross-compiling
else
tools:
	$(MAKE) -C $(TOOLSDIR)/lcc install
	$(MAKE) -C $(TOOLSDIR)/asm install
endif

define DO_Q3LCC
@echo "Q3LCC $<"
@$(Q3LCC) -o $@ $<
endef

#############################################################################
## TREMULOUS CGAME
#############################################################################

CGOBJ_ = \
  $(B)/$(MODPATH)/cgame/cg_main.o \
  $(B)/$(MODPATH)/game/bg_misc.o \
  $(B)/$(MODPATH)/game/bg_pmove.o \
  $(B)/$(MODPATH)/game/bg_slidemove.o \
  $(B)/$(MODPATH)/cgame/cg_consolecmds.o \
  $(B)/$(MODPATH)/cgame/cg_buildable.o \
  $(B)/$(MODPATH)/cgame/cg_animation.o \
  $(B)/$(MODPATH)/cgame/cg_animmapobj.o \
  $(B)/$(MODPATH)/cgame/cg_draw.o \
  $(B)/$(MODPATH)/cgame/cg_drawtools.o \
  $(B)/$(MODPATH)/cgame/cg_ents.o \
  $(B)/$(MODPATH)/cgame/cg_event.o \
  $(B)/$(MODPATH)/cgame/cg_marks.o \
  $(B)/$(MODPATH)/cgame/cg_players.o \
  $(B)/$(MODPATH)/cgame/cg_playerstate.o \
  $(B)/$(MODPATH)/cgame/cg_predict.o \
  $(B)/$(MODPATH)/cgame/cg_servercmds.o \
  $(B)/$(MODPATH)/cgame/cg_snapshot.o \
  $(B)/$(MODPATH)/cgame/cg_view.o \
  $(B)/$(MODPATH)/cgame/cg_weapons.o \
  $(B)/$(MODPATH)/cgame/cg_mem.o \
  $(B)/$(MODPATH)/cgame/cg_scanner.o \
  $(B)/$(MODPATH)/cgame/cg_attachment.o \
  $(B)/$(MODPATH)/cgame/cg_trails.o \
  $(B)/$(MODPATH)/cgame/cg_particles.o \
  $(B)/$(MODPATH)/cgame/cg_ptr.o \
  $(B)/$(MODPATH)/cgame/cg_tutorial.o \
  $(B)/$(MODPATH)/ui/ui_shared.o \
  \
  $(B)/$(MODPATH)/qcommon/q_math.o \
  $(B)/$(MODPATH)/qcommon/q_shared.o

CGOBJ = $(CGOBJ_) $(B)/$(MODPATH)/cgame/cg_syscalls.o
CGVMOBJ = $(CGOBJ_:%.o=%.asm) $(B)/$(MODPATH)/game/bg_lib.asm

$(B)/$(MODPATH)/cgame$(ARCH).$(SHLIBEXT) : $(CGOBJ)
	@echo "LD $@"
	@$(CC) $(SHLIBLDFLAGS) -o $@ $(CGOBJ)

$(B)/$(MODPATH)/vm/cgame.$(QVMEXT): $(CGVMOBJ) $(CGDIR)/cg_syscalls.asm
	@echo "Q3ASM $@"
	@$(Q3ASM) -o $@ $(CGVMOBJ) $(CGDIR)/cg_syscalls.asm



#############################################################################
## TREMULOUS GAME
#############################################################################

GOBJ_ = \
  $(B)/$(MODPATH)/game/g_main.o \
  $(B)/$(MODPATH)/game/bg_misc.o \
  $(B)/$(MODPATH)/game/bg_pmove.o \
  $(B)/$(MODPATH)/game/bg_slidemove.o \
  $(B)/$(MODPATH)/game/g_mem.o \
  $(B)/$(MODPATH)/game/g_active.o \
  $(B)/$(MODPATH)/game/g_client.o \
  $(B)/$(MODPATH)/game/g_cmds.o \
  $(B)/$(MODPATH)/game/g_combat.o \
  $(B)/$(MODPATH)/game/g_physics.o \
  $(B)/$(MODPATH)/game/g_buildable.o \
  $(B)/$(MODPATH)/game/g_item.o \
  $(B)/$(MODPATH)/game/g_misc.o \
  $(B)/$(MODPATH)/game/g_missile.o \
  $(B)/$(MODPATH)/game/g_mover.o \
  $(B)/$(MODPATH)/game/g_session.o \
  $(B)/$(MODPATH)/game/g_spawn.o \
  $(B)/$(MODPATH)/game/g_svcmds.o \
  $(B)/$(MODPATH)/game/g_target.o \
  $(B)/$(MODPATH)/game/g_team.o \
  $(B)/$(MODPATH)/game/g_trigger.o \
  $(B)/$(MODPATH)/game/g_utils.o \
  $(B)/$(MODPATH)/game/g_maprotation.o \
  $(B)/$(MODPATH)/game/g_ptr.o \
  $(B)/$(MODPATH)/game/g_weapon.o \
  $(B)/$(MODPATH)/game/g_admin.o \
  $(B)/$(MODPATH)/game/g_global.o \
  $(B)/$(MODPATH)/game/g_bot.o \
  $(B)/$(MODPATH)/game/acebot_ai.o \
  $(B)/$(MODPATH)/game/acebot_cmds.o \
  $(B)/$(MODPATH)/game/acebot_items.o \
  $(B)/$(MODPATH)/game/acebot_movement.o \
  $(B)/$(MODPATH)/game/acebot_nodes.o \
  $(B)/$(MODPATH)/game/acebot_spawn.o \
  \
  $(B)/$(MODPATH)/qcommon/q_math.o \
  $(B)/$(MODPATH)/qcommon/q_shared.o

GOBJ = $(GOBJ_) $(B)/$(MODPATH)/game/g_syscalls.o
GVMOBJ = $(GOBJ_:%.o=%.asm) $(B)/$(MODPATH)/game/bg_lib.asm

$(B)/$(MODPATH)/game$(ARCH).$(SHLIBEXT) : $(GOBJ)
	@echo "LD $@"
	@$(CC) $(SHLIBLDFLAGS) -o $@ $(GOBJ)

$(B)/$(MODPATH)/vm/game.$(QVMEXT): $(GVMOBJ) $(GDIR)/g_syscalls.asm
	@echo "Q3ASM $@"
	@$(Q3ASM) -o $@ $(GVMOBJ) $(GDIR)/g_syscalls.asm



#############################################################################
## TREMULOUS UI
#############################################################################

UIOBJ_ = \
  $(B)/$(MODPATH)/ui/ui_main.o \
  $(B)/$(MODPATH)/ui/ui_atoms.o \
  $(B)/$(MODPATH)/ui/ui_players.o \
  $(B)/$(MODPATH)/ui/ui_shared.o \
  $(B)/$(MODPATH)/ui/ui_gameinfo.o \
  \
  $(B)/$(MODPATH)/game/bg_misc.o \
  $(B)/$(MODPATH)/qcommon/q_math.o \
  $(B)/$(MODPATH)/qcommon/q_shared.o

UIOBJ = $(UIOBJ_) $(B)/$(MODPATH)/ui/ui_syscalls.o
UIVMOBJ = $(UIOBJ_:%.o=%.asm) $(B)/$(MODPATH)/game/bg_lib.asm

$(B)/$(MODPATH)/ui$(ARCH).$(SHLIBEXT) : $(UIOBJ)
	@echo "LD $@"
	@$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(UIOBJ)

$(B)/$(MODPATH)/vm/ui.$(QVMEXT): $(UIVMOBJ) $(UIDIR)/ui_syscalls.asm
	@echo "Q3ASM $@"
	@$(Q3ASM) -o $@ $(UIVMOBJ) $(UIDIR)/ui_syscalls.asm



#############################################################################
## GAME MODULE RULES
#############################################################################

$(B)/$(MODPATH)/cgame/%.o: $(CGDIR)/%.c
	$(DO_SHLIB_CC)

$(B)/$(MODPATH)/cgame/%.asm: $(CGDIR)/%.c
	$(DO_Q3LCC)


$(B)/$(MODPATH)/game/%.o: $(GDIR)/%.c
	$(DO_SHLIB_CC)

$(B)/$(MODPATH)/game/%.asm: $(GDIR)/%.c
	$(DO_Q3LCC)


$(B)/$(MODPATH)/ui/%.o: $(UIDIR)/%.c
	$(DO_SHLIB_CC)

$(B)/$(MODPATH)/ui/%.asm: $(UIDIR)/%.c
	$(DO_Q3LCC)


$(B)/$(MODPATH)/qcommon/%.o: $(CMDIR)/%.c
	$(DO_SHLIB_CC)

$(B)/$(MODPATH)/qcommon/%.asm: $(CMDIR)/%.c
	$(DO_Q3LCC)


#############################################################################
# MISC
#############################################################################

clean: clean-debug clean-release
	@$(MAKE) clean2

clean2:
	@echo "CLEAN $(B)"
	@if [ -d $(B) ];then (find $(B) -name '*.d' -exec rm {} \;)fi
	@rm -f $(GOBJ) $(CGOBJ) $(UIOBJ) \
		$(GVMOBJ) $(CGVMOBJ) $(UIVMOBJ)
	@rm -f $(TARGETS)

clean-debug:
	@$(MAKE) clean2 B=$(BD)

clean-release:
	@$(MAKE) clean2 B=$(BR)

toolsclean:
	@$(MAKE) -C $(TOOLSDIR)/asm clean uninstall
	@$(MAKE) -C $(TOOLSDIR)/lcc clean uninstall

distclean: clean toolsclean
	@rm -rf $(BUILD_DIR)

dist:
	@rm -rf tremulous-$(SVN_VERSION)
	@svn export . tremulous-$(SVN_VERSION)
	@tar --owner=root --group=root --force-local -cjf tremulous-$(SVN_VERSION).tar.bz2 tremulous-$(SVN_VERSION)
	@rm -rf tremulous-$(SVN_VERSION)

#############################################################################
# PK3s
#############################################################################

define DO_ZIP
@echo "ZIP $@"
@zip -X9 $@ $?
endef

GFXPK3_FILES = $(shell find gfx/ | sort)
ICONSPK3_FILES = $(shell find icons/ | sort)
MODELSPK3_FILES = $(shell find models/ | sort)
OVERRIDESPK3_FILES = $(shell find overrides/ | sort)
SCRIPTSPK3_FILES = $(shell find scripts/ | sort)
SOUNDPK3_FILES = $(shell find sound/ | sort)
UIPK3_FILES = $(shell find ui/ | sort)

#ui/infopanes.def: ui/infopanes.def.h
#	@echo "GCC $@"
#	@gcc -E $< | grep "^[^#].*" > $@

$(B)/$(MODPATH)/zgfx.$(PK3EXT): $(GFXPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zicons.$(PK3EXT): $(ICONSPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zmodels.$(PK3EXT): $(MODELSPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zoverrides.$(PK3EXT): $(OVERRIDESPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zscripts.$(PK3EXT): $(SCRIPTSPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zsound.$(PK3EXT): $(SOUNDPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zui.$(PK3EXT): $(UIPK3_FILES)
	$(DO_ZIP)

$(B)/$(MODPATH)/zvms.$(PK3EXT): $(B)/$(MODPATH)/vm/cgame.$(QVMEXT) $(B)/$(MODPATH)/vm/ui.$(QVMEXT)
	@echo "ZIP $@"
	@cd $(B)/$(MODPATH); zip -X9 zvms.$(PK3EXT) vm/cgame.$(QVMEXT) vm/ui.$(QVMEXT)

#############################################################################
# DEPENDENCIES
#############################################################################

D_FILES=$(shell find . -name '*.d')

ifneq ($(strip $(D_FILES)),)
  include $(D_FILES)
endif

.PHONY: all clean clean2 clean-debug clean-release \
	debug default dist distclean makedirs release \
	targets tools toolsclean
