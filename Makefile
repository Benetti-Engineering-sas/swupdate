# SPDX-FileCopyrightText: 2013 Stefano Babic <stefano.babic@swupdate.org>
#
# SPDX-License-Identifier: GPL-2.0-only

VERSION = 2025
PATCHLEVEL = 05
SUBLEVEL = 0

IPCLIB_VERSION = 0.1

# *DOCUMENTATION*
# To see a list of typical targets execute "make help"
# More info can be located in ./README
# Comments in this file are targeted only to the developer, do not
# expect to learn how to build the kernel reading this file.

# Do not:
# o  use make's built-in rules
#    (this increases performance and avoids hard-to-debug behaviour);
# o  print "Entering directory ...";
MAKEFLAGS += -r --no-print-directory

OSNAME := $(shell uname -s)
ifeq ($(OSNAME),Linux)
export HAVE_LINUX = y
else
export HAVE_LINUX = n
endif
ifeq ($(OSNAME),FreeBSD)
export HAVE_FREEBSD = y
else
export HAVE_FREEBSD = n
endif

# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands

ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

# kbuild supports saving output files in a separate directory.
# To locate output files in a separate directory two syntaxes are supported.
# In both cases the working directory must be the root of the kernel src.
# 1) O=
# Use "make O=dir/to/store/output/files/"
#
# 2) Set KBUILD_OUTPUT
# Set the environment variable KBUILD_OUTPUT to point to the directory
# where the output files shall be placed.
# export KBUILD_OUTPUT=dir/to/store/output/files/
# make
#
# The O= assignment takes precedence over the KBUILD_OUTPUT environment
# variable.

# Our default target
PHONY := _all
_all:

# KBUILD_SRC is set on invocation of make in OBJ directory
# KBUILD_SRC is not intended to be used by the regular user (for now)
ifeq ($(KBUILD_SRC),)

# OK, Make called in directory where kernel src resides
# Do we want to locate output files in a separate directory?
ifeq ("$(origin O)", "command line")
  KBUILD_OUTPUT := $(O)
endif

ifeq ("$(origin W)", "command line")
  export KBUILD_ENABLE_EXTRA_GCC_CHECKS := $(W)
endif

# Cancel implicit rules on top Makefile
$(CURDIR)/Makefile Makefile: ;

ifneq ($(KBUILD_OUTPUT),)
# Invoke a second make in the output directory, passing relevant variables
# check that the output directory actually exists
saved-output := $(KBUILD_OUTPUT)
KBUILD_OUTPUT := $(shell cd $(KBUILD_OUTPUT) && /bin/pwd)
$(if $(KBUILD_OUTPUT),, \
     $(error output directory "$(saved-output)" does not exist))

PHONY += $(MAKECMDGOALS) sub-make

$(filter-out _all sub-make $(CURDIR)/Makefile, $(MAKECMDGOALS)) _all: sub-make
	$(Q)@:

sub-make: FORCE
	$(if $(KBUILD_VERBOSE:1=),@)$(MAKE) -C $(KBUILD_OUTPUT) \
	KBUILD_SRC=$(CURDIR) \
	-f $(CURDIR)/Makefile \
	$(filter-out _all sub-make,$(MAKECMDGOALS))

# Leave processing to above invocation of make
skip-makefile := 1
endif # ifneq ($(KBUILD_OUTPUT),)
endif # ifeq ($(KBUILD_SRC),)

# We process the rest of the Makefile if this is the final invocation of make
ifeq ($(skip-makefile),)

# If building an external module we do not care about the all: rule
# but instead _all depend on modules
PHONY += all
_all: all

srctree		:= $(if $(KBUILD_SRC),$(KBUILD_SRC),$(CURDIR))
objtree		:= $(CURDIR)
src		:= $(srctree)
obj		:= $(objtree)

VPATH		:= $(srctree)

export srctree objtree VPATH

CROSS_COMPILE	?= $(CONFIG_CROSS_COMPILE:"%"=%)

KCONFIG_CONFIG	?= .config
export KCONFIG_CONFIG

# SHELL used by kbuild
CONFIG_SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	  else if [ -x /bin/bash ]; then echo /bin/bash; \
	  else echo sh; fi ; fi)

