#!/bin/bash
PROJECT_NAME=Postboks
PROJECT_DIR=$(pwd)/$PROJECT_NAME
INFOPLIST_FILE="Info.plist"

CFBundleVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
CFBundleShortVersionString=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")

rm -rf Archive/*
rm -rf Product/*

xcodebuild clean -workspace $PROJECT_NAME.xcworkspace -configuration DeveloperID -scheme $PROJECT_NAME

xcodebuild archive -workspace $PROJECT_NAME.xcworkspace -scheme $PROJECT_NAME -archivePath Archive/$PROJECT_NAME.xcarchive

xcodebuild -exportArchive -archivePath Archive/$PROJECT_NAME.xcarchive -exportPath Product/$PROJECT_NAME.app -exportFormat app

cd Product
zip -r -y "$PROJECT_NAME.v${CFBundleShortVersionString}.b${CFBundleVersion}.zip" $PROJECT_NAME.app
