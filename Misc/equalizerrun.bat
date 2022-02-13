set VerBuild=_TC_alpha120220129
set EqualizerPackage=Equalizer%VerBuild%.u

del %EqualizerPackage% 
rename "Equalizer.u" %EqualizerPackage%
ucc dumpint %EqualizerPackage%
ucc exportcache %EqualizerPackage%
copy %EqualizerPackage% Z:\home\the_cowboy\.ut2004\System\

rmdir /s /q Z:\home\the_cowboy\Dropbox\Equalizer\Equalizer1
mkdir Z:\home\the_cowboy\Dropbox\Equalizer\Equalizer1
xcopy /e C:\UT2004\Equalizer Z:\home\the_cowboy\Dropbox\Equalizer\Equalizer1


<buildnumberEQ.txt set /p counter=
set /a counter +=1
> buildnumberEQ.txt echo %counter% 

pause
