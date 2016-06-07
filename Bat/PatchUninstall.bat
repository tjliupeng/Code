@echo off
REM this script is working at the _uninstall directory in the HP SM Server install directory
echo.
echo Hewlett Packard Enterprise Software...
echo Begin to uninstall Service Manager Server Patch...
echo Some configuration files (such as lwssofmconf.xml and udp.xml) will be overwritten by files from the prior patch. If you have made any changes to these files, remember to update the new versions accordingly after the patch uninstall process is completed.
echo.
echo.
setlocal enableextensions

set smmajorversion=9
set smleastminorversion=4
set smpatchversion=4x
set currentworkingdir=%~dp0
set logfile="%currentworkingdir%PatchUninstall.log"

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

REM set /p sminstalldir="Full path of current SM Server installation directory:"

REM if "[%sminstalldir%]" equ "[]" (
REM	set errorMsg=Please provide current SM Server installation directory.
REM	goto error_end
REM )
cd /d ..

set sminstalldir=%cd%

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
	set smcompleterversion=%smcurrentversion%_%smcurrentpatchlevel%
)
echo.
@echo The current SM Server is %smcompleterversion%.

del smversion.txt

REM @echo "Stop SM Server..."
REM sm.exe -shutdown
REM net stop sm%smmajorversion%%smleastminorversion%service

:revert_patch
IF %smbackupdir:~-1%==\ SET smbackupdir=%smbackupdir:~0,-1%

if not exist "%smbackupdir%" (
	set errorMsg="SM Server backup directory %smbackupdir% does not exist."
	goto error_end
)

cd /d "%smbackupdir%"

@setlocal EnableDelayedExpansion
set cnt=0
for /f "tokens=*" %%g in ( ' dir /B /A:D ' ) do (	
	if exist "%%g\SMPatchDiff" (
		set /a cnt+=1
		set backupversion[!cnt!]=%%g		
	)
)

IF %cnt% EQU 0 (
	echo.
	echo No backup version in "%smbackupdir%".
	goto end
)

echo.
echo Existing backup versions of the SM Server:
set printind=0
for /L %%a in (1,1,!cnt!) do (
	set printversion=%%a. !backupversion[%%a]!
	@echo !printversion!
)

echo.
set /p selectindex="Select the version you want to restore:"

if "[%selectindex%]" equ "[]" (
	set errorMsg=Please select the restore version.
	goto error_end
)

set /a selectindex_val=%selectindex%

if %selectindex_val% EQU %selectindex% (
	IF %selectindex_val% LSS 1 (
		set errorMsg=Invalid restore option. The option should be greater than 0.
		goto error_end		
	) else (
		IF %selectindex_val% GTR !cnt! (
			set errorMsg=Invalid restore option. The option is out of range.
			goto error_end
		)
	)	
) else (
	set errorMsg=Invalid restore option.
	goto error_end
)

REM set /a selectindex_val-=1

set selectedversion=""
call :Trim selectedversion !backupversion[%selectindex_val%]!

@setlocal DisableDelayedExpansion 
echo.
set /p backoutanswer="Are you sure you want to back out the SM Server and revert to the backup of version %selectedversion%?(Y/N)"

if /i %backoutanswer% equ Y (
	echo.
	echo The restore process may take several minutes...
	cd /d "%sminstalldir%"
	@echo Remove platform_unloads. >%logfile%
	rmdir /S /Q "platform_unloads" >>%logfile% 2>&1
	if exist "platform_unloads" (
		set errorMsg=Failed to restore the SM server. Please check the log file %logfile% for error information. This failure may prevent the SM server from starting. Please retry the restore process to ensure a successful uninstall. 
		goto error_end
	)
	cd /d %sminstallrundir%
	@echo Remove jre, lib and tomcat. >>%logfile%
	rmdir /S /Q "jre" >>%logfile% 2>&1
	REM for rmdir, %ERRORLEVEL% is alway 0 no matter the command can be executed successfully
	if exist "jre" (
		set errorMsg=Failed to restore the SM server. Please check the log file %logfile% for error information. This failure may prevent the SM server from starting. Please retry the restore process to ensure a successful uninstall. 
		goto error_end
	)
	rmdir /S /Q "lib" >>%logfile% 2>&1
	if exist "lib" (
		set errorMsg=Failed to restore the SM server. Please check the log file %logfile% for error information. This failure may prevent the SM server from starting. Please retry the restore process to ensure a successful uninstall. 
		goto error_end
	)
	rmdir /S /Q "tomcat" >>%logfile% 2>&1
	if exist "tomcat" (
		set errorMsg=Failed to restore the SM server. Please check the log file %logfile% for error information. This failure may prevent the SM server from starting. Please retry the restore process to ensure a successful uninstall. 
		goto error_end
	)

	cd /d "%smbackupdir%"
	@echo Restoring the SM Server... >>%logfile%
	xcopy /e /Y "%selectedversion%" "%sminstalldir%" >>%logfile% 2>&1

	if %ERRORLEVEL% GTR 0 (
		set errorMsg=Failed to restore the SM server. Please check the log file %logfile% for error information. This failure may prevent the SM server from starting. Please retry the restore process to ensure a successful uninstall. 
		goto error_end
	)
	
	call :display_sm_version
	
	cd /d "%sminstalldir%"
	del /Q SMPatchDiff >NUL 2>&1
	echo.
	echo Finished restoring the SM Server Patch.
	goto end
	
) else (
	if /i %backoutanswer% equ N (
		@echo Backout cancelled.
		goto end
	) else (
		set  errorMsg=Invalid backout Option. Give up the backout.
		goto error_end
	)
)

:error_end
@setlocal DisableDelayedExpansion 
echo.
@echo %errorMsg%

goto end

:end
echo.
if defined sminstalldir (
	cd /d "%sminstalldir%"
)

pause>nul|set/p = "Press any key to exit."

@endlocal
EXIT /B %ERRORLEVEL%

:Trim
SetLocal EnableDelayedExpansion
set Params=%*
for /f "tokens=1*" %%a in ("!Params!") do EndLocal & set %1=%%b
exit /b

:display_sm_version
cd /d "%sminstallrundir%"
sm.exe -version > smversion.txt 2<&1

if not exist smversion.txt (
	set errorMsg=fail to get Service Manager server version information.
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
	set smcompleterversion=%smcurrentversion%
) else (
	set smcompleterversion=%smcurrentversion%_%smcurrentpatchlevel%
)

del smversion.txt

echo.
@echo The new SM Server version is %smcompleterversion%.

cd /d %currentworkingdir%

exit /B 0