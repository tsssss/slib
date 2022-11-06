;+
; Return the unique elements of an array, a list, 
;-

function unique, things, at=key

    retval = !null
    nthing = n_elements(things)
    if nthing eq 0 then return, retval
    if nthing eq 1 then return, things
    
    if n_elements(key) eq 0 then key = ''
    uniq_value = list()
    uniq_index = list()
    foreach thing, things, ii do begin
        if isa(thing,'hash') or isa(thing,'dictionary') then begin
            if ~thing.haskey(key) then continue
            val = thing[key]
        endif else if isa(thing,'struct') then begin
            thetag = strupcase(key)
            tags = tag_names(struct)
            index = where(tags eq thetag, count)
            if count eq 0 then continue
            val = thing.(index[0])
        endif else val = thing
        
        if uniq_value.where(val) ne !null then continue
        uniq_value.add, val
        uniq_index.add, ii
    endforeach
    
    if n_elements(uniq_index) eq 0 then return, retval
    return, things[uniq_index.toarray()]

end
