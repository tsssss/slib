
pro lanl_read_kev_proton, time_range, probe=probe, errmsg=errmsg, energy=energy

    errmsg = ''
    pre0 = probe+'_'

    ; read 'flux'
    lanl_read_data, time_range, id='sopa_energy', probe=probe
    lanl_read_data, time_range, id='sopa', probe=probe

    var = 'p_flux'
    fillval = -1e31
    nan = !values.f_nan
    get_data, var, times, data
    index = where(data eq fillval, count)
    if count ne 0 then data[index] = nan
    store_data, var, times, data


    get_data, var, times, dat
    var = pre0+'kev_h_flux'
    enbins = get_var_data('p_energy')
    nenbin = n_elements(enbins)

    ; apply energy range.
    if n_elements(energy) eq 0 then enidx = findgen(nenbin) else begin
        case n_elements(energy) of
            1: begin
                enidx = where(enbins eq energy, cnt)
                if cnt eq 0 then tmp = min(enbins-energy[0], /absolute, enidx)
            end
            2: begin
                enidx = where(enbins ge energy[0] and enbins le energy[1], cnt)
                if cnt eq 0 then begin
                    errmsg = 'no energy in given range ...'
                    return
                endif
            end
            else: begin
                errmsg = 'wrong # of energy info ...'
                return
            end
        endcase
    endelse
    dat = dat[*,enidx]
    enbins = enbins[enidx]
    nenbin = n_elements(enbins)

    store_data, var, times, dat, enbins

    yrange = 10d^ceil(alog10(minmax(dat)))
    add_setting, var, /smart, {$
        display_type: 'list', $
        ylog: 1, $
        yrange: yrange, $
        color_table: 52, $
        unit: '#/cm!U2!N-s-sr-keV', $
        value_unit: 'keV', $
        short_name: 'e!U-!N flux'}

end

time = time_double(['2014-08-28/09:00','2014-08-28/12:00'])
probes = ['LANL-01A','1991-080','1994-084','LANL-97A','LANL-04A','LANL-02A']
foreach probe, probes do lanl_read_kev_proton, time, probe=probe, energy=[0,1000]

e_probes = probes
p_probes = shift(reverse(probes),1)
end
