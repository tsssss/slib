;+
; resolution. A string. Default is '512ms', can be '1min','5min','512ms'.
;-

pro goes_read_fgm, time, datatype, probe=probe, print_datatype=print_datatype, $
    variable=vars, files=files, level=level, version=version, id=id, errmsg=errmsg, $
    resolution=resolution, coordinate=coord
    
    compile_opt idl2
    on_error, 0
    errmsg = ''

    
    nfile=n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('No time or file is given ...')
        return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    
    if n_elements(resolution) eq 0 then resolution = '512ms'
    if n_elements(coord) eq 0 then coord = 'gsm'
    loc_root = join_path([data_root_dir(),'data','goes'])
    rem_root = 'https://satdat.ngdc.noaa.gov/sem/goes/data'
    version = (n_elements(version) eq 0)? 'v[0-9]{2}': version
    pre0 = 'g'+probe

    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: '512ms', $
        base_pattern: 'goes'+probe+'_magneto_512ms_%Y%m%d_%Y%m%d.nc', $
        remote_pattern: join_path([rem_root,'new_full','%Y','%m','goes'+probe]), $
        local_pattern: join_path([loc_root,'goes'+probe,'fgm','512ms','%Y'])}]
; haven't tested yet.
;    type_dispatch = [type_dispatch, $
;        {id: '1min', $
;        base_pattern: 'goes'+probe+'_magneto_1m_%Y%m01_%Y%m[0-9]{2}.nc', $
;        remote_pattern: join_path([rem_root,'new_avg','%Y','%m']), $
;        local_pattern: join_path([loc_root,'fgm','1min','%Y'])}]
;    type_dispatch = [type_dispatch, $
;        {id: '5min', $
;        base_pattern: 'goes'+probe+'_magneto_5m_%Y%m01_%Y%m[0-9]{2}.nc', $
;        remote_pattern: join_path([rem_root,'new_avg','%Y','%m']), $
;        local_pattern: join_path([loc_root,'fgm','5min','%Y'])}]        
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif

    ; dispatch patterns.
    if n_elements(id) eq 0 then id = resolution
    ids = type_dispatch.id
    idx = where(ids eq id, cnt)
    if cnt eq 0 then message, 'Do not support type '+id+' yet ...'
    myinfo = type_dispatch[idx[0]]
  
    ; find files to be read. download directly if local file does not exist.
    file_cadence = 86400.
    if nfile eq 0 then begin
        index_file = 'remote-index.html'
        times = break_down_times(time, file_cadence)
        patterns = [myinfo.base_pattern, myinfo.local_pattern, myinfo.remote_pattern]
        files = find_data_file(time, patterns, index_file, $
            file_cadence=file_cadence)
    endif
    
    ; no file is found.
    if n_elements(files) eq 1 and files[0] eq '' then begin
        errmsg = handle_error('No file is found ...')
        return
    endif

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
    enp_var = (uint(probe) ge 13)? 'H_enp_1': 'H_enp'
    tvector_rotate, pre1+'pos_gei_enp_mat', enp_var, /invert
    bgeivar = enp_var+'_rot'
    get_data, bgeivar, uts, bgei
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
probe = '15'
pre0 = 'g'+probe+'_'
goes_read_fgm, utr0, probe=probe, file='/Users/Sheng/data/goes/new_full/2014/08/goes15/netcdf/g15_magneto_512ms_20140828_20140828.nc'
get_data, pre0+'b_gsm', uts, bgsm
ets = stoepoch(uts, 'unix')
bsm = sgsm2sm(bgsm, ets)
store_data, pre0+'b_sm', uts, [[bsm],[snorm(bsm)]], limits=$
    {colors:[2,4,6,0], labels:'SM B'+['x','y','z','t'], ytitle:'(nT)', labflag:-1}
tplot, pre0+'b_sm'
end