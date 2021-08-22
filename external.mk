################################################################################
#
# bugs
#
################################################################################

BUGS_VERSION = 1.0
BUGS_SITE = $(TOPDIR)/../src
BUGS_SITE_METHOD = local
BUGS_DEPENDENCIES = host-gnucobol

define BUGS_BUILD_CMDS
	$(MAKE) COBC=$(HOST_COBC) COB_CFLAGS=-I$(TARGET_DIR)/usr/include COB_LDFLAGS="-L$(TARGET_DIR)/usr/lib -lcob" -C $(@D) all
endef

define BUGS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/bugs $(TARGET_DIR)/bin
endef

$(eval $(generic-package))
