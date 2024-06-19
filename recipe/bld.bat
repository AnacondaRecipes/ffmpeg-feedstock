@echo ON

rem call autotools script from autotools_clang_conda
call %BUILD_PREFIX%\Library\bin\run_autotools_clang_conda_build.bat
if %ERRORLEVEL% neq 0 exit 1
