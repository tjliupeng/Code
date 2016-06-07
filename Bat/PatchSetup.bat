@echo off
echo.
echo Hewlett Packard Enterprise Software...
echo Begin to setup Service Manager Server Patch...
echo Some configuration files (such as lwssofmconf.xml and udp.xml) will be overwritten by files from the patch. If you have made any changes to these files, remember to update the new versions accordingly after the patch setup process is completed.
echo.
echo.

setlocal enableextensions

set smmajorversion=9
set smleastminorversion=4
set smpatchversion=4x
set currentworkingdir=%~dp0
set currentscriptname=%~n0%~x0
set uninstallscriptname=PatchUninstall.bat
set logfile="%currentworkingdir%PatchSetup.log"

tasklist /FI "IMAGENAME eq Scenter.exe" 2>NUL | find /I /N "Scenter.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set errorMsg="SM Legacy Scenter is still running, please stop it."
	goto error_end
)

tasklist /FI "IMAGENAME eq sm.exe" 2>NUL | find /I /N "sm.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set errorMsg="SM Server is still running, please stop it."
	goto error_end
)

tasklist /FI "IMAGENAME eq smservice.exe" 2>NUL | find /I /N "smservice.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set errorMsg="SM Server Service is still running, please stop it."
	goto error_end
)

set /p sminstalldir="Full path of current SM Server installation directory:"

if "[%sminstalldir%]" equ "[]" (
	set errorMsg=Failed to provide the current SM Server installation directory.
	goto error_end
)

FOR /F "delims=" %%F IN ("%sminstalldir%") DO SET "sminstalldir=%%~fF"

call :test_directory "%sminstalldir%"

