;+
; Uncompress all .gz files within a given folder.
;-
;

pro polar_pwg_uncompress, loc_root

    if file_test(loc_root,/directory) eq 0 then message, loc_root+' does not exist ...'
    
    lprmsg, 'Processing '+loc_root+' ...'
    
    files = file_search(loc_root+'/*')
    flags = file_test(files,/directory)
    
    idx1 = where(flags eq 0, cnt1)
    if cnt1 ne 0 then begin
        zips = files[idx1]
        idx = where(stregex(zips, '\.gz$') ne -1, cnt)
        if cnt ne 0 then begin
            zips = zips[idx]
            foreach zip, zips do begin
                lprmsg, 'Unzip '+zip+' ...'
                spawn, 'gunzip '+zip
            endforeach
        endif
    endif
    
    idx2 = where(flags eq 1, cnt2)
    if cnt2 ne 0 then begin
        dirs = files[idx2]
        lprmsg, 'Move into subdirectories ...'
        lprmsg, strjoin(dirs,', ')
        foreach dir, dirs do polar_pwg_uncompress, dir
    endif
    
end

;polar_pwg_uncompress, '/Volumes/Research/sdata/polar/pwg'
;end