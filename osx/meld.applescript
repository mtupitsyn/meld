#!/usr/bin/env osascript

on run argv
    --set current_path to do shell script "echo $PWD"
    set macos_path to POSIX path of ((path to me as text) & "::")
    set contents_path to parentFolder for macos_path
    set frameworks_path to contents_path & "/Frameworks"
    set resources_path to contents_path & "/Resources"
    set library_path to (quoted form of frameworks_path) & ":" & (quoted form of (resources_path & "/lib"))

    -- return do shell script "cd " & quoted form of current_path &  ";DYLD_LIBRARY_PATH=" & library_path & " " & quoted form of (macos_path & "Meld-bin") & " " & argv
   
    set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to " "
    do shell script "DYLD_LIBRARY_PATH=" & library_path & " exec " & quoted form of (macos_path & "Meld-bin") & " " & argv as text & " --"
end run

-- FUNCTIONS

-- From https://stackoverflow.com/a/30824337
to parentFolder for aPath
    set aPath to posixPath for aPath
    set {tids, text item delimiters, i} to {text item delimiters, "/", ((aPath ends with "/") as integer) + 1}
    set {pF, text item delimiters} to {text 1 thru text item -(i + 1) of aPath, tids}
    return pF
end parentFolder

-- From https://stackoverflow.com/a/30824337
to posixPath for aPath
    if class of aPath is not text then set aPath to aPath as text
    if aPath contains ":" then set aPath to POSIX path of aPath
    repeat while aPath starts with "//"
        set aPath to (characters 2 thru -1 of aPath) as text
    end repeat
    repeat while aPath ends with "//"
        set aPath to (characters 1 thru -2 of aPath) as text
    end repeat
    return aPath
end posixPath