;+
; Read RBSP boom flag, where 1 is for working boom.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; remote_root=. A string to set the remote root directory.
; version=. A string to set specific version of files. By default, the
;   program finds the files of the highest version.
;-

pro rbsp_efw_read_boom_flag, time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_root=local_root, remote_root=remote_root

    var = rbsp_read_boom_flag(time_range, probe=probe)
end
