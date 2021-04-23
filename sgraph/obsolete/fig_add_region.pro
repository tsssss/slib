;+
; fig.
; new_region.
; direction. 'left', 'right', 'above', 'below'. 'below' by default.
; old_region_id. The region direction applys to. The last panel by default.
;-

function region_find_parent_node, region_geometry, region_id

    index = (*region_geometry).where(region_id)
    if index ne !null then return, region_geometry

    foreach node, *region_geometry do begin
        if size(node,/type) ne 10 then continue
        parent_node = region_find_parent_node(node, region_id)
        if n_elements(parent_node) ne 0 then return, parent_node
        return, !null
    endforeach

end

pro fig_add_region, fig, new_region, relation, old_region_id, _extra=ex

    if n_elements(relation) eq 0 then relation = 'below'
    case relation of
        'above': direction = 'row'
        'below': direction = 'row'
        'left': direction = 'col'
        'right': direction = 'col'
    endcase

    nregion = fig.regions.length
    new_region_id = nregion+1
    if n_elements(old_region_id) eq 0 then old_region_id = nregion

    if old_region_id eq 0 then begin
        fig.regions.add, new_region
        *fig.region_geometry = list(direction, new_region_id)
        return
    endif

    old_region = fig.regions[old_region_id-1]
;    if direction eq 'row' then begin
;        xsize = old_region.xsize
;        region_scale, new_region, xsize=xsize
;    endif else begin
;        ysize = old_region.ysize
;        region_scale, new_region, ysize=ysize
;    endelse
    fig.regions.add, new_region


;---Need to add new region to the parent node of the old region.
    parent_node = region_find_parent_node(fig.region_geometry, old_region_id)
    old_index = (*parent_node).where(old_region_id)
    ; If there is only one node in the parent_node, then change its dir.
    if (*parent_node).length eq 2 then begin
        if relation eq 'below' or relation eq 'right' then begin
            new_list = list(direction, old_region_id, new_region_id)
        endif else begin
            new_list = list(direction, new_region_id, old_region_id)
        endelse
        fig.region_geometry = ptr_new(new_list)
        return
    endif else begin
        if direction eq (*parent_node)[0] then begin
            if relation eq 'below' or relation eq 'right' then old_index += 1
            (*parent_node).add, new_region_id, old_index
            return
        endif else begin
            if relation eq 'below' or relation eq 'right' then begin
                new_list = list(direction, old_region_id, new_region_id)
            endif else begin
                new_list = list(direction, new_region_id, old_region_id)
            endelse
            (*parent_node)[old_index] = ptr_new(new_list)
            return
        endelse
    endelse

end

;region_geometry = list('col', 0, list('row', 1, 2))
;n = region_find_parent_node(region_geometry, 1)

fig = fig_init(0)
fig_replace_region, fig, region_init(fig, nypan=4, xsize=4)
fig_add_region, fig, region_init(fig, nxpan=3, xsize=4), 'right', 1

end
