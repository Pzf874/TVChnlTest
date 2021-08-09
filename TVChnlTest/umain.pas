unit umain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, Grids, DBGrids, DB, ADODB,
  comobj, utools, uPlayer, Spin;

type
  TcsResult = record        //������ṹ
  	fth:Cardinal;            //�̺߳�
    fid:Integer;            //���
    fResult:Integer;        //���0..3
    fWidth:integer;
    fHeight:integer;
    fConnectms:integer;
    fSpeed:integer;
  end;

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
    cbRemeNGTO: TCheckBox;
    cbFollow: TCheckBox;
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
  private
    { Private declarations }
    NGTOips:TStringList;
    threads: array of TfPlayer;
    procedure aThreadTerminated(Sender:TObject);
    function GetNextSource(const index:Integer; var Curid:Integer; var url:string):Boolean;
    procedure SetCheckedSource(const cs: TcsResult);
    procedure StartNextThread(index,fid:Integer);
    procedure AddNGTOips(Url:string; Res,Thi:Integer);
    function isCheckedNGTO(furl:string; var res:Integer; var Thi:Cardinal):Boolean;
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

function Tfmain.GetNextSource(const index:Integer; var Curid:Integer; var url:string):Boolean;
var
   rowDelta: Integer;
   rowCur: integer;
begin
  Result := False;
  with dsrc.DataSet do if Active then begin
    if RecordCount=0 then Exit;
    DisableControls;
    rowDelta := THackDBGrid(DBGrd1).Row-1;//��ǰ���ڼ��У�TopRow=1(��Title)
    rowCur := THackDBGrid(DBGrd1).VisibleRowCount;//��ǰ����м���
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

function GetIpAddr(const Url:string):string;
var
  str1:string;
begin
  str1 := Url;
  GetSubStr(str1,'//');           //�е�"//��֮ǰ
  Result := GetSubStr(str1,'/');  //��á�/"֮ǰ
end;

//����url��IP��ַ�������������̺߳�
procedure Tfmain.AddNGTOips(Url:string; Res,Thi:Integer);
begin
  Url := GetIpAddr(Url);
  if Url='' then Exit;
  if NGTOips.IndexOfName(Url)>=0 then Exit;//IP�Ѿ�����
  NGTOips.Add(Format('%s=%d,%d',[Url,Res,Thi]));
end;

//���furl�Ƿ��ڼ����IP�б��У����򷵻ؼ���Ľ���ͼ����̺߳�
function Tfmain.isCheckedNGTO(furl:string; var res:Integer; var Thi:Cardinal):Boolean;
var
  i:Integer;
  str1,str2:string;
begin
  Result := False;
  furl := GetIpAddr(furl);
  if furl='' then Exit;
  i := NGTOips.IndexOfName(furl);
  if i<0 then Exit;
  str1 := NGTOips[i];
  GetSubStr(str1,'=');
  str2 := GetSubStr(str1,',');
  res := StrToIntDef(str2,0);
  Thi := StrToIntDef(str1,0);
  Result := res>0;
end;

//��Ǽ����
procedure Tfmain.SetCheckedSource(const cs: TcsResult);
var
   rowDelta: Integer;
   rowCur: integer;
begin
  with dsrc.DataSet do if Active then begin
    if RecordCount=0 then Exit;
    DisableControls;
    rowDelta := THackDBGrid(DBGrd1).Row-1;//��ǰ���ڼ��У�TopRow=1(��Title)
    rowCur := THackDBGrid(DBGrd1).VisibleRowCount;//��ǰ����м���
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
          if cbRemeNGTO.Checked then
            AddNGTOips(FieldByName('fUrl').AsString,cs.fResult,cs.fth);
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
  cs: TcsResult;
begin
  if (not btnCheck.Down) or (not GetNextSource(index,fid,furl)) or (fid=0) or (furl='') then begin
    threads[index].Free; threads[index] := nil;
    for i := Low(threads) to High(threads) do //���һ�����н����е��߳��Ƿ�ȫ�ر�
      if Assigned(threads[i]) then Exit;
    btnCheck.Down := False;
    btnCheck.Click;         //��ԭ��ť״̬�ͱ�ʶ
    btnCheck.Enabled := True;
    Exit;
  end;
  //���furl�Ƿ��Ѿ������ΪNG��TO
  if cbRemeNGTO.Checked and isCheckedNGTO(furl,cs.fResult,cs.fth) then begin
    cs.fid := fid;
    SetCheckedSource(cs);     //fid,fth,fResult�����壬��������
    StartNextThread(index,fid);   //�ݹ�
    Exit;
  end;

  with Tfplayer(threads[index]) do begin     //�����������
    findex := index;
    fIdnum := fid;
    fTimeOut := neTimeOut.Value*1000; //��ʱms
    OnCompleted := aThreadTerminated;
    Execute(Self,False);              //��ʼ��
    Media := furl;                    //ָ����������
  end;
