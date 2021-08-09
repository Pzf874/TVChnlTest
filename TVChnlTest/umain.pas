unit umain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, Grids, DBGrids, DB, ADODB,
  comobj, utools, uPlayer, Spin;

type
  TcsResult = record        //检查结果结构
  	fth:Cardinal;            //线程号
    fid:Integer;            //序号
    fResult:Integer;        //结果0..3
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

//获取当前curid序号后面一个未被检查线程占据的频道源
//占据与否以fThread的数值来判断:>0已在检查，否则未在检查：标记为检查线程号index+1,返回fid和furl内容，成功返回
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
    rowDelta := THackDBGrid(DBGrd1).Row-1;//当前表格第几行：TopRow=1(有Title)
    rowCur := THackDBGrid(DBGrd1).VisibleRowCount;//当前表格中间行
    if rowDelta<(rowCur div 2) then rowDelta := rowDelta-rowCur+1;
    rowCur := RecNo;

    try
      First;
      Locate('fid',Curid,[]);  //到达当前指定位置，无论成功或失败
      while not EOF do begin
        if FieldByName('fThread').AsInteger<1 then begin //找到未标记的下一个
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
  GetSubStr(str1,'//');           //切掉"//“之前
  Result := GetSubStr(str1,'/');  //获得”/"之前
end;

//记忆url的IP地址，检查结果，检查线程号
procedure Tfmain.AddNGTOips(Url:string; Res,Thi:Integer);
begin
  Url := GetIpAddr(Url);
  if Url='' then Exit;
  if NGTOips.IndexOfName(Url)>=0 then Exit;//IP已经存在
  NGTOips.Add(Format('%s=%d,%d',[Url,Res,Thi]));
end;

//检查furl是否在记忆的IP列表中，是则返回记忆的结果和检查的线程号
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

//标记检查结果
procedure Tfmain.SetCheckedSource(const cs: TcsResult);
var
   rowDelta: Integer;
   rowCur: integer;
begin
  with dsrc.DataSet do if Active then begin
    if RecordCount=0 then Exit;
    DisableControls;
    rowDelta := THackDBGrid(DBGrd1).Row-1;//当前表格第几行：TopRow=1(有Title)
    rowCur := THackDBGrid(DBGrd1).VisibleRowCount;//当前表格中间行
    if rowDelta<(rowCur div 2) then rowDelta := rowDelta-rowCur+1;
    rowCur := RecNo;
    try
      First;
      if not Locate('fid',cs.fid,[]) then Exit;  //到达当前指定位置
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

//开启fid后面下一个数据的检查线程，线程实例存入index位置
procedure Tfmain.StartNextThread(index,fid:Integer);
var
  i:Integer;
  furl:string;
  cs: TcsResult;
begin
  if (not btnCheck.Down) or (not GetNextSource(index,fid,furl)) or (fid=0) or (furl='') then begin
    threads[index].Free; threads[index] := nil;
    for i := Low(threads) to High(threads) do //检查一下所有进行中的线程是否全关闭
      if Assigned(threads[i]) then Exit;
    btnCheck.Down := False;
    btnCheck.Click;         //还原按钮状态和标识
    btnCheck.Enabled := True;
    Exit;
  end;
  //检查furl是否已经被标记为NG，TO
  if cbRemeNGTO.Checked and isCheckedNGTO(furl,cs.fResult,cs.fth) then begin
    cs.fid := fid;
    SetCheckedSource(cs);     //fid,fth,fResult有意义，其他无用
    StartNextThread(index,fid);   //递归
    Exit;
  end;

  with Tfplayer(threads[index]) do begin     //配置输入参数
    findex := index;
    fIdnum := fid;
    fTimeOut := neTimeOut.Value*1000; //超时ms
    OnCompleted := aThreadTerminated;
    Execute(Self,False);              //初始化
    Media := furl;                    //指定播放内容
  end;
end;

//双击一行频道，打开窗口播放它，实际看看能不能连接
procedure Tfmain.dbgrd1DblClick(Sender: TObject);
var
  fid:Integer;
  furl:String;
