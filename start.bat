@echo off

set tool=%1

cls

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "date=%dt:~0,4%_%dt:~4,2%_%dt:~6,2%"

call ./build.bat %tool%

Start remedybg %tool%/target/debug/%date%/%tool%.exe

code ./