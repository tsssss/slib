;+
; Type: function.
;
; Purpose: Return the parent directory of given path.
;
; Parameters: none.
;
; Keywords:
;   level, in, int, optional. Set to go # of level up. Default is 1.
;   trailing_slash, in, boolean, optional. Set to add a trailing slash.
;
; Return:
;   string. The aboslute path of the parent directory.
;
; Notes: Returns '.' if called from IDL console, ie, IDL> print, srootdir().
;
; Dependence: none.
;
; History:
;   2016-06-19, Sheng Tian, create.
;-

function sparentdir, dir, level=level, trailing_slash = trailing_slash

    if keyword_set(level) eq 0 then level = 1
    sep = path_sep()

    dirs = strsplit(dir, '/\', /extract)
    ndir = n_elements(dirs)
    if ndir ge 2 then dirs = dirs[0:ndir-1-level]
    rootdir = strjoin(dirs, sep)
    tmp = strmid(dir,0,1)
    if tmp eq '/' or tmp eq '/' then rootdir = sep+rootdir
    
    if keyword_set(trailing_slash) then rootdir+= sep
    return, rootdir

end
