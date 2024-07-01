#Get Task Sequence Name from MDT  
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$MDTSequenceName = $TSEnv.Value("TaskSequenceName")

#Get Task Sequence ID from MDT  
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$MDTSequenceID = $TSEnv.Value("TaskSequenceID")

#Get image language from MDT  
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$MDTImageLanguage = $TSEnv.Value("ImageLanguage001")

#Get IP Address from MDT  
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$MDTIPAddress = $TSEnv.Value("IPAddress001")

#Time # Time 
$DateTime = Get-Date -Format g 
$Time = get-date -format HH:mm 

# Computer Manufacturer 
$Make = (Get-WmiObject -Class Win32_BIOS).Manufacturer 

# Computer Model 
$Model = (Get-WmiObject -Class Win32_ComputerSystem).Model 

#Get the entered Computer Name from MDT  
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$MDTComputerName = $TSEnv.Value("OSDComputerName")

# Computer Serial Number 
[string]$SerialNumber = (Get-WmiObject win32_bios).SerialNumber 

# Get Installed ram of the Computer 
$PhysicalRAM = (Get-WMIObject -class Win32_PhysicalMemory |Measure-Object -Property capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})


$JSONBody = [PSCustomObject][Ordered]@{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "summary"    = "$MDTComputerName | Installation completed"
    "themeColor" = '0078D7'
    "sections"   = @(
		    @{
					"activityTitle"    = "$MDTComputerName | Installation completed"
          "activitySubtitle" = "Find the device details below"
          "facts"            = @(
						@{
							"name"  = "Hostname"
							"value" = $MDTComputerName
						},
						@{
							"name"  = "Completed on"
							"value" = $DateTime
						},
						@{
							"name"  = "Task Sequence Name"
							"value" = $MDTSequenceName
						},
						@{
							"name"  = "Task Sequence ID"
							"value" = $MDTSequenceID
						},
						@{
							"name"  = "Language"
							"value" = $MDTImageLanguage
						},
						@{
							"name"  = "IP Address"
							"value" = $MDTIPAddress
						},
						@{
							"name"  = "Computer Model"
							"value" = $Model
						},
						@{
							"name"  = "Serial Number"
							"value" = $SerialNumber
						}
						@{
							"name"  = "RAM Installed"
							"value" = "$PhysicalRAM GB"
						}                                                                                     
					)
					"markdown" = $true
				}
    )
}



$TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100

$parameters = @{
    "URI"         = '/IncomingWebhook/'
    "Method"      = 'POST'
    "Body"        = $TeamMessageBody
    "ContentType" = 'application/json'
}

Invoke-RestMethod @parameters | Out-Null
