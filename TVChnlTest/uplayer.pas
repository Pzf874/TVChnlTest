unit uPlayer;
//ԭ�����ӣ�https://blog.csdn.net/netwizard/article/details/70876943
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, OleCtnrs, ComObj, ActiveX, OleServer, APlayer3Lib_TLB,
  Buttons;

type
  TfPlayer = class(TForm)
    tmrSpeed: TTimer;
    procedure tmrSpeedTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    fMedia: string;
    fPlayShow: Boolean;   //False:�޽��沥�ţ�ֻΪ���鲥����Ч�Ժ�����ʱ�䣬�����ٶȣ���Ƶ�ߴ��
    fTimeOut: Cardinal;
    fMhandle: Hwnd;       //�����ߵľ�������ڷ��ͷ�����Ϣ

    VState,VWidth,VHeight:LongInt;
    VResult,VSpeed,VConnectms: Cardinal;

    SpeedDelay,FreshDelay:Integer;
    APlayerCreateSuccess: Boolean;
    NoCodec: string;
    Startingatms: Cardinal;
    FOnCompleted: TNotifyEvent;
    MyPlayer: TPlayer;
    procedure MyPlayerStateChanged(ASender: TObject; nOldState, nNewState: Integer);
    procedure MyPlayerDownloadCodec(ASender: TObject; const strCodecPath: WideString);
    function InitAPlayer(Handle:Hwnd): Boolean;
    procedure DoCompleted;
  public
    { Public declarations }
    property  OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
  end;

var
  fPlayer: TfPlayer;

implementation
{$R *.dfm}

uses
  utools, uTimMsgDlg;
//���ò�����Aplayer.exe furl fshow ftimout fmhandle findex
//����޲������ջ�����ʾ�Ƿ�ɹ���������Aplayer.dll�������˳�
//���1������������1��Ϊ��furl,�򿪴�furl���ţ������Զ��˳�
//���2������������2��Ϊ��fshow,�����Ƿ��в��Ż��棬Ĭ��=1
//���3������������3��Ϊ��ftimout,����fshow=0ʱ���ӳ�ʱ�˳�������Ĭ��=10��
//���4������������4��Ϊ��fmhandle�������߾����<>0���˳�ǰ����Ϣ��fmHandle��Ĭ��=0
//���5������������5��Ϊ��findex,�����߱�ǵ����֣�����Ϣ���ء�Ĭ��=0

{ TfPlayer }
//��Ϊ�жϽ���������UM_PLAY_END��Ϣ�������÷���wParam=0
//lParamΪstring:='findex,VResult,VSpeed,VConnectms,VWidth,VHeight,VState,'
procedure TfPlayer.DoCompleted;
begin
  if fMhandle>0 then begin
  	PostMessage(fMhandle,UM_PLAY_END1,(Tag shl 24)+VResult,VSpeed);	//������Ϣ��������Ĵ���
  	PostMessage(fMhandle,UM_PLAY_END2,(Tag shl 24)+VState,VConnectms);	//������Ϣ��������Ĵ���
  	PostMessage(fMhandle,UM_PLAY_END,(Tag shl 24)+VHeight,VWidth);	//������Ϣ��������Ĵ���
  end;

  if Assigned(FOnCompleted) then
    FOnCompleted(Self);

  VResult := 0;//�����жϽ���
end;

//�رյ�ͬ���˳����٣������ص���̨���رղ��ţ�����OnTerminate�¼�
procedure TfPlayer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrSpeed.Enabled := False;
  DoCompleted;
  if (APlayerCreateSuccess) then begin
    MyPlayer.Close;
    MyPlayer.Free;
  end;
end;

procedure TfPlayer.FormCreate(Sender: TObject);
var
  str1:string;
begin
  fPlayShow := True; fTimeOut := 10*1000;
  Caption := CmdLine;
  //���������������' '�������ַ���(furl fshow ftimout fmhandle findex)����Ϊ����1������
  if ParamCount>0 then begin //ParamStr[0]�ǳ�������·��
    str1 := ParamStr(1);//furl
    fMedia := Trim(GetSubStr(str1,'@'));
    Hint := fMedia;
  end;
  if ParamCount>1 then begin
    str1 := ParamStr(2);//fshow
    fPlayShow := Boolean(StrToIntDef(str1,1));
  end;
  if ParamCount>2 then begin
    str1 := ParamStr(3);//ftimout
    fTimeOut := StrToIntDef(str1,10)*1000;
  end;
  if ParamCount>3 then begin
    str1 := ParamStr(4);//fmhandle
    fmhandle := StrToIntDef(str1,0);
  end;
  if ParamCount>4 then begin
    str1 := ParamStr(5);//fth
    Tag := StrToIntDef(str1,0);
  end;

  if not fPlayShow then begin
    Application.ShowMainForm := False;
    Width := 16; Height := 9;
    SpeedDelay := 2500;  //�޻������Ӳ���ʱ�����벥�ź�2.5���Զ����
  end;

  MyPlayer := TPlayer.Create(Self);
  MyPlayer.OnStateChanged := MyPlayerStateChanged;
  MyPlayer.OnDownloadCodec := MyPlayerDownloadCodec;
  APlayerCreateSuccess := InitAPlayer(Handle);

  if APlayerCreateSuccess then begin
    //ָ��һ��������������
    tmrSpeed.Enabled := True;
    if fMedia<>'' then
      MyPlayer.Open(fMedia)
    else
      VResult := 4;//Unknown
  end
  else begin
    if fPlayShow then
      TimeMessage(3,'��APlayer.dll�������ؼ�����');
    DoCompleted;
    Application.ShowMainForm := False;
    Application.Terminate;
  end;
