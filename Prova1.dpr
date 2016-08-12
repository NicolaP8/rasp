{$I+,R+,Q+}
{$MODE Delphi}
Program Test1;

Uses
  BaseUnix, SysUtils, Crt, devicei2c, Holtek;

Var
  SigOA, SigNA : PSigActionRec;
  bStopNow : Boolean;
  i : integer;

  i2c : TDeviceI2C;
  dis : array[0..15] of byte; //for use with generic device

  h7 : THoltekSegmentDriver;


Procedure DoSig(sig:cint); Cdecl;
begin //Wait for SigTerm: kill pid
  bStopNow := True;
end; //DoSig

Procedure Init;
begin
  bStopNow := False;
  New(SigNA);
  New(SigOA);
  SigNA^.sa_Handler := SigActionHandler(@DoSig);
  Fillchar(SigNA^.Sa_Mask, sizeof(SigNA^.sa_mask), #0);
  SigNA^.Sa_Flags := 0;
  SigNA^.Sa_Restorer := Nil;
  if fpSigAction(SigTerm, SigNA, SigOA) <> 0 then begin
    writeln('Signal Handler Error: ', fpgeterrno);
    Halt(1);
  end;
end; //Init

begin
  Init;
  
  writeln('Pascal & RPi');
  writeln('I2C 7 segments display');

  writeln('Test generic device');
  i2c := TDeviceI2C.Create(1, $70);
  i2c.WriteByte($21); //Start system oscillator
  i2c.WriteByte($A0); //define row/int
  i2c.WriteByte($81); //display on, no blink
  i2c.WriteByte($e1); //Brightness
  
  for i := 0 to 15 do
    Dis[i] := $ff;
  i2c.WriteBlockData(0, 16, @dis);
  
  writeln('Brightness test');
  for i := 0 to 15 do begin
    Sleep(100);
    i2c.WriteByte($e0 + i); //Brightness
  end;
  for i := 15 downto 0 do begin
    Sleep(100);
    i2c.WriteByte($e0 + i); //Brightness
  end;
  i2c.Destroy;
  Sleep(1000);

  writeln('Holtek driver test');
  h7 := THoltekSegmentDriver.Create(1, $70, 0);
  h7.DigitCount := 5;
  h7.Autorefresh := False;
  h7.Decode := True; //the value will be translated to display the digit

  //init digits
  for i := 0 to 4 do
    h7.DigitOff(i);
  h7.Refresh;
  h7.DisplayOn;
  h7.Brightness := 7;
  Sleep(1000);
  
  for i := 0 to 999 do begin
    h7.Digit[0] := (i div 1000);
    h7.Digit[1] := (i div 100) mod 10;
    h7.Digit[3] := (i div 10) mod 10;
    h7.Digit[4] := i mod 10;
    if (i mod 10) = 0 then h7.Digit[2] := 8; //the double dot uses only bit 1 = segment B
    if (i mod 10) = 3 then h7.Digit[2] := 5; //segment B off! (it's in Decode mode)
    h7.Refresh;
    if KeyPressed then
      if ReadKey = #27 then bStopNow := True; //to terminate the test
    if bStopNow then Break; //from Signal Handler or keypress
    Sleep(100);
  end; //i

  writeln;
  h7.Destroy; //closes the device but the chip remains in the actual state
end.