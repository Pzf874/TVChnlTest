unit uTimMsgDlg;
//带定时退出的消息框，对话框，未提供Pos选项，从Dialogs.pas复制修改
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TMessageForm = class(TForm)
  private
    Message: TLabel;
    procedure HelpButtonClick(Sender: TObject);
  protected
    procedure CustomKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure WriteToClipBoard(Text: String);
    function GetFormText: String;
  public
    constructor CreateNew(AOwner: TComponent); reintroduce;
  end;

  TTimMessageForm = class(TMessageForm)
  private
    { Private declarations }
    fTimeOut:Integer;
    fTimer: TTimer;
    dButton: TButton;
    dCaption: string;
    procedure fTimerTimer(Sender: TObject);
  end;

function TimMessageDlg(TimeOut: Integer;const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; DefaultButton: TMsgDlgBtn): Integer; overload;
function TimMessageDlg(TimeOut: Integer;const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; DefaultButton: TMsgDlgBtn): Integer; overload;
function TimMessageDlg(TimeOut: Integer; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer; overload;

procedure TimeMessage(TimeOut: Integer;const Msg: string);
procedure TimeMessageFmt(TimeOut: Integer;const Msg: string; Params: array of const);

implementation

uses
  Consts, Dlgs, Math, ActiveX, StrUtils, WideStrUtils,
  Themes, MultiMon, HelpIntfs, CommCtrl;

var
  IconIDs: array[TMsgDlgType] of PChar = (IDI_EXCLAMATION, IDI_HAND,
    IDI_ASTERISK, IDI_QUESTION, nil);
  ButtonNames: array[TMsgDlgBtn] of string = (
    'Yes', 'No', 'OK', 'Cancel', 'Abort', 'Retry', 'Ignore', 'All', 'NoToAll',
    'YesToAll', 'Help');
  ButtonCaptions: array[TMsgDlgBtn] of string = (
    '是', '否', '确认', '取消', '中止', '重试', '忽略', '全体', '全否',
    '全是', '帮助');
  ModalResults: array[TMsgDlgBtn] of Integer = (
    mrYes, mrNo, mrOk, mrCancel, mrAbort, mrRetry, mrIgnore, mrAll, mrNoToAll,
    mrYesToAll, 0);
var
  ButtonWidths : array[TMsgDlgBtn] of integer;  // initialized to zero

////////////////////////////////////////////////////////////////////////////////
function GetAveCharSize(Canvas: TCanvas): TPoint;
var
  I: Integer;
  Buffer: array[0..51] of Char;
begin
  for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
  for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
  GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
  Result.X := Result.X div 52;
end;


////////////////////////////////////////////////////////////////////////////////
constructor TMessageForm.CreateNew(AOwner: TComponent);
var
  NonClientMetrics: TNonClientMetrics;
begin
  inherited CreateNew(AOwner);
  NonClientMetrics.cbSize := sizeof(NonClientMetrics);
  if SystemParametersInfo(SPI_GETNONCLIENTMETRICS, 0, @NonClientMetrics, 0) then
    Font.Handle := CreateFontIndirect(NonClientMetrics.lfMessageFont);
end;

procedure TMessageForm.HelpButtonClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

procedure TMessageForm.CustomKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift = [ssCtrl]) and (Key = Word('C')) then
  begin
    Beep;
    WriteToClipBoard(GetFormText);
  end;
end;

procedure TMessageForm.WriteToClipBoard(Text: String);
var
  Data: THandle;
  DataPtr: Pointer;
begin
  if OpenClipBoard(0) then
  begin
    try
      Data := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE, Length(Text) + 1);
      try
        DataPtr := GlobalLock(Data);
        try
          Move(PChar(Text)^, DataPtr^, Length(Text) + 1);
          EmptyClipBoard;
          SetClipboardData(CF_TEXT, Data);
        finally
          GlobalUnlock(Data);
        end;
      except
        GlobalFree(Data);
        raise;
      end;
    finally
      CloseClipBoard;
    end;
  end
  else
    raise Exception.CreateRes(@SCannotOpenClipboard);
end;

function TMessageForm.GetFormText: String;
var
  DividerLine, ButtonCaptions: string;
  I: integer;