begin
  with dsrc.DataSet do if Active then begin
    fid := FieldByName('fId').AsInteger;
    furl := Trim(FieldByName('fUrl').AsString);
    if furl='' then Exit;
    with Tfplayer.Create(Self) do begin     //配置输入参数
      findex := High(threads)+1; //不属于自动检查的
      fIdnum := fid;
      OnCompleted := aThreadTerminated;
      Execute(Self,True);              //初始化
      Media := furl;                    //指定播放内容
    end;
  end;
end;

//检查线程结束时回调函数
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

  //超出预先开好的范围:双击播放的可视窗口，结束
  if (cs.fth > High(threads)) then begin
    Sender.Free;                         //摧毁
    Exit;
  end;
  Application.ProcessMessages;
  StartNextThread(cs.fth,cs.fid);
end;

//开始或停止检查
procedure Tfmain.btnCheckClick(Sender: TObject);
var
  i:Integer;
  fid:Integer;
begin
  if btnCheck.Down then begin
    neThread.Enabled := False;
    neTimeOut.Enabled := False;
    btnCheck.Caption := '停止检查';
    with cmdADO do begin                      //删除所有已有的检查线程信息
      CommandText := 'Update RecData set fThread=NULL, fVWidth=NULL, fVHeight=NULL, fConnect=NULL, fSpeed=NULL ';
      CommandText := CommandText + GetWherePart(qryDatV.SQL.Text);
      Execute;
    end;
    TADOQuery(dsrc.DataSet).Requery;          //隐含了回到数据集首行
    NGTOips.Clear;
    SetLength(threads,neThread.Value);
    fid := 0;
    for i := Low(threads) to High(threads) do begin //开启指定数量的线程
      threads[i] := Tfplayer.Create(Self);
      StartNextThread(i,fid);
    end;
  end
  else begin
    neThread.Enabled := True;
    neTimeOut.Enabled := True;
    btnCheck.Caption := '开始检查';
    btnCheck.Enabled := False;
    for i := Low(threads) to High(threads) do //关闭所有进行中的线程
    begin
      if Assigned(threads[i]) then
        threads[i].Close;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//清空当前所有的频道数据
procedure Tfmain.btnClearClick(Sender: TObject);
begin
  if Assigned(Sender) then
    if TimMessageDlg(5,'确定清除全体(当前显示的)频道信息吗？',mtConfirmation,
    [mbOK, mbCancel],mbCancel)<>mrOk then
      Exit;

  with cmdADO do begin                      //删除所有已有的检查线程信息
    CommandText := 'Delete from RecData ';
    CommandText := CommandText + GetWherePart(qryDatV.SQL.Text);
    Execute;
  end;
  TADOQuery(dsrc.DataSet).Requery;
end;

//导出频道数据到其他文件(TXT，M3U)，仅导出当前过滤条件显示的内容行。
procedure Tfmain.btnExportClick(Sender: TObject);
begin
  with fExTrans do try
    FillListWithColumn(conEDB,'RecData','fGroup','','min(fid)',lstGrp.Items); //准备全体分类项目（按fid顺序）
    dtsp.DataSet := dsrc.DataSet;     //复制当前显示的数据集（经过各种过滤条件后）
    ShowModal;
  finally
    Close;
  end;
end;

//导出频道数据到EXCEL或WPS/ET的新工作簿的SHEET1页面（无需预先打开软件），导出范围为当前显示所有行(受过滤影响)。
procedure Tfmain.btnExportXLSClick(Sender: TObject);
var
  filtstr:String;
begin
  filtstr := '';
  filtstr := filtstr + '分组：' + cbbGrp.Text;
  filtstr := filtstr + '频道：' + cbbChn.Text;
  filtstr := filtstr + '链接：' + edtUrl.Text;
  if rgChecked.ItemIndex>=0 then
    filtstr := filtstr + '状态：' + rgChecked.Items[rgChecked.ItemIndex] ;

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

//导入频道数据从其他文件(TXT，M3U)，合并到当前数据中，忽略掉重复地址连接。
procedure Tfmain.btnImportClick(Sender: TObject);
begin
  with fImTrans do try
    aDataSet := dsrc.DataSet;
    ShowModal;
  finally
    Close;
  end;
