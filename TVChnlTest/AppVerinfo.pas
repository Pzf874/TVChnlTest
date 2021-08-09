{+=============================================================================+
 | TAppVerInfo created on 25.12.1997            By RicoSoft rico@mbox.4net.it  |
 | last updated:     1.1c 23.02.1999           Riccardo 'Rico' Pareschi, Italy |
 +-----------------------------------------------------------------------------+
  Merry Christmas Component. It's a gray fog day so ...
 +-----------------------------------------------------------------------------+
  This small component was developed after the study of works by Alex Wernhardt
  and Luca Benassi.
  This is my first attemp to write a component.
  This is Freeware/Careware. I put it on the net for the other programmers.
  I've write some small 'CareWare' programs and a lot of serious professional
  applications. This routines are presents in my works.
 +-----------------------------------------------------------------------------+
  This file is released to the Public Domain. Please use, share & enjoy. Rico.
  23.02.1999 - 1.1c - get the SystemLangID for VerQueryvalue to avoid language 
  										problems
  15.01.1999 - 1.1b - Added comments property
  25.12.1998 - 1.1a - Changed for Delphi 4 & NT 4.0
  25.12.1997 - 1.0a - First release
===============================================================================}
unit AppVerInfo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms;

type
  TAppVerInfo = class(TComponent)
  private
    { Private declarations }
		VSize : DWord;
    VData : Pointer;
    VVers : Pointer;
		iLangID: string;
		iFileName: string;

    iCompanyName: string;
    iFileDescription: string;
    iFileVersion: string;
    iInternalName: string;
    iLegalCopyright: string;
    iLegalTrademarks: string;
		iOriginalFilename: string;
    iProductName: string;
    iProductVersion: string;
		iComments: string;

  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    function    GetVerValue(Value : string): string;
    procedure   ExtractVerInfo;
  published
    { Published declarations }
		property LangID: string      			read iLangID;
		property CompanyName: string      read iCompanyName;
		property FileDescription: string  read iFileDescription;
    property FileVersion: string      read iFileVersion;
    property InternalName: string     read iInternalName;
    property LegalCopyright: string   read iLegalCopyright;
    property LegalTrademarks: string  read iLegalTrademarks;
    property OriginalFilename: string read iOriginalFilename;
    property ProductName: string      read iProductName;
    property ProductVersion: string   read iProductVersion;
    property Comments: string 	  		read iComments;
  end;

procedure Register;

implementation
{$R AppVerInfo.dcr}

{-------------------------------------------------------------------------------
  Change here for a different component palette
}
procedure Register;
begin
  RegisterComponents('MyVcl', [TAppVerInfo]);
end; {- Register }


{-------------------------------------------------------------------------------
  Here I get the complete filename to analize, then execute the extraction
  method.
}
constructor TAppVerInfo.Create(AOwner: TComponent);
begin
  inherited;
  // load the application file name
  iFileName := Application.ExeName;
  ExtractVerInfo;
end; {- Create }


{-------------------------------------------------------------------------------
  This is the extraction routine. Returns the Version Informations.
  The first four digits of the string 0410 04E4 is the key code for Italy.
  To avoid problems with other languages I've tried to get the SystemLangID
}
function TAppVerInfo.GetVerValue(Value : string): string;
var
	Qrystr: string;
	Dummy: DWord;
begin
	Result := '';
	if (iLangID='') or (Value='') then Exit;
	Qrystr := Format('\StringFileInfo\%s\%s', [iLangID, Value]);
	if VerQueryValue(VData,pChar(Qrystr),VVers,Dummy) then
		 if Dummy > 0 then begin
				Result := StrPas(VVers);
     end;
end; {- GetVerValue }


{-------------------------------------------------------------------------------
  This is all the job!
  There are a lot of informations to read from the file version. But I think
  these are the most useful for the about box.
}
procedure TAppVerInfo.ExtractVerInfo;
var
	Dummy: DWord;
begin
	VSize := GetFileVersionInfoSize(Pchar(iFileName), Dummy);
	if VSize=0 then Exit;
	GetMem(VData, VSize);
	try
		if not GetFileVersionInfo(Pchar(iFileName), Dummy, VSize, VData) then Exit;
		if not VerQueryValue(VData,'\VarFileInfo\Translation',VVers,Dummy) then Exit;
		iLangID:=format('%4.4x',[PWordArray(VVers)[0]])+format('%4.4x',[PWordArray(VVers)[1]]);
		iCompanyName := GetVerValue('CompanyName');
		iFileDescription := GetVerValue('FileDescription');
		iFileVersion := GetVerValue('FileVersion');
		iInternalName := GetVerValue('InternalName');
		iLegalCopyright := GetVerValue('LegalCopyright');
		iLegalTrademarks := GetVerValue('LegalTrademarks');
		iOriginalFilename := GetVerValue('OriginalFilename');
		iProductName := GetVerValue('ProductName');
		iProductVersion := GetVerValue('ProductVersion');
		iComments := GetVerValue('Comments');
	finally
		FreeMem(VData, VSize);
	end; // try...Finally
end; {- ExtractVerInfo }


end.
