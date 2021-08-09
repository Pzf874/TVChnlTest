unit APlayer3Lib_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// $Rev: 8291 $
// File generated on 2021/7/30 20:57:39 from Type Library described below.

// ************************************************************************  //
// Type Lib: D:\APlayerSDK\bin\APlayer.dll (1)
// LIBID: {97830570-35FE-4195-83DE-30E79B718713}
// LCID: 0
// Helpfile: 
// HelpString: APlayer3 1.0 ¿‡–Õø‚
// DepndLst: 
//   (1) v2.0 stdole, (C:\Windows\system32\stdole2.tlb)
// Errors:
//   Error creating palette bitmap of (TPlayer) : No Server registered for this CoClass
// ************************************************************************ //
// *************************************************************************//
// NOTE:                                                                      
// Items guarded by $IFDEF_LIVE_SERVER_AT_DESIGN_TIME are used by properties  
// which return objects that may need to be explicitly created via a function 
// call prior to any access via the property. These items have been disabled  
// in order to prevent accidental use from within the object inspector. You   
// may enable them by defining LIVE_SERVER_AT_DESIGN_TIME or by selectively   
// removing them from the $IFDEF blocks. However, such items must still be    
// programmatically created via a method of the appropriate CoClass before    
// they can be used.                                                          
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
interface

uses Windows, ActiveX, Classes, Graphics, OleServer, StdVCL, Variants;
  

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  APlayer3LibMajorVersion = 1;
  APlayer3LibMinorVersion = 0;

  LIBID_APlayer3Lib: TGUID = '{97830570-35FE-4195-83DE-30E79B718713}';

  DIID__IPlayerEvents: TGUID = '{31D6469C-1DA7-47C0-91F9-38F0C39F9B89}';
  IID_IPlayer: TGUID = '{F19169FA-7EB8-45EB-8800-0D1F7C88F553}';
  CLASS_Player: TGUID = '{A9332148-C691-4B9D-91FC-B9C461DBE9DD}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  _IPlayerEvents = dispinterface;
  IPlayer = interface;
  IPlayerDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library                       
// (NOTE: Here we map each CoClass to its Default Interface)              
// *********************************************************************//
  Player = IPlayer;


// *********************************************************************//
// DispIntf:  _IPlayerEvents
// Flags:     (4096) Dispatchable
// GUID:      {31D6469C-1DA7-47C0-91F9-38F0C39F9B89}
// *********************************************************************//
  _IPlayerEvents = dispinterface
    ['{31D6469C-1DA7-47C0-91F9-38F0C39F9B89}']
    procedure OnMessage(nMessage: Integer; wParam: Integer; lParam: Integer); dispid 1;
    procedure OnStateChanged(nOldState: Integer; nNewState: Integer); dispid 2;
    procedure OnOpenSucceeded; dispid 3;
    procedure OnSeekCompleted(nPosition: Integer); dispid 4;
    procedure OnBuffer(nPercent: Integer); dispid 5;
    procedure OnVideoSizeChanged; dispid 6;
    procedure OnDownloadCodec(const strCodecPath: WideString); dispid 7;
    procedure OnEvent(nEventCode: Integer; nEventParam: Integer); dispid 8;
  end;

// *********************************************************************//
// Interface: IPlayer
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {F19169FA-7EB8-45EB-8800-0D1F7C88F553}
// *********************************************************************//
  IPlayer = interface(IDispatch)
    ['{F19169FA-7EB8-45EB-8800-0D1F7C88F553}']
    procedure Open(const strUrl: WideString); safecall;
    procedure Close; safecall;
    procedure Play; safecall;
    procedure Pause; safecall;
    function GetVersion: WideString; safecall;
    procedure SetCustomLogo(nLogo: Integer); safecall;
    function GetState: Integer; safecall;
    function GetDuration: Integer; safecall;
    function GetPosition: Integer; safecall;
    function SetPosition(nPosition: Integer): Integer; safecall;
    function GetVideoWidth: Integer; safecall;
    function GetVideoHeight: Integer; safecall;
    function GetVolume: Integer; safecall;
    function SetVolume(nVolume: Integer): Integer; safecall;
    function IsSeeking: Integer; safecall;
    function GetBufferProgress: Integer; safecall;
    function GetConfig(nConfigId: Integer): WideString; safecall;
    function SetConfig(nConfigId: Integer; const strValue: WideString): Integer; safecall;
  end;

