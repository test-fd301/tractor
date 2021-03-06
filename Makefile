R=R
INSTALL=bin/tractor_Rinstall

all:
	@echo 'Run "make install" to install packages'

postinstall-info:
	@echo
	@echo "Installation complete. You may wish to add the following lines"
	@echo "to your ~/.bashrc file (or equivalent for other shells):"
	@echo
	@echo "  export TRACTOR_HOME=`pwd`"
	@echo '  export PATH=$${TRACTOR_HOME}/bin:$${PATH}'
	@echo '  export MANPATH=$${TRACTOR_HOME}/man:$${MANPATH}'
	@echo
	@echo "The ~/.bashrc file can be created if it does not already exist."

install-libs:
	@$(INSTALL) lib/reportr

install-base:
	@$(INSTALL) tractor.base

install-utils:
	@$(INSTALL) tractor.utils

install-session:
	@$(INSTALL) tractor.session

install-nt:
	@$(INSTALL) tractor.nt

install-interpreted: install-libs install-base install-utils install-session install-nt

install: install-interpreted postinstall-info

install-native:
	@$(INSTALL) tractor.native
	@$(INSTALL) lib/mmand
	@$(INSTALL) lib/multicore

install-all: install-interpreted install-native postinstall-info

uninstall:
	$(R) CMD REMOVE tractor.nt tractor.session tractor.utils tractor.base reportr

uninstall-native:
	$(R) CMD REMOVE tractor.native multicore

uninstall-all: uninstall uninstall-native

clean:
	@cd tests && $(MAKE) clean

test:
	@cd tests && $(MAKE) run-tests

dtest:
	@cd tests && $(MAKE) debug-tests
