	#SingleInstance force
	#Persistent
	SendMode Input
	SetKeyDelay, 0, 0
	OnExit, Exiting
	Menu, Tray, Icon, LeagueofLogins.exe, , 1
	Menu, Tray, Tip, League of Logins
  Menu, Tray, NoStandard
  Menu, Tray, add, Exit
  TrayTip, League of Logins, Right click the tray icon to select your accounts

	global name := "LeagueofLogins"
	global workingDir := A_Temp "\%A_ScriptName%"
  FileCreateDir, %workingDir%
  FileCreateDir, % A_MyDocuments "\" name
	checkUpdate(6)
  global Pin := A_UserName
  global loginFile := A_MyDocuments "\" name "\" A_UserName ".txt"
  global Array := Object()
  getLogins()
Return

GuiClose:
GuiEscape:
ExitApp

Exit:
ExitApp

getLogins()
{
  Menu, Delete, add, trash, trash
  Menu, Delete, DeleteAll
  Menu, Autostart, add, trash, trash
  Menu, Autostart, DeleteAll
  Menu, Tray, DeleteAll
  Menu, Tray, NoStandard
  Loop, Read, %loginFile%
  {
    StringSplit, login, A_LoopReadLine, :
    if login1
    {
      Menu, Tray, add, %login1%, login
      Menu, Delete, add, %login1%, Delete
      Array[login1] := login2
    }
  }
  Menu, Tray, add
  Menu, Tray, add, Add
  Menu, Tray, add
  Menu, Tray, add, Delete, :Delete
  Menu, Tray, add
  Menu, Autostart, Add, Yes
  Menu, Autostart, Add, No
  Menu, tray, add, Autostart, :Autostart
  Menu, Tray, add
  Menu, Tray, add, Exit
}

trash:
Return

Yes:
	MsgBox, %name% will now start with windows
	FileCreateShortcut, %A_ScriptFullPath%, %A_AppData%\Microsoft\Windows\Start Menu\Programs\Startup\%name%.lnk
return
No:
	MsgBox, %name% will no longer start with windows
	FileDelete, %A_AppData%\Microsoft\Windows\Start Menu\Programs\Startup\%name%.lnk
return

login:
    If WinExist("PVP.net Client") or WinExist("ahk_exe LeagueClientUx.exe")
    {
      WinActivate, PVP.net Client
      WinActivate, ahk_exe LeagueClientUx.exe
      MouseClick, left, 1090, 190, 2, 0
      SendRaw % A_ThisMenuItem
      MouseClick, left, 1090, 250, 2, 0
      SendRaw % AES.Decrypt(Array[A_ThisMenuItem], Pin, 256)
      Sleep, 500
      MouseClick, Left, 1080, 535, 1,0
    }
    Else
      MsgBox, Cannot find League of Legends client.
return

add:
  Gui -Resize -MaximizeBox -MinimizeBox +AlwaysOnTop
  global User
  global Pass
  Gui Add, Edit, w200 vUser, Username
  Gui Add, Edit, w200 vPass Password, Password
  Gui Add, Button, w200 Default, Submit
  Gui Add, Button, w200, Cancel
  Gui Show,, League of Logins
return
ButtonSubmit:
  Gui, Submit
  Gui, Destroy
  FileAppend, % User . ":" . AES.Encrypt(Pass, Pin, 256) . "`n", %loginFile%
  getLogins()
Return
ButtonCancel:
  Gui, Destroy
Return

delete:
  Loop, Read, %loginFile%
  {
    StringSplit, login, A_LoopReadLine, :
    if login1
    {
      if (login1 != A_ThisMenuItem)
      {
        file .= A_LoopReadLine . "`n"
      }
    }
  }
  FileDelete, %loginFile%
  FileAppend, %file%, %loginFile%
  file := ""
  getLogins()
return

Exiting:
  FileRemoveDir, %workingDir%, 1
  ExitApp

checkUpdate(currentVersion)
{
  FileInstall, Updater.exe, %workingDir%\Updater.exe
  UrlDownloadToFile, https://raw.githubusercontent.com/GodsVictory/LeagueofLogins/master/version.txt, %workingDir%\version.txt
  loop, Read, %workingDir%\version.txt
    version := A_LoopReadLine
  if (currentVersion < version)
  {
    TrayTip, %A_ScriptName%, Updating...
    Run, %workingDir%\Updater.exe "https://raw.githubusercontent.com/GodsVictory/LeagueofLogins/master/LeagueofLogins.exe" "%A_ScriptFullPath%"
    ExitApp
  }
}

