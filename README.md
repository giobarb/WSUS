# FUCK-WSUS
Hello everyone!

This is a script that is used to export all computers linked in to a GPO on your clients side, after this it will send an email. And you can use your remote WSUS server to verify what computers connected to the Update Service.

The process to set this up is as follows
  1. Download the _LocalGPOExport.ps1_ into your clients ADC Server, and put config.json into the same folder, make sure you put the correct information into the config and the correct GPO name.
  2. The second step is to setup SMTP authentication on your Exchange server, this can be done through either PowerShell or Web, reference this [article](https://docs.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission).
  3. The last step is to put the RemoteTSWSUS, into your Remote WSUS server and create a TS_WSUS folder under C:/ and put the name of each client so the structure looks like [this](https://imgur.com/a/jrHTCpA)
  4. After you have put the right .CSV export file into the client folder's name, just run the _RemoteWSUS.ps1_ script and it will create an HTML output into OUT_ERR which will show computers that are either not in ADC/WSUS and ARCH will have a .csv file that has all of the computers

If you have any questions feel free to ask!
