
function resolve_probe, probe

    missions = dictionary()
    missions.rbsp = dictionary($
        'name','rbsp', $        ; name is for tplot var.
        'short_name','rb', $    ; short name is for display.
        'routine_name','rbsp')  ; default name is for finding routine.
    missions.goes = dictionary($
        'name','g', $
        'short_name', 'g', $
        'routine_name', 'goes')
    missions.themis = dictionary($
        'name','th', $
        'short_name', 'th', $
        'routine_name', 'themis')
    missions.mms = dictionary($
        'name','mms', $
        'short_name','mms', $
        'routine_name','mms')

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
        mission.probe = the_probe
    endif else mission = !null

    return, mission
end