// *********************************************************************//
// DispIntf:  IPlayerDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {F19169FA-7EB8-45EB-8800-0D1F7C88F553}
// *********************************************************************//
  IPlayerDisp = dispinterface
    ['{F19169FA-7EB8-45EB-8800-0D1F7C88F553}']
    procedure Open(const strUrl: WideString); dispid 1;
    procedure Close; dispid 2;
    procedure Play; dispid 3;
    procedure Pause; dispid 4;
    function GetVersion: WideString; dispid 5;
    procedure SetCustomLogo(nLogo: Integer); dispid 6;
    function GetState: Integer; dispid 7;
    function GetDuration: Integer; dispid 8;
    function GetPosition: Integer; dispid 9;
    function SetPosition(nPosition: Integer): Integer; dispid 10;
    function GetVideoWidth: Integer; dispid 11;
    function GetVideoHeight: Integer; dispid 12;
    function GetVolume: Integer; dispid 13;
    function SetVolume(nVolume: Integer): Integer; dispid 14;
    function IsSeeking: Integer; dispid 15;
    function GetBufferProgress: Integer; dispid 16;
    function GetConfig(nConfigId: Integer): WideString; dispid 17;
    function SetConfig(nConfigId: Integer; const strValue: WideString): Integer; dispid 18;
  end;

// *********************************************************************//
// The Class CoPlayer provides a Create and CreateRemote method to          
// create instances of the default interface IPlayer exposed by              
// the CoClass Player. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoPlayer = class
    class function Create: IPlayer;
    class function CreateRemote(const MachineName: string): IPlayer;
  end;

  TPlayerOnMessage = procedure(ASender: TObject; nMessage: Integer; wParam: Integer; lParam: Integer) of object;
  TPlayerOnStateChanged = procedure(ASender: TObject; nOldState: Integer; nNewState: Integer) of object;
  TPlayerOnSeekCompleted = procedure(ASender: TObject; nPosition: Integer) of object;
  TPlayerOnBuffer = procedure(ASender: TObject; nPercent: Integer) of object;
  TPlayerOnDownloadCodec = procedure(ASender: TObject; const strCodecPath: WideString) of object;
  TPlayerOnEvent = procedure(ASender: TObject; nEventCode: Integer; nEventParam: Integer) of object;


