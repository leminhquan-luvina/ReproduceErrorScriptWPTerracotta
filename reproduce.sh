self="$0"
while [ -h "$self" ]; do
	res=`ls -ld "$self"`
	ref=`expr "$res" : '.*-> \(.*\)$'`
	if expr "$ref" : '/.*' > /dev/null; then
		self="$ref"
	else
		self="`dirname \"$self\"`/$ref"
	fi
done

dir=`dirname "$self"`
CUR_DIR=`cd "$dir/" && pwd`

echo $CUR_DIR
echo This is leminhquan speaking

function usage
(
        echo There are 2 cases
        echo Try to reproduce each case in separated folder
        echo Try to reproduce each case in separated folder because we create backup file for each case so you can compare it easily
        echo - Case 1: With JobManager bundle
        echo -  Connect successfully to Terracotta server
        echo -  "Wiperdog start successfully but doesn't execute job"
        echo -  Read log file for [java.lang.RuntimeException:
        echo -               java.lang.ClassNotFoundException: org.terracotta.quartz.wrappers.JobWrapper]
        echo ------------------------------------------------
        echo - Case 2: Without JobManager bundle
        echo -  Connect successfully to Terracotta server
        echo -  Using groovy script wiperdog/lib/groovy/libs.common/Terracotta_Prototype.groovy
        echo -    to create and get Quartz\'s Scheduler and execute a simple job
        echo -  Encounter MissingMethodException but actually the root cause is ClassLoader itself
        echo ------------------------------------------------
        echo Usage: reproduce.bat options
        echo options should be:
        echo /h : Open help
        echo /it : Install and run terracotta. If encouter java heap space error, go to bigmemory-max-4.1.0\server\bin\start-tc-server.bat and modify JAVA_OPTS option to < 1g.
        echo /iw : Get wiperdog from maven and install it without JobManager bundle.
        echo /iw /wjm : Get wiperdog from maven and install it with JobManger bundle.
        echo /rw : Run wiperdog if it exists
        echo Example:
        echo "reproduce.bat /it /iw /rw -> Install Terracotta, install wiperdog without JobManager bundle, run wiperdog"
        echo "reproduce.bat /it /iw /wjm /rw -> Install Terracotta, install wiperdog with JobManager bundle, run wiperdog"
        echo "reproduce.bat /it /iw /wjm -> Install Terracotta, install wiperdog with JobManager bundle, run wiperdog manually"
        echo "reproduce.bat /iw /wjm -> Install wiperdog with JobManager bundle, run wiperdog manually"
)

# Default value of variables
INSTALL_TERRACOTTA="FALSE"
INSTALL_WIPERDOG="FALSE"
WITH_JOB_MANAGER="FALSE"
RUN_WIPERDOG="FALSE"

# Get input parameters
while [ "$1" != "" ]; do
	case $1 in 
		/it) INSTALL_TERRACOTTA="TRUE"
		;;
		/iw) INSTALL_WIPERDOG="TRUE"
		;;
		/rw) RUN_WIPERDOG="TRUE"
		;;
		/wjm) WITH_JOB_MANAGER="TRUE"
		;;
		/h | /help)	usage
				exit
		;;
		* )	usage
			exit 1
	esac
	shift
done

# INSTALL TERRACOTTA
if [ $INSTALL_TERRACOTTA = "TRUE" ]; then
	echo "INSTALL TERRACOTTA"
	unzip bigmemory-max-4.1.0.zip
	chmod 755 bigmemory-max-4.1.0/server/bin/start-tc-server.sh
	echo 'bigmemory-max-4.1.0/server/bin/start-tc-server.sh' > startTerracottaServer.sh
	chmod +x startTerracottaServer.sh
	gnome-terminal -x ./startTerracottaServer.sh
fi

