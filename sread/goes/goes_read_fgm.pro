;+
; resolution. A string. Default is '512ms', can be '1m','5m','512ms'.
;-

pro goes_read_fgm, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_test, version=version, $
    local_root=local_root, remote_root=remote_root, $
    resolution=resolution, coordinate=coord

    compile_opt idl2
    on_error, 2
    errmsg = ''

;---Check inputs.
    sync_threshold = 1e7    ; sec of 4 months.
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','goes'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://satdat.ngdc.noaa.gov/sem/goes/data'
    if n_elements(version) eq 0 then version = ''
    if n_elements(resolution) eq 0 then resolution = '512ms'
    if n_elements(coord) eq 0 then coord = 'gsm'

;---Init settings.
    type_dispatch = hash()
    ; Magnetic field data 512ms.
    base_name = 'g'+probe+'_magneto_512ms_%Y%m%d_%Y%m%d.nc'
    local_path = [local_root,'goes'+probe,'fgm','512ms','%Y','%m','netcdf']
    remote_path = [remote_root,'full','%Y','%m','goes'+probe,'netcdf']
    type_dispatch['512ms'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name))

    ; Magnetic field data 1min or 5min.
    foreach key, ['1m','5m'] do begin
        base_name = 'g'+probe+'_magneto_'+key+'_%Y%m01_%Y%m[0-9]{2}.nc'
        local_path = [local_root,'goes'+probe,'fgm','low_res','%Y','%m','netcdf']
        remote_path = [remote_root,'avg','%Y','%m','goes'+probe,'netcdf']
        type_dispatch[key] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'sync_threshold', sync_threshold, $
            'cadence', 'month', $
            'extension', fgetext(base_name))
    endforeach

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

    ; no file is found.
    if n_elements(files) eq 0 then return


    ; read data to tplot.
    netcdf2tplot, files
    goes_combine_tdata, datatype='fgm', probe=probe, /noephem

    ; convert to fgm.
    pre1 = 'g'+probe+'_'
;    goes_read_orbit, time, probe=probe
;    get_data, pre1+'r_gsm', uts, rgsm
;    ets = stoepoch(uts,'unix')
;    rgei = sgsm2gei(rgsm, ets)
    pos = goes_load_pos(trange=time_string(time), probe=probe)
    uts = pos.time
    rgei = pos.pos_values
    store_data, pre1+'pos_gei', uts, rgei
    enp_matrix_make, pre1+'pos_gei'

    ; Need to choose which version of data to use.    
    max_b_enp = 200.
    fillval = !values.f_nan
    foreach enp_var, 'H_enp'+['','_1','_2'] do begin
        get_data, enp_var, times, b_enp
        if n_elements(b_enp) eq 1 then continue
        index = where(abs(b_enp) ge max_b_enp, count)
        if count eq 0 then break
        b_enp[index] = fillval
        index = where(finite(snorm(b_enp),/nan))
        b_enp[index,*] = fillval
        store_data, enp_var, times, b_enp
    endforeach
    
    tvector_rotate, pre1+'pos_gei_enp_mat', enp_var, $
        invert=1;, vector_skip_nonmonotonic=1   ; Sheng not worth to set vector_skip_nomonotonic b/c it's often just bad data.
    bgeivar = enp_var+'_rot'
    get_data, bgeivar, uts, bgei
    if n_elements(uts) eq 1 and uts[0] eq 0 then begin
        errmsg = 'No valid data ...'
        return
    endif
    ets = stoepoch(uts,'unix')
    bgsm = sgei2gsm(bgei, ets)

    bgsmvar = pre1+'b_gsm'
    case n_elements(time) of
        2: idx = where(uts ge time[0] and uts le time[1])
        1: tmp = where(uts-time[0], /absolute, idx)
        else: begin
            errmsg = handle_error('No data in given time ...')
            return
            end
    endcase
    uts = uts[idx]
    bgsm = bgsm[idx,*]
    store_data, bgsmvar, uts, bgsm, limits=$
        {colors:[6,4,2],labels:'GSM B'+['x','y','z'],ytitle:'(nT)',labflag:-1}

    ; cleanup.
    vars = ['BTSC_?','HT_?','H_enp_?','Bsc_?','Bsens_?',$
        pre1+'pos_gei',pre1+'pos_gei_enp_mat',bgeivar]
    store_data, vars, /delete

end

utr0 = time_double(['2014-08-28','2014-08-29'])
probe = '13'

utr0 = time_double(['2019-09-06','2019-09-07'])
utr0 = time_double(['2019-08-07','2019-08-08'])
;utr0 = time_double(['2019-09-07','2019-09-08'])
probe = '15'

pre0 = 'g'+probe+'_'
goes_read_fgm, utr0, probe=probe, id='512ms'
get_data, pre0+'b_gsm', uts, bgsm
bsm = cotran(bgsm, uts, 'gsm2sm')
store_data, pre0+'b_sm', uts, [[bsm],[snorm(bsm)]], limits=$
    {colors:sgcolor(['red','green','blue','black']), labels:'SM B'+['x','y','z','t'], ytitle:'(nT)', labflag:-1}
tplot, pre0+'b_sm'
end
