;+
; Read pitch angle distribution for both thermal and high energy electrons.
;-

function mms_read_pad_ele_all, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, get_name=get_name, update=update, suffix=suffix


    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'


    ; Prepare var name.
    species = 'e'
    if n_elements(suffix) eq 0 then suffix = ''
    var_info = prefix+species+'_pad_all'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info


    var_low = mms_read_pad_ele_thermal(time_range, probe=probe, species=species, errmsg=errmsg_low)
    var_high = mms_read_pad_ele_kev(time_range, probe=probe, species=species, errmsg=errmsg_high)
    errmsg = errmsg_low+errmsg_high
    if errmsg ne '' then return, retval

    ; Combine fluxs.
    flux1 = get_var_data(var_low, times=times, settings=settings1)
    flux2 = get_var_data(var_high, at=times, settings=settings2)

    ; Obtain a set of common energy bins.
    en_centers1 = settings1.en_centers
    nen_bin1 = n_elements(en_centers1)
    en_centers2 = settings2.en_centers
    nen_bin2 = n_elements(en_centers2)
    de_e1 = en_centers1[1:-1]/en_centers1[0:-2]
    de_e2 = en_centers2[1:-1]/en_centers2[0:-2]
    de_e = mean([mean(de_e1),mean(de_e2)])
    en_range = minmax([en_centers1,en_centers2])
    en_centers = smkgmtrc(en_range[0],en_range[1],de_e,'dx')
    nen_bin = n_elements(en_centers)
    ntime = n_elements(times)

    ; PA bins should be the same.
    pa_centers = settings1.pa_centers
    npa_bin = n_elements(pa_centers)

    ; Interpolate to common PAD fluxs.
    pad_flux1 = reform(transpose(sinterpol($
        transpose(reform(flux1,[ntime*npa_bin,nen_bin1])),en_centers1,en_centers)), ntime,npa_bin,nen_bin)
    pad_flux2 = reform(transpose(sinterpol($
        transpose(reform(flux2,[ntime*npa_bin,nen_bin2])),en_centers2,en_centers)), ntime,npa_bin,nen_bin)
    pad_fluxs = fltarr(ntime,npa_bin,nen_bin)
    index = where_pro(en_centers,'[]',minmax(en_centers1))
    pad_fluxs[*,*,index] = pad_flux1[*,*,index]
    index = where_pro(en_centers,'[]',minmax(en_centers2))

    pad_fluxs[*,*,index] = pad_flux2[*,*,index]
    store_data, var_info, times, pad_fluxs
    settings = settings1
    settings.en_centers = en_centers
    add_setting, var_info, smart=1, settings

    return, var_info

end


tr = time_double(['2016-08-04/22:15','2016-08-04/22:55'])
tr = time_double(['2016-08-04','2016-08-05'])
probe = '2'

tr = ['2016-10-14/20:00','2016-10-14/22:30']
probe = '1'
plot_time = time_double('2016-10-14/21:43:30')
plot_time = time_double('2016-10-14/22:11:00')
test = 1

; keV electron.
ele_var1 = mms_read_pad_ele_thermal(tr, probe=probe)
ele_var2 = mms_read_pad_ele_kev(tr, probe=probe)
ele_var0 = mms_read_pad_ele_all(tr, probe=probe)
ele_var = ele_var0+'_copy'
copy_data, ele_var0, ele_var
en_centers = get_var_setting(ele_var,'en_centers')
options, ele_var, 'en_centers', en_centers
plot_files = plot_pad_polygon(ele_var, test=test, plot_times=get_var_time(ele_var2), $
    xrange=[-1,1]*1e5, zrange=[5e1,5e7], color_table=74, ncolor=40, file_extension='png', axis_title='E (eV)')
prefix = 'mms'+probe+'_'
movie_file = join_path([homedir(),prefix+'pad_e_'+strjoin(time_string(tr,tformat='YYYY_MMDD_hh'),'_')+'_v02.mp4'])
fig2movie, movie_file, fig_files=plot_files
print, movie_file
end