;+
; Test what the perigee residue looks like in GSE.
;
; The jump around the beginning of 2013 is purely caused by maneuver. mgse2gse over the whole mission is too resource consuming. Don't do it again.
;-

time_range = time_double(['2012-09','2019-09'])
probes = ['a','b']

xyz = constant('xyz')
rgb = constant('rgb')

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'

    rbsp_efw_phasef_read_e_fit_var, time_range, probe=probe

    var = prefix+'e1_mgse'
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=var
    get_data, var, times, e1_mgse
    e1_mgse[*,0] = 0
    store_data, var, times, e1_mgse, limits=lim

    e_var = prefix+'e1_mgse'
    b_var = prefix+'b_mgse'
    new_var = prefix+'e1dotb_mgse'
    rbsp_efw_calc_edotb_to_zero, e_var, b_var, newname=new_var, no_preprocess=1

    get_data, new_var, times, e_mgse
    stop    ; too slow and memory consumng. Don't do it again.
    e_gse = cotran(e_mgse, times, 'mgse2gse', probe=probe)
    e_var = prefix+'e_gse'
    store_data, e_var, times, e_gse
    add_setting, e_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'GSE', $
        'coord_labels', xyz )

    vars = e_var+'_'+xyz
    stplot_split, e_var, newname=vars, labels='GSE E!D'+xyz, colors=rgb
    ylim, vars, [-1,1]*6

    sgopen, 0, xsize=6, ysize=4
    tplot, vars
    stop

endforeach

end
