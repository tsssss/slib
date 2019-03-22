;+
; Read Themis DC E field. Default is to read 'survey' data at 3 samples/sec.
;-
;
pro themis_read_efield, utr0, probe=probe, resolution=resolution

    pre0 = 'th'+probe+'_'
    rgb = sgcolor(['red','green','blue'])
    
    resolution = (keyword_set(resolution))? strlowcase(resolution): '3sec'
    case resolution of
        '3sec': begin
            dt = 3
            type = 'efs'
            end
        'hires': begin
            dt = 1d/8
            type = 'eff'
            end
    endcase
    
    ; read 'rbspx_edot0_gsm'
    themis_read_efi, utr0, type, level='l2', probe

    var = pre0+'edot0_gsm'
    rename_var, pre0+type+'_dot0_gsm', to=var
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'Edot0', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: rgb}

    uniform_time, var, dt
end


utr0 = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
themis_read_efield, utr0, probe='d'
end
