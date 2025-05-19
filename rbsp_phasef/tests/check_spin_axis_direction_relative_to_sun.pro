;+
; Load the spin axis direction in GSE and check it's angle relative to GSE x.
;-

time_range = time_double(['2013','2017'])
time_range = time_double(['2013-01-01','2014-01-01'])
time_range = time_double(['2019-01-01','2019-02-01'])

probes = ['a','b']
deg = constant('deg')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    ang_var = prefix+'wsc_sun_angle'

    if ~check_if_update(ang_var, time_range) then continue
    rbsp_read_spice_var, time_range, probe=probe
    wsc_var = prefix+'wsc_gse'  ; m[*,*,2].
    get_data, wsc_var, times, wsc_gse
    angle = acos(wsc_gse[*,0]/snorm(wsc_gse))*deg
    store_data, ang_var, times, angle
    add_setting, ang_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'deg', $
        'constants', make_bins([-20,20], 10), $
        'yrange', [-25,25], $
        'short_name', 'Sun Angle!C  RBSP-'+strupcase(probe) )
endforeach


ang_vars = 'rbsp'+probes+'_wsc_sun_angle'
tplot, ang_vars, trange=time_range

probe = 'a'
prefix = 'rbsp'+probe+'_'
get_data, prefix+'q_uvw2gse', times
times = sort_uniq(times)
ntime = n_elements(times)
x_gse = fltarr(ntime,3)
x_gse[*,0] = 1
x_mgse = cotran(x_gse, times, 'gse2mgse', probe=probe)

stop

end
