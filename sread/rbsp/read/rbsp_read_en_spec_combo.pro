;+
; Read parallel, perp, and anti-parallel energy spectrogram.
; input_time_range.
; probe=.
; species=['p','o','he','e'].
; get_name=.
; errmsg=.
;-

function rbsp_read_en_spec_combo, input_time_range, probe=probe, $
    errmsg=errmsg, species=species, get_name=get_name

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(species) eq 0 then species = 'e'
    all_species = rbsp_hope_species()
    index = where(all_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif

    settings = dictionary($
        'para', list([0,45]), $
        'perp', list([45,135]), $
        'anti', list([135,180]) )

    vinfo = dictionary()
    foreach key, settings.keys() do begin
        vinfo[key] = prefix+species+'_en_spec_'+key
    endforeach
    if keyword_set(get_name) then return, vinfo
    time_range = time_double(input_time_range)

    foreach key, settings.keys() do begin
        if ~check_if_update(vinfo[key], time_range) then continue
        info = settings[key]
        pitch_angle_range = info[0]
        var = rbsp_read_en_spec(time_range, probe=probe, errmsg=errmsg, species=species, pitch_angle_range=pitch_angle_range)
        if errmsg ne '' then return, retval
        tmp = rename_var(var, output=vinfo[key])
    endforeach

    return, vinfo

end


time_range = ['2013-06-01/05:00','2013-06-01/08:00']
probe = 'a'
time_range = ['2013-05-01/05:00','2013-05-01/08:00']
probe = 'b'
vars = []
all_species = ['e','p','o']
foreach species, all_species do begin
    vinfo = rbsp_read_en_spec_combo(time_range, probe=probe, species=species)
    vars = [vars, (vinfo.values()).toarray()]
endforeach
sgopen, 0, xsize=8, ysize=10
tplot, vars, trange=time_range
end
