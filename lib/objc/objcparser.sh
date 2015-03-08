#!/bin/sh
DIRNAME=`dirname $0`
java -jar $DIRNAME/objcparser.jar "$@"
