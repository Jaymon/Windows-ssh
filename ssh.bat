@echo off
REM this makes windows ssh act like a unix/mac ssh client with agent forwarding
rem
rem I finally got tired of not having proper agent forwarding in Windows and I don't use
rem putty (I like being able to fire up a shell and type ssh ..., just like in Linux and
rem Mac).
rem
rem @author  Jay Marcyes <jay@marcyes.com>
rem @since  3-3-12

REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
rem canary, if we haven't passed in -A then just pass the request to rsync ssh
rem since it is quite a bit faster than the git ssh
rem ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal

set /A use_agent=0

for %%i IN (%*) do if %%i EQU -A (
  set /A use_agent=1
)

if %use_agent% NEQ 1 (
  %~dp0ssh-rsync\ssh.exe %*
  goto :EOF
)

endlocal 

REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
rem find out if ssh-agent is running, and if it is, it is the ssh-agent whose info
rem we have access to in the .\ssh-agent-output.txt file, if ssh-agent isn't running
rem then start it up
rem ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEDELAYEDEXPANSION

echo Find ssh-agent

call tasklist /fo csv /nh /fi "IMAGENAME eq ssh-agent*" | findstr "ssh-agent" >NUL 2>&1

if %ERRORLEVEL% GTR 0 (

  REM we don't have an active ssh-agent so let's start one

  echo no ssh-agent found
  
  call %~dp0ssh-git\ssh-agent.exe > %~dp0ssh-agent-output.txt
  
  echo ssh-agent started
  
) else (

  REM note: I'm not happy with having to use the !var! syntax to get the restart_agent the right value,
  rem not sure how to fix it though

  echo ssh-agent found
  
  set /A restart_agent=1
  
  if EXIST %~dp0ssh-agent-output.txt (

    REM is the running ssh-agent the same ssh-agent that created the txt file?
    for /F "tokens=1,2,3,4* delims=; " %%i IN ('findstr /R /C:"Agent *pid *[0-9]*" %~dp0ssh-agent-output.txt') do (
      call tasklist /fo csv /nh /fi "PID eq %%l" | findstr "ssh-agent" >NUL 2>&1
      set /A restart_agent=!ERRORLEVEL!
    )

  )

  if !restart_agent! NEQ 0 (
  
    REM kill the ssh agent
    echo ssh-agent is not valid, restarting
    call taskkill /F /FI "IMAGENAME eq ssh-agent*" >NUL 2>&1
    call %~dp0ssh-git\ssh-agent.exe > %~dp0ssh-agent-output.txt
    
    echo zombie ssh-agents killed and new one started
  
  )
  
)

endlocal

REM go through the output of ssh-agent and add all the values to the environment
for /F "tokens=1,2,* delims==;" %%i IN ('findstr /R /C:"[^=]*=[^;]*" %~dp0ssh-agent-output.txt') do set %%i=%%j

echo ssh-agent vars placed in env

REM we could delete the agent key output but instead we'll leave it so we aren't constantly
rem deleting active ssh-agents and instead we use the existing values, this has the advantage
rem of not killing active shell sessions
REM del %~dp0ssh-agent-output.txt

echo adding user keys

REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
rem add the user's private ssh keys, it doesn't seem to be a problem re-adding the same key
rem so I haven't bothered to check if the key already exists
rem ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal

  set ssh_pk=%USERPROFILE%\.ssh\id_rsa
  if EXIST %ssh_pk% (
    call %~dp0ssh-git\ssh-add.exe %ssh_pk% >NUL 2>&1
  )

  set ssh_pk=%USERPROFILE%\.ssh\id_dsa
  if EXIST %ssh_pk% (
    call %~dp0ssh-git\ssh-add.exe %ssh_pk% >NUL 2>&1
  )

endlocal

REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
rem turn focus over to the git ssh
rem ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo passing focus to ssh

%~dp0ssh-git\ssh.exe %* 
: timeout 25