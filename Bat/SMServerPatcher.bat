@echo off

echo Hewlett Packard Enterprise Software...
echo ITOM Service Manager Server Patch Installer/UnInstaller...

setlocal enableextensions

set smmajorversion=9
set smleastminorversion=4
set smpatchversion=4x
set currentworkingdir=%~dp0


@echo Please enter full path of current SM Server installation directory:
set /p sminstalldir=""

if "[%sminstalldir%]" equ "[]" (
	set errorMsg=Please provide current SM Server installation directory!
	goto error_end
)

@echo Please enter full path of SM Server backup directory:
set /p smbackupdir=""

if "[%smbackupdir%]" equ "[]" (
	set errorMsg=Please provide  SM Server backup directory!
	goto error_end
)

cd /d %currentworkingdir%

set sminstallrundir="%sminstalldir%\RUN"

if not exist %sminstallrundir% (
	set errorMsg=%sminstallrundir% does not exist!
	goto error_end
)

cd /d %sminstallrundir%

if not exist sm.exe (
	set errorMsg=sm.exe does not exit!
	goto error_end
)

REM get installed sm version
sm.exe -version > smversion.txt 2<&1

if not exist smversion.txt (
	set errorMsg=fail to get Service Manager server version information!
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
set smcompleterversion=%smcurrentversion%_%smcurrentpatchlevel%
@echo "current SM Server is %smcompleterversion%."

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

@echo Please select SM Server patch option:
@echo 1)Apply Patch
@echo 2)Backout Patch
@echo 3)Exit
set /p sminstalloption=""

if [%sminstalloption%] equ [] (
	@echo "No option is selected."
	goto end
)

if %sminstalloption% equ 1 (
	goto apply_patch
) else (
	if %sminstalloption% equ 2 (
		goto revert_patch
	) else (
		if %sminstalloption% equ 3 (
			goto end
		) else (
			set  errorMsg="Invalid Option!"
			goto error_end
		)
	)
)

REM @echo "Stop SM Server..."
REM sm.exe -shutdown
REM net stop sm%smmajorversion%%smleastminorversion%service

tasklist /FI "IMAGENAME eq Scenter.exe" 2>NUL | find /I /N "Scenter.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set errorMsg="SM Legacy Scenter is still running, please stop it!"
	goto error_end
)

tasklist /FI "IMAGENAME eq sm.exe" 2>NUL | find /I /N "sm.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set errorMsg="SM Server is still running, please stop it!"
	goto error_end
)

tasklist /FI "IMAGENAME eq smservice.exe" 2>NUL | find /I /N "smservice.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set errorMsg="SM Server Service is still running, please stop it!"
	goto error_end
)

:apply_patch

@echo Please enter the directory of SM Server patch you will apply:
@echo Default is %currentworkingdir%
set /p smnewpatchdir=""

if "[%smnewpatchdir%]" equ "[]" (
	set smnewpatchdir=%currentworkingdir%
)

if not exist %smbackupdir% (
	mkdir %smbackupdir%
)

for /f "tokens=1-3 delims=." %%a in ( "%smcompleterversion%" ) do (
set smminorversion=%%b
)

if %smminorversion% lss %smleastminorversion% (
	set errorMsg="Current SM Server is %smcompleterversion%, can not apply %smmajorversion%.%smpatchversion% patch!"
	goto error_end
)

@echo "Backup current SM Server..."

cd /d %currentworkingdir%

@echo _jvm>exclulist.txt
@echo _uninstall>>exclulist.txt
@echo logs>>exclulist.txt
@echo .log>>exclulist.txt

IF %sminstalldir:~-1%==\ SET sminstalldir=%sminstalldir:~0,-1%

xcopy /s /i /EXCLUDE:exclulist.txt "%sminstalldir%" %smcompleterversion%

REM remove sc.ini for legacy scenter
if exist "%smcompleterversion%\legacyintegration\RUN\sc.ini" (
	del "%smcompleterversion%\legacyintegration\RUN\sc.ini"
)

REM remove sm.ini, sm.cfg, LicFile.txt and scemail.chk which don't need to backup
if exist %smcompleterversion%\RUN\sm.ini (
	del %smcompleterversion%\RUN\sm.ini
)

if exist %smcompleterversion%\RUN\sm.cfg (
	del %smcompleterversion%\RUN\sm.cfg
)