// *********************************************************************//
// OLE Server Proxy class declaration
// Server Object    : TPlayer
// Help String      : APlayer3 Control
// Default Interface: IPlayer
// Def. Intf. DISP? : No
// Event   Interface: _IPlayerEvents
// TypeFlags        : (2) CanCreate
// *********************************************************************//
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  TPlayerProperties= class;
{$ENDIF}
  TPlayer = class(TOleServer)
  private
    FOnMessage: TPlayerOnMessage;
    FOnStateChanged: TPlayerOnStateChanged;
    FOnOpenSucceeded: TNotifyEvent;
    FOnSeekCompleted: TPlayerOnSeekCompleted;
    FOnBuffer: TPlayerOnBuffer;
    FOnVideoSizeChanged: TNotifyEvent;
    FOnDownloadCodec: TPlayerOnDownloadCodec;
    FOnEvent: TPlayerOnEvent;
    FIntf: IPlayer;
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    FProps: TPlayerProperties;
    function GetServerProperties: TPlayerProperties;
{$ENDIF}
    function GetDefaultInterface: IPlayer;
  protected
    procedure InitServerData; override;
    procedure InvokeEvent(DispID: TDispID; var Params: TVariantArray); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Connect; override;
    procedure ConnectTo(svrIntf: IPlayer);
    procedure Disconnect; override;
    procedure Open(const strUrl: WideString);
    procedure Close;
    procedure Play;
    procedure Pause;
    function GetVersion: WideString;
    procedure SetCustomLogo(nLogo: Integer);
    function GetState: Integer;
    function GetDuration: Integer;
    function GetPosition: Integer;
    function SetPosition(nPosition: Integer): Integer;
    function GetVideoWidth: Integer;
    function GetVideoHeight: Integer;
    function GetVolume: Integer;
    function SetVolume(nVolume: Integer): Integer;
    function IsSeeking: Integer;
    function GetBufferProgress: Integer;
    function GetConfig(nConfigId: Integer): WideString;
    function SetConfig(nConfigId: Integer; const strValue: WideString): Integer;
    property DefaultInterface: IPlayer read GetDefaultInterface;
  published
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    property Server: TPlayerProperties read GetServerProperties;
{$ENDIF}
    property OnMessage: TPlayerOnMessage read FOnMessage write FOnMessage;
    property OnStateChanged: TPlayerOnStateChanged read FOnStateChanged write FOnStateChanged;
    property OnOpenSucceeded: TNotifyEvent read FOnOpenSucceeded write FOnOpenSucceeded;
    property OnSeekCompleted: TPlayerOnSeekCompleted read FOnSeekCompleted write FOnSeekCompleted;
    property OnBuffer: TPlayerOnBuffer read FOnBuffer write FOnBuffer;
    property OnVideoSizeChanged: TNotifyEvent read FOnVideoSizeChanged write FOnVideoSizeChanged;
    property OnDownloadCodec: TPlayerOnDownloadCodec read FOnDownloadCodec write FOnDownloadCodec;
    property OnEvent: TPlayerOnEvent read FOnEvent write FOnEvent;
  end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
// *********************************************************************//
// OLE Server Properties Proxy Class
// Server Object    : TPlayer
// (This object is used by the IDE's Property Inspector to allow editing
//  of the properties of this server)
// *********************************************************************//
 TPlayerProperties = class(TPersistent)
  private
    FServer:    TPlayer;
    function    GetDefaultInterface: IPlayer;
    constructor Create(AServer: TPlayer);
  protected
  public
    property DefaultInterface: IPlayer read GetDefaultInterface;
  published
  end;
{$ENDIF}


procedure Register;

resourcestring
  dtlServerPage = '(none)';

  dtlOcxPage = '(none)';

implementation

uses ComObj;

class function CoPlayer.Create: IPlayer;
begin
  Result := CreateComObject(CLASS_Player) as IPlayer;
end;

class function CoPlayer.CreateRemote(const MachineName: string): IPlayer;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_Player) as IPlayer;
end;

procedure TPlayer.InitServerData;
const
  CServerData: TServerData = (
    ClassID:   '{A9332148-C691-4B9D-91FC-B9C461DBE9DD}';
    IntfIID:   '{F19169FA-7EB8-45EB-8800-0D1F7C88F553}';
    EventIID:  '{31D6469C-1DA7-47C0-91F9-38F0C39F9B89}';
    LicenseKey: nil;
    Version: 500);
begin
  ServerData := @CServerData;
end;

procedure TPlayer.Connect;
var
  punk: IUnknown;
begin
  if FIntf = nil then
  begin
    punk := GetServer;
    ConnectEvents(punk);
    Fintf:= punk as IPlayer;
  end;
end;

procedure TPlayer.ConnectTo(svrIntf: IPlayer);
begin
  Disconnect;
  FIntf := svrIntf;
  ConnectEvents(FIntf);
end;

procedure TPlayer.DisConnect;
begin
  if Fintf <> nil then
  begin
    DisconnectEvents(FIntf);
    FIntf := nil;
  end;
end;

function TPlayer.GetDefaultInterface: IPlayer;
begin
  if FIntf = nil then
    Connect;
  Assert(FIntf <> nil, 'DefaultInterface is NULL. Component is not connected to Server. You must call "Connect" or "ConnectTo" before this operation');
  Result := FIntf;
end;

constructor TPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps := TPlayerProperties.Create(Self);
{$ENDIF}
end;

