#Requires -Version 5.1
#Requires -RunAsAdministrator

function Dismount-CimDiskImage {
    <#
        .SYNOPSIS
        Dismounts a cimfs disk image from your system.

        .DESCRIPTION
        When the volume DeviceId is supplied as a parameter it will remove the mount point if it exists and then dismount the cimfs disk image, will only work on cim files.  It will also dismount cimfs images with no mount point.

        .PARAMETER DeviceId
        Specifies the device ID of the volume, an example of which is: \\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\

        .INPUTS
        This function will take inputs via pipeline as string and by property name DeviceId

        .OUTPUTS
        None.

        .EXAMPLE
        PS> Dismount-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'
        Dismounts a volume by DeviceId
        .EXAMPLE
        PS> Dismount-CimDiskImage -DeviceId @('\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862e}\', '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\')
        Dismounts a list of multiple volumes by DeviceId
        .EXAMPLE
        PS> Get-CimDiskImage C:\MyMountPoint | Dismount-CimDiskImage
        Dismounts a volume by path
        .EXAMPLE
        PS> Get-CimDiskImage | Dismount-CimDiskImage
        Dismounts all Cimfs volumes
        .EXAMPLE
        PS> Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' } | Dismount-CimDiskImage
        Dismounts all Cimfs volumes
        
        .LINK
        https://github.com/JimMoyle/CimDiskImage-PowerShell/blob/main/Help/Dismount-CimDiskImage.md

    #>
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String[]]$DeviceId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        #CimFS operations need Win32 API calls to make work, I can't find a lot of native powershell to do what we need.

        <#
        $folderInfo = Get-Item $appPath
        $DeviceId = '\\?\' + $folderInfo.LinkTarget.Split('\')[0] +'\'
        #>

        #loop through multiple DeviceIds
        foreach ($Id in $DeviceId) {
        
            #Grab details of the cimfs volume from the device ID
            $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq $Id -and $_.FileSystem -eq 'cimfs' }
            if ($null -eq $volume) {
                Write-Error "Could not find cimfs $Id on this computer"
                return
            }

            #Check if there is a mount point, if there is remove it. It's possible to have a volume attached without a mount point, but unlikely.
            if ($volume.DeviceID -ne $volume.Name) {
                #Get Delete mount point API call from kernel32.dll
                $removeMountPointSignature = @"
[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool DeleteVolumeMountPoint(string mountPoint);
"@

                $mountPointRemove = Add-Type -MemberDefinition $removeMountPointSignature -Name "RemoveVolMntPnt" -Namespace Win32Functions -PassThru

                #Function only present for mocking reasons in Pester
                function mockremovemountpoint { $mountPointRemove::DeleteVolumeMountPoint($volume.Name) }
                $removeMountPointResult = mockremovemountpoint; $remMntPntErr = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()
                #Should return True/False

                if (-not ($removeMountPointResult)) {
                    $remMntPntErrStr = "Could not remove mount point to {0} Error:'{1}' ErrorCode:{2}" -f $volume.Name, $remMntPntErr.Message, $remMntPntErr.NativeErrorCode
                    Write-Error $remMntPntErrStr
                    return
                }
            }

            #Use CIM (WMI) to dismount volume after the mount point is removed.
            #Function only present for mocking reasons in Pester
            function mockdismount { Invoke-CimMethod -InputObject $volume -MethodName DisMount -Arguments @{ Force = $true } }
            $disMountVolumeResult = mockdismount

            switch ($disMountVolumeResult.ReturnValue) {
                0 { break } #Success no action
                1 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Access Denied'"; break }
                2 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Volume Has Mount Points'"; break }
                3 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Volume Does Not Support The No-Autoremount State'"; break }
                4 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Force Option Required'"; break }
                Default { Write-Error "Dismounting volume $($volume.DeviceId) failed with unknown error. Consult https://docs.microsoft.com/previous-versions/windows/desktop/vdswmi/dismount-method-in-class-win32-volume for documentation" }
            }

            Write-Verbose "Volume $Id Removed"

        }

    } # process
    end {} # end
}  #function Dismount-CimDiskImage

