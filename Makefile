PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all package install

all: ;

docker: 
	@docker build -t perimeterx/pxnginx .

package:
	@tar zcf pxNginxPlugin.tgz Dockerfile Makefile README.md nginx* lib/ vendor/ www/

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px
	@if test -f $(DESTDIR)/$(LUA_LIB_DIR)/px/pxconfig.lua; then \
		echo "pxconfig.lua exists - skipping"; \
	else \
		$(INSTALL) lib/px/pxconfig.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/pxconfig.lua; fi
	$(INSTALL) lib/px/pxnginx.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/pxnginx.lua
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px/block
	$(INSTALL) lib/px/block/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/block
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/px/utils
	$(INSTALL) lib/px/utils/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/px/utils

clean:
	rm -rf pxNginxPlugin.tgz 
