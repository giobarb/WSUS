Welcome to Fuck-WSUS!

Hi! these scripts are made so you can see which computers connected to your off-site WSUS server. The purpose of this is to make tracking devices that are or aren't connected.It **does not** show you which updates have and/or haven't been applied. I may add this if I find it useful for myself, feel free to fork it however.

# Prerequisites
There are two prerequisites for these scripts to run smoothly.
- The first is for you to have correctly setup [WinRM](https://support.infrasightlabs.com/help-pages/how-to-enable-winrm-on-windows-servers-clients/).
- The second one is for you to enable [SMTPAuthentication](https://docs.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission), if you are using O365.

# Files

- [CreateSecureString.ps1](https://github.com/giobarb/FUCK-WSUS/blob/main/CreateSecureString.ps1 "CreateSecureString.ps1") this is a very simple script that only creates a SecureString so you do not have to store your password in plaintext.
- [LocalDCGPOExport.ps1](https://github.com/giobarb/FUCK-WSUS/blob/main/LocalDCGPOExport.ps1 "LocalDCGPOExport.ps1") this is a script that exports all the computers that are linked to the GPO on your clients ADC to contact your off-site WSUS. This requires [config.json](https://github.com/giobarb/FUCK-WSUS/blob/main/config.json).
- [config.json](https://github.com/giobarb/FUCK-WSUS/blob/main/config.json) this is a config file for [LocalDCGPOExport.ps1](https://github.com/giobarb/FUCK-WSUS/blob/main/LocalDCGPOExport.ps1 "LocalDCGPOExport.ps1") Fill out this config as needed, this can not only send mails from O365, but through your local Exchange server if you leave the _SecureString_ parameter blank.
- [RemoteTSWSUS.ps1](https://github.com/giobarb/FUCK-WSUS/blob/main/RemoteTSWSUS.ps1 "RemoteTSWSUS.ps1") This is the script you should put on your WSUS server and run it along with the correct file structure.

## File structure on your off-site WSUS server.

Create a folder under the _C:\\_ drive called _TS_WSUS_ and create two folders named _ARCH_ and _OUT_ERR_, next create a folder for each of the clients you have for example _Contoso_,_Montoso_,_Cocktoso_ and _Dontoso_. It should look as such.
![WSUS Folder Structure under C:/ drive](https://raw.githubusercontent.com/giobarb/FUCK-WSUS/main/Images/folderStructureWSUS.png)After you run the _LocalDCGPOExport.ps1_ file you will receive a .csv as an attachment to your mail message, you put this file into your clients folder name, for example _Contoso_ as such.
![Content of your client folder](https://raw.githubusercontent.com/giobarb/FUCK-WSUS/main/Images/ContentOfClientFolder.png)