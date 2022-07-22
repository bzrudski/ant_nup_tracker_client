#!/bin/bash

#inkscape=/Applications/Inkscape.app/Contents/MacOS/inkscape
inputSVG=$1
exportName=$2
resolutions="40 58 60 80 87 120 152 167 180 1024"
dirName=${exportName}_icon

mkdir $dirName

for res in $resolutions
do
	inkscape $inputSVG -o $dirName/$exportName$res.png -w $res -h $res
done
