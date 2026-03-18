#
#  Makefile.unix - unix/linux make file
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

CXX=g++
STRIP=strip
PREFIX=/usr
SUFFIX=

define check_flag
  $(shell echo 'int main() { return 0; }' | $(CXX) $(1) -xc - 2>/dev/null && echo $(1))
endef

DESIRABLE_LDFLAGS  ?= -Wl,-z,now -Wl,-z,relro $(TRY_LDFLAGS)
DESIRABLE_CXXFLAGS ?= -fstack-protector-all -Wformat -Werror=format-security -s $(TRY_LDFLAGS)

SUPPORTED_LDFLAGS  += $(foreach flag,$(DESIRABLE_LDFLAGS),$(call check_flag,$(flag)))
SUPPORTED_CXXFLAGS += $(foreach flag,$(DESIRABLE_CXXFLAGS),$(call check_flag,$(flag)))

# These can be overridden with `CXXFLAGS="-something" LDFLAGS="" make target' ...
CXXFLAGS ?= -ffile-prefix-map=".=./src/bomutils"
LDFLAGS  ?= -pie
# ... while these will be appended anyway (to also override these use `make target CXXFLAGS=""')
CXXFLAGS := $(CXXFLAGS) -D_FORTIFY_SOURCE=2 $(SUPPORTED_CXXFLAGS)
LDFLAGS  := $(LDFLAGS) $(SUPPORTED_LDFLAGS)

LIBS=

BIN_DIR=$(PREFIX)/bin
MAN_DIR=$(PREFIX)/share/man

BUILD_DIR ?= build/unix
RELEASEZIP_NAME = $(shell uname -sm | tr ' ' _)
include build.mk
