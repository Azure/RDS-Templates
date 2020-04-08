# Power BI Template for WVD 

This repository contains a Power BI template to show user activity in a WVD environment. The report was created by [@MaheshSQL](https://github.com/MaheshSQL)

![alt text](https://raw.githubusercontent.com/Jonathan1Wade/RDS-Templates/master/wvd-powerbi/images/PBIdesktopWVD.jpg "Sample dashbaord")

### Detials available in the report include:
* User and session count
* User and session activity time
* Client operating system
* Drill downs to erros and alerts


### Prerequisites:
* Power BI Pro or Premium license
* [Log Analyitcs](https://docs.microsoft.com/en-us/azure/virtual-desktop/diagnostics-log-analytics) set up for WVD
* Account with read access permissions to the Log Analyitcs workspace

### Procedure
1. Set up WVD for logging 
2. Export M query
3. Download and open [Power BI template](https://docs.microsoft.com/en-us/azure/virtual-desktop/diagnostics-log-analytics)
4. Use connection info porvided in query 
5. Load report 

![alt text](https://raw.githubusercontent.com/Jonathan1Wade/RDS-Templates/master/wvd-powerbi/images/2%20Getting%20Started.png "Getting Started Guide")

### Reporting issues
Microsoft Support is not handling issues for any published tools in this repository. These tools are published as is with no implied support. However, we would like to welcome you to open issues using GitHub issues to collaborate and improve these tools. You can open [an issue](https://github.com/Azure/rds-templates/issues) and add the corresponding label (like **5-RDS-on-Windows-Server**) to associate it with the appropriate tool. 