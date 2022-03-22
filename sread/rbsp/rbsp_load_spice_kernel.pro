;+
; Now that the mission is finished. Load all data from a remote source.
;-
pro rbsp_load_spice_meta_kernel, meta_file, $
    remote_root=remote_root, local_root=local_root, probe=probe

;---Read kernel file.
    openr, lun, meta_file, /get_lun

    line = ''
    inblock = 0

    while not eof(lun) do begin
      readf, lun, line
      if strmatch(line, '*KERNELS_TO_LOAD += (*') then inblock = 1
      if inblock then begin
          paren1 = strpos(line, "'")
          kerneltoload = strmid(line,paren1+1)
          paren2 = strpos(kerneltoload,"'")
          kerneltoload = strmid(kerneltoload,0,paren2)
          str_replace,kerneltoload,'$ROOT/',''
          str_replace,kerneltoload,'$RBSPA','MOC_data_products/RBSPA'
          str_replace,kerneltoload,'$RBSPB','MOC_data_products/RBSPB'
          str_replace,kerneltoload,'$CKP','attitude_predict'
          str_replace,kerneltoload,'$CKFULL','attitude_history_full'
          str_replace,kerneltoload,'$CKQUICK','attitude_history'
          str_replace,kerneltoload,'$FKG','teams/spice/fk'
          str_replace,kerneltoload,'$FK','frame_kernel'
          str_replace,kerneltoload,'$IK','teams/spice/ik'
          str_replace,kerneltoload,'$LSK','leap_second_kernel'
          str_replace,kerneltoload,'$PCK','teams/spice/pck'
          str_replace,kerneltoload,'$SCLK','operations_sclk_kernel'
          str_replace,kerneltoload,'$SPKPE','planetary_ephemeris'
          str_replace,kerneltoload,'$SPKP','ephemeris_predict'
          str_replace,kerneltoload,'$SPKD','ephemerides'

;        ; strip out extra attitude_history kernels
;        if strpos(kerneltoload,'attitude_history/') ne -1 then begin
;
;      		; kernels are suffixed with _YYYY_DOY_VV.ath.bc
;      		kernelbits=strsplit(kerneltoload,'_',/extract)
;      		nkernelbits=n_elements(kernelbits)
;      		kyear=long(kernelbits[nkernelbits-3])
;      		kdoy=long(kernelbits[nkernelbits-2])
;      		doy_to_month_date,kyear,kdoy,kmonth,kday
;      		sktime=string(kyear,kmonth,kday,format='(I04,"-",I02,"-",I02)')
;      		ktime=time_double(sktime)
;      		if (ktime lt tr[0]) or (ktime gt tr[1]) then kerneltoload=''
;
;        endif
;
;        ; strip out extra attitude history full monthly files
;        if strpos(kerneltoload,'attitude_history_full/') ne -1 then begin
;
;          ; kernels are suffixed with _YYYY_DOY_YYYY_DOY_VV.ath.bc
;          kernelbits=strsplit(kerneltoload,'_',/extract)
;          nkernelbits=n_elements(kernelbits)
;          kstartyear=long(kernelbits[nkernelbits-5])
;          kstartdoy=long(kernelbits[nkernelbits-4])
;          kendyear=long(kernelbits[nkernelbits-3])
;          kenddoy=long(kernelbits[nkernelbits-2])
;          doy_to_month_date,kstartyear,kstartdoy,kstartmonth,kstartday
;          doy_to_month_date,kendyear,kenddoy,kendmonth,kendday
;          skstarttime=string(kstartyear,kstartmonth,kstartday,format='(I04,"-",I02,"-",I02)')
;          kstarttime=time_double(skstarttime)
;          skendtime=string(kendyear,kendmonth,kendday,format='(I04,"-",I02,"-",I02)')
;          kendtime=time_double(skendtime)
;          if (kendtime lt tr[0]) or (kstarttime gt tr[1]) then kerneltoload=''
;
;        endif

            if kerneltoload eq '' then continue
            the_paths = strsplit(kerneltoload,'/',/extract)
            local_file = join_path([local_root,the_paths])
            remote_file = join_path([remote_root,the_paths])
            download_flag = 0
            finfo = file_info(local_file)
            rinfo = get_remote_info(remote_file)
            if finfo.size ne rinfo.size then download_flag = 1
            if download_flag then download_file, local_file, remote_file, errmsg=errmsg
            if finfo.mtime ne rinfo.mtime then ftouch, local_file, mtime=mtime

            print,'Processing '+local_file
            cspice_furnsh,local_file

            if strmatch(line, '*)*') then inblock = 0
        endif
    endwhile

    free_lun,lun

end

pro rbsp_load_spice_kernel, reload=reload, $
    local_root=local_root, remote_root=remote_root

    if icy_test() eq 0 then message, 'Need to install ICY SPICE first ...'
    defsysv, '!rbsp_spice', exists=flag
    if flag eq 1 then begin
        if ~keyword_set(reload) then return
    endif
    rbsp_spice_init

    if n_elements(remote_root) eq 0 then remote_root = 'http://themis.ssl.berkeley.edu/data/rbsp/'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])

    ; Load the meta kernel.
    probes = ['a','b']
    paths = ['teams','spice','mk']
    meta_files = 'rbsp_meta_'+['general','time','definitive']+'.tm'
    foreach meta_file, meta_files do begin
        remote_file = join_path([remote_root,paths,meta_file])
        local_file = join_path([local_root,paths,meta_file])
        download_flag = 0
        finfo = file_info(local_file)
        rinfo = get_remote_info(remote_file)
        if finfo.size ne rinfo.size then download_flag = 1
        if download_flag then download_file, local_file, remote_file, errmsg=errmsg
        if finfo.mtime ne rinfo.mtime then ftouch, local_file, mtime=mtime


        foreach probe, probes do begin
            rbsp_load_spice_meta_kernel, local_file, remote_root=remote_root, local_root=local_root, probe=probe
        endforeach
    endforeach

end
