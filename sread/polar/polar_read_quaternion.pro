
pro polar_read_quaternion, time, probe=probe, errmsg=errmsg

    errmsg = ''

    ; read 'po_q_spc2gsm'.
    polar_read_ebv, time, id='quaternion', errmsg=errmsg
    if errmsg ne '' then return

    pre0 = 'po_'
    var = pre0+'q_spc2gsm'
    settings = { $
        display_type: 'vector', $
        unit: '#', $
        short_name: 'Q', $
        coord: 'SPC2GSM', $
        coord_labels: ['a','b','c','d'], $
        colors: sgcolor(['red','green','blue','black'])}
    add_setting, var, settings, /smart

end
