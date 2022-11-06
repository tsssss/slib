;+
; Test individual routine on cdf_id leakage.
;-

file = join_path([homedir(),'test.cdf'])
if file_test(file) eq 0 then cdf_save_setting, 'test', 0, filename=file
max_loop = 1e4



for ii=0ull,max_loop do begin
    print, ii
    tmp = cdf_read_setting(filename=file)
endfor
stop

for ii=0ull,max_loop do begin
    print, ii
    tmp = cdf_detect_unused_vars(file)
endfor


for ii=0ull,max_loop do begin
    print, ii
    tmp = cdf_read_skeleton(file)
endfor


for ii=0ull,max_loop do begin
    print, ii
    print, strjoin(cdf_atts(file),', ')
endfor


for ii=0ull,max_loop do begin
    print, ii
    print, strjoin(cdf_gatts(file),', ')
endfor



for ii=0ull,max_loop do begin
    print, ii
    print, strjoin(cdf_vars(file),', ')
endfor


for ii=0ull,max_loop do begin
    print, ii
    print, cdf_has_var('epochxx', filename=file)
    print, cdf_has_var('epoch', filename=file)
endfor
end
