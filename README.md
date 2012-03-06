# SSH for Windows

## What does this do?

the `ssh.bat` file allows normal ssh to work from the command line, it will start
up an ssh-agent and add your keys so you can take advantage of agent forwarding, It's only
activated when you pass in the `-A` option on the command line.

## Why did I build this?

I got sick of not having proper ssh-agent support on Windows, I don't use Putty because
I like being able to open a cmd shell anywhere and using ssh. And every now and again
I needed to forward my key to get access to a git repository or something and this last
time finally pushed me over the edge and so I figured out how to do it and wrote this
batch script to make it easier for me to forward my key.

## Where do you get the `.exe` files in the `ssh-git/` and `ssh-rsync/` directories?

The `ssh-git/` ssh files come from Git for Windows. Git's version of ssh actually has
support for ssh agent forwarding but it is kind of slow at connecting (at least on my Computer) 
and so I use the `ssh-rsync/` ssh when `-A` is not passed in since Rsync for Windows's version of
ssh is a lot faster connecting but doesn't support agent forwarding.

I'm guessing both versions can be upgraded by copy/pasting any new versions from newer
installs of Windows Git or Windows Rsync, as that's all I did.