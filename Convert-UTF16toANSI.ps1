param ($FileName)
get-content -Path $FileName -Encoding Unicode | out-file ("{0}.Ansi" -f $FileName) -encoding default