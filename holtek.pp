{
  Holtek HT16K33 RAM Mapping 16*8 LED Controller Driver with keyscan

  Chip used by 
    https://learn.adafruit.com/adafruit-7-segment-led-featherwings
  
  This chip can drive also 14 and 16 segment digits
  and led matrix. It can also read a button keypad.
  
  I implemented only a limited subset of functions.


  1.0 - 2016.08.11 - Nicola Perotto <nicola@nicolaperotto.it>
      Start
}
{$MODE DELPHI}
{$I}
unit holtek;

Interface

Uses devicei2c;

Const
  Segment7 : array[0..9] of word = (
    $003f, //0
    $0006, //1
    $005b, //2
    $004f, //3
    $0066, //4
    $006d, //5
    $007d, //6
    $0007, //7
    $007f, //8
    $006f //9
  );

  Segment14 = 0; //@@@ to do
  Segment16 = 0; //@@@ to do

Type
  EValidDigitNumber = 0..7; //This is the number of commons, each has 16 segments
  
  THoltekSegmentDriver = class(TDeviceI2C)
  private
    FDigitCount : integer; //useful also when will implement a procedure to set digits from string
    FDigits : array[EValidDigitNumber] of Word; //Maintain the current state of display
    FDecode : boolean; //the value of digit will be decoded
    FBrightness : integer; //a byte would been enough but the processor is 32 bit
    FAutoRefresh : Boolean;
    
    Function  GetDigit(Const D:EValidDigitNumber):Word;
    Procedure SetDigit(Const D:EValidDigitNumber; AValue:Word);
    Function  GetDot(Const D:EValidDigitNumber):Boolean;
    Procedure SetDot(Const D:EValidDigitNumber; Const AValue:Boolean);
    Procedure SetBrightness(Const AValue:integer);
    Procedure SetAutoRefresh(Const AValue:Boolean);
  public
    Constructor Create(Const ABusId, AAddress, ASubAddress:integer); Overload;
    Function DecodeSegments(Const AValue:word):Word;
    Procedure DigitOff(Const D:EValidDigitNumber);
    Procedure DisplayOn;
    Procedure DisplayOff;
    Procedure StandBy;
    Procedure Refresh;
  published
    Property DigitCount : integer read FDigitCount write FDigitCount;
    Property Digit [D:EValidDigitNumber] : Word read GetDigit write SetDigit;
    Property Decode : Boolean read FDecode write FDecode;
    Property Dot [D:EValidDigitNumber] : Boolean read GetDot write SetDot;
    Property Brightness : integer read FBrightness write SetBrightness;
    Property AutoRefresh : Boolean read FAutoRefresh write SetAutoRefresh;
  end;


Implementation

//  THoltekSegmentDriver
Constructor THoltekSegmentDriver.Create(Const ABusId, AAddress, ASubAddress:integer); Overload;
begin
  Inherited Create(ABusId, AAddress, ASubAddress);

  FDigitCount := 8;
  FillChar(FDigits, SizeOf(FDigits), #0);
  FDecode := True;
  FBrightness := 0;
  FAutoRefresh := True;
end; //Create

Function  THoltekSegmentDriver.GetDigit(Const D:EValidDigitNumber):Word;
begin
  Result := FDigits[D];
end; //GetDigit

Procedure THoltekSegmentDriver.SetDigit(Const D:EValidDigitNumber; AValue:Word);
begin
  if FDecode then begin
    if AValue > 9 then Exit; //@@@ raise error?
    AValue := Segment7[AValue];
  end;
  if (FDigits[D] <> AValue) then begin
    FDigits[D] := AValue;
    if FAutoRefresh then WriteBlockData(D*2, 2, @AValue);
  end;
end; //SetDigit

Function  THoltekSegmentDriver.GetDot(Const D:EValidDigitNumber):Boolean;
begin
  Result := (FDigits[D] and $0080) <> 0; //@@@valid only for 7 segments display
end; //GetDot

Procedure THoltekSegmentDriver.SetDot(Const D:EValidDigitNumber; Const AValue:Boolean);
Var
  bit : word;
begin
{
  Note: my display has a double point between digits 2 and 3 (ehm 4! -> 12:45)
  the segment of double dot is B (bit 1) of digit 3
}
  if AValue then
    bit := $0080
  else
    bit := $0000;
  if ((FDigits[D] and $ff7f) <> bit) then begin
    FDigits[D] := FDigits[D] and $ff7f or bit; //@@@valid only for 7 segments display
    if FAutoRefresh then WriteBlockData(D*2, 2, @FDigits[D]);
  end;
end; //SetDot

Function THoltekSegmentDriver.DecodeSegments(Const AValue:word):Word;
begin
  if AValue <= High(Segment7) then
    Result := Segment7[AValue]
  else
    Result := 0; //raise error?
end; //DecodeSegments

Procedure THoltekSegmentDriver.DigitOff(Const D:EValidDigitNumber);
begin
  FDigits[D] := 0;
  if FAutoRefresh then WriteBlockData(D*2, 2, @FDigits[D]);
end; //DigitOff

Procedure THoltekSegmentDriver.DisplayOn;
begin
  WriteByte($21); //Start system oscillator
  WriteByte($81); //display on, no blink
  WriteByte($A0); //define row/int
end; //DisplayOn

Procedure THoltekSegmentDriver.DisplayOff;
begin
  WriteByte($80); //display off
end; //DisplayOff

Procedure THoltekSegmentDriver.StandBy;
begin
  WriteByte($20); //Stop system oscillator
end; //StandBy

Procedure THoltekSegmentDriver.SetBrightness(Const AValue:integer);
begin
  FBrightNess := AValue and $0f;
  WriteByte($e0 or FBrightness); //Brightness
end; //SetBrightness

Procedure THoltekSegmentDriver.SetAutoRefresh(Const AValue:Boolean);
begin
  FAutoRefresh := AValue;
  if FAutoRefresh then Refresh;
end; //SetAutoRefresh

Procedure THoltekSegmentDriver.Refresh;
begin //@@@ specific to this 7 segment display!
  WriteBlockData(0, FDigitCount * 2, @FDigits);
end; //Refresh

end.