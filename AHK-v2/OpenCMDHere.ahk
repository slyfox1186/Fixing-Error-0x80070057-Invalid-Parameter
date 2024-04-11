/*____________________________________________________________________________________
    OpenCMDHereNew.ahk

    Mechanism of action:
      - Opens a cmd.exe window to the active explorer window's current folder, otherwise
        it will open cmd.exe to the current user's downloads folder.

    Extra Info:
      - Feel free to modify the command lines ' /E:ON /T:0A /K pushd ' to fit your needs.

    Authors:
      - SlyFox1186
*/

#SingleInstance Force
SetWorkingDir A_ScriptDir

!c::OpenCMDHereNew()

OpenCMDHereNew() {
    explorerWinTitle := "ahk_class CabinetWClass ahk_exe explorer.exe"
    cmdWinTitle := "ahk_class ConsoleWindowClass ahk_exe cmd.exe"

    if !WinActive(explorerWinTitle) {
        downloadsFolder := GetDownloadsFolder()
        Run A_ComSpec ' /E:ON /T:0A /K pushd "' downloadsFolder '"',, "Max", &outputPID
        If WinWait("ahk_pid " outputPID,, 1)
            WinActivate
        return
    }

    winObj := ComObject("Shell.Application").Windows
    activeHwnd := WinExist("A")
    activeTab := ControlGetHwnd("ShellTabWindowClass1", activeHwnd)

    for win in winObj {
        if (win.hwnd = activeHwnd) {
            if IsSet(activeTab) {
                try {
                    shellBrowser := ComObjQuery(win, "{000214E2-0000-0000-C000-000000000046}")
                    thisTab := 0
                    ComCall(3, shellBrowser, "Ptr", &thisTab)
                    if (thisTab != activeTab)
                        continue
                } catch {
                    ; Fallback to using the active window's path
                    pwd := '"' win.Document.Folder.Self.Path '"'
                    break
                }
            }
            pwd := '"' win.Document.Folder.Self.Path '"'
            break
        }
    }

    Run A_ComSpec ' /E:ON /T:0A /K pushd ' pwd,, "Max", &winPID
    if WinWait("ahk_pid " winPID,, 1)
        WinActivate
}

GetDownloadsFolder() {
    downloadsFolder := ""
    if (FileExist(A_MyDocuments "\Downloads"))
        downloadsFolder := A_MyDocuments "\Downloads"
    else if (FileExist("C:\Users\" . A_UserName . "\Downloads"))
        downloadsFolder := "C:\Users\" . A_UserName . "\Downloads"
    else
        MsgBox "Downloads folder not found."
    return downloadsFolder
}