# GET AND INSTALL WIPERDOG FROM MAVEN
if [ $INSTALL_WIPERDOG = "TRUE" ]; then
	echo "INSTALL WIPERDOG"
	mvn org.apache.maven.plugins:maven-dependency-plugin:2.4:get -Dartifact=org.wiperdog:wiperdog-assembly:0.2.4:jar:unix -Ddest=$CUR_DIR/wiperdog-assembly.jar -Dmdep.useBaseVersion=true
	java -jar wiperdog-assembly.jar -d $CUR_DIR/wiperdog -j 13111 -m "localhost" -p 27017 -n "wiperdog" -mp "" -s no

	dos2unix wiperdog/bin/*	

	# license key and config of terracotta 
	cp tmp/terracotta-license.key wiperdog/var/conf/terracotta-license.key
	cp tmp/terracotta.properties wiperdog/var/conf/terracotta.properties
	cp tmp/terracotta-toolkit-runtime-ee-4.1.0.jar wiperdog/lib/java/bundle.wrap/terracotta-toolkit-runtime-ee-4.1.0.jar
	
	# INSTALL WIPERDOG WITHOUT JOB MANAGER
	if [ $WITH_JOB_MANAGER = "FALSE" ]; then
		echo "NO JOB MANAGER"
		mv wiperdog/etc/boot.groovy wiperdog/etc/boot.groovy_bakNOJOBMANGER
		cp tmp/boot.groovy wiperdog/etc/boot.groovy
		cp tmp/Terracotta_Prototype.groovy wiperdog/lib/groovy/libs.common/Terracotta_Prototype.groovy
		mv wiperdog/bin/startGroovy wiperdog/bin/startGroovy_bakNOJOBMANAGER
		cp tmp/startGroovy wiperdog/bin/startGroovy
		cp tmp/quartz-ee-2.2.1.jar wiperdog/lib/java/bundle/quartz-ee-2.2.1.jar
		cp tmp/slf4j-api_1.6.2.jar wiperdog/lib/java/bundle/slf4j-api_1.6.2.jar
		cp tmp/slf4j-jcl_1.6.2.jar wiperdog/lib/java/bundle/slf4j-jcl_1.6.2.jar
		cp tmp/slf4j-log4j12_1.6.2.jar wiperdog/lib/java/bundle/slf4j-log4j12_1.6.2.jar
		mv wiperdog/bin/ListBundle.csv wiperdog/bin/ListBundle.csv_bakNOJOBMANAGER
		cp tmp/ListBundle.csv wiperdog/bin/ListBundle.csv
	fi
	# INSTALL WIPERDOG WITH JOB MANAGER
	if [ $WITH_JOB_MANAGER = "TRUE" ]; then
		echo "WITH JOB MANAGER"
		mv wiperdog/bin/ListBundle.csv wiperdog/bin/ListBundle.csv_bak
		cp tmp/withJobManager/ListBundle.csv wiperdog/bin/ListBundle.csv
		mv wiperdog/etc/boot.groovy wiperdog/etc/boot.groovy_bak
		cp tmp/withJobManager/boot.groovy wiperdog/etc/boot.groovy
		mv wiperdog/bin/startGroovy wiperdog/bin/startGroovy_bak
		cp tmp/withJobManager/startGroovy wiperdog/bin/startGroovy
		cp tmp/withJobManager/job1.job wiperdog/var/job/job1.job
		cp tmp/withJobManager/job1.trg wiperdog/var/job/job1.trg
		mv wiperdog/lib/groovy/libs.common/JobLoader.groovy wiperdog/lib/groovy/libs.common/JobLoader.groovy_bak
		cp tmp/withJobManager/JobLoader.groovy wiperdog/lib/groovy/libs.common/JobLoader.groovy
		mv wiperdog/lib/groovy/libs.target/GroovyScheduledJob.groovy wiperdog/lib/groovy/libs.target/GroovyScheduledJob.groovy_bak
		cp tmp/withJobManager/GroovyScheduledJob.groovy wiperdog/lib/groovy/libs.target/GroovyScheduledJob.groovy
		mv wiperdog/lib/groovy/libs.target/JobDsl.groovy wiperdog/lib/groovy/libs.target/JobDsl.groovy_bak
		cp tmp/withJobManager/JobDsl.groovy wiperdog/lib/groovy/libs.target/JobDsl.groovy
		mv wiperdog/lib/groovy/libs.target/DefaultSender.groovy wiperdog/lib/groovy/libs.target/DefaultSender.groovy_bak
		cp tmp/withJobManager/DefaultSender.groovy wiperdog/lib/groovy/libs.target/DefaultSender.groovy
		mv wiperdog/lib/groovy/libs.common/MonitorJobConfigLoader.groovy wiperdog/lib/groovy/libs.common/MonitorJobConfigLoader.groovy_bak
		cp tmp/withJobManager/MonitorJobConfigLoader.groovy wiperdog/lib/groovy/libs.common/MonitorJobConfigLoader.groovy
	fi
fi

# START WIPERDOG
if [ $RUN_WIPERDOG = "TRUE" ]; then
	echo "RUN WIPERDOG"
	./wiperdog/bin/startWiperdog.sh
fi
