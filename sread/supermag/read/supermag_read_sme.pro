;+
; Read SME (AE-like) data.
;-

pro supermag_read_sme, input_time_range, errmsg=errmsg

    compile_opt idl2
    supermag_api

    time_range = time_double(input_time_range)
    files = supermag_load_indices_array(time_range, errmsg=errmsg)
    if errmsg ne '' then return

    prefix = 'sm_'
    in_vars = ['sme','regionalsme','regionalmlt','regionalmlat']
    time_var = 'time'
    vatt_info = dictionary($
        'sme', dictionary($
            'VAR_TYPE', 'data', $
            'DEPEND_0', time_var, $
            'UNITS', 'nT', $
            'VAR_NOTES', 'SME index' ), $
        'regionalsme', dictionary($
            'VAR_TYPE', 'data', $
            'DEPEND_0', time_var, $
            'UNITS', 'nT', $
            'VAR_NOTES', 'regional SME index' ), $
        'regionalmlt', dictionary($
            'VAR_TYPE', 'data', $
            'DEPEND_0', time_var, $
            'UNITS', 'h', $
            'VAR_NOTES', 'regional MLT, in [0,24] h' ), $
        'regionalmlat', dictionary($
            'VAR_TYPE', 'data', $
            'DEPEND_0', time_var, $
            'UNITS', 'deg', $
            'VAR_NOTES', 'regional MLat') )


    secofday = constant('secofday')
    foreach file, files do begin
        foreach var, in_vars do begin
            if cdf_has_var(var, filename=file) then continue
            common_times = cdf_read_var(time_var, filename=file)
            day_time_range = common_times[0]+[0,secofday]
            ntime = n_elements(common_times)
            if var eq 'sme' then begin
                tmp = supermaggetindicesarray(day_time_range, times, sme=val)
                if ntime ne n_elements(times) then message, 'Inconsistency ...'
                cdf_save_var, var, value=val, filename=file
                cdf_save_setting, vatt_info[var], varname=var, filename=file
            endif else if var eq 'regionalsme' then begin
                tmp = supermaggetindicesarray(day_time_range, times, regionalsme=val)
                if ntime ne n_elements(times) then message, 'Inconsistency ...'
                cdf_save_var, var, value=val, filename=file
                cdf_save_setting, vatt_info[var], varname=var, filename=file
            endif else if var eq 'regionalmlt' then begin
                tmp = supermaggetindicesarray(day_time_range, times, regionalsme=tmp, regionalmlt=val)
                if ntime ne n_elements(times) then message, 'Inconsistency ...'
                cdf_save_var, var, value=val, filename=file
                cdf_save_setting, vatt_info[var], varname=var, filename=file
            endif else if var eq 'regionalmlat' then begin
                tmp = supermaggetindicesarray(day_time_range, times, regionalsme=tmp, regionalmlat=val)
                if ntime ne n_elements(times) then message, 'Inconsistency ...'
                cdf_save_var, var, value=val, filename=file
                cdf_save_setting, vatt_info[var], varname=var, filename=file
            endif
        endforeach
    endforeach


    var_list = list()
    out_vars = prefix+in_vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg


;---Further processing.
    sme_var = prefix+'sme'
    get_data, sme_var, times, sme
    omni_read_index, time_range
    ae = get_var_data('ae', at=times)
    store_data, sme_var, times, [[sme],[ae]]
    add_setting, sme_var, smart=1, dictionary($
        'display_type', 'stack', $
        'ytitle', 'nT', $
        'labels', ['SME','AE'], $
        'colors', sgcolor(['red','black']) )

    smereg_var = prefix+'regionalsme'
    mltreg_var = prefix+'regionalmlt'
    get_data, smereg_var, times, smereg
    get_data, mltreg_var, times, mltreg
    mlt0 = total(mltreg,2)*0.5

    mlt1 = [[mlt0[*,12:23]-24],[mlt0],[mlt0[*,0:11]+24]]
    sme1 = [[smereg[*,12:23]],[smereg],[smereg[*,0:11]]]

    ntime = n_elements(times)
    nmlt = 24
    mlts = findgen(nmlt)
    sme2d = fltarr(ntime,nmlt)
    foreach time, times, time_id do begin
        tmlt = mlt1[time_id,*]
        index = sort(tmlt)
        sme2d[time_id,*] = interpol(sme1[time_id,index],tmlt[index], mlts, nan=1)
    endforeach

    ; Make midnight to be the center.
    if n_elements(dmlt) eq 0 then dmlt = 12
    mlts -= dmlt-0.5
    sme2d = shift(sme2d,0,dmlt)

    sme2d_var = prefix+'sme2d'
    store_data, sme2d_var, times, sme2d, mlts, limits={$
        ytitle:'MLT (h)', spec:1, no_interp:1, $
        yrange:minmax(mlts), ystyle:1, $
        ztitle: 'SME (nT)', color_table:49, zrange: [0d,1000] }
    add_setting, sme2d_var, smart=1


end

test_time_range = list()
test_time_range.add, ['2016-10-13/05:00','2016-10-14/12:00']
test_time_range.add, ['2014-08-27/00:00','2014-08-29/00:00']
test_time_range.add, ['2014-09-12/00:00','2014-09-14/00:00']
test_time_range.add, ['2017-03-01/00:00','2017-03-03/00:00']
test_time_range.add, ['2017-03-27/00:00','2017-03-29/00:00']
test_time_range.add, ['2009-02-26/00:00','2009-02-27/00:00']
test_time_range.add, ['2008-01-19/06:00','2008-01-19/09:00']
test_time_range.add, ['2008-01-21/07:00','2008-01-21/10:00']
test_time_range.add, ['2016-08-09/08:00','2016-08-09/12:30']
test_time_range.add, ['2013-06-06','2013-06-09']
test_time_range.add, ['2013-03-17','2013-03-18/06:00']
test_time_range.add, ['2013-04-30','2013-05-03/00:00']
test_time_range.add, ['2013-05-31/18:00','2013-06-02']
test_time_range.add, ['2013-06-28/06:00','2013-06-30']
test_time_range.add, ['2013-10-02','2013-10-03']
test_time_range.add, ['2013-10-08/18:00','2013-10-10']
test_time_range.add, ['1998-08-06','1998-08-07']
test_time_range.add, ['1998-09-24/18:00','1998-09-26']
test_time_range.add, ['1998-11-13','1998-11-15']

foreach time_range, test_time_range do begin
	supermag_read_sme, time_range
	base = 'suvey_plot_for_dst_sme_'+strjoin(time_string(time_range,tformat='YYYY_MMD_hhmm'),'_to_')+'_v01.pdf'
	plot_file = join_path([googledir(),'works','azim_dp','plots','supermag_sme',base])
	if keyword_set(test) then plot_file = 0

	vars = ['dst','sm_sme','sm_sme2d']
	nvar = n_elements(vars)
	sgopen, plot_file, xsize=10, ysize=4

	poss = sgcalcpos(nvar, margins=[12,4,10,2])
	tplot, vars, position=poss, trange=time_range

	if keyword_set(test) then stop
	sgclose

endforeach
end
