;+
; Get the basename of a given full filename.
;-

function fgetbase, files
    nfile = n_elements(files)
    bases = strarr(nfile)
    for ii=0, nfile-1 do begin
        last = strmid(files[ii],0,1,/reverse_offset)
        if last eq '/' or last eq '\' then continue
        bases[ii] = file_basename(files[ii])
    endfor
    return, reform(bases)
end
