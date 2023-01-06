function goes_resolve_probe, input_probe

    probe = strlowcase(string(input_probe,format='(I0)'))
    if strmid(probe,0,1) eq 'g' then probe = strmid(probe,1)
    return, probe

end