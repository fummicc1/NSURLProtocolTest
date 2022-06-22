#!/bin/sh

# scriptsディレクトリから実行することを想定
swift run -c release --package-path ../BuildTools/swift-format swift-format format -r -i  ../ToiletMap/Source
