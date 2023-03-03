

function rbsp_plot_pa2d_read_data, input_time_range, probe=probe, species=species, get_name=get_name


    prefix = 'rbsp'+probe+'_'
    flux_var = strupcase('f'+species+'du')
    output_var = prefix+strlowcase(flux_var)

    
    time_range = time_double(input_time_range)
    files = rbsp_load_hope(time_range, id='l3%pa', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    suffix = (species eq 'e')? '_Ele': '_Ion'
    time_var = 'Epoch'+suffix
    energy_var = 'HOPE_ENERGY'+suffix
    dtime_var = time_var+'_DELTA'
    var_list.add, dictionary($
        'in_vars', [energy_var,flux_var,dtime_var], $
        'time_var_name', time_var, $
        'time_var_type', 'Epoch' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    ; Remove invalid data.
    fillval = 0
    get_data, flux_var, common_times, orig_fluxs
    index = where(abs(orig_fluxs) ge 1e30 or finite(orig_fluxs,nan=1), count)
    if count ne 0 then orig_fluxs[index] = fillval
    orig_pitch_angles = cdf_read_var('PITCH_ANGLE', filename=files[0])
    npitch_angle = n_elements(orig_pitch_angles)
    dtimes = get_var_data(dtime_var)*1e-3
    orig_energys = get_var_data(energy_var)

    ; Test: combine every several energy bins.
    if keyword_set(combine_energy_bin) then begin
        ncombo = 2
        combo_energys = sqrt(orig_energys[*,0:*:ncombo]*orig_energys[*,1:*:ncombo])
        combo_fluxs = 0.5*(orig_fluxs[*,0:*:ncombo,*]+orig_fluxs[*,1:*:ncombo,*])
    endif else begin
        combo_energys = orig_energys
        combo_fluxs = orig_fluxs
    endelse

    ; The two pitch angle bins in the original pitch angle are 4.5 deg away from 0 and 180 deg.
    ; They are effectively at 0 and 180 deg and then all pitch angle diffs are 18 deg.
    nangle = npitch_angle*2-2
    dangle = 360/nangle
    pitch_angles = smkarthm(0,360-dangle,dangle,'dx')
    

    output_var = duplicate_var(flux_var, output=output_var)
    options, flux_var, 'pitch_angles', pitch_angles
    options, flux_var, 'dtimes', dtimes
    options, flux_var, 'combo_energys', combo_energys
    store_data, output_var, common_times, combo_fluxs
    
    return, flux_var

end