begin
  DividerLine := StringOfChar('-', 27) + sLineBreak;
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TButton then
      ButtonCaptions := ButtonCaptions + TButton(Components[I]).Caption +
        StringOfChar(' ', 3);
  ButtonCaptions := StringReplace(ButtonCaptions,'&','', [rfReplaceAll]);
  Result := Format('%s%s%s%s%s%s%s%s%s%s', [DividerLine, Caption, sLineBreak,
    DividerLine, Message.Caption, sLineBreak, DividerLine, ButtonCaptions,
    sLineBreak, DividerLine]);
end;

////////////////////////////////////////////////////////////////////////////////
//秒倒计时显示在默认按钮，=0时自动按默认按钮一次
procedure TTimMessageForm.fTimerTimer(Sender: TObject);
var
  i:Integer;
begin
  if not Assigned(dButton) then begin
    for i := 0 to ControlCount - 1 do
      if Controls[i] is TButton then
        if TButton(Controls[i]).Default then begin
          dButton := TButton(Controls[i]);
          dCaption := dButton.Caption;
        end;
  end;
  if not Assigned(dButton) then Exit;
  dButton.Caption := dCaption + Format(' (%d)',[fTimeOut]);
  if fTimeOut<=0 then dButton.Click;
  Dec(fTimeOut);
end;

////////////////////////////////////////////////////////////////////////////////
type
  PTaskDialogData = ^TTaskDialogData;
  TTaskDialogData = record
    HelpCtx: Integer;
    HelpFileName: string;
    ParentWnd: HWND;
    Position: TPoint;
  end;

const
  tdbHelp = -1;

procedure ShowHelpException(ParentWnd: HWND; E: Exception);
var
  Msg: string;
  Flags: Integer;
begin
  Flags := MB_OK or MB_ICONSTOP;
  if Application.UseRightToLeftReading then
    Flags := Flags or MB_RTLREADING;
  Msg := E.Message;
  if (Msg <> '') and (AnsiLastChar(Msg) > '.') then
    Msg := Msg + '.';
  MessageBox(ParentWnd, PChar(Msg), PChar(Application.Title), Flags);
end;

function TaskDlgCallback(hwnd: HWND; msg: UINT; wParam: WPARAM;
  lParam: LPARAM; lpRefData: LONG_PTR): HResult; stdcall;
var
  Rect: TRect;
  LHandle: HMONITOR;
  LHelpFile: string;
  LHelpSystem: IHelpSystem;
  LMonitorInfo: TMonitorInfo;

  procedure DoShowHelp;
  begin
    with PTaskDialogData(lpRefData)^ do
    begin
      if HelpFileName = '' then
        LHelpFile := Application.HelpFile
      else
        LHelpFile := HelpFileName;
      if HelpIntfs.GetHelpSystem(LHelpSystem) then
      try
        LHelpSystem.Hook(Application.Handle, LHelpFile, HELP_CONTEXT, HelpCtx);
      except
        on E: Exception do
          ShowHelpException(hwnd, E);
      end;
    end;
  end;

begin
  Result := S_OK;
  case msg of
    TDN_BUTTON_CLICKED:
      if wParam = tdbHelp then
      begin
        Result := S_FALSE;
        DoShowHelp;
      end;
    TDN_HELP:
      DoShowHelp;
    TDN_CREATED:
      with PTaskDialogData(lpRefData)^, Position do
      begin
        LHandle := MonitorFromWindow(ParentWnd, MONITOR_DEFAULTTONEAREST);
        LMonitorInfo.cbSize := SizeOf(LMonitorInfo);
        if GetMonitorInfo(LHandle, @LMonitorInfo) then
          with LMonitorInfo do
          begin
            GetWindowRect(hwnd, Rect);
            if X < 0 then
              X := ((rcMonitor.Right - rcMonitor.Left) - (Rect.Right - Rect.Left)) div 2;
            if Y < 0 then
              Y := ((rcMonitor.Bottom - rcMonitor.Top) - (Rect.Bottom - Rect.Top)) div 2;
            Inc(X, rcMonitor.Left);
            Inc(Y, rcMonitor.Top);
            SetWindowPos(hwnd, 0, X, Y, 0, 0, SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOZORDER);
          end;
      end;
  end;
end;

