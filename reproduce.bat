@echo off
setlocal
:: Wiperdog Service Startup Script for Windows

:: determine the home

set INSTALL_DIR=%~dp0
SET INSTALL_TERRACOTTA="FALSE"
SET INSTALL_WIPERDOG="FALSE"
SET WITH_JOB_MANAGER="FALSE"
SET RUN_WIPERDOG="FALSE"

::for %%i in (""%INSTALL_DIR%"") do set INSTALL_DIR=%%~fsi
for %%i IN (%*) DO (
	if "%%i"=="/h" goto help
	if "%%i"=="/it" SET INSTALL_TERRACOTTA="TRUE"
	if "%%i"=="/iw" SET INSTALL_WIPERDOG="TRUE"
	if "%%i"=="/rw" SET RUN_WIPERDOG="TRUE"
	if "%%i"=="/wjm" SET WITH_JOB_MANAGER="TRUE"
)

if %INSTALL_TERRACOTTA%=="TRUE" (
	echo "INSTALL TERRACOTTA PROCESS..."
	:: unzip and start terracotta server
	"%JAVA_HOME%\..\bin\jar" -xf bigmemory-max-4.1.0.zip
	REM xcopy tmp\terracotta-license.key bigmemory-max-4.1.0 /Y
	cd "%INSTALL_DIR%"/bigmemory-max-4.1.0/server/bin
	set JAVA_OPTS=-Xmx1g
	start call start-tc-server.bat
	echo "When terracotta server is started successfully, press any key..."
	pause>null
)

if %INSTALL_WIPERDOG%=="TRUE" (
	echo "INSTALL WIPERDOG PROCESS"
	:: Getting wiperdog from maven
	echo "Getting wiperdog from maven. It could takes minutes..."
	echo "When maven is done, press any key..."
	cd "%INSTALL_DIR%"
	start call mvn org.apache.maven.plugins:maven-dependency-plugin:2.4:get -Dartifact=org.wiperdog:wiperdog-assembly:0.2.4:jar:win -Ddest="%INSTALL_DIR%/wiperdog-assembly.jar" -Dmdep.useBaseVersion=true
	pause>null
	
	java -jar "%INSTALL_DIR%/wiperdog-assembly.jar" -d "%INSTALL_DIR%wiperdog" -j 13111 -m "localhost" -p 27017 -n "wiperdog" -mp "" -s no
)
cd "%INSTALL_DIR%"
if %WITH_JOB_MANAGER%=="TRUE" (
	echo "WITH JOB MANAGER"
	ren "%INSTALL_DIR%"\\wiperdog\\bin\\ListBundle.csv ListBundle.csv_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\ListBundle.csv wiperdog\\bin /Y
	ren "%INSTALL_DIR%"\\wiperdog\\etc\\boot.groovy boot.groovy_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\boot.groovy wiperdog\\etc /Y
	ren "%INSTALL_DIR%"\\wiperdog\\bin\\startGroovy.bat startGroovy.bat_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\startGroovy.bat wiperdog\\bin /Y
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\job1.job wiperdog\\var\\job /Y
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\job1.trg wiperdog\\var\\job /Y
	ren "%INSTALL_DIR%"\\wiperdog\\lib\\groovy\\libs.common\\JobLoader.groovy JobLoader.groovy_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\JobLoader.groovy wiperdog\\lib\\groovy\\libs.common /Y
	ren "%INSTALL_DIR%"\\wiperdog\\lib\\groovy\\libs.target\\GroovyScheduledJob.groovy GroovyScheduledJob.groovy_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\GroovyScheduledJob.groovy wiperdog\\lib\\groovy\\libs.target /Y
	ren "%INSTALL_DIR%"\\wiperdog\\lib\\groovy\\libs.target\\JobDsl.groovy JobDsl.groovy_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\JobDsl.groovy wiperdog\\lib\\groovy\\libs.target /Y
	ren "%INSTALL_DIR%"\\wiperdog\\lib\\groovy\\libs.target\\DefaultSender.groovy DefaultSender.groovy_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\DefaultSender.groovy wiperdog\\lib\\groovy\\libs.target /Y
	ren "%INSTALL_DIR%"\\wiperdog\\lib\\groovy\\libs.common\\MonitorJobConfigLoader.groovy MonitorJobConfigLoader.groovy_bak
	xcopy "%INSTALL_DIR%"\tmp\withJobManager\MonitorJobConfigLoader.groovy wiperdog\\lib\\groovy\\libs.common /Y
)
if %INSTALL_WIPERDOG%=="TRUE" (
	if %WITH_JOB_MANAGER%=="FALSE" (
		echo "NO JOB MANAGER"
		ren "%INSTALL_DIR%"\\wiperdog\\etc\\boot.groovy boot.groovy_bakNOJOBMANAGER
		xcopy "%INSTALL_DIR%"\tmp\boot.groovy wiperdog\\etc /Y
		xcopy "%INSTALL_DIR%"\tmp\Terracotta_Prototype.groovy wiperdog\\lib\\groovy\\libs.common /Y
		ren "%INSTALL_DIR%"\\wiperdog\\bin\\startGroovy.bat startGroovy.bat_bakNOJOBMANAGER
		xcopy "%INSTALL_DIR%"\tmp\startGroovy.bat wiperdog\\bin /Y
		xcopy "%INSTALL_DIR%"\tmp\quartz-ee-2.2.1.jar wiperdog\\lib\\java\\bundle /Y
		xcopy "%INSTALL_DIR%"\tmp\slf4j-api_1.6.2.jar wiperdog\\lib\\java\\bundle /Y
		xcopy "%INSTALL_DIR%"\tmp\slf4j-jcl_1.6.2.jar wiperdog\\lib\\java\\bundle /Y
		xcopy "%INSTALL_DIR%"\tmp\slf4j-log4j12_1.6.2.jar wiperdog\\lib\\java\\bundle /Y
		ren "%INSTALL_DIR%"\\wiperdog\\bin\\ListBundle.csv ListBundle.csv_bakNOJOBMANAGER
		xcopy "%INSTALL_DIR%"\tmp\ListBundle.csv wiperdog\\bin /Y
	)
)

