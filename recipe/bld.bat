@echo ON

rem Copy over the bin, include and lib dirs
robocopy %SRC_DIR%\win-gpl\bin\ %LIBRARY_BIN%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

robocopy %SRC_DIR%\win-gpl\include\ %LIBRARY_INC%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

robocopy %SRC_DIR%\win-gpl\lib\ %LIBRARY_LIB%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

exit 0
