#SingleInstance force
Menu, Tray, Icon, Updater.exe, , 1
Menu, Tray, Tip, Updater
UrlDownloadToFile, %1%, %2%
while ErrorLevel
  UrlDownloadToFile, %1%, %2%
Run, "%2%"
ExitApp