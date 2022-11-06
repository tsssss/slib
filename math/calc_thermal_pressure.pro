;+
; Calculate thermal pressure, in nPa.
; Past the test to replicate the last panel in Figure 1 in
; https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2014JA020186.
;
; density. In cc.
; temperature. In eV.
;-

function calc_thermal_pressure, density, temperature

    ; cc*1e6 * eV*1.6e-19 * 1e9.
    return, density*temperature*1e-4

end

time_range = time_double(['2010-03-22/06:20','2010-03-22/06:50'])
probe = 'a'
prefix = 'th'+probe+'_'
themis_read_density, time_range, probe=probe
themis_read_ele_temp, time_range, probe=probe
themis_read_ion_temp, time_range, probe=probe

density = get_var_data(prefix+'ele_n', times=times)
ele_temp = get_var_data(prefix+'ele_t')
ion_temp = get_var_data(prefix+'ion_t')
ele_pres = calc_thermal_pressure(density, ele_temp)
ion_pres = calc_thermal_pressure(density, ion_temp)
total_pres = ele_pres+ion_pres
store_data, prefix+'ele_p', times, ele_pres
store_data, prefix+'ion_p', times, ion_pres
store_data, prefix+'total_p', times, total_pres

end
