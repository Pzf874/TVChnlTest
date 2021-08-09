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
    Text:= Utf8Decode(Text);  //UTF-8�ı��EE BB BF ���ᶪ������ת����3F(?)
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

//�����ļ�ASCII��UTF-8��ʽת������grpList�����б�����(���������)
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
  GetAllDataSet(DataSet);//��ȡ����������ʾ��ȫ�������˺󣩵�����

  with pgc1 do while (PageCount>0) do //ɾ����������
    Pages[0].Free;
  Lines := nil;                        //Ŀǰ��Ŀ��ָ��

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
  //filename.m3u8 or filename.txt or filename��as dir��

  try
    for i := 0 to grpList.Count do begin       //�������з���
      if i=grpList.Count then begin
        CurGrp := '';
        grp := '[�޷���]';
      end
      else begin
        CurGrp := lstgrp.Items[i];
        grp := CurGrp;
      end;
      if isText and not isSplit and isSufTag then grp := grp + ',#genre#';
      if isSplit and isNumidx then grp := IntToStr(900+i)+'#'+grp;//�����ļ��������:900��ʼ
      
      if isSplit then begin
        if Assigned(Lines) then Lines.EndUpdate;
        Lines := nil;                     //�´����´�����TabSheet��Memo
        if (not isText) then
          subtab := '\'+grp+'.m3u8'
        else
          subtab := '\'+grp+'.txt'
      end;

      with DataSet do begin               //����һ��ָ������
        Filtered := False;
        Filtered := True;                 //���˷���
        if Recordcount=0 then Continue;   //������������

        if not Assigned(Lines) then begin  //����һ��TTabSheet->pgc1, һ��Memo->TTabSheet��Lines->Memo.Lines
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
          if not isText then Lines.Add('#EXTM3U');   //M3U��ʽ����
        end;

        if isText and not isSplit then
          Lines.Add(grp);   //���������

        repeat //��������Ƶ����������һ��Ϊ׼
          First;
          if Recordcount=0 then break;   //����������Ƶ��������
          chn := FieldByName('fChannel').AsString;
          url := '';
          while not EOF do begin
            if (chn = FieldByName('fChannel').AsString) then begin  //ƥ�䣬���
              epg := FieldByName('fRemark').AsString;
              if isOneline then begin    //���ţ�ȫ��ƥ��Ƶ��ɨ���һ�����
                if (url<>'') then url := url + '#' + FieldByName('fUrl').AsString
                else url := FieldByName('fUrl').AsString;
              end
              else begin            //ֱ�����
                url := FieldByName('fUrl').AsString;
                ExportOneChnl(isText,grp,chn,url,epg,Lines);
                url := '';          //�������٣������onlineģʽʱ���۵�url����
              end;
              Delete;   //ƥ������ֱ��ɾ��
            end
            else        //��ƥ�䣬��һ��
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

//���º�ˢ�·������е�ĳЩĬ���ֶΣ�Ĭ��ֵ��ˢ�²��ض�������
procedure TfExTrans.qrycfgAfterPost(DataSet: TDataSet);
begin
  DataSet.Refresh;
end;


procedure TfExTrans.tmrReGenTimer(Sender: TObject);
begin
  tmrReGen.Enabled := False;
  ProcFile(cds1,lstGrp.Items); //����һ�����
end;

//���浱ǰ��ʾ����
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
  //��ָ���ļ�(��)���ڵ��ļ��в�ѡ�и��ļ�(��)
  ShellExecute(Handle,'Open','Explorer.exe',PChar('/select, '+afilename), nil, SW_SHOWNORMAL);
end;

procedure TfExTrans.cds1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
//  if CurGrp<>'' then
    Accept := Accept and SameText(DataSet.FieldByName('fGroup').AsString,CurGrp);
//  if CurChn<>'' then
//    Accept := Accept and SameText(DataSet.FieldByName('fChannel').AsString,CurChn);
end;

//������÷����䶯����Ŀ�䶯���������
procedure TfExTrans.dbrgrpfFormatChange(Sender: TObject);
begin
  if (dbrgrpfFormat.ItemIndex<>0) and (Sender=dbchk1Tag) then Exit;    //M3U��ʽʱ�����Ժ�׺�仯
  if dbchk1Split.Checked and (Sender=dbchk1Tag) then Exit;             //�ָ�ʱ�����Ժ�׺�仯
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

//������ʾ����������ñ�ˢ��һ�����
procedure TfExTrans.FormShow(Sender: TObject);
begin
  qrycfg.Open;    //����������б�ʼ�ն�λ�ڵ�һ�У�
  tmrReGen.Enabled := True;
end;

//��ȡ����������ʾ��ȫ�������˺󣩵�����
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
//���Թ��˹���
  if lstGrp.ItemIndex=-1 then CurGrp := ''
  else  CurGrp := lstgrp.Items[lstGrp.ItemIndex];
  cds1.Filtered := False;
  cds1.Filtered := True;
end;

//Items�϶����
procedure TfExTrans.lstGrpDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  i,j:integer;
  itm:string;
begin
  with lstGrp do begin
    i := ItemIndex;                  //��ǰѡ�е�Item
    j := lstGrp.ItemAtPos(point(x,y),true); //��ǰ���λ�õ�Item:-1������Count
    if (i=-1) or (i=j) then Exit;
    itm := Items[i];
    Items.Delete(i);
    Items.Insert(j,itm);             //Item:-1ʱ��׷�������
  end;
  tmrReGen.Enabled := True;
end;

//Items�϶���ʼ
procedure TfExTrans.lstGrpDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept:= source = lstGrp;
end;

end.