end;

//��Aplayer.dll����TPlayer���󲢰󶨵����ھ��Handle��
function TfPlayer.InitAPlayer(Handle:Hwnd): Boolean;
var
  hModule, hDll: THandle;
  APlayer: IPlayer;
  AtlAxAttachControl: TAtlAxAttachControl;
begin
  Result := False;
  hModule := LoadLibrary('atl.dll');
  if hModule < 32 then
    Exit;

  try
    hDll := LoadLibrary(APlayerDLLFile);
    APlayer := CreateComObjectFromDll(CLASS_Player, hDll) as IPlayer;
    if not Assigned(APlayer) then
      Exit;
    MyPlayer.ConnectTo(APlayer);
//15 - Disable audio                   int      R/W         ����Ⱦ��Ƶ��������Ƶ��������
    if not fPlayShow then     //���ⲥ�ţ���������Ƶ��Ƶ������CPU/GPUѹ��(�Ѿ���óߴ磬ֹͣ��Ƶ���ţ����ݼ�����ȡ��
      MyPlayer.SetConfig(15,'1');
//602 - Picture enable                 int      R/W         ������Ƶ��ͼ�ӹ���, 1-����, 0-������
//613 - Picture font                   str      R/W         ��ȡ�����õ����ı������壬��ʽ��"fontname;fontsize;fontcolor;edge"
    MyPlayer.SetConfig(602,'1');
    MyPlayer.SetConfig(608,'168');
    MyPlayer.SetConfig(613,'Arial;18;15655238;0');

    AtlAxAttachControl := TAtlAxAttachControl(GetProcAddress(hModule, 'AtlAxAttachControl'));
    if not Assigned(AtlAxAttachControl) then
      Exit;

    AtlAxAttachControl(APlayer, Handle, nil);
    Result := True;
  except
    Result := False;
  end;
end;

//������û�н�������ֹͣ�����˳�
procedure TfPlayer.MyPlayerDownloadCodec(ASender: TObject; const strCodecPath: WideString);
begin
  VResult := 1; //OK
  NoCodec := strCodecPath;
end;

//����״̬�ı䣬ˢ��VState, VConnectms��VWidth��VHeight
procedure TfPlayer.MyPlayerStateChanged(ASender: TObject; nOldState, nNewState: Integer);
begin
  VState := nNewState;
  if nNewState=0 then VResult := 2;   //NG
  if nNewState=1 then Startingatms := GetTickCount;   //����
  if nNewState=3 then begin
    VConnectms := GetTickCount-Startingatms;          //��ͣ�У�����ɣ�
    VWidth := MyPlayer.GetVideoWidth;
    VHeight := MyPlayer.GetVideoHeight;
//14 - Disable video                   int      R/W         ����Ⱦ��Ƶ��������Ƶ����Ƶ����
//15 - Disable audio                   int      R/W         ����Ⱦ��Ƶ��������Ƶ��������
    if not fPlayShow then begin    //���ⲥ�ţ���������Ƶ��Ƶ������CPU/GPUѹ��(�Ѿ���óߴ磬ֹͣ��Ƶ���ţ����ݼ�����ȡ��
      MyPlayer.SetConfig(14,'1');
      MyPlayer.SetConfig(15,'1');
    end;
  end;
  Caption := APlayStateStr[VState]+'->' + Hint;
end;

//ÿ1����ˢ��VSpeed,VResult
procedure TfPlayer.tmrSpeedTimer(Sender: TObject);
var
  cspd: Cardinal;
  Overstr: WideString;
begin
  if (VResult=0) and (VState=0) then Exit;    //�ȴ���������

//41 - Read speed                      int      R           ��ȡ��ǰ��ȡ�ٶȣ����������ļ���˵���������ٶȣ�����λǧ�ֽ�ÿ�� (KB/s)
  cspd := StrToIntDef(MyPlayer.GetConfig(41),0);
  if VSpeed<cspd then VSpeed := cspd; //ȡ��߷�ֵ
  
  if fPlayShow then begin             //��ʾ����ÿ��ˢ��
    Inc(FreshDelay,tmrSpeed.Interval);
    if FreshDelay>=1000 then begin
      Overstr := ''
        +#10+ Format('Speed = %d KB/s ',[cspd])
        +#10+ Format('Width = %d ',[VWidth])
        +#10+ Format('Height= %d ',[VHeight])
        ;
  //612 - Picture text                   str      W           ����һ���ı���Ϊ����ͼ��ֵΪ�ı����ݣ�֧�ֻس����з��������к��Զ����У��ı���Ȳ��� 623 �����µ��Զ����У���
      MyPlayer.SetConfig(612,OverStr);
    end;
  end;

  if VState=5 then begin  //�����У��ӳ�SpeedDelay�����Ϊ�ɹ�����������ٶ�
    Dec(SpeedDelay,tmrSpeed.Interval);
    if SpeedDelay<=0 then
      VResult := 1; //OK
  end;

  if (VResult=0) and (GetTickCount>(Startingatms+fTimeOut)) then  //��ʱ
    VResult := 3; //TO

  if (NoCodec<>'') or (not fPlayShow and (VResult>0)) then begin //���ⲥ��ʱ���ж��н���Ϳ������
    tmrSpeed.Enabled := False;
    if fPlayShow and (NoCodec<>'')  then
      TimeMessage(3,'codecs��Ŀ¼��ȱ�ٽ����ļ�:'+NoCodec);
    Close;
  end;
end;

end.
