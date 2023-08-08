;+
; Return the full path to a given file, 
; or return the full path to the current program.
; 
; This replaced sparentdir and srootdir.
; 
; files. An array of strings containing full file names.
; level=1. A number sets to go how many levels up.
;-
function fgetpath, files, level=level

    if n_elements(level) eq 0 then level = 1
    if n_elements(files) eq 0 then begin
        calls = scope_traceback(/struct)
        ncall = n_elements(calls)
        files = (ncall lt 2)? join_path([!dir,'tmp']): calls[ncall-2].filename
    endif
    
    dirs = (level gt 1)? file_dirname(fgetpath(files)): file_dirname(files)
    dirs = treatslash(dirs)

    return, dirs
end

files = list()
;files.add, '/home/user/test.txt'
;files.add, '\home\user\test.txt'
;files.add, '\home\user/test.txt'
;files.add, '\home\user\'
;files.add, '\home\user'
files.add, 'hehe'
files.add, !null
files.add, 'ftp:\\hehe\\haha'
files.add, 'ftp:\\hehe\haha\piou\\piou'


foreach file, files do print, fgetpath(file,level=2)
end
