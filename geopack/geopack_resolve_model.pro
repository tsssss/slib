;+
; Resolve model to a structure to be input to other geopack routines.
;-

function geopack_resolve_model, input_model

    model = strlowcase(input_model)
    info = dictionary($
        't89', 0, $
        't96', 0, $
        't01', 0, $
        't04', 0, $
        'storm', 0 )

    the_model = strmid(model,0,3)
    if info.haskey(the_model) then begin
        info[the_model] = 1
    endif
    index = strpos(model,'04')
    if index[0] ge 0 then info['t04'] = 1
    index = strpos(model,'s')
    if index[0] ge 0 then info['storm'] = 1

    info['ts04'] = info['t04']
    info.remove, 't04'

    return, info.tostruct()

end

info = geopack_resolve_model('ts04')
end