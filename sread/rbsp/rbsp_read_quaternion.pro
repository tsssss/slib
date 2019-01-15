;+
; Read quaternion to rotate from UVW to GSM.
;-
pro rbsp_read_quaternion, utr0, probe
    
    ; read 'q_uvw2gsm'.
    rbsp_read_spice, utr0, 'quaternion', probe
    
    pre0 = 'rbsp'+probe+'_'
    var = pre0+'q_uvw2gsm'
    rename_var, 'q_uvw2gsm', to=var
    settings = { $
        display_type: 'vector', $
        unit: '#', $
        short_name: 'Q', $
        coord: 'UVW2GSM', $
        coord_labels: ['a','b','c','d'], $
        colors: [6,4,2,0]}
    add_setting, var, settings, /smart

end
