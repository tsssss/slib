;+
; Apply version to a string containing the version format code.
;
; pattern. A string containing version format code ('%v').
; version. A string specifies the version, e.g., 'v01'.
; return. A string with the version replaced.
;-
function apply_version_to_pattern, pattern, version
    retval = ''

    if n_elements(pattern) eq 0 then return, retval
    if typename(pattern) ne strupcase('string') then return, retval
    if n_elements(version) eq 0 then version = '.*'

    ; No version format code.
    index = strpos(pattern,'%v')
    if index[0] eq -1 then return, pattern

    ; Treat version.
    return, strmid(pattern,0,index[0])+version[0]+strmid(pattern,index[0]+2)

end

version = 'v01'
print, apply_version_to_pattern('rbspa_spice_products_%Y_%m%d_%v.cdf', version)
end
