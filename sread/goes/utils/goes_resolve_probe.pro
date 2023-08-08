function goes_resolve_probe, input_probe

    if size(input_probe, type=1) ne 7 then begin
        probe = strlowcase(string(input_probe,format='(I0)'))
    endif else begin
        probe = input_probe
        if strmid(probe,0,1) eq 'g' then probe = strmid(probe,1)
    endelse
    
    return, probe

end