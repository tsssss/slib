;+
; A wrapper for get_var_setting.pro
;-
function var_get_setting, var, key, exist

    return, get_setting(var, key, exist)

end