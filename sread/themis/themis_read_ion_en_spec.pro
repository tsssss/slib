;+
; Read THEMIS ion energy-time spectrogram.
;-
pro themis_read_ion_en_spec, time, probe=probe, errmsg=errmsg

    pre0 = 'th'+probe+'_'

    ; read 'thx_ion_en_spec','thex_ion_en_spec_en'
    themis_read_esa, time, id='l2%ion_en_spec', probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    en_var = pre0+'ion_en_spec'
    get_data, en_var, times, flux
    enbin = get_var_data(pre0+'ion_en_spec_en')
;    ; convert flux from eV/cm!U2!N-s-sr-eV to 1/cm!U2!N-s-sr-keV.
;    tmp = enbin*1e-3    ; convert eV to keV.
;    flux = flux/tmp
    store_data, en_var, times, flux, enbin
    add_setting, en_var, /smart, dictionary($
        'display_type', 'spec', $
        'unit', 'eV/cm!U2!N-s-sr-eV', $
        ;'unit', '1/cm!U2!N-s-sr-keV', $
        'color_table', 33, $
        'ytitle', 'Energy (eV)', $
        'zlog', 1, $
        'zrange', [1e3,1e7], $
        'short_name', '' )

end

time_range = time_double(['2014-08-28/10:00','2014-08-28/11:00'])
probe = 'd'
themis_read_ion_en_spec, time_range, probe=probe
end
