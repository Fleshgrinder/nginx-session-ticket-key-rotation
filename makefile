# ------------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Makefile for easy pre-configured distribution of installation.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#                                                                      Variables
# ------------------------------------------------------------------------------


# The server names to install or rotate for.
SERVER_NAMES := example.com localhost

# The name of the user the repository should own after clean.
USER := fleshgrinder

# The name of the group the repository should own after clean.
GROUP := ${USER}


# ------------------------------------------------------------------------------
#                                                                        Targets
# ------------------------------------------------------------------------------


# Ensure make doesn't think these targets are up-to-date because of an existing
# directory.
.PHONY: test

# Mainly useful for testing.
all:
	clear
	make test
	make nginx_integration_test
	-make install
	make clean

# Clean everything and change repository owner back to default.
clean:
	sh uninstall.sh -v
	chown -R -- ${USER}:${GROUP} .
	chmod -R -- 0755 .
	find . -type f -exec chmod -- 0644 {} \;
	find . -name '*.sh' -type f -exec chmod -- 0755 {} \;

# Install TLS session ticket key rotation for defined servers.
install:
	sh install.sh -v $(SERVER_NAMES)

# Execute the integration test.
nginx_integration_test:
	rm -f test/nginx.log
	sh test/nginx_integration_test.sh

# Rotate existing TLS session ticket keys for defined servers.
rotate:
	sh generator.sh -v $(SERVER_NAMES)

# Execute all unit tests and final integration test.
test:
	sh test/all.sh