function Get-CimDiskImage {
    <#
        .SYNOPSIS
        Gets information about mounted cimfs disk image(s) on your system.

        .DESCRIPTION
        When the volume DeviceId or Mount Point is supplied, information about that disk will be returned, if no parameters are supplied all cimfs disks will be returned.

        .PARAMETER DeviceId
        Specifies the device ID of the volume, an example of which is: \\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\

        .PARAMETER Path
        Specifies the mount point of the volume, an example of which is: C:\MyMountPoint

        .INPUTS
        This function will take inputs via pipeline as string and by property name DeviceId

        .OUTPUTS
        Microsoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Volume

        .EXAMPLE
        PS> Get-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'
        Returns the details for the cimfs volume with the specified DeviceId
        .EXAMPLE
        PS> Get-CimDiskImage -Path C:\MyMountPoint
        Returns the details for the cimfs volume with the specified Path
        .EXAMPLE
        PS> Get-CimDiskImage
        Returns details about all cimfs volumes currently mounted.

        .LINK
        https://github.com/JimMoyle/CimDiskImage-PowerShell/blob/main/Help/Get-CimDiskImage.md

    #>
    [CmdletBinding(DefaultParameterSetName = 'DeviceId')]

    Param (
        [Parameter(
            ParameterSetName = 'Path',
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [Alias('Fullname', 'Name')]
        [System.String]$Path,

        [Parameter(
            ParameterSetName = 'DeviceId',
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$DeviceId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        #Get All the cimfs volumes
        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' }

        #Filter (or not) based on parameter, param sets used so you can't put both deviceID and path in as params
        switch ($false) {
            ( [String]::IsNullOrEmpty($Path) ) {
                $out = $volume | Where-Object { $_.Name.TrimEnd('\') -eq $Path.TrimEnd('\') }
                Write-Output $out
                break
            }
            ( [String]::IsNullOrEmpty($DeviceId) ) {
                $out = $volume | Where-Object { $_.DeviceId -eq $DeviceId }
                Write-Output $out
                break
            }
            Default {
                Write-Output $volume
            }
        }
    } # process
    end {} # end
}  #function Get-CimDiskImage

function Mount-CimDiskImage {
    <#
        .SYNOPSIS
        Mounts a cimfs disk image to your system.

        .DESCRIPTION
        This will mount a cim file to a drive letter or directory of your choosing, allowing you to browse the contents. Remember to use the -Passthru Parameter to get output

        .PARAMETER ImagePath
        Specifies the location of the cim file to be mounted.

        .PARAMETER DriveLetter
        Specifies the Drive letter which the cim file should be mounted to.  It can be in the format 'X:' or 'X:\'

        .PARAMETER MountPath
        Specifies the local folder to which the cim file will be mounted.  This folder needs to exist and be empty  prior to attempting to mount a cim file to it.

        .PARAMETER NoMountPath
        Specifies that the volume will be attached but no filesystem mountpath will be created.

        .PARAMETER PassThru
        Will output details of the mount operation to the pipeline.  Otherwise there will be no output

        .INPUTS
        This function will take inputs via pipeline by type and property and by position.

        .OUTPUTS
        PSCustomObject containing 'DeviceId', 'FileSystem', 'Path' and 'Guid'

        .EXAMPLE
        PS> Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -MountPath C:\MyMountPath -Passthru
        Mounts the Cim file to a local directory and sends the result to the pipeline
        .EXAMPLE
        PS> Mount-CimDiskImage C:\MyCimFile.cim C:\MyMountPath
        Mounts the Cim file to a local directory
        .EXAMPLE
        PS> Get-ChildItem C:\MyCimFile.cim | Mount-CimDiskImage -MountPath C:\MyMountPath -Passthru
        Mounts the Cim file to a local directory and sends the result to the pipeline
        .EXAMPLE
        PS> Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -NoMountPath -PassThru
        ounts the Cim Disk Image file to a volume without mounting to the filesystem and outputs the results to the pipeline
        .EXAMPLE
        PS> 'C:\MyCimFile.cim' | Mount-CimDiskImage -MountPath C:\MyMountPath

        .LINK
        https://github.com/JimMoyle/CimDiskImage-PowerShell/blob/main/Help/Mount-CimDiskImage.md

    #>
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('FullName')]
        [Alias('Path')]
        [System.String]$ImagePath,

        [Parameter(
            ParameterSetName = 'ByLetter',
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$DriveLetter,

        [Parameter(
            ParameterSetName = 'ByPath',
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$MountPath,

        [Parameter(
            ParameterSetName = 'NoMountPath',
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [Alias('NoDriveLetter')]
        [Switch]$NoMountPath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$PassThru
    )

    begin {
        Set-StrictMode -Version Latest
        #requires -RunAsAdministrator
    } # begin
    process {
        #CimFS operations need Win32 API calls to make work, I can't find a lot of native powershell to do what we need.

        #Is the file there
        If (-not (Test-Path $ImagePath)) {
            Write-Error "$ImagePath does not exist"
            return
        }

        switch ($PSCmdlet.ParameterSetName) {
            ByLetter {
                if ($DriveLetter -notmatch "^\w\:\\?$") {
                    Write-Error "$DriveLetter does not seem to be a drive letter. Example X: or X:\"
                    return
                }
                else {
                    $MountPath = $DriveLetter
                }
                break
            }
            ByPath {
                If (-not (Test-Path $MountPath)) {
                    Write-Error "$MountPath does not exist"
                    return
                }
                break
            }
            Default {}
        }

        #Let's get the full file information, we'll need it later
        $fileInfo = Get-ChildItem $ImagePath

        #Is it a Cim file?
        If ($fileInfo.Extension -ne '.cim') {
            Write-Error "$ImagePath is not a Cim file"
            return
        }

        #Grab some file information in named variables
        $fileName = $fileInfo.Name
        $folder = $fileInfo.Directory.FullName

        # Make sure the path ends with a single \ as the SetVolumeMountPoint api requires this
        if (-not $NoMountPath) {
            $MountPath = $MountPath.TrimEnd('\') + '\'
        }
        #We need to supply a random guid for the mount param (needs to be cast as a ref to interact with the API)
        $guid = (New-Guid).Guid
        [ref]$guidRef = $guid

        #Get the method from the Cimfs.dll (don't change formatting)
        $mountSignature = @"
[DllImport( "cimfs.dll", CharSet = CharSet.Unicode, SetLastError = true )] public static extern long CimMountImage(String imageContainingPath, String imageName, IntPtr mountImageFlags, ref Guid volumeId);
"@
        #Create object
        $CimFSMount = Add-Type -MemberDefinition $mountSignature -Name "CimFSMount" -Namespace Win32Functions -PassThru

        #This function is only here so I can mock it during pester testing.
        function mockmount {
            #Mount the volume image flag needs to be 0
            $CimFSMount::CimMountImage($folder, $fileName, 0, $guidRef)
        }
        $mountResult = mockmount; $mntErr = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()
        If ($mountResult -ne 0) {
            $mntErrStr = "Mounting {0} to volume failed with Error:'{1} ErrorCode:{2}'" -f $ImagePath, $mntErr.Message , $mntErr.NativeErrorCode
            Write-Error $mntErrStr
            return
        }

        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq "\\?\Volume{$guid}\" }

        if (-not $NoMountPath) {
      
            $mountPointSignature = @"
[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern bool SetVolumeMountPoint(string lpszVolumeMountPoint, string lpszVolumeName);
"@

            $mountPoint = Add-Type -MemberDefinition $mountPointSignature -Name "CimMountPoint" -Namespace Win32Functions -PassThru

            #This function is only here so I can mock it during pester testing.
            function mockmountpoint { $mountPoint::SetVolumeMountPoint($MountPath, $volume.DeviceID) }
            $mpResult = mockmountpoint; $mpError = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()

            If (-not ($mpResult)) {
                $mpErrStr = "Mounting {0} to {1} failed with Error:'{2}' ErrorCode:{3}" -f $volume.DeviceId, $mountPath , $mpError.Message, $mpError.NativeErrorCode
                Write-Error $mpErrStr
                $volume.DeviceID | Dismount-CimDiskImage
                return
            }

            Write-Verbose "Mounted $ImagePath to $MountPath"
        }
        else {
            $MountPath = $null
        }
        
        #Dump out with no object if sucessful as per guidelines
        If (-not ($Passthru)) {
            return
        }

        #This should be all you need to find it again
        $out = [PSCustomObject]@{
            DeviceId   = $volume.DeviceID
            FileSystem = $volume.FileSystem
            Path       = $MountPath
            Guid       = $guid
        }

        Write-Output $out

    } # process
    end {} # end
}  #function Mount-CimDiskImage


