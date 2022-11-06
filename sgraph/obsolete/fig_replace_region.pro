;+
; Replace the old_region with new.
;-
pro fig_replace_region, fig, new_region, old_region_id

    if n_elements(old_region_id) eq 0 then old_region_id = 1
    (fig.regions)[old_region_id-1] = new_region

end