HOSTCC       = cc
HOSTCXX      = c++
HOSTCFLAGS   = -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer
HOSTCXXFLAGS = -O2

# Beautify output
# ---------------------------------------------------------------------------
#
# Normally, we echo the whole command before executing it. By making
# that echo $($(quiet)$(cmd)), we now have the possibility to set
# $(quiet) to choose other forms of output instead, e.g.
#
#         quiet_cmd_cc_o_c = Compiling $(RELDIR)/$@
#         cmd_cc_o_c       = $(CC) $(c_flags) -c -o $@ $<
#
# If $(quiet) is empty, the whole command will be printed.
# If it is set to "quiet_", only the short version will be printed.
# If it is set to "silent_", nothing will be printed at all, since
# the variable $(silent_cmd_cc_o_c) doesn't exist.
#
# A simple variant is to prefix commands with $(Q) - that's useful
# for commands that shall be hidden in non-verbose mode.
#
#	$(Q)ln $@ :<
#
# If KBUILD_VERBOSE equals 0 then the above command will be hidden.
# If KBUILD_VERBOSE equals 1 then the above command is displayed.

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

# If the user is running make -s (silent mode), suppress echoing of
# commands

ifneq ($(findstring s,$(MAKEFLAGS)),)
  quiet=silent_
endif

export quiet Q KBUILD_VERBOSE


# Look for make include files relative to root of kernel src
MAKEFLAGS += --include-dir=$(srctree)

# We need some generic definitions (do not try to remake the file).
$(srctree)/scripts/Kbuild.include: ;
include $(srctree)/scripts/Kbuild.include

# Make variables (CC, etc...)

# this looks a bit horrible, but 'VAR ?= VALUE' preserves builtin values
# rather than only user-supplied values from env or command-line
$(call set_if_default_or_unset,AS,$$(CROSS_COMPILE)as)
$(call set_if_default_or_unset,LD,$$(CROSS_COMPILE)cc)
$(call set_if_default_or_unset,CC,$$(CROSS_COMPILE)cc)
$(call set_if_default_or_unset,CPP,$$(CC) -E)
$(call set_if_default_or_unset,AR,$$(CROSS_COMPILE)ar)
$(call set_if_default_or_unset,NM,$$(CROSS_COMPILE)nm)
$(call set_if_default_or_unset,STRIP,$$(CROSS_COMPILE)strip)
$(call set_if_default_or_unset,OBJCOPY,$$(CROSS_COMPILE)objcopy)
$(call set_if_default_or_unset,OBJDUMP,$$(CROSS_COMPILE)objdump)
$(call set_if_default_or_unset,PKG_CONFIG,pkg-config)

AWK		= awk
INSTALLKERNEL  := installkernel
PERL		= perl

CHECKFLAGS     := -D__linux__ -Dlinux -D__STDC__ -Dunix -D__unix__ \
		  -Wbitwise -Wno-return-void $(CF)
CFLAGS_KERNEL	=
AFLAGS_KERNEL	=

BINDIR ?= /usr/bin
LIBDIR ?= /usr/lib
INCLUDEDIR ?= /usr/include

# Use LINUXINCLUDE when you must reference the include/ directory.
# Needed to be compatible with the O= option
LINUXINCLUDE    := -Iinclude \
                   $(if $(KBUILD_SRC), -I$(srctree)/include) \
                   -include include/generated/autoconf.h

KBUILD_CPPFLAGS :=
KBUILD_CFLAGS   :=
KBUILD_AFLAGS_KERNEL :=
KBUILD_CFLAGS_KERNEL :=
KBUILD_AFLAGS   := -D__ASSEMBLY__

# Read KERNELRELEASE from include/config/kernel.release (if it exists)
KERNELRELEASE = $(shell cat include/config/kernel.release 2> /dev/null)
KERNELVERSION = $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)

# Kconfiglib
KCONFIGLIB = $(srctree)/scripts/Kconfiglib

export ARCH SRCARCH CONFIG_SHELL HOSTCC HOSTCFLAGS CROSS_COMPILE AS LD CC
export CPP AR NM STRIP OBJCOPY OBJDUMP
export MAKE AWK GENKSYMS INSTALLKERNEL PERL UTS_MACHINE
export HOSTCXX HOSTCXXFLAGS

