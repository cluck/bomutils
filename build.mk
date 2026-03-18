#
#  build.mk - Makefile
#
#  Copyright (C) 2013 Fabian Renn - fabian.renn (at) gmail.com
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA
#
#  Initial work done by Joseph Coffland and Julian Devlin.
#  Numerous further improvements by Baron Roberts.

OPTFLAGS += -O3 -g0 -s

APP_SOURCES=\
	mkbom.cpp \
	dumpbom.cpp \
	lsbom.cpp \
	ls4mkbom.cpp

COMMON_SOURCES=\
	printnode.cpp \
	crc32.cpp

BUILD_DIR ?= build
BUILD_BIN_DIR=$(BUILD_DIR)/bin
BUILD_OBJ_DIR=$(BUILD_DIR)/obj
BUILD_MAN_DIR=$(BUILD_DIR)/man

RELEASEZIP_DIR ?= build/release
RELEASEZIP_ROOT ?= .
RELEASEZIP_CONTENT ?= bin man

DOCKER_IMAGE_NAME=bomutils

SOURCES=$(APP_SOURCES) $(COMMON_SOURCES)
DEPS=$(addprefix $(BUILD_OBJ_DIR)/,$(SOURCES:.cpp=.d))
COMMON_OBJECTS=$(addprefix $(BUILD_OBJ_DIR)/,$(COMMON_SOURCES:.cpp=.o))
APP_NAMES=$(addsuffix $(SUFFIX),$(APP_SOURCES:.cpp=))
APPS=$(addprefix $(BUILD_BIN_DIR)/,$(APP_NAMES))
MAN=$(addprefix $(BUILD_MAN_DIR)/,$(APP_SOURCES:.cpp=.1.gz))
GIT_VERSION=$(shell if ( git tag 2>&1 ) > /dev/null; then git tag | tail -n 1; else echo unknown; fi)
ROOT_DIRECTORY_NAME=$(shell basename $${PWD})

vpath %.cpp src
vpath %.1 man

.PHONY: $(APP_NAMES) all install clean dist
.PRECIOUS: $(BUILD_OBJ_DIR)/%.o $(BUILD_OBJ_DIR)/%.d

STRIP ?= strip
binutils_strip = $(shell $(STRIP) --help | grep -m1 -- --strip-unneeded | wc -l)
ifeq ($(binutils_strip),1)
STRIP_COMMAND = $(STRIP) --strip-unneeded
else
STRIP_COMMAND = $(STRIP)
endif

all : $(APPS) $(MAN)

install : all
	install -d $(DESTDIR)$(BIN_DIR)
	install -d $(DESTDIR)$(MAN_DIR)/man1
	install -m 0755 $(APPS) $(DESTDIR)$(BIN_DIR)
	install -m 0644 $(MAN) $(DESTDIR)$(MAN_DIR)/man1

$(BUILD_OBJ_DIR)/%.o : %.cpp
	@mkdir -p $(BUILD_OBJ_DIR)
	$(CXX) -o $@ -c $(OPTFLAGS) $(CXXFLAGS) $(CFLAGS) $<

$(BUILD_OBJ_DIR)/%.d : %.cpp
	@mkdir -p $(BUILD_OBJ_DIR)
	@set -e; rm -f $@; $(CXX) -MM $(OPTFLAGS) $(CXXFLAGS) $(CFLAGS) $< > $@.$$$$; \
	sed -e 's,\($*\)\.o[ :]*,$(BUILD_OBJ_DIR)/\1.o $@ : ,g' < $@.$$$$ > $@; rm -f $@.$$$$

$(BUILD_BIN_DIR)/%$(SUFFIX) : $(BUILD_OBJ_DIR)/%.o $(COMMON_OBJECTS)
	@mkdir -p $(BUILD_BIN_DIR)
	$(CXX) -o $@ $(LDFLAGS) $^ $(LIBS)
	$(STRIP_COMMAND) $@

$(BUILD_MAN_DIR)/%.1.gz : %.1
	@mkdir -p $(BUILD_MAN_DIR)
	gzip -c $< > $@

$(APP_NAMES) :
	$(MAKE) $(BUILD_BIN_DIR)/$@

-include $(DEPS)

dist : clean
	cd .. && tar cvzf bomutils_$(GIT_VERSION).tar.gz --exclude .git $(ROOT_DIRECTORY_NAME)

clean :
	rm -rf $(BUILD_DIR)

docker-image :
	docker build -t bomutils .

docker-extract :
	mkdir -p "$(BUILD_DIR)/docker"
	CID=$$(docker create --annotation=bomutils=build bomutils cat) ; \
	docker export --output $(BUILD_DIR)/docker/rootfs.tar $$CID ; \
	docker container rm $$CID
	tar -C "$(BUILD_DIR)" -xf "$(BUILD_DIR)/docker/rootfs.tar" --strip-components=1 usr/bin usr/man

release :
	mkdir -p "$(RELEASEZIP_DIR)"
	rm -f "$(RELEASEZIP_DIR)/$(RELEASEZIP_NAME).zip"
	cd "$(BUILD_DIR)/$(RELEASEZIP_ROOT)" ; zip -r "$(abspath $(RELEASEZIP_DIR))/$(RELEASEZIP_NAME).zip" $(RELEASEZIP_CONTENT)
.PHONY: release

