  Created this component based on the information from
  https://stackoverflow.com/users/800214/whosrdaddy:

  For non unicode aware Delphi versions go here:
  https://stackoverflow.com/questions/10598313/communicate-with-command-prompt-through-delphi

This component is bare bones, and has no ability to do any special commands.  You will have to post your own commands using XXX and reading from the events.

I am planning to create an SSH component using this component.  I found you will need to target Windows 64-bit mode.  You can find that information here: https://stackoverflow.com/questions/59583322/createprocess-of-c-windows-system32-openssh-ssh-exe-fails-with-error-2
