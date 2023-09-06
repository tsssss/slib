

pro themis_read_mag_per_site, time, id=datatype, site=site, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, remote_root=remote_root, $
    sync_after=sync_after, file_times=file_times, index_file=index_file, skip_index=skip_index, $
    sync_index=sync_index, sync_files=sync_files, stay_local=stay_loca, $
    time_var_name=time_var_name, time_var_type=time_var_type, generic_time=generic_time

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('No time or file is given ...')
        return
    endif
    if n_elements(site) eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'http://themis.ssl.berkeley.edu/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    thx = 'thg'
    pre0 = thx+'_'+site+'_'
    pre1 = thx+'_mag_'

    sync_threshold = 86400d*120
    base_name = thx+'_l2_mag_'+site+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,thx,'l2','mag',site,'%Y']
    remote_path = [remote_root,thx,'l2','mag',site,'%Y']
    type_dispatch = hash()
    type_dispatch['l2%mag'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', pre1+site, $
                'out_vars', pre0+'mag', $
                'time_var_name', pre1+site+'_time', $
                'time_var_type', 'unix')))    


    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif

;---Dispatch patterns.
    datatype = 'l2%mag'
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

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

end


pro themis_read_mag, time, sites=sites, errmsg=errmsg, $
    mlon_range=mlon_range, mlat_range=mlat_range, component=component, $
    sort_by_mlon=sort_by_mlon, sort_by_mlat=sort_by_mlat

    compile_opt idl2
    on_error, 0
    errmsg = ''

    test = 1

;---Check inputs.
    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif
    if size(time,/type) eq 7 then time = time_double(time)

    site_infos = themis_read_mag_metadata(sites=sites)
    nsite_info = n_elements(site_infos)
    nsite = n_elements(sites)
    sites = site_infos.id

    if n_elements(mlon_range) eq 2 then begin
        index = where_pro(site_infos.mlon, 'in', mlon_range, count=count)
        if count eq 0 then begin
            errmsg = handle_error('No site in MLon range: '+mlon_range+' ...')
            return
        endif
        sites = sites[index]
        site_infos = site_infos[index]
    endif

    if n_elements(mlat_range) eq 2 then begin
        index = where_pro(site_infos.mlat, 'in', mlat_range, count=count)
        if count eq 0 then begin
            errmsg = handle_error('No site in MLat range: '+mlat_range+' ...')
            return
        endif
        sites = sites[index]
        site_infos = site_infos[index]
    endif


;---Load data and merge.
    nsite = n_elements(sites)
    site_flags = bytarr(nsite)  ; 1 for error in loading data.
    foreach site, sites, ii do begin
        themis_read_mag_per_site, time, site=site, id='l2%mag', errmsg=errmsg
        if errmsg ne '' then site_flags[ii] = 1
        the_var = 'thg_'+site+'_mag'
        if check_if_update(the_var) then site_flags[ii] = 1
    endforeach
    
    ; Filter out the sites have no data.
    index = where(site_flags ne 1, nsite)
    if nsite eq 0 then begin
        errmsg = handle_error('No site has data ...')
        return
    endif
    sites = sites[index]
    site_infos = site_infos[index]
    
    ; Sort by MLon/MLat.
    sort_site = 0
    if keyword_set(sort_by_mlon) then begin
        index = sort(site_infos.mlon)
        sort_site = 1
    endif
    if keyword_set(sort_by_mlat) then begin
        index = sort(site_infos.mlat)
        sort_site = 1
    endif
    if sort_site then begin
        sites = sites[index]
        site_infos = site_infos[index]
    endif

    ; Merge sites and save as components.
    comps = ['h','d','z']   ; north, east, down.
    comp_indices = [0,1,2]
    if size(component,/type) eq 7 then begin
        index = (where(component eq comps, count))[0]
        if count ne 0 then begin
            comps = comps[index]
            comp_indices = comp_indices[index]
        endif
    endif
    ncomp = n_elements(comps)

    time_rate = 0.5 ; sec.
    times = time
    if n_elements(time) eq 2 then times = make_bins(time, time_rate)
    ntime = n_elements(times)

    mag_vars = 'thg_'+sites+'_mag'
    for ii=0, ncomp-1 do begin
        bdata = fltarr(ntime,nsite)
        for jj=0, nsite-1 do begin
            get_data, mag_vars[jj], uts, dat
            bdata[*,jj] = sinterpol(dat[*,comp_indices[ii]], uts, times)
        endfor
        for jj=0, nsite-1 do bdata[*,jj] -= bdata[0,jj]
        bvar = 'thg_db'+comps[ii]
        store_data, bvar, times, bdata, strupcase(sites)
        add_setting, bvar, /smart, {$
            display_type: 'list', $
            unit: 'nT', $
            short_name: 'dB!D'+comps[ii]+'!N'}
    endfor

end

time_range = time_double(['2014-08-28/10:00','2014-08-28/10:40'])
mlat_range = [61,71]
mlon_range = [-170,10]
themis_read_mag, time_range, mlat_range=mlat_range, mlon_range=mlon_range, component='h', /sort_by_mlon
get_data, 'thg_dbh', times, data, sites
themis_read_mag_gen_site_map, sites, mlat_range=mlat_range, mlon_range=mlon_range, filename=0, charsize=1, symsize=1
sgopen, 1, xsize=8, ysize=8
device, decomposed=0
loadct2, 43
tplot, 'thg_dbh', trange=time_range
sgclose


end
