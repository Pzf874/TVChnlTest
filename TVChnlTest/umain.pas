unit umain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, Grids, DBGrids, DB, ADODB,
  comobj, utools, Spin;

type
  TcsResult = record        //������ṹ
  	fth:Integer;            //�̺߳�
    fid:Integer;            //���
    fResult:Integer;        //���0..3
    fWidth:integer;
    fHeight:integer;
    fConnectms:integer;
    fSpeed:integer;
    fPlayer:THandle;        //����������hProcess���
  end;
  PcsResult = ^TcsResult;

  Tfmain = class(TForm)
    pnl1: TPanel;
    dsrc: TDataSource;
    dbgrd1: TDBGrid;
    btnImport: TBitBtn;
    btnExport: TBitBtn;
    grpNew: TGroupBox;
    lblgrp: TLabel;
    cbbGrp: TComboBox;
    lblchn: TLabel;
    cbbChn: TComboBox;
    lblAdr: TLabel;
    edtUrl: TEdit;
    stat1: TStatusBar;
    btnClear: TBitBtn;
    lblCount: TLabel;
    conEDB: TADOConnection;
    qryDatV: TADOQuery;
    cmdADO: TADOCommand;
    btnExportXLS: TBitBtn;
    btnImportXLS: TBitBtn;
    rgChecked: TRadioGroup;
    neThread: TSpinEdit;
    lbl1: TLabel;
    neTimeOut: TSpinEdit;
    btnCheck: TSpeedButton;
    cbFollow: TCheckBox;
    tmr1: TTimer;
    procedure btnClearClick(Sender: TObject);
    procedure grpRewDblClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure cbbChnGrpChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure dsetAfterOpen(DataSet: TDataSet);
    procedure dsetAfterScroll(DataSet: TDataSet);
    procedure btnExportXLSClick(Sender: TObject);
    procedure btnImportXLSClick(Sender: TObject);
    procedure cbbGrpDropDown(Sender: TObject);
    procedure cbbChnDropDown(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCheckClick(Sender: TObject);
    procedure dbgrd1DblClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
    threads: array of TcsResult;
    oneplay: TcsResult;
    function GetNextSource(const index:Integer; var Curid:Integer; var url:string):Boolean;
    procedure SetCheckedSource(const cs: TcsResult);
    procedure StartNextThread(index,fid:Integer);
    function PlayerStart(const idx,fid:Integer;const url:string):Hwnd;
    procedure PlayerEnd1(var Message:TMessage);Message UM_PLAY_END1;
    procedure PlayerEnd2(var Message:TMessage);Message UM_PLAY_END2;
    procedure PlayerEnd(var Message:TMessage);Message UM_PLAY_END;
  public
    { Public declarations }
  end;

var
  fmain: Tfmain;

implementation

{$R *.dfm}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
uses
  AppVerInfo, uExport, uImport, uTimMsgDlg;

//��ȡ��ǰcurid��ź���һ��δ������߳�ռ�ݵ�Ƶ��Դ
//ռ�������fThread����ֵ���ж�:>0���ڼ�飬����δ�ڼ�飺���Ϊ����̺߳�index+1,����fid��furl���ݣ��ɹ�����
type
  THackDBGrid = class(TDBGrid);

//����һ��exe����,������������hwnd
function CreateProcessHwnd(exe,cmd:string):Hwnd;
var
  StartUpInfo: TStartUpInfoA;
  ProcessInfo: TProcessInformation;
  gui: tagGUITHREADINFO;
  hAcount: HWND;
begin
  FillChar(StartUpInfo, Sizeof(TStartUpInfo), #0);
  FillChar(ProcessInfo, Sizeof(TProcessInformation), #0);
  StartUpInfo.cb := Sizeof(TstartUpInfo);
  StartUpInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartUpInfo.wShowWindow := SW_SHOWNOACTIVATE;
  try
    CreateProcess(nil, PChar(exe+' '+cmd), nil, nil, False, 0, nil, nil,
      StartUpInfo, ProcessInfo);
  except
    Result := 0;
    Exit;
  end;
  Result := ProcessInfo.hProcess;
{  WaitForInputIdle(ProcessInfo.hProcess, INFINITE);
  FillMemory(@gui, Sizeof(tagGUITHREADINFO), 0);
  gui.cbSize   :=   Sizeof(tagGUITHREADINFO);
  //������Եõ��ղŴ������̵������ھ��
  GetGUIThreadInfo(ProcessInfo.dwThreadId, gui);
  hAcount := gui.hwndActive;
  Result := hAcount;

  //�õ��Ӵ��ھ��
  hAcount := FindWindowExA(gui.hwndActive, 0, 'ATL:30A441A8', PAnsiChar(0));

  //���Խ����Լ������Ľ���
  TerminateProcess(ProcessInfo.hProcess, 0);
}
end;

//Ϊ�˲�Ӱ�챾���򣬴��������Ĳ��Ž��̲���url����idx,fid����ȥ���ڽ����Ϣ���غ�ȶ�
function Tfmain.PlayerStart(const idx,fid:Integer;const url:string):Hwnd;
var
  c,s: string;
  pcs: PcsResult;
begin
Perform(WM_SETREDRAW, 0, 0); //����Ļ ��ֹ��˸
tmr1.Enabled := True;
//���ò�����Aplayer.exe furl fshow ftimout fmhandle findex
  s := Format('%s %d %d %d %d',[url,Ord(idx>High(threads)),neTimeOut.Value,Handle,idx]);
  c := ExtractFilePath(Application.ExeName)+'Aplayer.exe';
	Result := CreateProcessHwnd(c,s);
  if idx>High(threads) then pcs := @oneplay else pcs := @threads[idx];
  pcs^.fPlayer := Result;
  pcs^.fTh := idx;
  pcs^.fid := fid;
end;

//��ȡָ����ź������Ҫ������һ����ź�URL�����سɹ�������ź�url��ˢ��curid,url
function Tfmain.GetNextSource(const index:Integer; var Curid:Integer; var url:string):Boolean;
var
   rowDelta: Integer;
   rowCur: integer;
begin
Perform(WM_SETREDRAW, 0, 0); //����Ļ ��ֹ��˸
tmr1.Enabled := True;
  Result := False;
  with dsrc.DataSet do if Active then begin
    if RecordCount=0 then Exit;
    DisableControls;
    rowDelta := THackDBGrid(DBGrd1).Row-1;//��ǰ����ڼ��У�TopRow=1(��Title)
    rowCur := THackDBGrid(DBGrd1).VisibleRowCount;//��ǰ�����м���
    if rowDelta<(rowCur div 2) then rowDelta := rowDelta-rowCur+1;
    rowCur := RecNo;

    try
      First;
      Locate('fid',Curid,[]);  //���ﵱǰָ��λ�ã����۳ɹ���ʧ��
      while not EOF do begin
        if FieldByName('fThread').AsInteger<1 then begin //�ҵ�δ��ǵ���һ��
          Edit;
          FieldByName('fThread').AsInteger := index+1;
          Post;
          Curid := FieldByName('fId').AsInteger;
          url := FieldByName('fUrl').AsString;
          Result := True;
          Exit;
        end;
        Next;
      end;
    finally
      if not cbFollow.Checked then begin
        RecNo := rowCur;
        MoveBy(-rowDelta) ;
        MoveBy(rowDelta) ;
      end;
      EnableControls;
    end;
  end;
end;

//��Ǽ����
procedure Tfmain.SetCheckedSource(const cs: TcsResult);
var
   rowDelta: Integer;
   rowCur: integer;
begin
Perform(WM_SETREDRAW, 0, 0); //����Ļ ��ֹ��˸
tmr1.Enabled := True;
  with dsrc.DataSet do if Active then begin
    if RecordCount=0 then Exit;
    DisableControls;
    rowDelta := THackDBGrid(DBGrd1).Row-1;//��ǰ����ڼ��У�TopRow=1(��Title)
    rowCur := THackDBGrid(DBGrd1).VisibleRowCount;//��ǰ�����м���
    if rowDelta<(rowCur div 2) then rowDelta := rowDelta-rowCur+1;
    rowCur := RecNo;
    try
      First;
      if not Locate('fid',cs.fid,[]) then Exit;  //���ﵱǰָ��λ��
      Edit;
      if (cs.fResult>0) and (cs.fResult<=High(ResultStr)) then begin
        FieldByName('fResult').AsString := ResultStr[cs.fResult]; //OK-NG-TO;
        if cs.fResult=1 then begin                                //OK
          FieldByName('fVWidth').AsInteger := cs.fWidth;
          FieldByName('fVHeight').AsInteger := cs.fHeight;
          FieldByName('fConnect').AsInteger := cs.fConnectms;
          FieldByName('fSpeed').AsInteger := cs.fSpeed;
        end
        else begin                                            //NG-TO
          FieldByName('fVWidth').Value := Null;
          FieldByName('fVHeight').Value := Null;
          FieldByName('fConnect').Value := Null;
          FieldByName('fSpeed').Value := Null;
        end;
      end
      else begin                                              //Unknow
        FieldByName('fResult').Value := Null;
        FieldByName('fVWidth').Value := Null;
        FieldByName('fVHeight').Value := Null;
        FieldByName('fConnect').Value := Null;
        FieldByName('fSpeed').Value := Null;
      end;
      FieldByName('fThread').AsInteger := cs.fth+1;
      Post;
      RecNo := rowCur;
      MoveBy(-rowDelta) ;
      MoveBy(rowDelta) ;
    finally
      EnableControls;
    end;
  end;
end;

//����fid������һ�����ݵļ���̣߳��߳�ʵ������indexλ��
procedure Tfmain.StartNextThread(index,fid:Integer);
var
  i:Integer;
  furl:string;
begin
  if (not btnCheck.Down) or (not GetNextSource(index,fid,furl)) or (fid=0) or (furl='') then begin
    for i := Low(threads) to High(threads) do //���һ�����н����е��߳��Ƿ�ȫ�ر�
      if threads[i].fPlayer>0 then Exit;
    btnCheck.Down := False;
    btnCheck.Click;         //��ԭ��ť״̬�ͱ�ʶ
    btnCheck.Enabled := True;
    Exit;
  end;
  PlayerStart(index,fid,furl);
end;

procedure Tfmain.tmr1Timer(Sender: TObject);
begin
  tmr1.Enabled := False;
  Perform(WM_SETREDRAW, 1, 0); //������Ļ
  ReDrawWindow(Handle,nil,0,RDW_INVALIDATE or RDW_ALLCHILDREN);
end;

//˫��һ��Ƶ�����򿪴��ڲ�������ʵ�ʿ����ܲ�������
procedure Tfmain.dbgrd1DblClick(Sender: TObject);
var
  fth,fid:Integer;
  furl:String;
begin
  with dsrc.DataSet do if Active then begin
    fid := FieldByName('fId').AsInteger;
    furl := Trim(FieldByName('fUrl').AsString);
    if furl='' then Exit;

    if oneplay.fPlayer>0 then
      TerminateProcess(oneplay.fPlayer, 0);        //threads[i]��Ľ���THandle=hProcess

    fth := High(threads)+1;
    if fth<neThread.Value then fth := neThread.Value;
    PlayerStart(fth,fid,furl);  //�����������
  end;
end;

//����߳̽���ʱ�ص�����
procedure Tfmain.PlayerEnd1(var Message:TMessage);
var
  idx:Integer;
  pcs: PcsResult;
begin
  idx := Message.WParam shr 24;
  if idx>High(threads) then pcs := @oneplay else pcs := @threads[idx];
  pcs^.fResult := Message.WParam and $FFFFFF;
  pcs^.fSpeed := Message.lParam;
end;

procedure Tfmain.PlayerEnd2(var Message:TMessage);
var
  idx:Integer;
  pcs: PcsResult;
begin
  idx := Message.WParam shr 24;
  if idx>High(threads) then pcs := @oneplay else pcs := @threads[idx];
//  pcs^.fResult := Message.WParam and $FFFFFF;
  pcs^.fConnectms := Message.lParam;
end;

procedure Tfmain.PlayerEnd(var Message:TMessage);
var
  idx:Integer;
  pcs: PcsResult;
begin
  idx := Message.WParam shr 24;
  if idx>High(threads) then pcs := @oneplay else pcs := @threads[idx];
  pcs^.fHeight := Message.WParam and $FFFFFF;
  pcs^.fWidth := Message.lParam;
  SetCheckedSource(pcs^);
  pcs^.fPlayer := 0;        //��Ϊ�˽����Ѿ�����

  //����Ԥ�ȿ��õķ�Χ:˫�����ŵĿ��Ӵ��ڣ�����
  if (pcs^.fth <= High(threads)) then
    StartNextThread(pcs^.fth,pcs^.fid);
end;

//��ʼ��ֹͣ���
procedure Tfmain.btnCheckClick(Sender: TObject);
var
  i:Integer;
  fid:Integer;
begin
  if btnCheck.Down then begin
    if not FileExists(ExtractFilePath(Application.ExeName)+'Aplayer.exe') then
      TimeMessage(3,'û�С���򲥷�������'+ExtractFilePath(Application.ExeName)+'Aplayer.exe');
    
    neThread.Enabled := False;
    neTimeOut.Enabled := False;
    btnCheck.Caption := 'ֹͣ���';
    with cmdADO do begin                      //ɾ���������еļ���߳���Ϣ
      CommandText := 'Update RecData set fThread=NULL, fVWidth=NULL, fVHeight=NULL, fConnect=NULL, fSpeed=NULL ';
      CommandText := CommandText + GetWherePart(qryDatV.SQL.Text);
      Execute;
    end;
    TADOQuery(dsrc.DataSet).Requery;          //�����˻ص����ݼ�����
    SetLength(threads,neThread.Value);
    fid := 0;
    for i := Low(threads) to High(threads) do begin //����ָ���������߳�
      StartNextThread(i,fid);
    end;
  end
  else begin
    neThread.Enabled := True;
    neTimeOut.Enabled := True;
    btnCheck.Caption := '��ʼ���';
//    btnCheck.Enabled := False;              //ʹ��TerminateProcess�����н�����Ϣ������
    for i := Low(threads) to High(threads) do //�ر����н����е��߳�
    begin
      if threads[i].fPlayer>0 then
        TerminateProcess(threads[i].fPlayer, 0);        //threads[i]��Ľ���THandle=hProcess
//        PostMessage(threads[i].fPlayer,WM_CLOSE,0,0); //threads[i]��Ľ��̵������ڵ�Hwnd
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//��յ�ǰ���е�Ƶ������
procedure Tfmain.btnClearClick(Sender: TObject);
begin
  if Assigned(Sender) then
    if TimMessageDlg(5,'ȷ�����ȫ��(��ǰ��ʾ��)Ƶ����Ϣ��',mtConfirmation,
    [mbOK, mbCancel],mbCancel)<>mrOk then
      Exit;

  with cmdADO do begin                      //ɾ���������еļ���߳���Ϣ
    CommandText := 'Delete from RecData ';
    CommandText := CommandText + GetWherePart(qryDatV.SQL.Text);
    Execute;
  end;
  TADOQuery(dsrc.DataSet).Requery;
end;

//����Ƶ�����ݵ������ļ�(TXT��M3U)����������ǰ����������ʾ�������С�
procedure Tfmain.btnExportClick(Sender: TObject);
begin
  with fExTrans do try
    FillListWithColumn(conEDB,'RecData','fGroup','','min(fid)',lstGrp.Items); //׼��ȫ�������Ŀ����fid˳��
    dtsp.DataSet := dsrc.DataSet;     //���Ƶ�ǰ��ʾ�����ݼ����������ֹ���������
    ShowModal;
  finally
    Close;
  end;
end;

//����Ƶ�����ݵ�EXCEL��WPS/ET���¹�������SHEET1ҳ�棨����Ԥ�ȴ���������������ΧΪ��ǰ��ʾ������(�ܹ���Ӱ��)��
procedure Tfmain.btnExportXLSClick(Sender: TObject);
var
  filtstr:String;
begin
  filtstr := '';
  filtstr := filtstr + '���飺' + cbbGrp.Text;
  filtstr := filtstr + 'Ƶ����' + cbbChn.Text;
  filtstr := filtstr + '���ӣ�' + edtUrl.Text;
  if rgChecked.ItemIndex>=0 then
    filtstr := filtstr + '״̬��' + rgChecked.Items[rgChecked.ItemIndex] ;

  with dsrc.DataSet do if Active then begin
    Screen.Cursor := crHourGlass;
    DisableControls;
    try
      ExportToExcel(filtstr, dsrc.DataSet);
    finally
      EnableControls;
      Screen.Cursor := crDefault;
    end;
  end;
end;

//����Ƶ�����ݴ������ļ�(TXT��M3U)���ϲ�����ǰ�����У����Ե��ظ���ַ���ӡ�
procedure Tfmain.btnImportClick(Sender: TObject);
begin
  with fImTrans do try
    aDataSet := dsrc.DataSet;
    ShowModal;
  finally
    Close;
  end;
end;

//����Ƶ�����ݴ�EXCEL��WPS/ET��ǰҳ�棨��Ԥ�ȴ����������ϲ�����ǰ�����У����Ե��ظ���ַ���ӡ�
procedure Tfmain.btnImportXLSClick(Sender: TObject);
begin
  with dsrc.DataSet do if Active then begin
    Screen.Cursor := crHourGlass;
    DisableControls;
    try
      ImportFromExcel(dsrc.DataSet);
    finally
      EnableControls;
      Screen.Cursor := crDefault;
    end;
  end;
end;


//����������ķ��ࡢƵ������������
procedure Tfmain.grpRewDblClick(Sender: TObject);
var
  grp,chn,url:String;
  idx:Integer;
begin
  grp := Trim(cbbGrp.Text);
  chn := Trim(cbbChn.Text);
  url := Trim(edtUrl.Text);
  idx := rgChecked.ItemIndex;
  cbbGrp.Text := '';
  cbbChn.Text := '';
  edtUrl.Text := '';
  rgChecked.ItemIndex := -1;

  //TCombobox��Text������ı䲻���Զ�����OnChange,TEdit�ı�����ı���Զ�������
  if ((grp<>'') or (chn<>'') or (idx<>-1)) and (url='') then
    cbbChn.OnChange(Sender);  //grp��chn���˶�urlû�䣬�ֶ�����һ��OnChange
end;


//Ƶ��������ť���ѵ�ǰ��������µ�Ƶ���Ķ�������
procedure Tfmain.cbbChnDropDown(Sender: TObject);
var
  grp,filtstr:String;
begin
  grp := Trim(cbbGrp.Text);
  if grp<>'' then filtstr := 'where fGroup like '+ QuotedStr('%'+grp+'%') else filtstr := '';
  FillListWithColumn(conEDB,'RecData','fChannel',filtstr,'min(fid)',cbbChn.Items);
  lblchn.Caption := Format('Ƶ��(%d):',[cbbChn.Items.Count]);
end;

//����������ť�������з���Ķ�������
procedure Tfmain.cbbGrpDropDown(Sender: TObject);
begin
  FillListWithColumn(conEDB,'RecData','fGroup','','min(fid)',cbbGrp.Items);
  lblgrp.Caption := Format('����(%d):',[cbbGrp.Items.Count]);
end;

//���࣬Ƶ������ַ������������б仯��������ʾ����
procedure Tfmain.cbbChnGrpChange(Sender: TObject);
var
  grp,chn,url,filtstr:String;
begin
  grp := Trim(cbbGrp.Text);
  chn := Trim(cbbChn.Text);
  url := Trim(edtUrl.Text);

  if grp<>'' then filtstr := 'fGroup like '+ QuotedStr('%'+grp+'%') else filtstr := '';
  if chn<>'' then begin
    if filtstr<>'' then filtstr := filtstr + ' and ';
    filtstr := filtstr + 'fChannel like '+ QuotedStr('%'+chn+'%');
  end;
  if url<>'' then begin
    if filtstr<>'' then filtstr := filtstr + ' and ';
    filtstr := filtstr + 'fUrl like '+ QuotedStr('%'+url+'%');
  end;
  if (rgChecked.ItemIndex>=0) and (rgChecked.ItemIndex<=High(ResultStr))then begin
    if filtstr<>'' then filtstr := filtstr + ' and ';
    if rgChecked.ItemIndex=0 then
      filtstr := filtstr + 'fResult is NULL'
    else //OK-NG-TO
      filtstr := filtstr + 'fResult='+ QuotedStr(ResultStr[rgChecked.ItemIndex]); //OK-NG-TO
  end;
  if filtstr<>'' then
    filtstr := ' where ' + filtstr;
  with qryDatV do begin
    DisableControls;
    try
      Close;
      SQL.Clear;
      SQL.Add('Select * from RecData '+filtstr+' order by fid');
      Open;
    finally
      EnableControls;
    end;
  end;
end;


//���ݼ��򿪺��ʽ����ʾ����Ϳ��Ⱥ͸�ʽ
procedure Tfmain.dsetAfterOpen(DataSet: TDataSet);
begin
  FormatDataSetView(DataSet);
end;

procedure Tfmain.dsetAfterScroll(DataSet: TDataSet);
begin
  stat1.Panels[1].Text := Format('%d/%d',[DataSet.RecNo,DataSet.RecordCount]);
end;


function ADOTableExists(conn:TADOConnection; Table:string):Boolean;
var
  tables:TStringList;
begin
  tables := TStringList.Create;
  try
    conn.GetTableNames(tables);
    Result := tables.IndexOf(Table)>=0;
  finally
    tables.Free;
  end;
end;

//��������
procedure Tfmain.FormCreate(Sender: TObject);
var
	i : integer;
	cstr : string;
  APPDB : string;
	csdbs : OleVariant;
	Vers: TAppVerInfo;
begin
  ReportMemoryLeaksOnShutdown := Boolean(DebugHook);
  DoubleBuffered := True;
  for i := 0 to ControlCount - 1 do
    if Controls[i] is TWinControl then
      TWinControl(Controls[i]).DoubleBuffered := True;

  Hint := Application.Title;
	Vers := TAppVerInfo.Create(Self);
	try
		Caption := Hint + Vers.ProductVersion;
	finally
		Vers.Free;
	end;

	APPDB := ChangeFileExt(Application.ExeName,'.MDB');
	//����Access���ݿ⣬�粻���ڣ�����֮
	conEDB.Connected := False;
  cstr := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+APPDB;

  //������ݿ��ļ������ڣ��򴴽������ݿ�
  if not FileExists(APPDB) then begin
		csdbs := CreateOleObject('ADOX.Catalog');
		csdbs.Create(cstr);
    csdbs := Unassigned;
  end;

  conEDB.Provider := 'Microsoft.Jet.OLEDB.4.0';
	conEDB.ConnectionString := cstr;
	conEDB.Connected := True;

  //�����ݿ�:�������б���
  if not ADOTableExists(conEDB,'RecData') then with CmdADO do begin
  	CommandText := 'Create Table RecData ('	;		//��¼���ݱ�
		for i := Low(CDSFIELDS) to High(CDSFIELDS) do begin
      case CDSFIELDS[i].ftype of
        ftWideString,ftString: cstr := Format(' %s varchar(%d) ',[CDSFIELDS[i].eTitle,CDSFIELDS[i].fsize]);
        ftInteger: cstr := Format(' %s integer ',[CDSFIELDS[i].eTitle]);
        ftFloat: cstr := Format(' %s double ',[CDSFIELDS[i].eTitle]);
        ftDateTime: cstr := Format(' %s datetime ',[CDSFIELDS[i].eTitle]);
        ftAutoInc: cstr := Format(' %s autoincrement ',[CDSFIELDS[i].eTitle]);
        else
          Continue;
      end;
      if i < High(CDSFIELDS) then cstr := cstr + ',';
     CommandText := CommandText + cstr;
    end;
    CommandText := CommandText + ')';
    Execute;

   	CommandText := 'Create Index RecData_ID on RecData (fID) with Primary';
    Execute;
   	CommandText := 'Create UNIQUE Index RecData_URL on RecData (fUrl)'; 	//��������:Ψһ��
    Execute;
  end;

  if not ADOTableExists(conEDB,'SaveCfg') then with CmdADO do begin
  	CommandText := 'Create Table SaveCfg ('			//������ñ�
                    + 'fName varchar(32) not null, '
                    + 'fFormat Integer not null default 0, '
                    + 'fEncode Integer not null default 0, '
                    + 'fGrpTag bit default 0, '
                    + 'fOneline bit default 0, '
                    + 'fSplit bit default 0, '
                    + 'fDir varchar(128) '
                    + ')';
    Execute;

   	CommandText := 'Create Index SaveCfg_Cfg on SaveCfg (fName) with Primary';
    Execute;
   	CommandText := 'Insert into SaveCfg Values '
      + '('#39'�ٴ�/DIYPӰ������ӿ�'#39',0,1,True,False,False,NULL)';
    Execute;
   	CommandText := 'Insert into SaveCfg Values '
      + '('#39'���񲥷���PC��'#39',0,1,False,True,False,'#39'playlist\TV'#39')';
    Execute;
   	CommandText := 'Insert into SaveCfg Values '
      + '('#39'�󲿷ֲ������Զ���'#39',0,1,False,False,True,'#39'FTV'#39')';
    Execute;
  end;

  QryDatV.Open;

  {	with dset do begin
		//�������ֶ�: ����Ԥ��������CDSFIELDS
		for i := Low(CDSFIELDS) to High(CDSFIELDS) do
      FieldDefs.Add(CDSFIELDS[i].eTitle,CDSFIELDS[i].ftype,CDSFIELDS[i].fsize);

    IndexDefs.Add('2','Url',[ixUnique]);			//��������:��ַ����Ψһ����
		CreateDataSet;			        //�������ݱ�

    //������ݼ�
    if FileExists('.\LastSave.cds') then try
      LoadFromFile('.\LastSave.cds');
    except
      ;
    end;
		Open;
    LogChanges := False;
  end;
}

end;

//�Զ������ڴ���ʱ�������ݣ��ر���ʱ��
procedure Tfmain.FormDestroy(Sender: TObject);
begin
  if oneplay.fPlayer>0 then
    TerminateProcess(oneplay.fPlayer, 0);   //threads[i]��Ľ���THandle=hProcess
  btnCheck.Down := False;                   //����м���߳������У�ȫ��ֹͣ
  btnCheck.Click;
	conEDB.Connected := False;
end;

procedure Tfmain.FormResize(Sender: TObject);
begin
  stat1.Panels[0].Width := Width - 100;  //�Ҷ��룬�ռ�����Panels[0]
end;

end.