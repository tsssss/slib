;+
; Read the horizontal ionosphere current.
;-


function themis_read_weygand_parse_eics, file, glat, glon
    ; Horizontal current:
    ;   Jx (mA/m, points to geographic north),
    ;   Jy (mA/m, points to geographic east)

    nline = file_lines(file)
    if nline ne 183 then return, !null
    ncol = 4
    data = fltarr(ncol, nline)
    openr, lun, file, /get_lun
    readf, lun, data
    free_lun, lun

    glat = reform(data[0,*])
    glon = reform(data[1,*])
    return, transpose(data[2:3,*])

end

function themis_read_weygand_parse_secs, file, glat, glon
    ; Vertical current: J (A, points to vertical up)

    nline = file_lines(file)
    ncol = 3
    data = fltarr(ncol, nline)
    openr, lun, file, /get_lun
    readf, lun, data
    free_lun, lun

    glat = reform(data[0,*])
    glon = reform(data[1,*])
    return, transpose(data[2,*])

end

pro themis_read_weygand_gen_file, file_time, filename=local_file, remote_root=remote_root, errmsg=errmsg

    local_path = fgetpath(local_file)
    foreach the_type, ['EICS','SECS'] do begin
        base_name = apply_time_to_pattern(the_type+'%Y%m%d', file_time)
        zip_name = base_name+'.zip'
        zip_file = join_path([local_path,zip_name])
        remote_file = apply_time_to_pattern(join_path([remote_root,the_type,'%Y','%m',zip_name]), file_time)
        download_file, zip_file, remote_file, errmsg=errmsg
        if errmsg ne '' then begin
            if file_test(zip_file) eq 1 then file_delete, zip_file
            return
        endif
        
        file_unzip, zip_file, files=orig_files
        index = where(stregex(orig_files, '\.dat') ne -1, nfile, complement=index2)
        if nfile eq 0 then begin
            errmsg = 'No data ...'
            return
        endif
        zip_dir = orig_files[index2]
        files = orig_files[index]
        times = time_double(strmid(fgetbase(files),4,15),tformat='YYYYMMDD_hhmmss') ; some files are duplicated.
        index = uniq(times,sort(times))
        files = files[index]
        times = times[index]

        time_var = 'ut'
        if ~cdf_has_var(time_var, filename=local_file) then begin
            cdf_save_var, time_var, value=times, filename=local_file
            cdf_save_setting, varname=time_var, filename=local_file, dictionary($
                'unit', 'sec', $
                'var_type', 'support_data' )
        endif

        case the_type of
            'EICS': suffix = '_j_hor'
            'SECS': suffix = '_j_ver'
        endcase

        routine = 'themis_read_weygand_parse_'+the_type
        tmp = call_function(routine, files[0], glat, glon)
        glat_var = 'thg_glat'+suffix
        cdf_save_var, glat_var, filename=local_file, value=glat
        glon_var = 'thg_glon'+suffix
        cdf_save_var, glon_var, filename=local_file, value=glon


        data = fltarr([nfile,size(tmp,/dimensions)])
        foreach file, files, ii do begin
            tmp = call_function(routine, file)
            if n_elements(tmp) eq 0 then continue
            data[ii,*,*] = tmp
        endforeach
        case the_type of
            'EICS': begin
                var_name = 'thg'+suffix
                settings = dictionary($
                    'display_type', 'vector', $
                    'unit', 'mA/m', $
                    'short_name', 'J', $
                    'coord', '', $
                    'coord_labels', ['x','y'], $
                    'colors', sgcolor(['red','blue']) )
                end
            'SECS': begin
                var_name = 'thg'+suffix
                settings = dictionary($
                    'display_type', 'scalar', $
                    'unit', 'A', $
                    'short_name', 'J' )
                end
        endcase
        settings['depend_0'] = time_var
        settings['depend_1'] = glat_var
        settings['depend_2'] = glon_var

        cdf_save_var, var_name, value=data, filename=local_file
        cdf_save_setting, varname=var_name, filename=local_file, settings


        ; Clean up.
        nfile = n_elements(orig_files)
        flags = bytarr(nfile)
        for ii=0, nfile-1 do flags[ii] = file_test(orig_files[ii], directory=1)
        index = where(flags eq 0, complement=index2)
        file_delete, orig_files[index], allow_nonexistent=1
        file_delete, orig_files[index2], allow_nonexistent=1
        file_delete, zip_file, allow_nonexistent=1
        file_delete, zip_dir, allow_nonexistent=1
    endforeach

