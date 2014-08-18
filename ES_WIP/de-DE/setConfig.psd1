# Localized ArchiveResources.psd1

ConvertFrom-StringData @'
###PSLOC
ErrorOpeningExistingFile=Ein Fehler ist beim öffnen der Datei {0} aufgetreten. Bitte die "Inner Exception" für weitergehende Fehler überprüfen
KeyNotExist=Name {0} existiert nicht und wird erstellt "{0}: {1}".
CommentForKeyExist=Kommentar für den Key {0} existiert. Ersetze Kommentar "#{0}:" mit "{0}: {1}".
CommentForKeyNotExist=Kommentar für den Key {0} existiert nicht. Erstelle Eintrag "{0}: {1}".
ItemNotEqual=Key {0} existiert, aber der Wert ist nicht gleich. Ändere {1} in {2}.
KeyAndItemEqual="{0}: {1}" sind gleich.
###PSLOC
'@