if exist %smcompleterversion%\RUN\LicFile.txt (
	del %smcompleterversion%\RUN\LicFile.txt
)

if exist %smcompleterversion%\RUN\scemail.chk (
	del %smcompleterversion%\RUN\scemail.chk
)

cd /d %currentworkingdir%

@echo Begin to compress the current SM Server package...
.\bin\zip.exe -r %smcompleterversion%.zip "%smcompleterversion%" -D -x \\*.log

move %smcompleterversion%.zip %smbackupdir%

rmdir /S /Q %smcompleterversion%

@echo Applying SM Server Patch...

cd /d %sminstallrundir%

rmdir /S /Q "jre"
rmdir /S /Q "lib"
rmdir /S /Q "tomcat"

cd /d %currentworkingdir%

@echo %~nx0>exclulist.txt
@echo exclulist.txt>>exclulist.txt

REM remove the trailing back slash, because xcopy command requires
IF %smnewpatchdir:~-1%==\ SET smnewpatchdir=%smnewpatchdir:~0,-1%

xcopy /s /e /Y /EXCLUDE:exclulist.txt "%smnewpatchdir%" "%sminstalldir%"

del exclulist.txt

call :display_sm_version

@echo Apply SM Server Patch finished.

goto end

:revert_patch
IF %smbackupdir:~-1%==\ SET smbackupdir=%smbackupdir:~0,-1%

if not exist %smbackupdir% (
	set errorMsg="SM Server backup directory %smbackupdir% does not exist!"
	goto error_end
)

cd /d %smbackupdir%

IF NOT EXIST "%smmajorversion%.%smleastminorversion%*.zip" (
	echo No backup version in %smbackupdir%
	goto end
)

echo The backup versions for your SM Server are as follow:
@setlocal EnableDelayedExpansion
set cnt=0
for /f "tokens=*" %%g in ( ' dir /B /O N %smmajorversion%.%smleastminorversion%*.zip ' ) do (
	set backupversion[!cnt!]=%%~ng
	set /a cnt+=1
	set version=%%~ng
	set printversion=!cnt!^)!version!
	@echo !printversion!
)

echo Please select the version you want to backout:

set /p selectindex=""
if "[%selectindex%]" equ "[]" (
	set errorMsg=Please select the backout version!
	goto error_end
)

set /a selectindex_val=%selectindex%

if %selectindex_val% EQU %selectindex% (
	IF %selectindex_val% LEQ 0 (
		set errorMsg=Invalid backout option. The option should be greater than 0.
		goto error_end		
	) else (
		IF %selectindex_val% GTR !cnt! (
			set errorMsg=Invalid backout option! The option is out of range.
			goto error_end
		)
	)	
) else (
	set errorMsg=Invalid backout option.
	goto error_end
)

set /a selectindex_val-=1

echo Are you sure to backout the version !backupversion[%selectindex_val%]!(Y/N)?

set /p backoutanswer=""

if /i %backoutanswer% equ Y (
	cd /d %currentworkingdir%

	.\bin\unzip.exe !smbackupdir!\!backupversion[%selectindex_val%]!

	cd /d %sminstallrundir%

	rmdir /S /Q "jre"
	rmdir /S /Q "lib"
	rmdir /S /Q "tomcat"

	cd /d %currentworkingdir%

	xcopy /s /e /Y "!backupversion[%selectindex_val%]!" "%sminstalldir%"

	rmdir /S /Q "!backupversion[%selectindex_val%]!"

	call :display_sm_version
	
	echo Backout to !backupversion[%selectindex_val%]! finished.
	
	goto end
	
) else (
	if /i %backoutanswer% equ N (
		@echo Give up the backout!
		goto end
	) else (
		set  errorMsg=Invalid backout Option. Give up the backout.
		goto error_end
	)
)

:error_end
@setlocal DisableDelayedExpansion 
@echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
@echo %errorMsg%
@echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
goto end

:end
@echo Exting...
cd /d %currentworkingdir%
@endlocal
EXIT /B %ERRORLEVEL%

:display_sm_version
cd /d %sminstallrundir%
sm.exe -version > smversion.txt 2<&1

if not exist smversion.txt (
	set errorMsg=fail to get Service Manager server version information!
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

set smcompleterversion=%smcurrentversion%_%smcurrentpatchlevel%

del smversion.txt

@echo The new SM Server version is %smcompleterversion%.

cd /d %currentworkingdir%

exit /B 0