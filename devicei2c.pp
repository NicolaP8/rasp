{
  I2C interface Object
     Wrapper to use the library i2c_dev.pas from https://github.com/SAmeis/pascalio

  1.0 - 2016.08.11 - Nicola Perotto <nicola@nicolaperotto.it>
      Start
}
{$MODE DELPHI}
{$I}
unit devicei2c;

Interface

Uses BaseUnix, SysUtils, RtlConsts, Classes, I2C_dev;

Type
  TDeviceI2C = class(TObject)
  private
	  FI2CBus : integer;
	  FI2CAddress : integer;
	  FI2CSubAddress : integer;
	  FHandle : cint;
    FTag : integer;

    Procedure StartOp;
  public
    Constructor Create(Const ABusId, AAddress:integer); Overload;
    Constructor Create(Const ABusId, AAddress, ASubAddress:integer); Overload;
    Destructor  Destroy; override;

    Procedure WriteByte(Const AValue:byte);
    Procedure WriteByteData(Const ACmd, AData:byte);
    Procedure WriteBlockData(Const ACmd, ACount:byte; Const ABuffer:PByte); //max 32 bytes see Kernel limits!
    Function  ReadByte:byte;
    //@@@ to do: more read functions!
  published
    Property BusId : integer read FI2CBus;
    Property Address : integer read FI2CAddress;
    Property SubAddress : integer read FI2CSubAddress;
    Property Handle : cint read FHandle;
    Property Tag : integer read FTag write FTag; //for user storage
  end;


Implementation

const
  I2C_DEV_FNAME = '/dev/i2c-%d';

//******************************************************************************
Constructor TDeviceI2C.Create(Const ABusId, AAddress, ASubAddress:integer); Overload;
Var
  name : string;
begin
  FI2CBus := -1;
  FI2CAddress := -1;
  FI2CSubAddress := -1;

  if ABusId >= 0 then begin
    name := Format(I2C_DEV_FNAME, [ABusID]);
    FHandle := FpOpen(name, O_RDWR);
    if fHandle < 0 then
      raise EFOpenError.CreateFmt(SFOpenError, [name]);
    FI2CBus := ABusId;
    FI2CSubAddress := ASubAddress;
    FI2CAddress := AAddress;
    StartOp;
  end;
end; //Create

Constructor TDeviceI2C.Create(Const ABusId, AAddress:integer); Overload;
begin
  Create(ABusId, AAddress, 0);
end; //Create

Destructor TDeviceI2C.Destroy;
begin
  if FHandle >= 0 then FpClose(FHandle);
  Inherited;
end; //Destroy

Procedure TDeviceI2C.StartOp;
Var
  a, e : integer;
begin
  a := FI2cAddress + FI2cSubAddress;
  e := FpIoctl(FHandle, I2C_SLAVE, Pointer(a)); //Ignore warning!
  if e < 0 then RaiseLastOSError;
end; //SetAddr

Procedure TDeviceI2C.WriteByte(Const AValue:byte);
begin
  StartOp;
  i2c_smbus_write_byte(FHandle, AValue);
end; //WriteByte

Procedure TDeviceI2C.WriteByteData(Const ACmd, AData:byte);
begin
  StartOp;
	i2c_smbus_write_byte_data(FHandle, ACmd, AData);
end; //WriteByteData

Procedure TDeviceI2C.WriteBlockData(Const ACmd, ACount:byte; Const ABuffer:PByte);
begin
  StartOp;
//  i2c_smbus_write_block_data(FHandle, ACmd, ACount, ABuffer);
  i2c_smbus_write_i2c_block_data(FHandle, ACmd, ACount, ABuffer);
end; //WriteBlockData

Function TDeviceI2C.ReadByte:byte;
Var
  i : Longint;
begin
  StartOp;
  i := i2c_smbus_read_byte(FHandle);
  if i < 0 then begin
    RaiseLastOSError;
   end else
    Result := byte(i and $ff);
end; //ReadByte

end.