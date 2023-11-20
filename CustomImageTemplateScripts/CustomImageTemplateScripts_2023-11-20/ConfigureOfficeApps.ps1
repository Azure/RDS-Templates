<#Author       : Akash Chawla
# Usage        : Configure office applications for AVD
#>

#############################################
#         Configure Office applications     #
#############################################



[CmdletBinding()] Param (
    [Parameter(
        Mandatory
    )]
    [ValidateSet("Word","PowerPoint","Access","Excel","OneNote","Outlook","Publisher","Visio", "Project")]
    [System.String[]]$Applications,

    [Parameter(
        Mandatory
    )]
    [ValidateSet("32", "64")]
    [string]$Version,

    [Parameter(
        Mandatory
    )]
    [ValidateSet("Add", "Remove")]
    [string]$Type
    
)

function AddProductsToConfigurationXML {

    [CmdletBinding()] Param (
        [Parameter(
            Mandatory
        )]
        [ValidateSet("Visio","Project")]
        [System.String[]]$Applications,

        [Parameter(
            Mandatory
        )]
        $xmlFile,

        [Parameter(
            Mandatory
        )]
        [string]$xmlFilePath,

        [Parameter(
            Mandatory
        )]
        [ValidateSet("32", "64")]
        [string]$Version
    )

    Begin {

        try {
            $addElement = $xmlFile.DocumentElement.Add

            if ($null -eq $addElement) {
                Throw "Not able to access the xml element"
            }


            $addElement.setAttribute("OfficeClientEdition", $Version)
            $VisioProductID = "VisioProRetail"
            $projectProductID = "ProjectProRetail"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    Process {

        try {
            foreach ($app in $Applications) {

                Write-Host " AVD AIB Customization Office apps: Request to add $app"
                $productElement = $xmlFile.CreateElement("Product");
                $languageElement = $xmlFile.CreateElement("Language")
                $languageElement.setAttribute("ID", "MatchOS")
    
                $productElement.AppendChild($languageElement)
    
    
                if ($app -eq "Visio") {
                    $productElement.setAttribute("ID", $VisioProductID)
                }
    
                if ($app -eq "Project") {
                    $productElement.setAttribute("ID", $ProjectProductID)
                }
    
                $addElement.AppendChild($productElement)
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    End {

        $xmlFile.Save($xmlFilePath)
    }
}

function RemoveProductsFromConfigurationXML {

   
    [CmdletBinding()] Param (
        [Parameter(
            Mandatory
        )]
        [ValidateSet("Word","PowerPoint","Access","Excel","OneNote","Outlook","Publisher")]
        [System.String[]]$Applications,

        [Parameter(
            Mandatory
        )]
        $xmlFile,

        [Parameter(
            Mandatory
        )]
        [string]$xmlFilePath,

        [Parameter(
            Mandatory
        )]
        [ValidateSet("32", "64")]
        [string]$Version
    )

    Begin {

        try {
            $addElement = $xmlFile.DocumentElement.Add
            $addElement.setAttribute("OfficeClientEdition", $Version)
            $productID = "O365ProPlusRetail"
            $productElement = $xmlFile.CreateElement("Product")
            $productElement.setAttribute("ID", $productID)

            $languageElement = $xmlFile.CreateElement("Language")
            $languageElement.setAttribute("ID", "MatchOS")

            $productElement.AppendChild($languageElement)
        } 
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    Process {

        try {
            foreach ($app in $Applications) {

                Write-Host " AVD AIB Customization Office apps: Request to remove $app"
                $excludeElement = $xmlFile.CreateElement("ExcludeApp")
                $excludeElement.setAttribute("ID", $app);
                $productElement.AppendChild($excludeElement)
            }
    
            $addElement.AppendChild($productElement)
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    End {

        $xmlFile.Save($xmlFilePath)
    }
}

function ConfigureOfficeXML($Applications, $xmlFile, $xmlFilePath, $Version, $Type) {

    if ($Type -eq "Add") {
        Write-Host " AVD AIB Customization Office apps: Adding office applications"
        AddProductsToConfigurationXML -Applications $Applications -xmlFile $file -xmlFilePath $xmlFilePath -Version $Version
    } 
    else {
        Write-Host " AVD AIB Customization Office apps: Removing office applications"
        RemoveProductsFromConfigurationXML -Applications $Applications -xmlFile $file -xmlFilePath $xmlFilePath -Version $Version
    }
}

function installOfficeUsingODT($Applications, $Version, $Type) {


    Begin {

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Host "Starting AVD AIB Customization : Office Apps : $((Get-Date).ToUniversalTime())"

        $configXML = @'
            <Configuration>
            <Add Channel="Monthly">
            </Add>
            <RemoveMSI />
            <Updates Enabled="FALSE" />
            <Display Level="None" AcceptEULA="TRUE" />
            <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
            <Property Name="SharedComputerLicensing" Value="1" />
            </Configuration>
'@

        $ODTDownloadLinkRegex = '/officedeploymenttool[a-z0-9_-]*\.exe$'
        $guid = [guid]::NewGuid().Guid
        $tempFolder = (Join-Path -Path "C:\temp\" -ChildPath $guid)
        $ODTDownloadUrl = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'
        $templateFilePathFolder = "C:\AVDImage"

        if (!(Test-Path -Path $tempFolder)) {
            New-Item -Path $tempFolder -ItemType Directory
        }

        Write-Host "AVD AIB Customization Office Apps : Created temp folder $tempFolder"
    }

    Process {

        try {
         
            $HttpContent = Invoke-WebRequest -Uri $ODTDownloadUrl -UseBasicParsing
            
            if ($HttpContent.StatusCode -ne 200) { 
                throw "Office Installation script failed to find Office deployment tool link -- Response $($Response.StatusCode) ($($Response.StatusDescription))"
            }

            $ODTDownloadLinks = $HttpContent.Links | Where-Object { $_.href -Match $ODTDownloadLinkRegex }

            #pick the first link in case there are multiple
            $ODTToolLink = $ODTDownloadLinks[0].href
            Write-Host "AVD AIB Customization Office Apps : Office deployment tool link is $ODTToolLink"

            $ODTexePath = Join-Path -Path $tempFolder -ChildPath "officedeploymenttool.exe"

            #download office deployment tool

            Write-Host "AVD AIB Customization Office Apps : Downloading ODT tool into folder $ODTexePath"
            $ODTResponse = Invoke-WebRequest -Uri "$ODTToolLink" -UseBasicParsing -UseDefaultCredentials -OutFile $ODTexePath -PassThru

            if ($ODTResponse.StatusCode -ne 200) { 
                throw "Office Installation script failed to download Office deployment tool -- Response $($ODTResponse.StatusCode) ($($ODTResponse.StatusDescription))"
            }

            Write-Host "AVD AIB Customization Office Apps : Extracting setup.exe into $tempFolder"
            # extract setup.exe
            Start-Process -FilePath $ODTexePath -ArgumentList "/extract:`"$($tempFolder)`" /quiet" -PassThru -Wait -NoNewWindow

            $setupExePath = Join-Path -Path $tempFolder -ChildPath 'setup.exe'
            
            # Construct XML config file for Office Deployment Kit setup.exe
            $xmlFilePath = Join-Path -Path $tempFolder -ChildPath 'installOffice.xml'

            Write-Host "AVD AIB Customization Office Apps : Saving xml content into xml file : $xmlFilePath"
            $configXML | Out-File -FilePath $xmlFilePath -Force -Encoding ascii
            
            [XML]$file = Get-Content $xmlFilePath
            ConfigureOfficeXML -Applications $Applications -xmlFile $file -xmlFilePath $xmlFilePath -Version $Version -Type $Type
            
            Write-Host "AVD AIB Customization Office Apps : Running setup.exe to download Office"
            $ODTRunSetupExe = Start-Process -FilePath $setupExePath -ArgumentList "/download $(Split-Path -Path $xmlFilePath -Leaf)" -PassThru -Wait -WorkingDirectory $tempFolder -WindowStyle Hidden

            if (!$ODTRunSetupExe) {
                Throw "AVD AIB Customization Office Apps : Failed to run `"$setupExePath`" to download Office"
            }

            if ( $ODTRunSetupExe.ExitCode) {
                Throw "AVD AIB Customization Office Apps : Exit code $($ODTRunSetupExe.ExitCode) returned from `"$setupExePath`" to download Office"
            }

            Write-Host "AVD AIB Customization Office Apps : Running setup.exe to Install Office"
            $InstallOffice = Start-Process -FilePath $setupExePath -ArgumentList "/configure $(Split-Path -Path $xmlFilePath -Leaf)" -PassThru -Wait -WorkingDirectory $tempFolder -WindowStyle Hidden

            if (!$InstallOffice) {
                Throw "AVD AIB Customization Office Apps : Failed to run `"$setupExePath`" to install Office"
            }

            if ( $ODTRunSetupExe.ExitCode ) {
                Throw "AVD AIB Customization Office Apps : Exit code $($ODTRunSetupExe.ExitCode) returned from `"$setupExePath`" to download Office"
            }
            
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    End {

        #Cleanup
        if ((Test-Path -Path $tempFolder -ErrorAction SilentlyContinue)) {
            Remove-Item -Path $tempFolder -Force -Recurse -ErrorAction Continue
        }

        if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
            Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
        }

        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed
        Write-Host "Ending AVD AIB Customization : Office Apps - Time taken: $elapsedTime"

    }
}

installOfficeUsingODT -Applications $Applications -Version $Version -Type $Type
