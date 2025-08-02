// See https://aka.ms/new-console-template for more information
using LoggerService;
using NLog;
using System.Reflection;

Console.WriteLine("Logger service testing console");

Assembly assembly = Assembly.GetExecutingAssembly();;
NLog.Config.ISetupBuilder setupBuilder = NLog.LogManager.Setup();
NLog.Config.ISetupBuilder configuredSetupBuilder = setupBuilder.LoadConfigurationFromAssemblyResource(assembly);

// testing NLOG
var nlogLoggingService = new NLogLoggingService("Nlog.config");
nlogLoggingService.Info("This is an info message.");
nlogLoggingService.GetConfiguration().FindTargetByName<NLog.Targets.NetworkTarget>("udp").Address = "udp4://10.0.0.2:9999";

// testing Basic Logger
var basicLoggingService = new BasicLoggingService();
basicLoggingService.Info("This is an info message.");

Console.ReadLine();