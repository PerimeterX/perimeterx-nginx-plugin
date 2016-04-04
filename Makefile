PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all install

all: ;

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px
	$(INSTALL) lib/px/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px/block
	$(INSTALL) lib/px/block/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/block
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px/challenge
	$(INSTALL) lib/px/challenge/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/challenge
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px/utils
	$(INSTALL) lib/px/utils/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/utils

