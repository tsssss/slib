;+
; Test to mask perigee E field after eclipse.
;-


    probe = 'a'
    time_range = time_double(['2015-01-01','2019-01-01'])
    boom_pair = '12'

    data_file = join_path([homedir(),'rbspa_data_after_2015.cdf'])

    e_var = 'efield_in_corotation_frame_spinfit_mgse_'+boom_pair
    if check_if_update(e_var) then cdf2tplot, data_file
    get_data, e_var, times, e_mgse
    
    foreach var, tnames('efield_in_corotation_frame_spinfit_mgse_??') do begin
        options, var, 'colors', constant('rgb')
    endforeach

    perigee_lshell = 3
    dis = snorm(get_var_data('position_gse'))/constant('re')
    perigee_index = where(dis ge perigee_lshell, count)
    if count eq 0 then message, 'Inconsistency ...'
    fillval = !values.f_nan
    e_mgse[perigee_index,*] = fillval
    store_data, 'e_mgse', times, e_mgse, limits={$
        ytitle:'Spinfit from V'+boom_pair+'!C(mV/m)', $
        colors: constant('rgb'), $
        labels: constant('xyz'), $
        labflag: -1, $
        yrange: [-1,1]*100, $
        ystyle: 1, $
        constant: [0,[-1,1]*50] }

    flags = get_var_data('flags_all_'+boom_pair)
    eclipse_flag = flags[*,1]
    store_data, 'eclipse', times, eclipse_flag, limits={$
            ytitle: 'Flag (#)', $
            yrange: [-0.1,1.1], $
            ystyle: 1, $
            ytickv: [0,1], $
            yticks: 1, $
            yminor: 0, $
            labels: 'Eclipse' }

    vars = ['e_mgse','eclipse']
    tplot, vars, trange=time_range


end
