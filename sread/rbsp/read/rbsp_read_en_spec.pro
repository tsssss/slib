;+
; Read the energy-time spectrogram, for a given pitch angle.
; time_range.
; probe=.
;-

function rbsp_read_en_spec, input_time_range, probe=probe, errmsg=errmsg, $
    species=species, get_name=get_name, $
    pitch_angle_range=pitch_angle_range

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

    spec_var = prefix+species+'_en_spec'
    if keyword_set(get_name) then return, spec_var

    time_range = time_double(input_time_range)
    files = rbsp_load_hope(time_range, id='l3%pa', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()

    suffix = (species eq 'e')? '_Ele': '_Ion'
    time_var = 'Epoch'+suffix
    energy_var = 'HOPE_ENERGY'+suffix
    flux_var = strupcase('f'+species+'du')
    var_list.add, dictionary($
        'in_vars', [energy_var,flux_var], $
        'time_var_name', time_var, $
        'time_var_type', 'Epoch' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    pitch_angles = cdf_read_var('PITCH_ANGLE', filename=files[0])
    npitch_angle = n_elements(pitch_angles)


    species_infos = dictionary()
    species_infos['e'] = dictionary('short_name', 'e!U-!N')
    species_infos['p'] = dictionary('short_name', 'H!U+!N')
    species_infos['o'] = dictionary('short_name', 'O!U+!N')
    species_infos['he'] = dictionary('short_name', 'He!U+!N')
    supported_species = species_infos.keys()

    fillval = !values.f_nan
    get_data, flux_var, times, fluxs
    index = where(abs(fluxs) ge 1e30, count)
    if count ne 0 then fluxs[index] = fillval


;---Treat pa.
    if n_elements(pitch_angle_range) eq 1 then begin
        tmp = min(pitch_angles-pitch_angle_range[0], abs=1, pitch_index)
        npitch_index = 1
    endif else if n_elements(pitch_angle_range) eq 2 then begin
        pitch_index = lazy_where(pitch_angles, '[]', pitch_angle_range, count=npitch_index)
        if npitch_index eq 0 then begin
            errmsg = 'Invalid pitch angle range ...'
            return, retval
        endif
    endif else begin
        npitch_index = npitch_angle
        pitch_index = findgen(npitch_index)
        pitch_angle_range = [0,180]
    endelse

    energys = get_var_data(energy_var)
    the_fluxs = fluxs[*,*,pitch_index]

    dims = size(the_fluxs,dimensions=1)
    data = reform(total(the_fluxs,3,nan=1)/dims[2])

    store_data, spec_var, times, data, energys

    zrange = (species eq 'e')? [1e4,1e10]: [1e4,1e8]
    species_name = species_infos[species].short_name
    add_setting, spec_var, /smart, {$
        display_type: 'spec', $
        unit: '#/cm!U2!N-s-sr-keV', $
        zrange: zrange, $
        species_name: species_name, $
        ytitle: 'Energy (eV)', $
        ylog: 1, $
        zlog: 1, $
        short_name: ''}
    if npitch_index eq 1 then begin
        the_pitch = pitch_angles[pitch_index]
        pitch_msg = sgnum2str(the_pitch)
    endif else begin
        pitch_msg = '['+sgnum2str(pitch_angle_range[0])+','+sgnum2str(pitch_angle_range[1])+']'
    endelse
    add_setting, spec_var, {$
        pitch_angle: pitch_angles[pitch_index], $
        ytitle: 'Energy (eV)!C'+species_name+', PA '+pitch_msg+' deg'}

    return, spec_var

end

time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])
probe = 'b'

vars = list()
foreach species, ['p','o'] do begin
    var = rbsp_read_en_spec(time_range, probe=probe, species=species, pitch_angle_range=[0,45])
    vars.add, rename_var(var, output=var+'_para')
    var = rbsp_read_en_spec(time_range, probe=probe, species=species, pitch_angle_range=[45,135])
    vars.add, rename_var(var, output=var+'_perp')
    var = rbsp_read_en_spec(time_range, probe=probe, species=species, pitch_angle_range=[135,180])
    vars.add, rename_var(var, output=var+'_anti')
endforeach
vars = vars.toarray()
options, vars, 'zrange', [1e4, 1e6]
options, vars, 'color_table', 40

sgopen, 0, xsize=8, ysize=10
nvar = n_elements(vars)
margins = [15,4,12,1]
poss = sgcalcpos(nvar, margins=margins)
tplot, vars, trange=time_range, position=poss
times = make_bins(time_range, 5*60, inner=1)
timebar, times, color=sgcolor('white'), linestyle=1
constants = [1e1,1e2,1e3,1e4]
yrange = [1,5e4]
xrange = time_range
for ii=0,nvar-1 do begin
    tpos = poss[*,ii]
    plot, xrange, yrange, $
        xstyle=5, ystyle=5, ylog=1, $
        nodata=1, noerase=1, position=tpos
    foreach ty, constants do begin
        oplot, xrange, ty+[0,0], linestyle=1, color=sgcolor('white')
    endforeach
endfor

end
