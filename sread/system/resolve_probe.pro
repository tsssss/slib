
function resolve_probe, probe

    missions = dictionary()
    missions.rbsp = dictionary($
        'name','rbsp', $        ; name is for tplot var.
        'prefix_name', 'rbsp', $; used in prefix for tplot var.
        'short_name','rb', $    ; short name is for display.
        'routine_name','rbsp')  ; default name is for finding routine.
    missions.arase = dictionary($
        'name','arase', $
        'prefix_name', 'arase', $
        'short_name', 'erg', $
        'routine_name','arase')
    missions.polar = dictionary($
        'name','polar', $
        'prefix_name', 'po', $
        'short_name','po', $
        'routine_name','polar')
    missions.goes = dictionary($
        'name','g', $
        'prefix_name', 'g', $
        'short_name', 'g', $
        'routine_name', 'goes')
    missions.themis = dictionary($
        'name','th', $
        'prefix_name', 'th', $
        'short_name', 'th', $
        'routine_name', 'themis')
    missions.mms = dictionary($
        'name','mms', $
        'prefix_name', 'mms', $
        'short_name','mms', $
        'routine_name','mms')
    missions.cluster = dictionary($
        'name','c', $
        'prefix_name', 'c', $
        'short_name','c', $
        'routine_name','cluster')

    probe = strlowcase(probe)
    found_probe = 0
    foreach key, missions.keys() do begin
        mission = missions[key]
        name = mission.name
        if strmid(probe,0,strlen(name)) eq name then begin
            found_probe = 1
            break
        endif
    endforeach

    if found_probe then begin
        the_probe = strmid(probe,strlen(name))
        mission['probe'] = the_probe
        mission['prefix'] = mission.prefix_name+the_probe+'_'
        mission['short_name'] = mission.short_name+the_probe
    endif else mission = !null

    return, mission
end