destructor TPlayer.Destroy;
begin
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps.Free;
{$ENDIF}
  inherited Destroy;
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
function TPlayer.GetServerProperties: TPlayerProperties;
begin
  Result := FProps;
end;
{$ENDIF}

procedure TPlayer.InvokeEvent(DispID: TDispID; var Params: TVariantArray);
begin
  case DispID of
    -1: Exit;  // DISPID_UNKNOWN
    1: if Assigned(FOnMessage) then
         FOnMessage(Self,
                    Params[0] {Integer},
                    Params[1] {Integer},
                    Params[2] {Integer});
    2: if Assigned(FOnStateChanged) then
         FOnStateChanged(Self,
                         Params[0] {Integer},
                         Params[1] {Integer});
    3: if Assigned(FOnOpenSucceeded) then
         FOnOpenSucceeded(Self);
    4: if Assigned(FOnSeekCompleted) then
         FOnSeekCompleted(Self, Params[0] {Integer});
    5: if Assigned(FOnBuffer) then
         FOnBuffer(Self, Params[0] {Integer});
    6: if Assigned(FOnVideoSizeChanged) then
         FOnVideoSizeChanged(Self);
    7: if Assigned(FOnDownloadCodec) then
         FOnDownloadCodec(Self, Params[0] {const WideString});
    8: if Assigned(FOnEvent) then
         FOnEvent(Self,
                  Params[0] {Integer},
                  Params[1] {Integer});
  end; {case DispID}
end;

procedure TPlayer.Open(const strUrl: WideString);
begin
  DefaultInterface.Open(strUrl);
end;

procedure TPlayer.Close;
begin
  DefaultInterface.Close;
end;

procedure TPlayer.Play;
begin
  DefaultInterface.Play;
end;

procedure TPlayer.Pause;
begin
  DefaultInterface.Pause;
end;

function TPlayer.GetVersion: WideString;
begin
  Result := DefaultInterface.GetVersion;
end;

procedure TPlayer.SetCustomLogo(nLogo: Integer);
begin
  DefaultInterface.SetCustomLogo(nLogo);
end;

function TPlayer.GetState: Integer;
begin
  Result := DefaultInterface.GetState;
end;

function TPlayer.GetDuration: Integer;
begin
  Result := DefaultInterface.GetDuration;
end;

function TPlayer.GetPosition: Integer;
begin
  Result := DefaultInterface.GetPosition;
end;

function TPlayer.SetPosition(nPosition: Integer): Integer;
begin
  Result := DefaultInterface.SetPosition(nPosition);
end;

function TPlayer.GetVideoWidth: Integer;
begin
  Result := DefaultInterface.GetVideoWidth;
end;

function TPlayer.GetVideoHeight: Integer;
begin
  Result := DefaultInterface.GetVideoHeight;
end;

function TPlayer.GetVolume: Integer;
begin
  Result := DefaultInterface.GetVolume;
end;

function TPlayer.SetVolume(nVolume: Integer): Integer;
begin
  Result := DefaultInterface.SetVolume(nVolume);
end;

function TPlayer.IsSeeking: Integer;
begin
  Result := DefaultInterface.IsSeeking;
end;

function TPlayer.GetBufferProgress: Integer;
begin
  Result := DefaultInterface.GetBufferProgress;
end;

function TPlayer.GetConfig(nConfigId: Integer): WideString;
begin
  Result := DefaultInterface.GetConfig(nConfigId);
end;

function TPlayer.SetConfig(nConfigId: Integer; const strValue: WideString): Integer;
begin
  Result := DefaultInterface.SetConfig(nConfigId, strValue);
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
constructor TPlayerProperties.Create(AServer: TPlayer);
begin
  inherited Create;
  FServer := AServer;
end;

function TPlayerProperties.GetDefaultInterface: IPlayer;
begin
  Result := FServer.DefaultInterface;
end;

{$ENDIF}

procedure Register;
begin
  RegisterComponents('MyVcl', [TPlayer]);
end;

end.