end


pro themis_read_weygand, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    probe = 'g'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','themis','thg'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/aaa_special-purpose-datasets/spherical-elementary-and-equivalent-ionospheric-currents-weygand'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

;---Init settings.
    type_dispatch = hash()
    thx = 'th'+probe
    valid_range = ['2007-01-19']    ; the start date applies to tha-the.
    base_name = 'thg_weygand_'+'%Y_%m%d.cdf'
    local_path = [local_root,'weygand','%Y']
    types = ['hor','ver']
    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', 'thg_j_'+types, $
                'time_var_name', 'ut', $
                'time_var_type', 'unix')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            themis_read_weygand_gen_file, file_time, filename=local_file, remote_root=remote_root
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    if n_elements(files) eq 0 then begin
        errmsg = 'No data ...'
        return
    endif
    read_files, time, files=files, request=request, errmsg=errmsg
    if errmsg ne '' then return

;---Read glat and glon and map 1D data to 2D grid.
    foreach type, types do begin
    ;foreach type, types do begin
        j_var = 'thg_j_'+type
        glat_var = 'thg_glat_j_'+type
        glon_var = 'thg_glon_j_'+type

        glat = cdf_read_var(glat_var, filename=files[0])
        glon = cdf_read_var(glon_var, filename=files[0])
        glatbins = sort_uniq(glat)
        glonbins = sort_uniq(glon)
        nglatbin = n_elements(glatbins)
        nglonbin = n_elements(glonbins)
        if nglatbin eq 0 then begin
            errmsg = 'No data ...'
            return
        endif
        glatbinsize = glatbins[1]-glatbins[0]
        glonbinsize = glonbins[1]-glonbins[0]
        glat_index = round((glat-glatbins[0])/glatbinsize)
        glon_index = round((glon-glonbins[0])/glonbinsize)

        get_data, j_var, times, j_orig
        ntime = n_elements(times)
        ndim = (type eq 'hor')? 2: 1
        jdata = fltarr(ntime,nglonbin*nglatbin,ndim)
        mapping_index = glon_index+glat_index*nglonbin
        jdata[*,mapping_index,*] = j_orig
        jdata = reform(jdata, [ntime,nglonbin,nglatbin,ndim])
        store_data, j_var, times, jdata
        options, j_var, 'glonbins', glonbins
        options, j_var, 'glatbins', glatbins


    ;;---Convert glat/glon to mlat/mlon.
        ;apexfile = join_path([homedir(),'Projects','idl','spacephys','aurora','image','support','mlatlon.1997a.xdr'])
        ;geotoapex, glat, glon, apexfile, mlat, mlon
;
        ;mlat2d = fltarr(nglonbin*nglatbin)
        ;mlat2d[mapping_index] = mlat
        ;mlat2d = reform(mlat2d, [nglonbin,nglatbin])
;
        ;mlon2d = fltarr(nglonbin*nglatbin)
        ;mlon2d[mapping_index] = mlon
        ;mlon2d = reform(mlon2d, [nglonbin,nglatbin])
;
        ;mlatbins = make_bins([55,85],2)
        ;mlonbins = make_bins([-150,50],4)
        ;nmlatbin = n_elements(mlatbins)
        ;nmlonbin = n_elements(mlonbins)
        ;jdata_m = fltarr(ntime,nmlonbin,nmlatbin,ndim)
        ;for ii=0,ntime-1 do begin
            ;jdata_g = reform(jdata[ii,*,*,0])
            ;jdata_m[ii,*,*,0] = griddata(mlon2d[*], mlat2d[*], jdata_g[*], grid=1, xout=mlonbins, yout=mlatbins)
        ;endfor
;
;test = 0
        ;ct = 70
        ;max_j = 2.5e5
        ;margins = [8,4,10,1]
        ;xticklen = -0.015
        ;colors = reverse(findgen(255))
        ;fig_ysize = 3
        ;time_range = minmax(times)
;
;
    ;;---Glonlat.
        ;fig_xsize = 4
        ;sgopen, 0, xsize=fig_xsize, ysize=fig_ysize, /inch, xchsz=xchsz, ychsz=ychsz
        ;tpos = sgcalcpos(1, margins=margins, xchsz=xchsz, ychsz=ychsz)
        ;yticklen = xticklen/(tpos[2]-tpos[0])*(tpos[3]-tpos[1])
        ;cbpos = tpos[[2,1,2,3]]+[1,0,2,0]*xchsz
        ;fig_dir = join_path([homedir(),'vertical_current_glonlat'])
        ;fig_files = strarr(ntime)
