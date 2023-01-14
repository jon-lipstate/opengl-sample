setlocal
@echo off
echo Cleaning

cd %~dp0
pushd .\target\
del /q "*.*?" 
popd

Call build.bat