Class AES
{
  Encrypt(string, Password, alg)
  {
    len := this.StrPutVar(string, str_buf, 0, "UTF-16")
    this.Crypt(str_buf, len, Password, alg, 1)
    Return this.b64Encode(str_buf, len)
  }
  Decrypt(string, Password, alg)
  {
    len := this.b64Decode(string, encr_Buf)
    sLen := this.Crypt(encr_Buf, len, Password, alg, 0)
    sLen /= 2
    Return StrGet(&encr_Buf, sLen, "UTF-16")
  }
  Crypt(ByRef encr_Buf, ByRef Buf_Len, password, ALG_ID, CryptMode := 1)
  {
    static MS_ENH_RSA_AES_PROV := "Microsoft Enhanced RSA and AES Cryptographic Provider"
    static PROV_RSA_AES        := 24
    static CRYPT_VERIFYCONTEXT := 0xF0000000
    static CALG_SHA1           := 0x00008004
    static CALG_SHA_256        := 0x0000800c
    static CALG_SHA_384        := 0x0000800d
    static CALG_SHA_512        := 0x0000800e
    static CALG_AES_128        := 0x0000660e
    static CALG_AES_192        := 0x0000660f
    static CALG_AES_256        := 0x00006610
    static KP_BLOCKLEN         := 8
    If !(DllCall("advapi32.dll\CryptAcquireContext", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "Uint", PROV_RSA_AES, "UInt", CRYPT_VERIFYCONTEXT))
        MsgBox % "*CryptAcquireContext (" DllCall("kernel32.dll\GetLastError") ")"
    If !(DllCall("advapi32.dll\CryptCreateHash", "Ptr", hProv, "Uint", CALG_SHA1, "Ptr", 0, "Uint", 0, "Ptr*", hHash))
        MsgBox % "*CryptCreateHash (" DllCall("kernel32.dll\GetLastError") ")"
    passLen := this.StrPutVar(Password, passBuf, 0, "UTF-16")
    If !(DllCall("advapi32.dll\CryptHashData", "Ptr", hHash, "Ptr", &passBuf, "Uint", passLen, "Uint", 0))
        MsgBox % "*CryptHashData (" DllCall("kernel32.dll\GetLastError") ")"
    If !(DllCall("advapi32.dll\CryptDeriveKey", "Ptr", hProv, "Uint", CALG_AES_%ALG_ID%, "Ptr", hHash, "Uint", (ALG_ID << 0x10), "Ptr*", hKey))
        MsgBox % "*CryptDeriveKey (" DllCall("kernel32.dll\GetLastError") ")"
    If !(DllCall("advapi32.dll\CryptGetKeyParam", "Ptr", hKey, "Uint", KP_BLOCKLEN, "Uint*", BlockLen, "Uint*", 4, "Uint", 0))
        MsgBox % "*CryptGetKeyParam (" DllCall("kernel32.dll\GetLastError") ")"
    BlockLen /= 8
    If (CryptMode)
        DllCall("advapi32.dll\CryptEncrypt", "Ptr", hKey, "Ptr", 0, "Uint", 1, "Uint", 0, "Ptr", &encr_Buf, "Uint*", Buf_Len, "Uint", Buf_Len + BlockLen)
    Else
        DllCall("advapi32.dll\CryptDecrypt", "Ptr", hKey, "Ptr", 0, "Uint", 1, "Uint", 0, "Ptr", &encr_Buf, "Uint*", Buf_Len)
    DllCall("advapi32.dll\CryptDestroyKey", "Ptr", hKey)
    DllCall("advapi32.dll\CryptDestroyHash", "Ptr", hHash)
    DllCall("advapi32.dll\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
    Return Buf_Len
  }
  StrPutVar(string, ByRef var, addBufLen := 0, encoding := "UTF-16")
  {
    tlen := ((encoding = "UTF-16" || encoding = "CP1200") ? 2 : 1)
    str_len := StrPut(string, encoding) * tlen
    VarSetCapacity(var, str_len + addBufLen, 0)
    StrPut(string, &var, encoding)
    Return str_len - tlen
  }
  b64Encode(ByRef VarIn, SizeIn)
  {
    static CRYPT_STRING_BASE64 := 0x00000001
    static CRYPT_STRING_NOCRLF := 0x40000000
    DllCall("crypt32.dll\CryptBinaryToStringA", "Ptr", &VarIn, "UInt", SizeIn, "Uint", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", SizeOut)
    VarSetCapacity(VarOut, SizeOut, 0)
    DllCall("crypt32.dll\CryptBinaryToStringA", "Ptr", &VarIn, "UInt", SizeIn, "Uint", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", &VarOut, "UInt*", SizeOut)
    Return StrGet(&VarOut, SizeOut, "CP0")
  }
  b64Decode(ByRef VarIn, ByRef VarOut)
  {
    static CRYPT_STRING_BASE64 := 0x00000001
    static CryptStringToBinary := "CryptStringToBinary" (A_IsUnicode ? "W" : "A")
    DllCall("crypt32.dll\" CryptStringToBinary, "Ptr", &VarIn, "UInt", 0, "Uint", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", SizeOut, "Ptr", 0, "Ptr", 0)
    VarSetCapacity(VarOut, SizeOut, 0)
    DllCall("crypt32.dll\" CryptStringToBinary, "Ptr", &VarIn, "UInt", 0, "Uint", CRYPT_STRING_BASE64, "Ptr", &VarOut, "UInt*", SizeOut, "Ptr", 0, "Ptr", 0)
    Return SizeOut
  }
}
