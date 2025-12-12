#!/bin/bash
cd /Users/mac/development/flutter_projects/pola/ios
for i in {1..100}; do
  /usr/local/bin/pod install && exit 0
  sleep 3
done
exit 1
