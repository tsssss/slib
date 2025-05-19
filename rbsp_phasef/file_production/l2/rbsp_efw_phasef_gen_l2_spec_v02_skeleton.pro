
pro rbsp_efw_phasef_gen_l2_spec_v02_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'HTTP_LINK', 'http://rbsp.space.umn.edu http://athena.jhuapl.edu', $
        'LINK_TITLE', 'Daily Summary Plots and additional data', $
        'Data_version', 'v02', $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_source', prefix+'efw-l2_spec', $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'MODS', '', $
        'LINK_TEXT', 'EFW home page at Minnesota with Van Allen Probes', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Project', 'RBSP>Radiation Belt Storm Probes' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    keys = ['Inst_mod','Inst_settings','Caveats','Validity','Validator','Parents','Software_version']
    foreach key, keys do cdf_del_setting, key, filename=file

    vars = ['epoch','epoch_qual']
    var_notes = 'Epoch tagged at the center of each interval, resolution is '+['4','10']+' sec'
    foreach var, vars, var_id do begin
        cdf_save_setting, 'VAR_NOTES', var_notes[var_id], filename=file, varname=var
        cdf_save_setting, 'UNITS', 'ps (pico-second)', filename=file, varname=var
    endforeach


end