export KBUILD_CPPFLAGS NOSTDINC_FLAGS LINUXINCLUDE OBJCOPYFLAGS LDFLAGS
export KBUILD_CFLAGS CFLAGS_KERNEL
export KBUILD_AFLAGS AFLAGS_KERNEL
export KBUILD_AFLAGS_KERNEL KBUILD_CFLAGS_KERNEL
export KBUILD_ARFLAGS

# Files to ignore in find ... statements

RCS_FIND_IGNORE := \( -name SCCS -o -name BitKeeper -o -name .svn -o -name CVS -o -name .pc -o -name .hg -o -name .git \) -prune -o

# ===========================================================================
# Rules shared between *config targets and build targets

-include $(srctree)/Makefile.deps

# Basic helpers built in scripts/
PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic

# To avoid any implicit rule to kick in, define an empty command.
scripts/basic/%: scripts_basic ;

PHONY += outputmakefile
# outputmakefile generates a Makefile in the output directory, if using a
# separate output directory. This allows convenient use of make in the
# output directory.
outputmakefile:
ifneq ($(KBUILD_SRC),)
	$(Q)ln -fsn $(srctree) source
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile \
	    $(srctree) $(objtree) $(VERSION) $(PATCHLEVEL)
endif


# To make sure we do not include .config for any of the *config targets
# catch them early, and hand them over to scripts/Kconfiglib/.
# It is allowed to specify more targets when calling make, including
# mixing *config targets and build targets.
# For example 'make oldconfig all'.
# Detect when mixed targets is specified, and make a second invocation
# of make so .config is not included in this case either (for *config).

no-dot-config-targets := clean mrproper distclean \
			 cscope gtags TAGS tags help %docs check% coccicheck \
			 include/linux/version.h headers_% \
			 kernelversion %src-pkg

config-targets := 0
mixed-targets  := 0
dot-config     := 1

ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		dot-config := 0
	endif
endif

ifneq ($(filter config %config,$(MAKECMDGOALS)),)
        config-targets := 1
        ifneq ($(filter-out config %config,$(MAKECMDGOALS)),)
                mixed-targets := 1
        endif
endif

ifeq ($(mixed-targets),1)
# ===========================================================================
# We're called with mixed targets (*config and build targets).
# Handle them one by one.

%:: FORCE
	$(Q)$(MAKE) -C $(srctree) KBUILD_SRC= $@

else
ifeq ($(config-targets),1)
# ===========================================================================
# *config targets only - make sure prerequisites are updated, and call
# scripts/Kconfiglib to make the *config target

# Read arch specific Makefile to set KBUILD_DEFCONFIG as needed.
# KBUILD_DEFCONFIG may point out an alternative default configuration
# used for 'make defconfig'
#include $(srctree)/arch/$(SRCARCH)/Makefile
export KBUILD_DEFCONFIG KBUILD_KCONFIG

config: scripts_basic outputmakefile FORCE
	$(Q)mkdir -p include/linux include/config
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

%config: scripts_basic outputmakefile FORCE
	$(Q)mkdir -p include/linux include/config
	$(Q)$(KCONFIGLIB)/$@.py

%_defconfig: scripts_basic outputmakefile FORCE
	$(Q)mkdir -p include/linux include/config
	$(Q)$(KCONFIGLIB)/defconfig.py $(srctree)/configs/$@

else


ifeq ($(dot-config),1)
# Read in config
-include include/config/auto.conf


# Read in dependencies to all Kconfig* files, make sure to run
# oldconfig if changes are detected.
-include include/config/auto.conf.cmd

# To avoid any implicit rule to kick in, define an empty command
$(KCONFIG_CONFIG) include/config/auto.conf.cmd: ;

# If .config is newer than include/config/auto.conf, someone tinkered
# with it and forgot to run make oldconfig.
# if auto.conf.cmd is missing then we are probably in a cleaned tree so
# we execute the config step to be sure to catch updated Kconfig files
include/config/%.conf: $(KCONFIG_CONFIG) include/config/auto.conf.cmd
	$(Q)mkdir -p $(objtree)/include/config $(objtree)/include/generated
	$(Q)$(KCONFIGLIB)/genconfig.py \
		--header-path $(objtree)/include/generated/autoconf.h \
		--sync-deps $(objtree)/include/config

