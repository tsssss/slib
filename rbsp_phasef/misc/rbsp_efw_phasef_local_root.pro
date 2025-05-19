;+
; Set the local root for saving RBSP data.
;-

function rbsp_efw_phasef_local_root

    local_root = join_path([diskdir('data'),'rbsp'])
    local_root = join_path([diskdir('rbsp')])    ; Sheng: temporary change on 2025-02-10.
    if file_test(local_root) eq 0 then local_root = join_path([homedir(),'data','rbsp'])
    return, local_root

end
