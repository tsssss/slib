;+
; Add event to project.
; 
; project.
; time_range=
; id=.
; update=.
;-

function project_add_event, project, time_range=input_time_range, id=event_id, update=update

    tr = time_double(input_time_range)
    tr_str = time_string(input_time_range)
    if n_elements(event_id) eq 0 then event_id = time_string(tr[0],tformat='YYYY_MMDD_hh')

    if keyword_set(update) then project = project_delete_event(project, id=event_id)
    if ~project.events.haskey(event_id) then begin
        project.events[event_id] = dictionary($
            'time_range', tr, $
            'time_range_str', tr_str, $
            'id', event_id, $
            'data_requests', list(), $
            'plot_dir', join_path([project.plot_dir,event_id]), $
            'data_dir', project.data_dir )
    endif

    return, project_get_event(project, id=event_id)

end