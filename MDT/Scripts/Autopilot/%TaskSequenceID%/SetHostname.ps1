$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment  
  
#Get Name and OS Disk from MDT  
$MDTComputerName = $TSEnv.Value("OSDComputerName")  
$MDTOSDisk = $TSEnv.Value("OSDisk")  
  
# Read the current config  
$config = Get-Content .\AutoPilotConfigurationFile.json -Encoding Ascii | ConvertFrom-Json  
  
# Add the computer name  
$config | Add-Member "CloudAssignedDeviceName" $MDTComputerName  
  
# Write the updated file  
$targetDrive = $tsenv.Value("OSDisk")  
$null = MkDir "$targetDrive\Windows\Provisioning\Autopilot" -Force  
$destConfig = "$targetDrive\Windows\Provisioning\Autopilot\AutoPilotConfigurationFile.json"  
$config | ConvertTo-JSON | Set-Content -Path $destConfig -Force