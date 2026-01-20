#!/bin/bash

export PATH="/usr/local/bin:$PATH"
unset GEM_HOME
unset GEM_PATH

exec /usr/local/bin/pod "$@"
