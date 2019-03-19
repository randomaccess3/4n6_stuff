'["' + $((get-childitem -include "NTUSER.DAT", "USRCLASS.DAT", "SAM", "SYSTEM", "SOFTWARE", "SECURITY" -Recurse -Force) -replace('\\', '\\') -join '","')+'"]' > reg.re_proj