REM if not exist %sminstalldir% (
if %ERRORLEVEL% EQU 1 (
	set errorMsg="%sminstalldir%" does not exist.
	goto error_end
)

echo.
set /p smbackupdir="Full path of SM Server backup directory:"

if "[%smbackupdir%]" equ "[]" (
	set errorMsg=Failed to provide the SM Server backup directory.
	goto error_end
)

set original_smbackupdir=%smbackupdir%

FOR /F "delims=" %%F IN ("%smbackupdir%") DO SET "smbackupdir=%%~fF"

if /i "%original_smbackupdir%" neq "%smbackupdir%" (
	set errorMsg=Please provide full path of SM Server backup directory.
	goto error_end
)

cd /d "%currentworkingdir%"

set sminstallrundir="%sminstalldir%\RUN"

if not exist %sminstallrundir% (
	set errorMsg=%sminstallrundir% does not exist.
	goto error_end
)

cd /d %sminstallrundir%

if not exist sm.exe (
	set errorMsg=sm.exe does not exist.
	goto error_end
)

REM get installed sm version
sm.exe -version > smversion.txt 2<&1

if not exist smversion.txt (
	set errorMsg=Failed to get Service Manager server version information.
	goto error_end
)

for /f "tokens=2" %%a in (
'findstr /I /R /C:"^[ ]*Version: " smversion.txt'
) do (
set smcurrentversion=%%a
)

for /f "tokens=1-3" %%a in (
'findstr /I /R /C:"^[ ]*Patch Level: " smversion.txt'
) do (
set smcurrentpatchlevel=%%c
)

REM @echo %smcurrentversion%
REM @echo %smcurrentpatchlevel%
if "[%smcurrentpatchlevel%]" equ "[]" (
	set smcompleterversion=%smcurrentversion%
) else (
	set smcompleterversion=%smcurrentversion%-%smcurrentpatchlevel%
)
echo.
@echo The current SM Server is %smcompleterversion%.

del smversion.txt
REM get sm log file directory
for /f "tokens=1-2 delims=:" %%a in (
'findstr /I /C:"log:" sm.ini'
) do (
  set smlogfile=%%b
)

REM @echo "SM Server Log file is %smlogfile%"

for %%A in ("%smlogfile%") do (
    set smlogfolder=%%~dpA
    set smlogfileame=%%~nxA
)

REM @echo "SM Server Log file folder is %smlogfolder%"
REM @echo "SM Server Log file name is %smlogfileame%"

:apply_patch

echo.

REM set /p smnewpatchdir="Please enter the directory of SM Server patch you will apply(Default is %currentworkingdir%):"

REM if "[%smnewpatchdir%]" equ "[]" (
set smnewpatchdir=%currentworkingdir%
REM )

if not exist "%smbackupdir%" (
	mkdir "%smbackupdir%"
)

for /f "tokens=1-3 delims=." %%a in ( "%smcompleterversion%" ) do (
set smminorversion=%%b
)

if %smminorversion% lss %smleastminorversion% (
	set errorMsg="Current SM Server is %smcompleterversion%, can not apply %smmajorversion%.%smpatchversion% patch."
	goto error_end
)
echo.
@echo The setup process may take several minutes...
echo.
@echo Backing up the current SM Server to %smbackupdir%\%smcompleterversion%...

cd /d "%currentworkingdir%"

@echo _jvm>exclulist.txt
@echo _uninstall>>exclulist.txt
@echo logs>>exclulist.txt
@echo .log>>exclulist.txt

IF %sminstalldir:~-1%==\ SET sminstalldir=%sminstalldir:~0,-1%
@echo Backing up the current SM Server to %smbackupdir%\%smcompleterversion%... >PatchSetup.log
xcopy /e /i /Y /EXCLUDE:exclulist.txt "%sminstalldir%" "%smbackupdir%\%smcompleterversion%" >>PatchSetup.log 2>&1

if %ERRORLEVEL% GTR 0 (
	set errorMsg=Failed to back up SM Server. Please check the error information in the log file %logfile%.
	goto error_end
)
REM remove scemail.chk which don't need to backup
cd /d "%smbackupdir%\%smcompleterversion%\RUN"

if exist "scemail.chk" (
	del scemail.chk
)

cd /d "%smbackupdir%\%smcompleterversion%"

if exist "exclulist.txt" (
	del exclulist.txt
)

copy /y NUL SMPatchDiff >NUL
echo.
@echo Applying the SM Server Patch...

cd /d %sminstallrundir%

rmdir /S /Q "jre" >>PatchSetup.log 2>&1
if exist "jre" (
		set errorMsg=Failed to apply the SM Server upgrade. Please check the %logfile% log file for error information. This failure may prevent the SM Server from starting. Please retry the upgrade process to ensure a successful setup. 
		goto error_end
)
rmdir /S /Q "lib" >>PatchSetup.log 2>&1
if exist "lib" (
		set errorMsg=Failed to apply the SM Server upgrade. Please check the %logfile% log file for error information. This failure may prevent the SM Server from starting. Please retry the upgrade process to ensure a successful setup. 
		goto error_end
)
rmdir /S /Q "tomcat" >>PatchSetup.log 2>&1
if exist "tomcat" (
		set errorMsg=Failed to apply the SM Server upgrade. Please check the %logfile% log file for error information. This failure may prevent the SM Server from starting. Please retry the upgrade process to ensure a successful setup. 
		goto error_end
)

cd /d %sminstalldir%

if not exist "_uninstall" (
	mkdir _uninstall
)

cd /d "%currentworkingdir%"

@echo %~nx0>exclulist.txt
@echo %currentscriptname%>>exclulist.txt
@echo PatchSetup.log>>exclulist.txt
@echo %uninstallscriptname%>>exclulist.txt
@echo exclulist.txt>>exclulist.txt

REM remove the trailing back slash, because xcopy command requires
IF %smnewpatchdir:~-1%==\ SET smnewpatchdir=%smnewpatchdir:~0,-1%

@echo Applying SM Server Patch... >>PatchSetup.log
xcopy /e /Y /EXCLUDE:exclulist.txt "%smnewpatchdir%" "%sminstalldir%" >>PatchSetup.log 2>&1

if %ERRORLEVEL% GTR 0 (
	set errorMsg=Failed to apply the SM Server upgrade. Please check the %logfile% log file for error information. This failure may prevent the SM Server from starting. Please retry the upgrade process to ensure a successful setup. 
	goto error_end
)

copy /Y "%smnewpatchdir%\%uninstallscriptname%" "%sminstalldir%\_uninstall" > NUL 2>&1

del exclulist.txt

call :display_sm_version
echo.
@echo Finished applying the SM Server Patch.
@echo Finished applying the SM Server Patch. >>PatchSetup.log
move /Y PatchSetup.log "%sminstalldir%"  > NUL 2>&1

if exist "%sminstalldir%\exclulist.txt" (
	del "%sminstalldir%\exclulist.txt"
)

@echo.
@echo Remember to update the configuration files if necessary. You can get the backup copy from %smbackupdir%\%smcompleterversion%.

goto end

:error_end
@setlocal DisableDelayedExpansion 
echo.
@echo %errorMsg%

goto end

:end
echo.
cd /d %currentworkingdir%
pause>nul|set/p = "Press any key to exit."
@endlocal
EXIT /B %ERRORLEVEL%

:display_sm_version
cd /d %sminstallrundir%
sm.exe -version > smversion.txt 2<&1

if not exist smversion.txt (
	set errorMsg=Failed to get Service Manager server version information.
	goto error_end
)

for /f "tokens=2" %%a in (
'findstr /I /R /C:"^[ ]*Version: " smversion.txt'
) do (
set smcurrentversion=%%a
)

for /f "tokens=1-3" %%a in (
'findstr /I /R /C:"^[ ]*Patch Level: " smversion.txt'
) do (
set smcurrentpatchlevel=%%c
)
if "[%smcurrentpatchlevel%]" equ "[]" (
	set smcurrentcompleterversion=%smcurrentversion%
) else (
	set smcurrentcompleterversion=%smcurrentversion%_%smcurrentpatchlevel%
)

del smversion.txt
echo.
@echo The new SM Server version is %smcurrentcompleterversion%.

cd /d %currentworkingdir%

exit /B 0

:test_directory
setlocal enableextensions
if "%~1"=="" goto NoDirectory

pushd %1 2>nul && popd || goto :BadDirectory

endlocal
goto :eof

:NoDirectory
exit /b 1

:BadDirectory
exit /b 1