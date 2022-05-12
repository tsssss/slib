;+
; Read all lines in a simple text file.
; 
; txtfile. A string of the full filename of the txt file.
; skip_header=. Set it to an integer to skip headers in the beginning of the file.
;-
function read_all_lines, txtfile, skip_header=nheader
    
    if file_test(txtfile) eq 0 then return, ''
        nline = file_lines(txtfile)
    if nline eq 0 then return, ''
    lines = strarr(nline)
    openr, lun, txtfile, /get_lun
    readf, lun, lines
    free_lun, lun
    
    if n_elements(nheader) ne 0 then lines = lines[nheader:*]
        
    return, lines

end

file = 'E:\data\swarm\swarmc\level1b\Current\MAGx_LR\2013\local_index.html'
lines = read_all_lines(file)
foreach line, lines do print, '"'+line+'"'
end