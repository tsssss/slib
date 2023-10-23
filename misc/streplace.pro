;+
; String replace.
;-

function streplace, input_str, target, goal

    return, strjoin(strsplit(input_str, target, regex=1, extract=1, preserve_null=1), goal)

end

print, streplace('rbspa_r_gsm', 'gsm', 'mgse')
end