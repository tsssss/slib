;+
; Return an array of letters.
; 
; letter_range. Controls which letters are returned.
;   If it's a number or a string, it sets the end letter. For example,
;   set it to 'b' or 2, to return ['a','b'].
;   If it's a two-element array, then it sets the start and end letter.
;-

function letters, letter_range, errmsg=errmsg

    errmsg = ''
    retval = !null
    all_letters = [ $
        'a','b','c','d','e','f','g', $
        'h','i','j','k','l','m','n', $
        'o','p','q','r','s','t','u', $
        'v','w','x','y','z']
    if n_elements(letter_range) eq 0 then return, all_letters


    ; Convert the end letter to number.
    case n_elements(letter_range) of
        1: ranges = list(0,letter_range[0])
        2: ranges = list(letter_range,/extract)
    endcase

    foreach range, ranges, ii do begin
        if size(range,/type) eq 7 then begin
            range = strlowcase(range)
            ranges[ii] = where(all_letters eq range)
        endif
    endforeach

    ; Check the range.
    error = 0
    ranges = ranges.toarray()
    if ranges[1] lt ranges[0] then error = 1
    if min(ranges) lt 0 then error = 1
    if max(ranges) ge n_elements(all_letters) then error = 1
    if error then begin
        errmsg = handle_error('Invalid letter range ...')
        return, retval
    endif

    return, all_letters[ranges[0]:ranges[1]]
end

print, letters()
print, letters('c')
print, letters(['d','h'])
print, letters(4)
print, letters([5,6])
end