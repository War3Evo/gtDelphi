  Created this component based on the information from
  https://stackoverflow.com/users/800214/whosrdaddy:

  For non unicode aware Delphi versions go here:
  https://stackoverflow.com/questions/10598313/communicate-with-command-prompt-through-delphi

This component is bare bones, and has no ability to do any special commands.

EXAMPLE:
```
procedure TForm1.Button1Click(Sender: TObject);
begin
  CommandPrompt1.Start;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  CommandPrompt1.Stop;
end;

procedure TForm1.CommandPrompt1ReadCommandPrompt(OutPut: AnsiString);
begin
  memo1.Lines.Add('IN: ' + String(OutPut));
end;

procedure TForm1.CommandPrompt1WriteCommandPrompt(OutPut: AnsiString);
begin
  memo1.Lines.Add('OUT: ' + String(OutPut));
end;

procedure TForm1.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if ord(Key) = VK_RETURN then
  begin
    Key := #0; // prevent beeping
    CommandPrompt1.cmdWriteln(AnsiString(Edit1.Text));
  end;
end;
```

I am planning to create an SSH component using this component.  You will need to target Windows 64-bit mode.  You can find that information here: https://stackoverflow.com/questions/59583322/createprocess-of-c-windows-system32-openssh-ssh-exe-fails-with-error-2
