/*____________________________________________________________________________________
    [ OpenTERMINALHere ]

    By: SlyFox1186
    Pastebin: https://pastebin.com/u/slyfox1186
    GitHub: https://github.com/slyfox1186/
    - Looking for a coder? You found him. Contact me on GitHub.

    Purpose:
    - This will open Windows' WSL terminal to the active file explorer folder or if no active window is found, C:\Windows\System32
    
    Instructions:
    - You need to replace the below variable "_osName" with the wsl distribution of your choosing. to find the available distros run (wsl -l --all) using powershell to get a list of available options
*/

!w::_OpenWSLHere()

_OpenWSLHere()
{

    _osName := "Ubuntu-22.04"

    ; OPEN CMD.EXE USING THE ACTIVE EXPLORER WINDOW'S FOLDER PATH
    If WinExist("ahk_class CabinetWClass ahk_exe explorer.exe")
        _winHwnd := WinActive()
    For win in ComObjCreate("Shell.Application").Windows
        If (win.HWND = _winHwnd)
        {
            _pwd := SubStr(win.LocationURL, 9)
            _pwd := RegExReplace(_pwd, "%20", " ")
            _pwd := RegExReplace(_pwd, "%21", "!")
            _pwd := RegExReplace(_pwd, "%23", "#")
            _pwd := RegExReplace(_pwd, "%24", "$")
            _pwd := RegExReplace(_pwd, "%25", "%")
            _pwd := RegExReplace(_pwd, "%26", "&")
            _pwd := RegExReplace(_pwd, "%27", "'")
            _pwd := RegExReplace(_pwd, "%28", "(")
            _pwd := RegExReplace(_pwd, "%29", ")")
            _pwd := RegExReplace(_pwd, "%2D", "-")
            _pwd := RegExReplace(_pwd, "%2E", ".")
            _pwd := RegExReplace(_pwd, "%30", "*")
            _pwd := RegExReplace(_pwd, "%3A", ":")
            _pwd := RegExReplace(_pwd, "%3F", "?")
            _pwd := RegExReplace(_pwd, "%40", "@")
            _pwd := RegExReplace(_pwd, "%5B", "[")
            _pwd := RegExReplace(_pwd, "%5D", "]")
            _pwd := RegExReplace(_pwd, "%5E", "^")
            _pwd := RegExReplace(_pwd, "%5F", "_")
            _pwd := RegExReplace(_pwd, "%60", "``")
            _pwd := RegExReplace(_pwd, "%7B", "{")
            _pwd := RegExReplace(_pwd, "%7C", "|")
            _pwd := RegExReplace(_pwd, "%7D", "}")
            _pwd := RegExReplace(_pwd, "%7E", "~")
            _pwd := RegExReplace(_pwd, "/", "\")
        }
    If (_pwd = "")
        Run, "%A_ProgramFiles%\PowerShell\7\pwsh.exe" -NoP -NoL -W Hidden -C "Start-Process wt.exe -Args '-w new-tab -M -d \"%A_windir%\System32\" wsl.exe -d %_osName%' -Verb RunAs",, Max, _wPID
    Else
        Run, "%A_ProgramFiles%\PowerShell\7\pwsh.exe" -NoP -NoL -W Hidden -C "Start-Process wt.exe -Args '-w new-tab -M -d \"%_pwd%\" wsl.exe -d %_osName%' -Verb RunAs",, Max, _wPID
    _wPID := "ahk_pid " . _wPID
    WinWait, %_winPID%,, 2
    WinActivate, %_winPID%
}
Return
