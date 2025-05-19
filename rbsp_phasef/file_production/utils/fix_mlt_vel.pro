pro fix_mlt_vel, root_dir

    if file_test(root_dir,/directory) eq 0 then return
    files = file_search(join_path([root_dir,'*','*.cdf']))
    nfile = n_elements(files)
    if nfile eq 0 then return

    foreach file, files do begin
        base = file_basename(file)
        prefix = strmid(base,0,6)
        probe = strmid(base,4,1)

        cdf_vars = ['mlt','vel_gse','velocity_gse']
        tplot_vars = prefix+['mlt','v_gse','v_gse']
        foreach cdf_var, cdf_vars, var_id do begin
            if ~cdf_has_var(cdf_var, filename=file) then continue
            setting = cdf_read_setting(cdf_var, filename=file)
            time_key = 'DEPEND_0'
            if ~setting.haskey(time_key) then continue
            time_var = setting[time_key]
            epochs = cdf_read_var(time_var, filename=file)
            common_times = convert_time(epochs,from='epoch16',to='unix')

            time_range = minmax(common_times)
            rbsp_read_spice_var, time_range, probe=probe

            tplot_var = tplot_vars[var_id]
            data = get_var_data(tplot_var, at=common_times)
            if cdf_var eq 'mlt' then begin
                index = where(data gt 12, count)
                if count ne 0 then begin
                    data[index] -= 24
                endif
            endif else begin
                data = transpose(data)
            endelse
            cdf_save_data, cdf_var, filename=file, value=data
        endforeach
    endforeach

end


probes = ['a','b']
data_info_list = list()
data_info_list.add, dictionary($
    'level', 'l2', $
    'types', [$
        'e-spinfit-mgse_v04', $
    ;    'vsvy-hires_v04', $
    ;    'esvy_despun_v04',$
    ;    'vsvy-hires_v03', $
    ;    'esvy_despun_v03', $
        'dummy' ] )

data_info_list.add, dictionary($
    'level', 'l3_v04', $
    'types', [$
        '', $
        'dummy' ] )

foreach data_info, data_info_list do begin
    level = data_info.level
    types = data_info.types
    
    foreach type, types do begin
        foreach probe, probes do begin
            rbspx = 'rbsp'+probe
            root_dir = join_path([rbsp_efw_phasef_local_root(),rbspx,level,type])
            fix_mlt_vel, root_dir
        endforeach
        
    endforeach
endforeach


end
