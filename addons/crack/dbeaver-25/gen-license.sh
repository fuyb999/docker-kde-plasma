#!/bin/bash
jar_file="dbeaver-agent.jar"
java -cp "libs/*:./${jar_file}" com.dbeaver.agent.License "$@"