else
# Dummy target needed, because used as prerequisite
include/config/auto.conf: ;
endif # $(dot-config)

# Now we can define CFLAGS etc according to .config
include $(srctree)/Makefile.flags

# The all: target is the default when no target is given on the
# command line.
# This allow a user to issue only 'make' to build a kernel including modules
# Defaults to vmlinux, but the arch makefile usually adds further targets

objs-y		:= core handlers bootloader suricatta
libs-y		:= corelib mongoose parser fs containers
bindings-y	:= bindings
tools-y		:= tools

ipc-y		:= ipc
ipc-lib 	:= $(patsubst %,%/built-in.o, $(ipc-y))
ipc-dirs 	:= $(ipc-y)

swupdate-ipc-lib 	:= libswupdate.so.${IPCLIB_VERSION}

swupdate-dirs	:= $(objs-y) $(libs-y)
swupdate-objs	:= $(patsubst %,%/built-in.o, $(objs-y))
swupdate-libs	:= $(patsubst %,%/lib.a, $(libs-y))
swupdate-all	:= $(swupdate-objs) $(swupdate-libs)

tools-dirs	:= $(tools-y)
tools-objs	:= $(patsubst %,%/lib.a, $(tools-y))
tools-bins	:= $(patsubst $(srctree)/$(tools-y)/%.c,$(tools-y)/%,$(wildcard $(srctree)/$(tools-y)/*.c))
tools-bins-unstr:= $(patsubst %,%_unstripped,$(tools-bins))
tools-all	:= $(tools-objs)

ifeq ($(HAVE_LUA),y)
lua_swupdate	:= lua_swupdate.so.0.1
endif

bindings-dirs	:= $(bindings-y)
bindings-libs	:= $(patsubst %,%/built-in.o, $(bindings-y))
bindings-all	:= $(bindings-libs)

.cfg-sanity-check: .config
	@if [ "x$(CONFIG_SETSWDESCRIPTION)" = "xy" -a -z "$(patsubst "%",%,$(strip $(CONFIG_SWDESCRIPTION)))" ]; then \
		echo "ERROR: CONFIG_SETSWDESCRIPTION set but not CONFIG_SWDESCRIPTION"; \
		exit 1; \
	fi
	@if [ "x$(CONFIG_SETEXTPARSERNAME)" = "xy" -a -z "$(patsubst "%",%,$(strip $(CONFIG_EXTPARSERNAME)))" ]; then \
		echo "ERROR: CONFIG_SETEXTPARSERNAME set but not CONFIG_EXTPARSERNAME"; \
		exit 1; \
	fi
	@touch .cfg-sanity-check

all: swupdate ${tools-bins} ${lua_swupdate}

# Do modpost on a prelinked vmlinux. The finally linked vmlinux has
# relevant sections renamed as per the linker script.
quiet_cmd_swupdate = LD      $@
      cmd_swupdate = $(srctree)/scripts/trylink \
      "$@" \
      "$(CC)" \
      "$(KBUILD_CFLAGS) $(CFLAGS_swupdate)" \
      "$(LDFLAGS) $(EXTRA_LDFLAGS) $(LDFLAGS_swupdate)" \
      "$(swupdate-objs) $(ipc-lib)" \
      "$(swupdate-libs)" \
	  "$(LDLIBS)"

swupdate_unstripped: ${swupdate-ipc-lib} $(swupdate-all)
	$(call if_changed,swupdate)

quiet_cmd_addon = LD      $@
      cmd_addon = $(srctree)/scripts/trylink \
      "$@" \
      "$(CC)" \
      "$(KBUILD_CFLAGS) $(CFLAGS_swupdate)" \
      "$(LDFLAGS) $(EXTRA_LDFLAGS) $(LDFLAGS_swupdate) -L$(objtree)" \
      "$(2)" \
      "$(swupdate-libs)" \
	  "$(LDLIBS) :${swupdate-ipc-lib}"

quiet_cmd_shared = LD      $@
      cmd_shared = $(srctree)/scripts/trylink \
      "$@" \
      "$(CC)" \
      "-shared -Wl,-soname,$@" \
      "$(KBUILD_CFLAGS) $(CFLAGS_swupdate)" \
      "$(LDFLAGS) $(EXTRA_LDFLAGS) $(LDFLAGS_swupdate) -L$(objtree)" \
      "$(2)" \
	  "$(LDLIBS)"

lua_swupdate.so.0.1: $(bindings-libs) ${swupdate-ipc-lib}
	$(call if_changed,shared,$(bindings-libs) $(ipc-lib))

${swupdate-ipc-lib}: $(ipc-lib)
	$(call if_changed,shared,$(ipc-lib))

ifeq ($(SKIP_STRIP),y)
quiet_cmd_strip = echo $@
cmd_strip = cp $@_unstripped $@
else
quiet_cmd_strip = STRIP   $@
cmd_strip = $(STRIP) -s --remove-section=.note --remove-section=.comment \
               $@_unstripped -o $@; chmod a+x $@
endif

swupdate: .cfg-sanity-check swupdate_unstripped
	$(call cmd,strip)

.tools-built-in: tools/lib.a
	@touch .tools-built-in

${tools-bins}: ${swupdate-ipc-lib} ${tools-objs} ${swupdate-libs} .tools-built-in
	$(call if_changed,addon,$@.o)
	@mv $@ $@_unstripped
	$(call cmd,strip)

install: all
	install -d ${DESTDIR}/${BINDIR}
	install -d ${DESTDIR}/${INCLUDEDIR}
	install -d ${DESTDIR}/${LIBDIR}
	install -m 755 swupdate ${DESTDIR}/${BINDIR}
	for i in ${tools-bins};do \
		install -m 755 $$i ${DESTDIR}/${BINDIR}; \
	done
	install -m 0644 $(srctree)/include/network_ipc.h ${DESTDIR}/${INCLUDEDIR}
	install -m 0644 $(srctree)/include/swupdate_status.h ${DESTDIR}/${INCLUDEDIR}
	install -m 0644 $(srctree)/include/progress_ipc.h ${DESTDIR}/${INCLUDEDIR}
	install -m 0755 $(objtree)/${swupdate-ipc-lib} ${DESTDIR}/${LIBDIR}
	ln -sfr ${DESTDIR}/${LIBDIR}/${swupdate-ipc-lib} ${DESTDIR}/${LIBDIR}/libswupdate.so
	if [ $(HAVE_LUA) = y ]; then \
		install -d ${DESTDIR}/${LIBDIR}/lua/$(LUAVER); \
		install -m 0755 ${lua_swupdate} $(DESTDIR)/${LIBDIR}/lua/$(LUAVER); \
		ln -sf ${lua_swupdate} $(DESTDIR)/${LIBDIR}/lua/$(LUAVER)/lua_swupdate.so; \
	fi

PHONY += tests
tests: acceptance-tests test

PHONY += acceptance-tests
acceptance-tests: swupdate ${tools-bins} FORCE
	$(Q)$(MAKE) $(build)=scripts/acceptance-tests tests

PHONY += test
test:
	$(Q)$(MAKE) $(build)=test SWOBJS="$(swupdate-objs)" SWLIBS="$(swupdate-libs) ${swupdate-ipc-lib}" LDLIBS="$(LDLIBS)" tests

# The actual objects are generated when descending,
# make sure no implicit rule kicks in
$(sort $(swupdate-all)): $(swupdate-dirs) ;
$(sort $(tools-all)): $(tools-dirs) ;
$(sort $(bindings-all)): $(bindings-dirs) ;
$(sort $(ipc-lib)): $(ipc-dirs) ;

# Handle descending into subdirectories listed in $(vmlinux-dirs)
# Preset locale variables to speed up the build process. Limit locale
# tweaks to this spot to avoid wrong language settings when running
# make menuconfig etc.
# Error messages still appears in the original language

PHONY += $(swupdate-dirs) $(tools-dirs) $(bindings-dirs) $(ipc-dirs)
$(swupdate-dirs): scripts
	$(Q)$(MAKE) $(build)=$@
$(tools-dirs): scripts
	$(Q)$(MAKE) $(build)=$@
$(bindings-dirs): scripts
	$(Q)$(MAKE) $(build)=$@
$(ipc-dirs): scripts
	$(Q)$(MAKE) $(build)=$@

###
# Cleaning is done on three levels.
# make clean     Delete most generated files
#                Leave enough to build external modules
# make mrproper  Delete the current configuration, and all generated files
# make distclean Remove editor backup files, patch leftover files and the like

# Directories & files removed with 'make clean'
CLEAN_DIRS  +=
CLEAN_FILES += swupdate swupdate_unstripped* lua_swupdate* libswupdate* ${tools-bins} \
	$(patsubst %,%_unstripped,$(tools-bins)) \
	$(patsubst %,%.out,$(tools-bins)) \
	$(patsubst %,%.map,$(tools-bins)) \

# Directories & files removed with 'make mrproper'
MRPROPER_DIRS  += include/config include/generated
MRPROPER_FILES += .config .config.old tags TAGS cscope* GPATH GTAGS GRTAGS GSYMS

# clean - Delete most, but leave enough to build external modules
#
clean: rm-dirs  := $(CLEAN_DIRS)
clean: rm-files := $(CLEAN_FILES)
clean-dirs      := $(addprefix _clean_, $(swupdate-dirs) $(ipc-dirs) $(tools-dirs) $(bindings-dirs) scripts/acceptance-tests)

PHONY += $(clean-dirs) clean archclean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

clean: $(clean-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)
	@find . $(RCS_FIND_IGNORE) \
		\( -name '*.[oas]' -o -name '.*.cmd' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \
		-o -name modules.builtin -o -name '.tmp_*.o.*' \
		-o -name '*.o.tmp' \) -type f -print | xargs rm -f
	@pwd
	$(Q)$(MAKE) -f $(srctree)/doc/Makefile BUILDDIR=$(CURDIR)/doc/build clean

# mrproper - Delete all generated files, including .config
#
mrproper: rm-dirs  := $(wildcard $(MRPROPER_DIRS))
mrproper: rm-files := $(wildcard $(MRPROPER_FILES))
mrproper-dirs      := $(addprefix _mrproper_, scripts)

PHONY += $(mrproper-dirs) mrproper
$(mrproper-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _mrproper_%,%,$@)

mrproper: clean $(mrproper-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)

# distclean
#
PHONY += distclean
distclean: mrproper
	@find $(srctree) $(RCS_FIND_IGNORE) \
		\( -name '*.orig' -o -name '*.rej' -o -name '*~' \
		-o -name '*.bak' -o -name '#*#' -o -name '.*.orig' \
		-o -name '.*.rej' -o -size 0 \
		-o -name '*%' -o -name '.*.cmd' -o -name 'core' \) \
		-type f -print | xargs rm -f


# FIXME Should go into a make.lib or something
# ===========================================================================

quiet_cmd_rmdirs = $(if $(wildcard $(rm-dirs)),CLEAN   $(wildcard $(rm-dirs)))
      cmd_rmdirs = rm -rf $(rm-dirs)

quiet_cmd_rmfiles = $(if $(wildcard $(rm-files)),CLEAN   $(wildcard $(rm-files)))
      cmd_rmfiles = rm -f $(rm-files)

# Shorthand for $(Q)$(MAKE) -f scripts/Makefile.clean obj=dir
# Usage:
# $(Q)$(MAKE) $(clean)=dir
clean := -f $(if $(KBUILD_SRC),$(srctree)/)scripts/Makefile.clean obj

-include $(srctree)/Makefile.help

endif #ifeq ($(config-targets),1)
endif #ifeq ($(mixed-targets),1)

# Documentation
# run Makefile in doc directory

dirhtml singlehtml pickle json htmlhelp qthelp devhelp epub \
latex latexpdf text man changes linkcheck html doctest:
	$(Q)$(MAKE) -C $(srctree)/doc BUILDDIR=$(CURDIR)/doc/build $@

endif	# skip-makefile

PHONY += FORCE
FORCE:

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)
