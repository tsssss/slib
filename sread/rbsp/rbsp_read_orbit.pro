;+
; Read RBSP position in GSM. Save as 'rbspx_r_gsm'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, 'a' or 'b'.
;-
pro rbsp_read_orbit, time, probe=probe, errmsg=errmsg, _extra=ex

    ; read 'q_uvw2gsm'.
    rbsp_read_spice, time, id='orbit', probe=probe, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return

    pre0 = 'rbsp'+probe+'_'
    var = pre0+'r_gsm'
    rename_var, 'pos_gsm', to=var
    settings = { $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    add_setting, var, settings, /smart

end
