;+
; Delete event from project.
;-

function project_delete_event, project, id=event_id

    if project.events.haskey(event_id) then begin
        project.events.remove, event_id
    endif

    return, project

end