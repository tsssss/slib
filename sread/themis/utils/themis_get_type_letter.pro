function themis_get_type_letter, id

    if id eq 'esa' then begin
        type_letter = 'e'
    endif else if id eq 'sst' then begin
        type_letter = 's'
    endif else if id eq 'esa_sst' then begin
        type_letter = 't'
    endif

    return, type_letter

end