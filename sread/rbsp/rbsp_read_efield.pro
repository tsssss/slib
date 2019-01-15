;+
; Read RBSP DC E field. Default is to read 'survey mgse' at 11 sec.
;-
;

pro rbsp_read_efield, utr0, probe, resolution=resolution

    pre0 = 'rbsp'+probe+'_'
    
    resolution = (keyword_set(resolution))? strlowcase(resolution): 'hires'
    case resolution of
        'hires': dt = 1d/32
        'survey': dt = 11d
    endcase
    
    ; read 'rbspx_e_mgse'
    rbsp_read_efw, utr0, 'efw', probe=probe, id='l3%efw', errmsg=errmsg
    if errmsg ne '' then return
    
    evar = pre0+'e_mgse'
    rename_var, 'efield_inertial_frame_mgse', to=evar
    add_setting, evar, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: 'MGSE', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}
        
    uniform_time, evar, dt

end
