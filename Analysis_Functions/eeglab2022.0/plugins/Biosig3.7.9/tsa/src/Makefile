####################################################
# Copyright 2010,2011,2012,2016,2019 Alois Schloegl
# This is part of the TSA-toolbox - Time Series analysis toolbox
# http://pub.ist.ac.at/~schloegl/matlab/tsa/
####################################################
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA  02111-1307, USA.


### modify directories according to your needs 

# Define non-default octave-version 
# Octave - global install  (e.g. from debian package)
# OCTAVE_VERSION= 
# Better alternative: define an OCTAVE_VERSION bash variable (or in .bashrc or .profile)
# OCTAVE_VERSION=-3.6.3

# Matlab configuration
# MATLABDIR = /usr/local/MATLAB/R2010b
# comment the following line if you use MATLAB on 32-bit operating system
MEX_OPTION += -largeArrayDims

# Mingw crosscompiler: available at http://www.nongnu.org/mingw-cross-env/
CROSS   = $(HOME)/src/mxe/usr/bin/i686-w64-mingw32.static-
CROSS64 = $(HOME)/src/mxe/usr/bin/x86_64-w64-mingw32.static-
# include directory for Win32-Matlab include
W32MAT_INC = $(HOME)/bin/win32/Matlab/R2010b/extern/include/
W64MAT_INC = $(HOME)/bin/win64/Matlab/R2010b/extern/include/
# path to GNUMEX libraries, available from here http://sourceforge.net/projects/gnumex/
GNUMEX   = $(HOME)/bin/win32/gnumex
GNUMEX64 = $(HOME)/bin/win64/gnumex
# building gnumex64 was difficult, these hints were quite useful: 
# http://sourceforge.net/mailarchive/forum.php?thread_name=AANLkTinZvxgC9ezp2P3UCX_a7TAUYuVsp2U40MQUV6qr%40mail.gmail.com&forum_name=gnumex-users
# Instead of building "mex shortpath.c" and "mex uigetpath.c", I used empty m-functions within argout=argin; 
####################################################
MKOCTFILE ?= mkoctfile$(OCTAVE_VERSION)
CC      ?= gcc
CXX     ?= g++
CFLAGS  = -Wall -Wextra -Wconversion -O2 -fPIC
OCTMEX	= mkoctfile$(OCTAVE_VERSION) --mex
RM      = rm

# Support Debian Hardening flags
# https://wiki.debian.org/HardeningWalkthrough#Handling_dpkg-buildflags_in_your_upstream_build_system
CFLAGS += $(CPPFLAGS)

ifeq ($(OS),Windows_NT)
  # CC need to be defined on Windows, see also http://savannah.gnu.org/bugs/?47559
  CC = gcc
else ifeq (Darwin,$(shell uname))
  # no OpenMP on MacOSX, neither for Matlab nor Octave
else
  # enable OpenMP support
  CFLAGS      += -fPIC -fopenmp
  OCTMEX      += -lgomp
  MEX_OPTION  += -lgomp
  MEX_OPTION  += CC\#$(CXX) CXX\#$(CXX) CFLAGS\#"$(CFLAGS) " CXXFLAGS\#"$(CFLAGS) "
endif

MEX_OPTION  += CC\#$(CXX) CXX\#$(CXX) CFLAGS\#"$(CFLAGS)" CXXFLAGS\#"$(CFLAGS)"
MATMEX      = $(MATLABDIR)/bin/mex $(MEX_OPTION)

PROGS       = #covm_mex.mex sumskipnan_mex.mex histo_mex.mex kalman_maar.mex

### per default only the mex-files for octave are built
mex4o octave: $(PROGS)


### Matlab configuration - search for a matlab directory if not defined above
ifeq (,$(MATLABDIR))
  ifneq (,$(shell ls -1 /usr/local/ |grep MATLAB))
    # use oldest, typically mex-files a compatible with newer Matlab versions 
    MATLABDIR=/usr/local/MATLAB/$(shell ls -1rt /usr/local/MATLAB/  |grep "^R*" |head -1)
  endif
endif

### if MATLABDIR has been found or defined 
ifneq (,$(MATLABDIR))
  ifneq (,$(shell ls -1 $(MATLABDIR)/bin/mexext))
    MEX_EXT=$(shell $(MATLABDIR)/bin/mexext)
    mex4m matlab: $(patsubst %.mex, %.$(MEX_EXT), $(PROGS))
  endif
endif


mexw32 win32:  $(patsubst %.mex, %.mexw32, $(PROGS))
mexw64 win64:  $(patsubst %.mex, %.mexw64, $(PROGS))
all:    octave win32 win64 mex4m

clean:
	-$(RM) *.o *.obj *.o64 core octave-core *.oct *~ *.mex* 


#########################################################

#	Octave, MATLAB on Linux 
#########################################################
%.oct: %.cc
	mkoctfile$(OCTAVE_VERSION) "$<"

%.mex: %.cpp
	$(OCTMEX) "$<" -llapack -lblas
%.$(MEX_EXT): %.cpp
	$(MATMEX) "$<" -llapack -lblas


#########################################################
#	MATLAB/WIN32
#########################################################
%.obj: %.cpp
	$(CROSS)$(CXX) -fopenmp -c -DMATLAB_MEX_FILE -x c++ -o "$@" -I$(W32MAT_INC) -O2 -DMX_COMPAT_32 "$<"
%.obj: %.c
	$(CROSS)$(CXX) -fopenmp -c -DMATLAB_MEX_FILE -x c++ -o "$@" -I$(W32MAT_INC) -O2 -DMX_COMPAT_32 "$<"

%.mexw32: %.obj
	$(CROSS)$(CXX) -shared $(GNUMEX)/mex.def -o "$@" -L$(GNUMEX) -s "$<" -llibmx -llibmex -llibmat -lcholmod -lgomp -lpthread -L$(LDLIBS_W32) -lblas -llapack


#########################################################
#	MATLAB/WIN64
#########################################################

## ToDO: fix OpenMP support: currently -fopenmp causes Matlab to crash
%.o64: %.cpp
	$(CROSS64)$(CXX) -c -DMATLAB_MEX_FILE -x c++ -o "$@" -I$(W64MAT_INC) -O2 "$<"
%.o64: %.c
	$(CROSS64)$(CXX) -c -DMATLAB_MEX_FILE -x c++ -o "$@" -I$(W64MAT_INC) -O2 "$<"

%.mexw64: %.o64
	$(CROSS64)$(CXX) -shared $(GNUMEX64)/mex.def -o "$@" -L$(GNUMEX64) -s "$<" -llibmx -llibmex -llibmat -lcholmod -lgomp -lpthread -L$(LDLIBS_W64) -lblas -llapack

