unit uExport;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,  DB, DBCtrls, Mask, ADODB, Grids,
  DBGrids, DBClient, Provider, ComCtrls;

type
  TfExTrans = class(TForm)
    pnl1: TPanel;
    btnSave: TBitBtn;
    dbrgrpfEncode: TDBRadioGroup;
    dbrgrpfFormat: TDBRadioGroup;
    dbchk1Tag: TDBCheckBox;
    dbchk1Combi: TDBCheckBox;
    dbchk1Split: TDBCheckBox;
    dbedt1Dir: TDBEdit;
    lbl1: TLabel;
    qrycfg: TADOQuery;
    ds1: TDataSource;
    dbgrd1: TDBGrid;
    lbl2: TLabel;
    dtsp: TDataSetProvider;
    cds1: TClientDataSet;
    tmrReGen: TTimer;
    pgc1: TPageControl;
    pnl2: TPanel;
    pnl3: TPanel;
    lstGrp: TListBox;
    spl1: TSplitter;
    procedure btnSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure qrycfgAfterPost(DataSet: TDataSet);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstgrpClick(Sender: TObject);
    procedure cds1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure dbrgrpfFormatChange(Sender: TObject);
    procedure tmrReGenTimer(Sender: TObject);
    procedure lstGrpDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure lstGrpDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
  private
    { Private declarations }
    CurGrp:string;
    procedure ProcFile(DataSet: TDataSet; grpList:TStrings);
    procedure GetAllDataSet(DataSet: TDataSet);
  public
    { Public declarations }
  end;

var
  fExTrans: TfExTrans;

implementation

{$R *.dfm}
uses
  utools, shellapi, umain, MidasLib;

function DecordUtf8(Text: String): String;
begin
    Text:= Utf8Decode(Text);  //UTF-8的标记EE BB BF 不会丢弃而是转换成3F(?)
  Result := Text;
end;

procedure ExportOneChnl(const isText:Boolean; const grp,chn,url,epg:string; Lines:TStrings);
var
  mepg,mgrp:string;
begin
  if isText then begin
    if epg<>'' then mepg := ','+epg;
    Lines.Add(chn+','+url+mepg);
  end
  else begin
    if epg<>'' then mepg := ' tvg-name="'+epg+'"';
    if grp<>'' then mgrp := ' group-title="'+grp+'"';
    Lines.Add('#EXTINF:-1'+mepg+mgrp+','+chn);
//    if epg<>'' then mepg := ','+epg;
//    Lines.Add(url+mepg);
    Lines.Add(url);
  end;
end;

//处理文件ASCII或UTF-8格式转换，按grpList分组列表排序(或独立分组)
procedure TfExTrans.ProcFile(DataSet: TDataSet; grpList:TStrings);
var
  isText,isSufTag,isSplit,isOneline,isNumidx:Boolean;
  i: integer;
  grp,chn,url,epg,tabname,subtab:string;
  Lines:TStrings;
  sheet:TTabSheet;
  mmo:TMemo;
begin
  Screen.Cursor := crHourGlass;
  DataSet.DisableControls;
  grpList.BeginUpdate;
  GetAllDataSet(DataSet);//获取主界面上显示的全部（过滤后）的数据

  with pgc1 do while (PageCount>0) do //删除已有内容
    Pages[0].Free;
  Lines := nil;                        //目前无目标指向

  isText := dbrgrpfFormat.ItemIndex=0;
  isSufTag := dbchk1Tag.Checked;
  isOneline := dbchk1Combi.Checked;
  isSplit := dbchk1Split.Checked;
	tabname := dbedt1Dir.Text;
  if Pos('#',tabname)=1 then begin
    isNumidx := True;
    subtab := GetSubStr(tabname,'#'); 
  end
  else
    isNumidx := False;

  if tabname='' then tabname := 'TV';

  subtab := '';

  if not isSplit then begin
    if (not isText) then
      tabname := ChangeFileExt(tabname,'.m3u8')
    else
      tabname := ChangeFileExt(tabname,'.txt')
  end;
  //filename.m3u8 or filename.txt or filename（as dir）

  try
    for i := 0 to grpList.Count do begin       //处理所有分类
      if i=grpList.Count then begin
        CurGrp := '';
        grp := '[无分类]';
      end
      else begin
        CurGrp := lstgrp.Items[i];
        grp := CurGrp;
      end;
      if isText and not isSplit and isSufTag then grp := grp + ',#genre#';
      if isSplit and isNumidx then grp := IntToStr(900+i)+'#'+grp;//分类文件名排序号:900开始
      
      if isSplit then begin
        if Assigned(Lines) then Lines.EndUpdate;
        Lines := nil;                     //下次重新创建新TabSheet和Memo
        if (not isText) then
          subtab := '\'+grp+'.m3u8'
        else
          subtab := '\'+grp+'.txt'
      end;

      with DataSet do begin               //处理一个指定分类
        Filtered := False;
        Filtered := True;                 //过滤分类
        if Recordcount=0 then Continue;   //本分类无内容

        if not Assigned(Lines) then begin  //创建一个TTabSheet->pgc1, 一个Memo->TTabSheet，Lines->Memo.Lines
          sheet:=Ttabsheet.Create(pgc1);
          with sheet do begin
//            name:='tabsheet1';
            caption:=tabname+subtab;
            pagecontrol:=pgc1;
            Parent := pgc1;
            Visible:=true;
          end;
          mmo:=TMemo.Create(sheet);
          with mmo do begin