function GetActiveForm:TForm;
var
  i: Integer;
  wnd: HWnd;
begin
  wnd := Application.ActiveFormHandle;
  for i := 0 to Application.ComponentCount - 1 do
    if (Application.Components[i] is TForm) and (TForm(Application.Components[i]).Handle=wnd) then
    begin
      Result := TForm(Application.Components[i]);
      Exit;
    end;
  Result := Application.MainForm;
end;

function DoTimMessageDlgPosHelp(MessageDialog: TForm; HelpCtx: Longint; X, Y: Integer;
  const HelpFileName: string): Integer;
begin
  with MessageDialog do
    try
      HelpContext := HelpCtx;
      HelpFile := HelpFileName;
      if X >= 0 then Left := X;
      if Y >= 0 then Top := Y;
      if (Y < 0) and (X < 0) then Position := poOwnerFormCenter;
      Result := ShowModal;
    finally
      Free;
    end;
end;


function CreateTimMessageDialog(TimeOut:Integer; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; DefaultButton: TMsgDlgBtn): TForm; overload;
const
  mcHorzMargin = 8;
  mcVertMargin = 8;
  mcHorzSpacing = 10;
  mcVertSpacing = 10;
  mcButtonWidth = 50;
  mcButtonHeight = 14;
  mcButtonSpacing = 4;
var
  DialogUnits: TPoint;
  HorzMargin, VertMargin, HorzSpacing, VertSpacing, ButtonWidth,
  ButtonHeight, ButtonSpacing, ButtonCount, ButtonGroupWidth,
  IconTextWidth, IconTextHeight, X, ALeft: Integer;
  B, CancelButton: TMsgDlgBtn;
  IconID: PChar;
  TextRect: TRect;
  LButton: TButton;