if %RUN_WIPERDOG%=="TRUE" (
	xcopy "%INSTALL_DIR%"\tmp\terracotta-license.key wiperdog\\var\\conf /Y
	xcopy "%INSTALL_DIR%"\tmp\terracotta.properties wiperdog\\var\\conf /Y
	xcopy "%INSTALL_DIR%"\tmp\terracotta-toolkit-runtime-ee-4.1.0.jar wiperdog\\lib\\java\\bundle.wrap /Y
	"%INSTALL_DIR%wiperdog\\bin\\startwiperdog.bat"
)

:help
echo This is a reproduce error script.
echo Note that you must set JAVA_HOME at jre first and your computer has maven already
echo There are two cases.
echo Try to reproduce each case in separated folder because we create backup file for each case so you can compare it easily
echo - Case 1: With JobManager bundle
echo -  Connect successfully to Terracotta server
echo -  Wiperdog start successfully but doesn't execute job
echo -  Read log file for [java.lang.RuntimeException: 
echo -               java.lang.ClassNotFoundException: org.terracotta.quartz.wrappers.JobWrapper]
echo ------------------------------------------------
echo - Case 2: Without JobManager bundle
echo -  Connect successfully to Terracotta server
echo -  Using groovy script wiperdog/lib/groovy/libs.common/Terracotta_Prototype.groovy
echo -    to create and get Quartz's Scheduler and execute a simple job
echo -  Encounter MissingMethodException but actually the root cause is ClassLoader itself
echo ------------------------------------------------
echo Usage: reproduce.bat options
echo options should be:
echo /h : Open help
echo "/it : Install and run terracotta. If encouter java heap space error, go to bigmemory-max-4.1.0/server/bin/start-tc-server.bat and modify JAVA_OPTS option to < 1g".
echo /iw : Get wiperdog from maven and install it without JobManager bundle.
echo /iw /wjm : Get wiperdog from maven and install it with JobManger bundle.
echo /rw : Run wiperdog if it exists
echo Example:
echo "reproduce.bat /it /iw /rw -> Install Terracotta, install wiperdog without JobManager bundle, run wiperdog"
echo "reproduce.bat /it /iw /wjm /rw -> Install Terracotta, install wiperdog with JobManager bundle, run wiperdog"
echo "reproduce.bat /it /iw /wjm -> Install Terracotta, install wiperdog with JobManager bundle, run wiperdog manually"
echo "reproduce.bat /iw /wjm -> Install wiperdog with JobManager bundle, run wiperdog manually"