//            name:='tabsheet1';
            ScrollBars := ssBoth;
            WordWrap := False;
            Align := alClient;
            Parent := sheet;
            Visible:=true;
          end;
          Lines := mmo.Lines;
          Lines.BeginUpdate;
          if not isText then Lines.Add('#EXTM3U');   //M3U格式首行
        end;

        if isText and not isSplit then
          Lines.Add(grp);   //输出分类名

        repeat //过滤所有频道名：按第一个为准
          First;
          if Recordcount=0 then break;   //本分类所有频道输出完成
          chn := FieldByName('fChannel').AsString;
          url := '';
          while not EOF do begin
            if (chn = FieldByName('fChannel').AsString) then begin  //匹配，输出
              epg := FieldByName('fRemark').AsString;
              if isOneline then begin    //存着，全体匹配频道扫完后一行输出
                if (url<>'') then url := url + '#' + FieldByName('fUrl').AsString
                else url := FieldByName('fUrl').AsString;
              end
              else begin            //直接输出
                url := FieldByName('fUrl').AsString;
                ExportOneChnl(isText,grp,chn,url,epg,Lines);
                url := '';          //用完销毁，避免和online模式时积累的url混淆
              end;
              Delete;   //匹配用完直接删除
            end
            else        //不匹配，下一行
              Next;
          end;
          if isOneline and (url<>'') then
            ExportOneChnl(isText,grp,chn,url,epg,Lines);
         until False;
      end;
    end;
  finally
    if Assigned(Lines) then Lines.EndUpdate;
    pgc1.ActivePageIndex := pgc1.PageCount-1;
    grpList.EndUpdate;
    DataSet.EnableControls;
    Screen.Cursor := crDefault;
  end;
end;

//更新后刷新方案表中的某些默认字段（默认值不刷新不回读过来）
procedure TfExTrans.qrycfgAfterPost(DataSet: TDataSet);
begin
  DataSet.Refresh;
end;


procedure TfExTrans.tmrReGenTimer(Sender: TObject);
begin
  tmrReGen.Enabled := False;
  ProcFile(cds1,lstGrp.Items); //处理一次输出
end;

//保存当前显示内容
procedure TfExTrans.btnSaveClick(Sender: TObject);
var
	afilename:String;
  afile: File;
  aText:AnsiString;
  wText:WideString;
  i:integer;
begin
  with pgc1 do for i := 0 to PageCount - 1 do begin
    aText := TMemo(Pages[i].Controls[0]).Lines.Text;
    afilename := Pages[i].Caption;
    afilename := ExtractFilePath(Application.ExeName) + afilename;
    ForceDirectories(ExtractFileDir(afilename));
    AssignFile(afile,afilename);
    Rewrite(afile,1);
    case dbrgrpfEncode.ItemIndex of
      2: begin
        wText := aText;
        BlockWrite(afile,(wText[1]),Length(wText)*SizeOf(WideChar));
      end;
      1: begin
        aText := UTF8Encode(aText);
        BlockWrite(afile,(aText[1]),Length(aText));
      end;
      else
        BlockWrite(afile,(aText[1]),Length(aText));
    end;
    CloseFile(afile);
  end;
  //打开指定文件(夹)所在的文件夹并选中该文件(夹)
  ShellExecute(Handle,'Open','Explorer.exe',PChar('/select, '+afilename), nil, SW_SHOWNORMAL);
end;

procedure TfExTrans.cds1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
//  if CurGrp<>'' then
    Accept := Accept and SameText(DataSet.FieldByName('fGroup').AsString,CurGrp);
//  if CurChn<>'' then
//    Accept := Accept and SameText(DataSet.FieldByName('fChannel').AsString,CurChn);
end;

//输出配置方案变动或项目变动，重新输出
procedure TfExTrans.dbrgrpfFormatChange(Sender: TObject);
begin
  if (dbrgrpfFormat.ItemIndex<>0) and (Sender=dbchk1Tag) then Exit;    //M3U格式时，忽略后缀变化
  if dbchk1Split.Checked and (Sender=dbchk1Tag) then Exit;             //分割时，忽略后缀变化
  tmrReGen.Enabled := True;
end;

procedure TfExTrans.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if qrycfg.State in [dsEdit,  dsInsert] then try
    qrycfg.Post;
  except
    qrycfg.Cancel;
  end;
end;

//窗口显示，打开输出配置表，刷新一次输出
procedure TfExTrans.FormShow(Sender: TObject);
begin
  qrycfg.Open;    //打开输出方案列表（始终定位在第一行）
  tmrReGen.Enabled := True;
end;

//获取主界面上显示的全部（过滤后）的数据
procedure TfExTrans.GetAllDataSet(DataSet: TDataSet);
begin
  dtsp.DataSet.DisableControls;
  try
    cds1.Data := dtsp.Data;
  finally
    dtsp.DataSet.EnableControls;
  end;
end;


procedure TfExTrans.lstgrpClick(Sender: TObject);
begin
//测试过滤过程
  if lstGrp.ItemIndex=-1 then CurGrp := ''
  else  CurGrp := lstgrp.Items[lstGrp.ItemIndex];
  cds1.Filtered := False;
  cds1.Filtered := True;
end;

//Items拖动完成
procedure TfExTrans.lstGrpDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  i,j:integer;
  itm:string;
begin
  with lstGrp do begin
    i := ItemIndex;                  //当前选中的Item
    j := lstGrp.ItemAtPos(point(x,y),true); //当前鼠标位置的Item:-1代表超出Count
    if (i=-1) or (i=j) then Exit;
    itm := Items[i];
    Items.Delete(i);
    Items.Insert(j,itm);             //Item:-1时会追加在最后
  end;
  tmrReGen.Enabled := True;
end;

//Items拖动开始
procedure TfExTrans.lstGrpDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept:= source = lstGrp;
end;

end.