begin
  Result := TTimMessageForm.CreateNew(GetActiveForm);
  with TTimMessageForm(Result) do
  begin
    fTimeOut := TimeOut;
    fTimer := TTimer.Create(Result);
    fTimer.Enabled := TimeOut>0;
    fTimer.OnTimer := fTimerTimer;
  end;
  with Result do
  begin
    BiDiMode := Application.BiDiMode;
    BorderStyle := bsDialog;
    Canvas.Font := Font;
    KeyPreview := True;
    Position := poDesigned;
    OnKeyDown := TMessageForm(Result).CustomKeyDown;
    DialogUnits := GetAveCharSize(Canvas);
    HorzMargin := MulDiv(mcHorzMargin, DialogUnits.X, 4);
    VertMargin := MulDiv(mcVertMargin, DialogUnits.Y, 8);
    HorzSpacing := MulDiv(mcHorzSpacing, DialogUnits.X, 4);
    VertSpacing := MulDiv(mcVertSpacing, DialogUnits.Y, 8);
    ButtonWidth := MulDiv(mcButtonWidth, DialogUnits.X, 4);
    for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
    begin
      if B in Buttons then
      begin
        if ButtonWidths[B] = 0 then
        begin
          TextRect := Rect(0,0,0,0);
          Windows.DrawText( canvas.handle,
            PChar({LoadResString}(ButtonCaptions[B])), -1,
            TextRect, DT_CALCRECT or DT_LEFT or DT_SINGLELINE or
            DrawTextBiDiModeFlagsReadingOnly);
          with TextRect do ButtonWidths[B] := Right - Left + 8;
        end;
        if ButtonWidths[B] > ButtonWidth then
          ButtonWidth := ButtonWidths[B];
      end;
    end;
    ButtonHeight := MulDiv(mcButtonHeight, DialogUnits.Y, 8);
    ButtonSpacing := MulDiv(mcButtonSpacing, DialogUnits.X, 4);
    SetRect(TextRect, 0, 0, Screen.Width div 2, 0);
    DrawText(Canvas.Handle, PChar(Msg), Length(Msg)+1, TextRect,
      DT_EXPANDTABS or DT_CALCRECT or DT_WORDBREAK or
      DrawTextBiDiModeFlagsReadingOnly);
    IconID := IconIDs[DlgType];
    IconTextWidth := TextRect.Right;
    IconTextHeight := TextRect.Bottom;
    if IconID <> nil then
    begin
      Inc(IconTextWidth, 32 + HorzSpacing);
      if IconTextHeight < 32 then IconTextHeight := 32;
    end;
    ButtonCount := 0;
    for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if B in Buttons then Inc(ButtonCount);
    ButtonGroupWidth := 0;
    if ButtonCount <> 0 then
      ButtonGroupWidth := ButtonWidth * ButtonCount +
        ButtonSpacing * (ButtonCount - 1);
    ClientWidth := Max(IconTextWidth, ButtonGroupWidth) + HorzMargin * 2;
    ClientHeight := IconTextHeight + ButtonHeight + VertSpacing +
      VertMargin * 2;
    Left := (Screen.Width div 2) - (Width div 2);
    Top := (Screen.Height div 2) - (Height div 2);
    Caption := Application.Title;
    if IconID <> nil then
      with TImage.Create(Result) do
      begin
        Name := 'Image';
        Parent := Result;
        Picture.Icon.Handle := LoadIcon(0, IconID);
        SetBounds(HorzMargin, VertMargin, 32, 32);
      end;
    TMessageForm(Result).Message := TLabel.Create(Result);
    with TMessageForm(Result).Message do
    begin
      Name := 'Message';
      Parent := Result;
      WordWrap := True;
      Caption := Msg;
      BoundsRect := TextRect;
      BiDiMode := Result.BiDiMode;
      ALeft := IconTextWidth - TextRect.Right + HorzMargin;
      if UseRightToLeftAlignment then
        ALeft := Result.ClientWidth - ALeft - Width;
      SetBounds(ALeft, VertMargin,
        TextRect.Right, TextRect.Bottom);
    end;
    if mbCancel in Buttons then CancelButton := mbCancel else
      if mbNo in Buttons then CancelButton := mbNo else
        CancelButton := mbOk;
    X := (ClientWidth - ButtonGroupWidth) div 2;
    for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if B in Buttons then
      begin
        LButton := TButton.Create(Result);
        with LButton do
        begin
          Name := ButtonNames[B];
          Parent := Result;
          Caption := {LoadResString}(ButtonCaptions[B]);
          ModalResult := ModalResults[B];
          if B = DefaultButton then
          begin
            Default := True;
            ActiveControl := LButton;
            TTimMessageForm(Result).fTimerTimer(nil);
          end;
          if B = CancelButton then
            Cancel := True;
          SetBounds(X, IconTextHeight + VertMargin + VertSpacing,
            ButtonWidth, ButtonHeight);
          Inc(X, ButtonWidth + ButtonSpacing);
          if B = mbHelp then
            OnClick := TMessageForm(Result).HelpButtonClick;
        end;
      end;
  end;
end;

function CreateTimMessageDialog(TimeOut:Integer; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons): TForm; overload;
var
  DefaultButton: TMsgDlgBtn;
begin
  if mbOk in Buttons then DefaultButton := mbOk else
    if mbYes in Buttons then DefaultButton := mbYes else
      DefaultButton := mbRetry;
  Result := CreateTimMessageDialog(TimeOut, Msg, DlgType, Buttons, DefaultButton);
end;

function TimMessageDlg(TimeOut: Integer;const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; DefaultButton: TMsgDlgBtn): Integer;
begin
  Result := TimMessageDlg(TimeOut, Msg, DlgType, Buttons, 0, DefaultButton);
end;

function TimMessageDlg(TimeOut:Integer; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
begin
  Result := DoTimMessageDlgPosHelp(CreateTimMessageDialog(TimeOut, Msg, DlgType, Buttons),
      HelpCtx, -1, -1, '');
end;

function TimMessageDlg(TimeOut:Integer; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; DefaultButton: TMsgDlgBtn): Integer;
begin
  Result := DoTimMessageDlgPosHelp(CreateTimMessageDialog(TimeOut, Msg, DlgType, Buttons, DefaultButton),
      HelpCtx, -1, -1, '');
end;

procedure TimeMessage(TimeOut:Integer; const Msg: string);
begin
  TimMessageDlg(TimeOut, Msg, mtInformation, [mbOK], 0);
end;

procedure TimeMessageFmt(TimeOut:Integer; const Msg: string; Params: array of const);
begin
  TimeMessage(TimeOut, Format(Msg, Params));
end;

end.
