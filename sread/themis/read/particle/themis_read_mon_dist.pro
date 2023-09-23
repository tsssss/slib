;+
; Read moment distribution for further integration.
; store dictionary to tplot, {'esa_sst','esa','sst'}
;-

function themis_read_mom_dist, input_time_range, probe=probe, $
    id=id, species=species0, $
    errmsg=errmsg, get_name=get_name, update=update

    errmsg = ''
    retval = ''

;---Check input.
    ; probe.
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; species.
    if n_elements(species0) eq 0 then species0 = 'i'
    ; species is used for original spedas routines. in 'e' and 'i'.
    species = species0
    if species eq 'p' then species = 'i'
    if ~themis_esa_species_is_valid(species) then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    ; species1 is used for uniformed species info. in 'e' and 'p'.
    species1 = species
    if species1 eq 'i' then species1 = 'p'
    
    
    ; time_range and coord.
    time_range = time_double(input_time_range)
    
    
    ; id.
    if n_elements(id) eq 0 then id = 'esa_sst'


;---Init return value and determine if load data.
    load_data = 0
    prefix1 = prefix+species1+'_'
    var_out = prefix1+'mom_dist'
    if check_if_update(var_out, time_range) then load_data = 1
    if keyword_set(get_name) then return, var_out
    if keyword_set(update) then load_data = 1
    if load_data eq 0 then return, var_out

;---Load data.
    esa_type = 'pe'+species+'r'
    sst_type = 'ps'+species+'f'
    combo_dist = thm_part_combine(probe=probe, trange=time_range, $
        esa_datatype=esa_type, sst_datatype=sst_type, $
        orig_esa=esa_dist, orig_sst=sst_dist, $
        sst_sun_bins=sst_mask, energies=energy_bins, unit=unit)
    dist_info = dictionary($
        'esa_sst', combo_dist, $
        'esa', esa_dist, $
        'sst', sst_dist )
    store_data, var_out, 0, dist_info

    return, var_out


end