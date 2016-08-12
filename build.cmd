del /F vboxcentos-7.box
if %ERRORLEVEL% GEQ 1 echo "del previous vbox: returned %ERRORLEVEL%"
vagrant destroy -f
if %ERRORLEVEL% GEQ 1 echo "vagrant destroy: returned %ERRORLEVEL%"

vagrant up
if %ERRORLEVEL% GEQ 1 echo "vagrant up: returned %ERRORLEVEL%"

vagrant package --output vboxcentos-7.box
if %ERRORLEVEL% GEQ 1 echo "vagrant package: returned %ERRORLEVEL%"
vagrant box add --force vboxcentos/7 vboxcentos-7.box
if %ERRORLEVEL% GEQ 1 echo "vagrant box add: returned %ERRORLEVEL%"

REM No point in leaving the vagrant box around.
vagrant destroy -f
if %ERRORLEVEL% GEQ 1 echo "vagrant destroy: returned %ERRORLEVEL%"

REM Vagrant key is not compatible with putty. Convert it to ppk
REM Ask Vagrant where it's key is
REM   C:> vagrant ssh-config <name_of_vagrant_vm>
REM Use puttygen GUI to load the vagrant key and save it as a .ppk key
REM http://www.alittleofboth.com/2014/04/putty-unable-to-use-vagrants-private-key/

REM Add this key to the connection in Putty connection config 
