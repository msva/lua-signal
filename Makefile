include .config

UNAME            ?= $(shell uname)
DESTDIR          ?= /
PKG_CONFIG       ?= pkg-config
INSTALL          ?= install
RM               ?= rm
LUA_IMPL         ?= lua
LUA_BIN          ?= $(LUA_IMPL)
LUA_CMODULE_DIR  ?= $(shell $(PKG_CONFIG) --variable INSTALL_CMOD $(LUA_IMPL))
LIBDIR           ?= $(shell $(PKG_CONFIG) --variable libdir $(LUA_IMPL))
LUA_INC          ?= $(shell $(PKG_CONFIG) --variable INSTALL_INC $(LUA_IMPL))
CC               ?= cc

ifeq ($(UNAME), Linux)
OS_FLAGS         ?= -shared
endif
ifeq ($(UNAME), Darwin)
OS_FLAGS         ?= -bundle -undefined dynamic_lookup
endif

BIN               = src/signal.so
OBJ               = src/signal.o src/signames.o src/queue.o
SRC               = src/signal.c src/signames.c src/queue.c
HDR               = src/signames.h src/queue.h

INCLUDES          = -I$(LUA_INC)
DEFINES           =
LIBS              = -L$(LIBDIR)
COMMONFLAGS       = -O2 -g -pipe -fPIC $(OS_FLAGS)
LF                = $(LIBS) $(COMMONFLAGS) $(LDFLAGS)
CF                = -c $(INCLUDES) $(DEFINES) $(COMMONFLAGS) $(CFLAGS)

TEST_FLS          = alarm_test.lua signal_test.lua simple_test.lua
OTHER_FILES       = Makefile \
	            .config \
	            README \
	            LICENSE \
	            TODO
VERSION           = "LuaSignal-0.2"

all: $(BIN)

$(OBJ): $(HDR)

$(BIN): $(OBJ)
	$(CC) $(LF) $^ -o $@

%.o: %.c
	$(CC) $(CF) -o $@ $<

clean:
	$(RM) -f $(OBJ) $(BIN) test/*.so

dep:
	makedepend $(DEFINES) -Y $(SRC) > /dev/null 2>&1
	$(RM) -f Makefile.bak

test: all
	ln -sf ../$(BIN) test/
	cd test && $(LUA_BIN) alarm_test.lua
#       doesn't work in non-interactive mode. At least, with LuaJIT
#	-(cd test && $(LUA_BIN) signal_test.lua)
	cd test && $(LUA_BIN) simple_test.lua

install: all
	$(INSTALL) -d $(DESTDIR)$(LUA_CMODULE_DIR)
	$(INSTALL) $(BIN) $(DESTDIR)$(LUA_CMODULE_DIR)

uninstall: clean
	cd $(LUA_CMODULE_DIR);
	$(RM) -f $(BIN)

dist: $(VERSION).tar.gz

$(VERSION).tar.gz: $(SRC) $(TEST_FLS) $(OTHER_FILES)
	@mkdir $(VERSION)
	@mkdir $(VERSION)/src
	@cp $(SRC) $(HDR) $(VERSION)/src
	@mkdir $(VERSION)/test
	@cp $(TEST_FLS) $(VERSION)/test
	@mkdir $(VERSION)/test/$(TTT_TEST_DIR)
	@cp $(TTT_TEST_FLS) $(VERSION)/test/$(TTT_TEST_DIR)
	@cp $(OTHER_FILES) $(VERSION)
	@tar -czf $(VERSION).tar.gz $(VERSION)
	@$(RM) -rf $(VERSION)
