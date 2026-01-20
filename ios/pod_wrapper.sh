#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
unset GEM_PATH GEM_HOME MY_RUBY_HOME IRBRC
exec /usr/local/bin/pod "$@"
