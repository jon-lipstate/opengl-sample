@echo off
setlocal enabledelayedexpansion
echo Building Odin 

cd %~dp0
odin build . -out:target/opengl.exe -debug -ignore-unknown-attributes 
@REM -subsystem:windows

echo Build Done