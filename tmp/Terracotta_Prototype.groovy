import org.quartz.JobBuilder;
import org.quartz.JobDataMap;
import org.quartz.JobDetail;
import org.quartz.JobKey
import org.quartz.Scheduler;
import org.quartz.SchedulerFactory;
import org.quartz.SimpleTrigger;
import org.quartz.Trigger
import org.quartz.TriggerBuilder;
import org.quartz.DateBuilder.IntervalUnit;

import java.util.HashSet
import java.util.Properties

import org.quartz.impl.StdSchedulerFactory
import org.quartz.impl.DirectSchedulerFactory
import org.quartz.spi.ThreadPool
import org.quartz.spi.JobStore
import org.quartz.Job

import static org.quartz.DateBuilder.futureDate;
import static org.quartz.JobBuilder.newJob;
import static org.quartz.SimpleScheduleBuilder.simpleSchedule;
import static org.quartz.TriggerBuilder.newTrigger;

class Terracotta_Prototype{
	def context
	def rootloader
	
	def Terracotta_Prototype(rootloader1){
		try{
			rootloader = rootloader1
			println rootloader
			println rootloader.class.getName()
			// this.context = ctx
			// println "context:" + context + "-" + context.class
			
			// println "Service :" + context.getAllServiceReferences(null, null)
			println "----------------------------------------------"
			println "----------Terracotta + OGSI + Groovy----------"
			println "----------------------------------------------"
			final String JOB = "JOB"
			final String FETCHACTION = "FETCHACTION"
			
			// ------Init Quarzt scheduler with config file------
			// SchedulerFactory sf = new StdSchedulerFactory();
			// def sched = sf.getScheduler()
			// ------/Init Quarzt scheduler with config file------
			
			// --Misc test--
			// SchedulerFactory sf = new DirectSchedulerFactory()
			// def sf = new DirectSchedulerFactory()
			// def sf = rootloader.loadClass("org.quartz.impl.DirectSchedulerFactory").newInstance()
			// def jobStore = rootloader.loadClass("org.terracotta.quartz.TerracottaJobStore").newInstance()// as JobStore
			// jobStore.setTcConfigUrl("10.0.1.153:9510")
			// jobStore.setMisfireThreshold(60000) 
			// def sf = rootloader.loadClass("org.quartz.impl.StdSchedulerFactory").newInstance()
			// --/Misc test--
			
			// ------Init Quarzt scheduler programmatically------
			def sf = new StdSchedulerFactory()
			def schedProp = new Properties()
			schedProp.setProperty("org.quartz.scheduler.instanceName", "TestScheduler") 
			schedProp.setProperty("org.quartz.scheduler.instanceId", "groovy_instance") 
			schedProp.setProperty("org.quartz.scheduler.skipUpdateCheck", "true") 
			schedProp.setProperty("org.quartz.threadPool.class", "org.quartz.simpl.SimpleThreadPool") 
			schedProp.setProperty("org.quartz.threadPool.threadCount", "1") 
			schedProp.setProperty("org.quartz.threadPool.threadPriority", "5") 
			schedProp.setProperty("org.quartz.jobStore.misfireThreshold", "60000") 
			schedProp.setProperty("org.quartz.jobStore.class", "org.terracotta.quartz.TerracottaJobStore") 
			schedProp.setProperty("org.quartz.jobStore.tcConfigUrl", "localhost:9510") 
			// schedProp.setProperty("org.quartz.scheduler.classLoadHelper.class", "org.quartz.simpl.ThreadContextClassLoadHelper") 
			// schedProp.setProperty("org.quartz.scheduler.classLoadHelper.class", "org.quartz.simpl.InitThreadContextClassLoadHelper") 
			schedProp.setProperty("org.quartz.scheduler.classLoadHelper.class", "org.quartz.simpl.LoadingLoaderClassLoadHelper") 
			sf.initialize(schedProp) 
			def sched = sf.getScheduler()
			// ------/Init Quarzt scheduler programmatically------
						
			String jobName = "job1"
			def jobDetail = createJob(jobName)
			def trigger = createTrigger(jobDetail)
			sched.scheduleJob(jobDetail, trigger)
			// sched.scheduleJob(trigger)
			// sched.addJob(jobDetail, true)
			
			println "--Start scheduler--"
			sched.start();
		} catch(Exception ex){
			// println ex
			ex.printStackTrace();
		}
	}
	
	def createJob(jobName){
		// ----Using current threadClassLoader----
		// def jobDetail = JobBuilder.newJob(AJob.class).withIdentity(jobName).storeDurably(true).build()
		// ----/Using current threadClassLoader----
		
		// ----Using RootLoader----
		def jobItf = rootloader.loadClass("org.quartz.Job")
		def jobClass = rootloader.loadClass("AJob").asType(jobItf)
		
		def jobDetail = rootloader.loadClass("org.quartz.JobBuilder").newJob(jobClass.class).withIdentity(jobName).storeDurably(true).build()
		// ----/Using RootLoader----
		return jobDetail
	}
	
	def createTrigger(jobDetail){
		// ----Using current threadClassLoader----
		// def trigger = TriggerBuilder.newTrigger().forJob(jobDetail).startNow()
									// .withSchedule(simpleSchedule().repeatForever().withIntervalInSeconds(10)).build();
		// ----/Using current threadClassLoader----
		
		// ----Using RootLoader----
		def simpleSchedulerCls = rootloader.loadClass("org.quartz.SimpleScheduleBuilder").newInstance()
		def trigger = rootloader.loadClass("org.quartz.TriggerBuilder").newTrigger().forJob(jobDetail).startNow()
									.withSchedule(simpleSchedulerCls.repeatForever().withIntervalInSeconds(10)).build();
		// ----/Using RootLoader----
		return trigger
	}
}

import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
class AJob implements Job, Serializable{
	static final long serialVersionUID = 1L;
	
	public void execute(JobExecutionContext arg0) throws JobExecutionException {
		println "Executing job..."
	}
}
