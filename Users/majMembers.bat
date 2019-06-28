@echo off

rem The account that is used to login the server and call Members REST services. 
set USER=cedric.ferchal
set PASSWORD=cedric.ferchal

rem The context root of Jazz Team Server.
set CONTEXT_ROOT=https://owrcap10:9443/jts

rem The input file that defines the memberships.
set INPUT_FILE=majMembers.csv

rem Three temporary files. 
set COOKIES=%cd%\cookies.txt
set SINGLE_RECORD_FILE=singleRecord.csv
set POST_BODY_FILE=postBody.xml

rem Connect server
echo Connecting...
D:\Applications\curl\bin\curl -k -c %COOKIES% "%CONTEXT_ROOT%/authenticated/identity"
D:\Applications\curl\bin\curl -k -L -b %COOKIES% -c %COOKIES% -d j_username=%USER% -d j_password=%PASSWORD% "%CONTEXT_ROOT%/authenticated/j_security_check"

rem 1. Read the csv file
rem 2. Create post body
rem 3. Add members using curl (POST)
echo Adding members...
setlocal enabledelayedexpansion 
for /f "tokens=1,2* delims=," %%a in (%INPUT_FILE%) do (
	set USER_ID=%%a
	set PROCESS_AREA_URL=%%b
	set ROLES=%%c
	
	set SERVICE_URL=!PROCESS_AREA_URL!/members

	rem Contruct post body xml file
	echo ^<?xml version="1.0" encoding="UTF-8"?^> > %POST_BODY_FILE%
	echo ^<jp06:members xmlns:jp06="http://jazz.net/xmlns/prod/jazz/process/0.6/"^> >> %POST_BODY_FILE%
	echo ^<jp06:member^> >> %POST_BODY_FILE%
	echo ^<jp06:user-url^>%CONTEXT_ROOT%/users/!USER_ID!^</jp06:user-url^> >> %POST_BODY_FILE%
	rem Contruct role assignments sections
	echo ^<jp06:role-assignments^> >> %POST_BODY_FILE%
	for %%i in (!ROLES!) do (
		echo ^<jp06:role-assignment^> >> %POST_BODY_FILE%
		echo ^<jp06:role-url^>%%i^</jp06:role-url^> >> %POST_BODY_FILE%
		echo ^</jp06:role-assignment^> >> %POST_BODY_FILE%
	)
	echo ^</jp06:role-assignments^> >> %POST_BODY_FILE%
	echo ^</jp06:member^> >> %POST_BODY_FILE%
	echo ^</jp06:members^> >> %POST_BODY_FILE%
	
	rem POST to the service url
	curl -D - -k -b %COOKIES% -H "Content-Type: application/xml" -X POST --data-binary @%POST_BODY_FILE% !SERVICE_URL!
)
endlocal
echo Ended adding members!
