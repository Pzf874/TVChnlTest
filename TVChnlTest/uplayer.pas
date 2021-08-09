unit uPlayer;
//原文链接：https://blog.csdn.net/netwizard/article/details/70876943
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
    fPlayShow: Boolean;   //False:无界面播放，只为检验播放有效性和连接时间，播放速度，视频尺寸等
    fTimeOut: Cardinal;
    fMhandle: Hwnd;       //调用者的句柄，用于发送返回信息

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
//调用参数：Aplayer.exe furl fshow ftimout fmhandle findex
//如果无参数：空画面显示是否成功连接上了Aplayer.dll，不会退出
//如果1个参数：参数1认为是furl,打开此furl播放，不会自动退出
//如果2个参数：参数2认为是fshow,决定是否有播放画面，默认=1
//如果3个参数：参数3认为是ftimout,决定fshow=0时连接超时退出秒数，默认=10秒
//如果4个参数：参数4认为是fmhandle，调用者句柄，<>0则退出前发消息给fmHandle，默认=0
//如果5个参数：参数5认为是findex,调用者标记的数字，发消息返回。默认=0

{ TfPlayer }
//认为判断结束，发送UM_PLAY_END消息给主调用方，wParam=0
//lParam为string:='findex,VResult,VSpeed,VConnectms,VWidth,VHeight,VState,'
procedure TfPlayer.DoCompleted;
begin
  if fMhandle>0 then begin
  	PostMessage(fMhandle,UM_PLAY_END1,(Tag shl 24)+VResult,VSpeed);	//返回消息给发命令的窗口
  	PostMessage(fMhandle,UM_PLAY_END2,(Tag shl 24)+VState,VConnectms);	//返回消息给发命令的窗口
  	PostMessage(fMhandle,UM_PLAY_END,(Tag shl 24)+VHeight,VWidth);	//返回消息给发命令的窗口
  end;

  if Assigned(FOnCompleted) then
    FOnCompleted(Self);

  VResult := 0;//本次判断结束
end;

//关闭等同于退出销毁，不隐藏到后台，关闭播放，调用OnTerminate事件
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
  //解析传入参数：用' '隔开的字符串(furl fshow ftimout fmhandle findex)，作为传入1个参数
  if ParamCount>0 then begin //ParamStr[0]是程序本身，带路径
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
    SpeedDelay := 2500;  //无画面连接测试时：进入播放后2.5秒自动完成
  end;

  MyPlayer := TPlayer.Create(Self);
  MyPlayer.OnStateChanged := MyPlayerStateChanged;
  MyPlayer.OnDownloadCodec := MyPlayerDownloadCodec;
  APlayerCreateSuccess := InitAPlayer(Handle);

  if APlayerCreateSuccess then begin
    //指定一个播放内容连接
    tmrSpeed.Enabled := True;
    if fMedia<>'' then
      MyPlayer.Open(fMedia)
    else
      VResult := 4;//Unknown
  end
  else begin
    if fPlayShow then
      TimeMessage(3,'打开APlayer.dll并创建控件错误。');
    DoCompleted;
    Application.ShowMainForm := False;
    Application.Terminate;
  end;
end;

//从Aplayer.dll创建TPlayer对象并绑定到窗口句柄Handle上
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
//15 - Disable audio                   int      R/W         不渲染音频，即把视频无声播放
    if not fPlayShow then     //虚拟播放，不解码视频音频，减少CPU/GPU压力(已经获得尺寸，停止视频播放，数据继续获取）
      MyPlayer.SetConfig(15,'1');
//602 - Picture enable                 int      R/W         激活视频叠图加功能, 1-激活, 0-不激活
//613 - Picture font                   str      R/W         获取或设置叠加文本的字体，格式："fontname;fontsize;fontcolor;edge"
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

//播放器没有解码插件：停止播放退出
procedure TfPlayer.MyPlayerDownloadCodec(ASender: TObject; const strCodecPath: WideString);
begin
  VResult := 1; //OK
  NoCodec := strCodecPath;
end;

//播放状态改变，刷新VState, VConnectms，VWidth，VHeight
procedure TfPlayer.MyPlayerStateChanged(ASender: TObject; nOldState, nNewState: Integer);
begin
  VState := nNewState;
  if nNewState=0 then VResult := 2;   //NG
  if nNewState=1 then Startingatms := GetTickCount;   //打开中
  if nNewState=3 then begin
    VConnectms := GetTickCount-Startingatms;          //暂停中（打开完成）
    VWidth := MyPlayer.GetVideoWidth;
    VHeight := MyPlayer.GetVideoHeight;
//14 - Disable video                   int      R/W         不渲染视频，即把视频当音频播放
//15 - Disable audio                   int      R/W         不渲染音频，即把视频无声播放
    if not fPlayShow then begin    //虚拟播放，不解码视频音频，减少CPU/GPU压力(已经获得尺寸，停止视频播放，数据继续获取）
      MyPlayer.SetConfig(14,'1');
      MyPlayer.SetConfig(15,'1');
    end;
  end;
  Caption := APlayStateStr[VState]+'->' + Hint;
end;

//每1秒中刷新VSpeed,VResult
procedure TfPlayer.tmrSpeedTimer(Sender: TObject);
var
  cspd: Cardinal;
  Overstr: WideString;
begin
  if (VResult=0) and (VState=0) then Exit;    //等待播放启动

//41 - Read speed                      int      R           获取当前读取速度（对于网络文件来说就是下载速度），单位千字节每秒 (KB/s)
  cspd := StrToIntDef(MyPlayer.GetConfig(41),0);
  if VSpeed<cspd then VSpeed := cspd; //取最高峰值
  
  if fPlayShow then begin             //显示窗口每秒刷新
    Inc(FreshDelay,tmrSpeed.Interval);
    if FreshDelay>=1000 then begin
      Overstr := ''
        +#10+ Format('Speed = %d KB/s ',[cspd])
        +#10+ Format('Width = %d ',[VWidth])
        +#10+ Format('Height= %d ',[VHeight])
        ;
  //612 - Picture text                   str      W           设置一段文本作为叠加图像，值为文本内容，支持回车换行符主动换行和自动换行（文本宽度参数 623 限制下的自动换行）。
      MyPlayer.SetConfig(612,OverStr);
    end;
  end;

  if VState=5 then begin  //播放中，延迟SpeedDelay秒后，置为成功，获得下载速度
    Dec(SpeedDelay,tmrSpeed.Interval);
    if SpeedDelay<=0 then
      VResult := 1; //OK
  end;

  if (VResult=0) and (GetTickCount>(Startingatms+fTimeOut)) then  //超时
    VResult := 3; //TO

  if (NoCodec<>'') or (not fPlayShow and (VResult>0)) then begin //虚拟播放时，判断有结果就可以完成
    tmrSpeed.Enabled := False;
    if fPlayShow and (NoCodec<>'')  then
      TimeMessage(3,'codecs子目录内缺少解码文件:'+NoCodec);
    Close;
  end;
end;

end.