end;

//˫��һ��Ƶ�����򿪴��ڲ�������ʵ�ʿ����ܲ�������
procedure Tfmain.dbgrd1DblClick(Sender: TObject);
var
  fid:Integer;
  furl:String;
begin
  with dsrc.DataSet do if Active then begin
    fid := FieldByName('fId').AsInteger;
    furl := Trim(FieldByName('fUrl').AsString);
    if furl='' then Exit;
    with Tfplayer.Create(Self) do begin     //�����������
      findex := High(threads)+1; //�������Զ�����
      fIdnum := fid;
      OnCompleted := aThreadTerminated;
      Execute(Self,True);              //��ʼ��
      Media := furl;                    //ָ����������
    end;
  end;
end;

//����߳̽���ʱ�ص�����
procedure Tfmain.aThreadTerminated(Sender:TObject);
var
  cs:TcsResult;
begin
  with Tfplayer(Sender) do begin
    cs.fth := findex;
    cs.fid := fIdnum;
    cs.fResult := VResult;
    cs.fWidth := VWidth;
    cs.fHeight := VHeight;
    cs.fConnectms := VConnectms;
    cs.fSpeed := VSpeed;
    SetCheckedSource(cs);
  end;

  //����Ԥ�ȿ��õķ�Χ:˫�����ŵĿ��Ӵ��ڣ�����
  if (cs.fth > High(threads)) then begin
    Sender.Free;                         //�ݻ�
    Exit;
  end;
  Application.ProcessMessages;
  StartNextThread(cs.fth,cs.fid);
end;

//��ʼ��ֹͣ���
procedure Tfmain.btnCheckClick(Sender: TObject);
var
  i:Integer;
  fid:Integer;
begin
  if btnCheck.Down then begin
    neThread.Enabled := False;
    neTimeOut.Enabled := False;
    btnCheck.Caption := 'ֹͣ���';
    with cmdADO do begin                      //ɾ���������еļ���߳���Ϣ
      CommandText := 'Update RecData set fThread=NULL, fVWidth=NULL, fVHeight=NULL, fConnect=NULL, fSpeed=NULL ';
      CommandText := CommandText + GetWherePart(qryDatV.SQL.Text);
      Execute;
    end;
    TADOQuery(dsrc.DataSet).Requery;          //�����˻ص����ݼ�����
    NGTOips.Clear;
    SetLength(threads,neThread.Value);
    fid := 0;
    for i := Low(threads) to High(threads) do begin //����ָ���������߳�
      threads[i] := Tfplayer.Create(Self);
      StartNextThread(i,fid);
    end;
  end
  else begin
    neThread.Enabled := True;
    neTimeOut.Enabled := True;
    btnCheck.Caption := '��ʼ���';
    btnCheck.Enabled := False;
    for i := Low(threads) to High(threads) do //�ر����н����е��߳�
    begin
      if Assigned(threads[i]) then
        threads[i].Close;
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

//����Ƶ�����ݵ�EXCEL��WPS/ET���¹�������SHEET1ҳ�棨����Ԥ�ȴ��������������ΧΪ��ǰ��ʾ������(�ܹ���Ӱ��)��
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

//����Ƶ�����ݴ�EXCEL��WPS/ET��ǰҳ�棨��Ԥ�ȴ���������ϲ�����ǰ�����У����Ե��ظ���ַ���ӡ�
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


//���ݼ��򿪺��ʽ����ʾ����Ϳ�Ⱥ͸�ʽ
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

//�������
procedure Tfmain.FormCreate(Sender: TObject);
var
	i : integer;
	cstr : string;
  APPDB : string;
	csdbs : OleVariant;
	Vers: TAppVerInfo;
begin
  ReportMemoryLeaksOnShutdown := True;//Boolean(DebugHook);

  Hint := Application.Title;
	Vers := TAppVerInfo.Create(Self);
	try
		Caption := Hint + Vers.ProductVersion;
	finally
		Vers.Free;
	end;
  NGTOips := TStringList.Create;
  NGTOips.Duplicates := dupIgnore;
  NGTOips.CaseSensitive := False;
  NGTOips.Sorted := True;

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

  //�����ݿ�:�������б��
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

//�Զ������ڴ���ʱ������ݣ��ر���ʱ��
procedure Tfmain.FormDestroy(Sender: TObject);
begin
  btnCheck.Down := False; //����м���߳������У�ȫ��ֹͣ
  btnCheck.Click;
{	with dset do begin
    SaveToFile('.\LastSave.cds');
    Close;
  end;
}
	conEDB.Connected := False;
  NGTOips.Free;
end;

procedure Tfmain.FormResize(Sender: TObject);
begin
  stat1.Panels[0].Width := Width - 100;  //�Ҷ��룬�ռ�����Panels[0]
end;

end.
