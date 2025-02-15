
function project_get_event, project, id=event_id

    if project.events.haskey(event_id) then begin
        return, project.events[event_id]
    endif else begin
        return, !null
    endelse


end