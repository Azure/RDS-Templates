# Windows Virtual Desktop - Diagnostics tool
Deploy this web app in your Azure subscription to search and view diagnostic activities for users. Follow deployment instructions in the [documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/deploy-diagnostics).


> **Reporting issues:**
> Microsoft Support is not handling issues for any published tools in this repository. These tools are published as is with no implied support. However, we would like to welcome you to open issues using GitHub issues to collaborate and improve these tools. You can open [an issue](https://github.com/Azure/rds-templates/issues) and add the label **6-diagnostics** to associate it with this tool.
> Provide logs to pin down the issue faster.
> - Open PowerShell as an administrator and run [Get Logfiles for Diagnostics.ps1](https://raw.githubusercontent.com/Azure/RDS-Templates/wvd-monitoring/wvd-templates/diagnostics-sample/deploy/scripts/Get%20Logfiles%20for%20Diagnostics.ps1)
> - Provide values for the paramters:
> 	* Enter a name for the Webapp (WebappName)
> 	* Provide the Azure Subscription ID (Subscriptionid)
> 	* Provide the log file download path (DestinationFolderPath)
> - When prompted sign in with the user that has delegated admin access
> - Log files are successfully downloaded to the DestinationFolderPath which you specified. 

## How to modify performance counters 

### Locate the configuration file for your app 

To get started, you’ll need to find your app’s configuration file. First, navigate to the Kudu portal: 

- https://&lt;yourappname&gt;.scm.azurewebsites.net/DebugConsole 

Next, select the Site folder and navigate to wwwroot. 

- Look for metrics.xml and select Edit to update the file directly on the portal or download the file and edit locally.  

Before you begin editing, you should be familiar with the Kusto query language to achieve the following: 

- Change thresholds for preconfigured performance counters 

- Add new performance counters.

For more information about the Kusto query language, see our Kusto documentation [here](https://docs.microsoft.com/azure/kusto/query/).

### Change thresholds for preconfigured performance counters 
The metrics.xml file contains all preconfigured counters for the Log Analytics workspace. This guide will explain how to change counter thresholds using an example counter. 

First, locate the counter you want to configure. The query for each counter is defined in HTML tagging format. For example, 	&lt;countername	&gt;&lt;/countername&gt;. 

The following example shows a complete query involving our example counter: 

	<Processor_Usage>
 	   <Query>

        Perf | where Computer in ({0}) 

        | where ObjectName == "Processor Information" 

        | where CounterName == "% Processor Time" 

        | summarize Value = avg(CounterValue) by Computer 

        | project avg = 0, Value , Computer, Status = iff(Value> 80, 0,2) 

      </Query> 

            <timespan>PT30M</timespan> 

            <Tooltip>Unhealthy:More than 80% in the last 30 minutes.</Tooltip> 

    </Processor_Usage>
		
To modify the threshold, look for <B>|project</B> int the query. In our example, the line looks like this: 

      | project avg = 0, Value , Computer, Status = iff(Value> 80, 0,2)
			
The iff statement contains the threshold definition. In this example, the iff statement says that if processor usage is above 80%, the counter will be reported as unhealthy (0). If it‘s below the 80% threshold, it will be reported as healthy (2).

### Add a new performance counter 
Before adding a new performance counter, you need to ensure that you have configured the counter in your log analytics workspace. To learn more about how to add new Windows counters, see the [Azure Monitor documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-sources-performance-counters). The following instructions describe how to add the counter in the metrics.xml file. 

1. Confirm which counters you want to add in your Log Analytics workspace. 

2. Edit the followings things in the metrics.xml file: 

	a. Define &lt;countername	&gt;&lt;/countername&gt;. 

	b. Set the ObjectName (Windows performance counters are defined in the following format: Objectname(*)\Countername. For example,  if your object name is “LogicalDisk” and your counter name is “%Free Space,” it would look like LogicalDisk(*)\%Free Space.).
	
	c. Define the threshold in the iff statement. 

When you‘re finshed, your file should look  like the following example:

	<Memory_Usage> 

            <Query> 

                <![CDATA[ 

       Perf | where Computer in ({0}) 

       | where ObjectName == "Memory" 

       | where CounterName == "Available MBytes" 

       | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer 

       | project avg = 0, Value, Computer, Status = iff(Value < 500, 0, 2)]]> 

            </Query> 

            <timespan>PT30M</timespan> 

       </Memory_Usage> 