end;

//导入频道数据从EXCEL或WPS/ET当前页面（请预先打开软件），合并到当前数据中，忽略掉重复地址连接。
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


//清空左侧输入的分类、频道、链接内容
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

  //TCombobox的Text被程序改变不会自动触发OnChange,TEdit的被程序改变会自动触发。
  if ((grp<>'') or (chn<>'') or (idx<>-1)) and (url='') then
    cbbChn.OnChange(Sender);  //grp或chn变了而url没变，手动触发一次OnChange
end;


//频道下拉按钮：搜当前分类过滤下的频道的独立名称
procedure Tfmain.cbbChnDropDown(Sender: TObject);
var
  grp,filtstr:String;
begin
  grp := Trim(cbbGrp.Text);
  if grp<>'' then filtstr := 'where fGroup like '+ QuotedStr('%'+grp+'%') else filtstr := '';
  FillListWithColumn(conEDB,'RecData','fChannel',filtstr,'min(fid)',cbbChn.Items);
  lblchn.Caption := Format('频道(%d):',[cbbChn.Items.Count]);
end;

//分类下拉按钮：搜所有分类的独立名称
procedure Tfmain.cbbGrpDropDown(Sender: TObject);
begin
  FillListWithColumn(conEDB,'RecData','fGroup','','min(fid)',cbbGrp.Items);
  lblgrp.Caption := Format('分类(%d):',[cbbGrp.Items.Count]);
end;

//分类，频道，地址，输入框内容有变化，过滤显示内容
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


//数据集打开后格式化显示标题和宽度和格式
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

//创建表格
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
	//连接Access数据库，如不存在，创建之
	conEDB.Connected := False;
  cstr := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+APPDB;

  //如果数据库文件不存在，则创建新数据库
  if not FileExists(APPDB) then begin
		csdbs := CreateOleObject('ADOX.Catalog');
		csdbs.Create(cstr);
    csdbs := Unassigned;
  end;

  conEDB.Provider := 'Microsoft.Jet.OLEDB.4.0';
	conEDB.ConnectionString := cstr;
	conEDB.Connected := True;

  //新数据库:创建所有表格
  if not ADOTableExists(conEDB,'RecData') then with CmdADO do begin
  	CommandText := 'Create Table RecData ('	;		//记录数据表
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
   	CommandText := 'Create UNIQUE Index RecData_URL on RecData (fUrl)'; 	//常用索引:唯一的
    Execute;
  end;

  if not ADOTableExists(conEDB,'SaveCfg') then with CmdADO do begin
  	CommandText := 'Create Table SaveCfg ('			//输出配置表
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
      + '('#39'百川/DIYP影音网络接口'#39',0,1,True,False,False,NULL)';
    Execute;
   	CommandText := 'Insert into SaveCfg Values '
      + '('#39'黑鸟播放器PC端'#39',0,1,False,True,False,'#39'playlist\TV'#39')';
    Execute;
   	CommandText := 'Insert into SaveCfg Values '
      + '('#39'大部分播放器自定义'#39',0,1,False,False,True,'#39'FTV'#39')';
    Execute;
  end;

  QryDatV.Open;

  {	with dset do begin
		//创建的字段: 按照预定义数组CDSFIELDS
		for i := Low(CDSFIELDS) to High(CDSFIELDS) do
      FieldDefs.Add(CDSFIELDS[i].eTitle,CDSFIELDS[i].ftype,CDSFIELDS[i].fsize);

    IndexDefs.Add('2','Url',[ixUnique]);			//创建索引:地址链接唯一索引
		CreateDataSet;			        //创建数据表

    //填充数据集
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

//自动保存内存临时表格内容，关闭临时表
procedure Tfmain.FormDestroy(Sender: TObject);
begin
  btnCheck.Down := False; //如果有检查线程运行中，全体停止
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
  stat1.Panels[0].Width := Width - 100;  //右对齐，空间留给Panels[0]
end;

end.
