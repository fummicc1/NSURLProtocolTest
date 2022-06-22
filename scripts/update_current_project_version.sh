#!/bin/sh

# scriptsディレクトリから実行することを想定
cd ..
xcrun agvtool next-version -all
cd scripts