;
        ;for ii=0,ntime-1 do begin
            ;ofn = join_path([fig_dir,'vertical_current_glonlat_'+time_string(times[ii],tformat='YYYY_MMDD_hhmm_ss')+'.png'])
            ;if keyword_set(test) then ofn = 0
            ;sgopen, ofn, xsize=fig_xsize, ysize=fig_ysize, /inch, xchsz=xchsz, ychsz=ychsz
            ;erase, sgcolor('white')
            ;sgtv, bytscl(reform(-jdata[ii,*,*,0]),min=-max_j,max=max_j), ct=ct, position=tpos, /resize
            ;plot, glonbins, glatbins, /nodata, /noerase, $
                ;xstyle=1, xticklen=xticklen, xtitle='GLon (deg)', $
                ;ystyle=1, yticklen=yticklen, ytitle='GLat (deg)', $
                ;position=tpos
            ;tx = tpos[0]+xchsz*0.5
            ;ty = tpos[3]-ychsz*0.8
            ;xyouts, tx,ty, /normal, time_string(times[ii])+' UT'
            ;sgcolorbar, colors, ct=ct, zrange=[-1,1]*max_j, ztitle='Vertical J (A), red (>0) for upward', position=cbpos
            ;if keyword_set(test) then stop
            ;sgclose
            ;fig_files[ii] = ofn
        ;endfor
;
        ;mov_file = join_path([homedir(),'vertical_current_glonlat_'+strjoin(time_string(time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.mp4'])
        ;spic2movie, fig_dir, mov_file, 'png'
;
;
;
    ;;---Mlonlat.
        ;fig_xsize = 6
        ;sgopen, 0, xsize=fig_xsize, ysize=fig_ysize, /inch, xchsz=xchsz, ychsz=ychsz
        ;tpos = sgcalcpos(1, margins=margins, xchsz=xchsz, ychsz=ychsz)
        ;yticklen = xticklen/(tpos[2]-tpos[0])*(tpos[3]-tpos[1])
        ;cbpos = tpos[[2,1,2,3]]+[1,0,2,0]*xchsz
        ;fig_dir = join_path([homedir(),'vertical_current_mlonlat'])
        ;fig_files = strarr(ntime)
        ;for ii=0,ntime-1 do begin
            ;ofn = join_path([fig_dir,'vertical_current_mlonlat_'+time_string(times[ii],tformat='YYYY_MMDD_hhmm_ss')+'.png'])
            ;if keyword_set(test) then ofn = 0
            ;sgopen, ofn, xsize=fig_xsize, ysize=fig_ysize, /inch, xchsz=xchsz, ychsz=ychsz
            ;erase, sgcolor('white')
            ;sgtv, bytscl(reform(-jdata_m[ii,*,*,0]),min=-max_j,max=max_j), ct=ct, position=tpos, /resize
            ;plot, mlonbins, mlatbins, /nodata, /noerase, $
                ;xstyle=1, xticklen=xticklen, xtitle='MLon (deg)', $
                ;ystyle=1, yticklen=yticklen, ytitle='MLat (deg)', $
                ;position=tpos
            ;tx = tpos[0]+xchsz*0.5
            ;ty = tpos[3]-ychsz*0.8
            ;xyouts, tx,ty, /normal, time_string(times[ii])+' UT'
            ;sgcolorbar, colors, ct=ct, zrange=[-1,1]*max_j, ztitle='Vertical J (A), red (>0) for upward', position=cbpos
            ;if keyword_set(test) then stop
            ;sgclose
            ;fig_files[ii] = ofn
        ;endfor
;
        ;mov_file = join_path([homedir(),'vertical_current_mlonlat_'+strjoin(time_string(time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.mp4'])
        ;spic2movie, fig_dir, mov_file, 'png'
    endforeach

end


time = time_double(['2014-08-28/10:05','2014-08-28/10:20'])
time = time_double(['2007-03-23/10:05','2007-03-23/10:20']) ; No data online.
time = time_double(['2007-06-04/10:05','2007-06-04/10:20']) ; Duplicated data.
time = time_double(['2007-08-17/10:05','2007-08-17/10:20']) ; irregular txt file.
time = time_double(['2007-12-12/10:05','2007-12-12/10:20']) ; data gap.

themis_read_weygand, time
end
