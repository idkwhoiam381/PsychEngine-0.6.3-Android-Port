#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git linc_luajit https://github.com/PsychExtendedThings/linc_luajit --global
haxelib install tjson --global
haxelib git flixel https://github.com/PsychExtendedThings/flixel 5.6.1 --global
haxelib install flixel-addons 3.2.2 --global
haxelib install flixel-ui 2.4.0 --global
haxelib install hscript 2.4.0 --global
haxelib git hxCodec https://github.com/PsychExtendedThings/hxCodec-0.6.3 --global
haxelib git hxcpp https://github.com/PsychExtendedThings/hxcpp --global
haxelib git lime https://github.com/PsychExtendedThings/lime-new --global
haxelib install openfl 9.3.3 --global
echo Setting dependencies...
haxelib dev linc_luajit /root/haxelib/linc_luajit/git
haxelib dev tjson /root/haxelib/tjson/1,4,0
haxelib dev flixel /root/haxelib/flixel/git
haxelib dev flixel-addons /root/haxelib/flixel-addons/3,2,2
haxelib dev flixel-ui /root/haxelib/flixel-ui/2,4,0
haxelib dev hscript /root/haxelib/hscript/2,4,0
haxelib dev hxCodec /root/haxelib/hxCodec/git
haxelib dev hxcpp /root/haxelib/hxcpp/git
haxelib dev lime /root/haxelib/lime/git
haxelib dev openfl /root/haxelib/openfl/9,3,3
echo Finished!