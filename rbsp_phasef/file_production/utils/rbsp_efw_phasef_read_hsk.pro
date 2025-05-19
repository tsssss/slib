;+
; Read EFW housekeeping data, return rbspx_[usher,gaurd,ibias].
;
; time_range. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-


; Adopted from rbsp_load_efw_hsk. Only load BEB data.
pro rbsp_load_efw_hsk_beb,probe=probe, datatype=datatype, trange=trange, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
    cdf_data=cdf_data,get_support_data=get_support_data, $
    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
    varformat=varformat, valid_names = valid_names, files=files,$
    type=type, integration=integration, msim=msim, etu=etu, qa=qa

    rbsp_efw_init

    if keyword_set(etu) then probe = 'a'

    if(keyword_set(probe)) then $
        p_var = strlowcase(probe)

    if n_elements(verbose) gt 0 then vb = verbose else begin
        vb = 0
        vb >= !rbsp_efw.verbose
    endelse

    vprobes = ['a','b']
    vlevels = ['l1','l2']
    vdatatypes=['hsk']


    if keyword_set(valid_names) then begin
        probe = vprobes
        level = vlevels
        datatype = vdatatypes
        return
    endif

    if not keyword_set(p_var) then p_var='*'
    p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

    if not keyword_set(datatype) then datatype='*'
    datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)

    if not keyword_set(level) then level='*'
    level = strfilter(vdatatypes, level ,delimiter=' ',/string)

    addmaster=0

    probe_colors = ['m','b']

    for s=0,n_elements(p_var)-1 do begin
        rbspx = 'rbsp'+ p_var[s]
        if keyword_set(integration) then rbsppref = rbspx + '/l1_int' $
        else if keyword_set(msim) then rbsppref = rbspx+ '/l1_msim' $
        else if keyword_set(etu) then rbsppref = rbspx+ '/l1_etu' $
        else if keyword_set(qa) then rbsppref = rbspx+ '/l1_qa' $
        else rbsppref = rbspx + '/l1'

        ;---------------------------------------------------------------
        ;Find out what BEB analog files are online
        format = rbsppref + '/hsk_beb_analog/YYYY/'+rbspx+'_l1_hsk_beb_analog_YYYYMMDD_v*.cdf'
        relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)

        ;...and load them
        file_loaded = []
        for ff=0, n_elements(relpathnames)-1 do begin
            undefine,lf
            localpath = file_dirname(relpathnames[ff])+'/'
            locpath = !rbsp_efw.local_data_dir+localpath
            remfile = !rbsp_efw.remote_data_dir+relpathnames[ff]
            tmp = spd_download(remote_file=remfile, local_path=locpath, local_file=lf,/last_version)
            locfile = locpath+lf
            if file_test(locfile) eq 0 then locfile = file_search(locfile)
            if locfile[0] ne '' then file_loaded = [file_loaded,locfile]
        endfor

        if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue
        suf=''
        prefix=rbspx+'_efw_hsk_beb_analog_'
        cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
            tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables


        ;If files loaded then continue
        if is_string(tns) then begin

            pn = byte(p_var[s]) - byte('a')
            options, /def, tns, colors = probe_colors[pn]
            dprint, dlevel = 5, verbose = verbose, 'Setting options...'
            options, /def, tns, code_id = '$Id: rbsp_load_efw_hsk.pro 26346 2018-12-17 22:43:40Z aaronbreneman $'
                c_var = [1, 2, 3, 4, 5, 6]
            dprint, dwait = 5., verbose = verbose, 'Flushing output'
            dprint, dlevel = 4, verbose = verbose, 'Housekeeping data Loaded for probe: '+p_var[s]

        endif else begin
            dprint, dlevel = 0, verbose = verbose, 'No EFW HSK BEB Analog data loaded...'+' Probe: '+p_var[s]
            dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
        endelse

    endfor
end


pro rbsp_efw_phasef_read_hsk, date0, probe=probe, errmsg=errmsg, $
    log_file=log_file, source=source

    errmsg = ''

;---Check input.
    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    ;data_type = 'hsk'      ; starts from 09-14.
    data_type = 'flags_all' ; starts from 09-05.
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date0) eq 0 then begin
        errmsg = 'No input time ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date0,/type) eq 7 then date = time_double(date0) else date = date0
    secofday = constant('secofday')
    date = date-(date mod secofday)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input time: '+strjoin(time_string(time_range),' ')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif
    time_range = date+[0,secofday]
    if n_elements(source) eq 0 then source = 'l1'


;---Load data.
    timespan, time_range[0], total(time_range*[-1,1]), /second
    
    if source eq 'l4' then begin
        rbsp_efw_read_l4, time_range, probe=probe

        old_vars = prefix+['bias_current','usher_voltage','guard_voltage']
        new_vars = prefix+['ibias','usher','guard']
        foreach old_var, old_vars, var_id do begin
            var = rename_var(old_var, output=new_vars[var_id])
        endforeach
    endif else begin
        rbsp_load_efw_hsk_beb, probe=probe, get_support_data=0, trange=time_range

        time_step = 256d
        common_times = make_bins(time_range, time_step)
        ncommon_time = n_elements(common_times)
        
        suffix = string(findgen(6)+1,format='(I0)')
        ndim = n_elements(suffix)
        
        hsk_types = ['GUARD','USHER','IBIAS']
        hsk_units = '('+['V','V','nA']+')'
        
        ; rbspx_efw_hsk_beb_analog_IEFI_[GUARD,USHER,IBIAS].
        foreach hsk_type, hsk_types, hsk_id do begin
            vars = prefix+'efw_hsk_beb_analog_IEFI_'+hsk_type+suffix
            
            get_data, vars[0], times
            index = where_pro(times, '[]', time_range, count=ntime)
            if ntime lt 5 then begin
                data = fltarr(ncommon_time,ndim)+!values.f_nan
                times = common_times
            endif else begin
                times = times[index]
                data = fltarr(ntime,ndim)
                foreach var, vars, var_id do begin
                    data[*,var_id] = (get_var_data(var))[index]
                endforeach
            endelse
            store_data, prefix+strlowcase(hsk_type), times, data, $
                limits={ytitle:hsk_units[hsk_id], labels:'V'+suffix, labflag:-1}
        endforeach
    endelse


end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2012-09-05'
date = '2019-01-13'
date = '2016-01-01'

; No data.
date = '2012-09-15'

;; Only a little data.
;date = '2012-09-05'

; Good day with data.
;date = '2013-01-01'

date = time_double(date)
rbsp_efw_phasef_read_hsk, date, probe=probe
end
