@echo off
setlocal enabledelayedexpansion
echo.

call kill_shadercompiler.bat

rem == Setup path to nmake.exe ==
@REM find vs2017 directory, if vswhere doesn't exist, skip
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
	for /f "usebackq tokens=1* delims=: " %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop`) do (
		if /i "%%i"=="installationPath" (
			set VSDIR=%%j
			call "!VSDIR!\Common7\Tools\VsDevCmd.bat" >nul
			echo Using VS2017 tools
			goto :start
		)
	)	
) else if exist "%VS140COMNTOOLS%vsvars32.bat" (
	call "%VS140COMNTOOLS%vsvars32.bat"
	echo Using VS2015 tools
	
) else if exist "%VS120COMNTOOLS%vsvars32.bat" (
	call "%VS120COMNTOOLS%vsvars32.bat"
	echo Using VS2013 tools
	
) else if exist "%VS100COMNTOOLS%vsvars32.bat" (
	call "%VS100COMNTOOLS%vsvars32.bat"
	echo Using VS2010 tools
	
) else echo Install Either Visual Studio Version 2010, 2013, 2015, or 2017


:start
set TTEXE=..\..\devtools\bin\timeprecise.exe
if not exist %TTEXE% goto no_ttexe
goto no_ttexe_end

:no_ttexe
set TTEXE=time /t
:no_ttexe_end

echo.
echo ~~~~~~~~~~~~ buildallshaders %* ~~~~~~~~~~~~
%TTEXE% -cur-Q
set tt_all_start=%ERRORLEVEL%
set tt_all_chkpt=%tt_start%

rem ===================================
rem ====== LAUNCH CONFIGURATIONS ======

rem == Set the absolute path to your mod's game directory here ==
@REM change this to the core folder (platform atm)
set GAMEDIR=%cd%\..\..\..\game\mod_hl2

rem == Set the relative or absolute path to the bin folder ==
set "ENGINEDIR=..\..\..\game"

rem ==  Set the Path to your mod's root source code ==
rem This should already be correct, accepts relative paths only!
set SOURCEDIR=..\..

set "targetdir=..\..\..\game\platform\shaders"

set BUILD_SHADER=call buildshaders.bat

@REM dynamic shaders only builds the required files (inc) to build stdshader_dx*.dll
set dynamic_shaders=0

rem ==== LAUNCH CONFIGURATIONS END ====
rem ===================================

@REM maybe set something up like this? idk
@REM For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
@REM For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)



REM ****************
REM BUILD SHADERS
REM ****************
@REM shove the output into txt file 
echo --------------------------------------------------------------------------------------------
echo Outputting to log_stdshader_dx9_20b.txt
%BUILD_SHADER% stdshader_dx9_20b				-game %GAMEDIR% -source %SOURCEDIR% %dynamic_shaders% >log_stdshader_dx9_20b.txt
echo --------------------------------------------------------------------------------------------
echo Outputting to log_stdshader_dx9_30.txt
%BUILD_SHADER% stdshader_dx9_30					-game %GAMEDIR% -source %SOURCEDIR% %dynamic_shaders% -dx9_30 -force30 >log_stdshader_dx9_30.txt
echo --------------------------------------------------------------------------------------------
@REM %BUILD_SHADER% stdshader_dx10			-game %GAMEDIR% -source %SOURCEDIR% %dynamic_shaders% -dx10
echo.

REM ****************
REM PC Shader copy
REM Publish the generated files to the output dir using XCOPY
REM This batch file may have been invoked standalone or slaved (master does final smart mirror copy)
REM ****************
:DoXCopy
if not "%dynamic_shaders%" == "1" (
	if not exist "%targetdir%" md "%targetdir%"
	xcopy "%cd%\shaders" "%cd%\%targetdir%\" /q /e /y	
)
goto end

REM ****************
REM END
REM ****************
:end

rem echo.
if not "%dynamic_shaders%" == "1" (
  echo Finished full buildallshaders %*
) else (
  echo Finished dynamic buildallshaders %*
)

%TTEXE% -diff %tt_all_start% -cur
echo.

echo Press any key to rebuild shaders group and exit . . .
pause >nul

..\..\devtools\bin\vpc.exe /f +shaders_all