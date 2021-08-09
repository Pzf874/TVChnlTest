unit uImport;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,  DB;

type
  TfImTrans = class(TForm)
    mmo1: TMemo;
    pnl1: TPanel;
    pnl2: TPanel;
    btnOpen: TBitBtn;
    btnInput: TBitBtn;
    mmoDis: TMemo;
    procedure btnOpenClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnInputClick(Sender: TObject);
    procedure pnl1DblClick(Sender: TObject);
  private
    { Private declarations }
		procedure GetFile(var msg: Tmessage); message wm_dropfiles; //拖入文件时收到的消息
    procedure ProcFile(Filename: string; List:TStrings);
  public
    { Public declarations }
    aDataSet:TDataSet;
  end;

var
  fImTrans: TfImTrans;

implementation

{$R *.dfm}
uses
  utools, uTimMsgDlg, shellapi;

function IsUTF8(const pBuffer:PChar; size:Integer):Boolean;
var
  pstart, pend: PChar;
begin
  pstart := pBuffer;
  pend := pBuffer + size;
  Result := True;
  while (pstart < pend) do begin
    if (Byte(pstart^) < $80) then // (10000000): 值小于0x80的为ASCII字符
    begin
      pstart := pstart+1;
    end
    else if (Byte(pstart^) < $C0) then // (11000000): 值介于0x80与0xC0之间的为无效UTF-8字符
    begin
      Result := false;
      break;
    end
    else if (Byte(pstart^) < $E0) then // (11100000): 此范围内为2字节UTF-8字符
    begin
      if (pstart >= pend - 1) then
        break;
      if ((Byte(pstart[1]) and ($C0)) <> $80) then
      begin
        Result := false;
        break;
      end;
  
      pstart := pstart+2;
    end
    else if (Byte(pstart^) < $F0) then // (11110000): 此范围内为3字节UTF-8字符
    begin
      if (pstart >= pend - 2)  then
        break;
      if ((Byte(pstart[1]) and $C0) <> $80) or ((Byte(pstart[2]) and $C0) <> $80)  then
      begin
        Result := false;
        break;
      end;

      pstart := pstart+3;
    end
    else
    begin
      Result := false;
      break;
    end;
  end;
end;

function DecordUtf8(Text: String): String;
begin
  if IsUTF8(PChar(Text), length(Text)) then
    Text:= Utf8Decode(Text);  //UTF-8的标记EE BB BF 不会丢弃而是转换成3F(?)
  Result := Text;
end;

//处理文件ASCII或UTF-8格式转换，并读入List
procedure TfImTrans.ProcFile(Filename: string; List:TStrings);
var
  memread:TMemoryStream;
  i: integer;
begin
  Screen.Cursor := crHourGlass;
  memread := TMemoryStream.Create;
  try
    memread.LoadFromFile(Filename);
    memread.Seek(0,0);
    SetString(Filename, nil, memread.Size);
    memread.Read(Pointer(Filename)^, memread.Size);
    //处理掉第一行的所有3F(?)
    List.BeginUpdate;
    List.Text := DecordUtf8(Filename);
    for i := 0 to List.Count - 1 do if (List[i]<>'') and (List[i][1]='?') then
      List[i] := Copy(List[i],2,Length(List[i]));
    List.EndUpdate;
  finally
    memread.Free;
    Screen.Cursor := crDefault;
  end;
end;

//用户拖动文件进入程序窗口，获取文件并处理之。
procedure TfImTrans.GetFile(var msg: Tmessage);
var
	afilename,aext: string;
	ilen, iCount: integer;
begin
	iCount := DragQueryFile(msg.WParam, $FFFFFFFF, nil, 0);
  if iCount>1 then Exit;																//只能拖动一个文件
	setlength(afilename, 254);
	ilen := DragQueryFile(msg.WParam, 0, pchar(afilename), 254);//唯一的文件
	setlength(afilename, ilen);
  aext := ExtractFileExt(afilename);
  if SameText(aext,'.txt') or SameText(aext,'.m3u') or SameText(aext,'.m3u8') then
    ProcFile(afilename,mmo1.Lines)
end;

procedure TfImTrans.pnl1DblClick(Sender: TObject);
begin
  mmo1.Lines.Clear;
end;

procedure TfImTrans.btnInputClick(Sender: TObject);

  //#EXTINF:-1 tvg-name="51zmt-CCTV1"  group-title="央视",CCTV-1综合
  //从上述字符串中，获得Grp,Chl,Epg信息
  procedure GetM3UGrpChn(var Group,Channel,Tvgname:string;strs:string);
  var
    i:Integer;
    subs:String;
  begin
    i := Pos('group-title',LowerCase(strs));  //查找分类关键字：group-title
    if(i>0) then begin
      subs := Copy(strs,i,Length(strs));      //从group-title之后
      GetSubStr(subs,'"');                    //切除到’“‘之后
      subs := GetSubStr(subs,'"');            //subs为’“‘之内的内容
      Group := Trim(GetSubStr(subs,','));     //如果有，则之前为分组名，','后面忽略
    end;
    i := Pos('tvg-name',LowerCase(strs));     //查找分类关键字：tvg-name
    if(i>0) then begin
      subs := Copy(strs,i,Length(strs));      //从tvg-name之后
      GetSubStr(subs,'"');                    //切除到’“‘之后
      subs := GetSubStr(subs,'"');            //subs为’“‘之内的内容
      Tvgname := Trim(subs);
    end;
    i := Pos(',',strs);  //查找分类关键字：’，'
    if(i>0) then begin
      Delete(strs,1,i);             //切除到’，'之后
      Channel := Trim(strs);        //后面作为频道名
    end;
  end;

var
  grp,chn,url,epg,strs,subs:String;
  i,j,cnt,added:Integer;
  isM3u:Boolean;
begin
  if not Assigned(aDataSet) then Exit;
  Screen.Cursor := crHourGlass;
  aDataSet.DisableControls;
  with aDataSet do try
		if not Active then Exit;
    grp := ''; chn := ''; url := ''; epg := ''; isM3u := False; cnt := 0; added := 0;
    for i := 0 to mmo1.Lines.Count - 1 do begin
      strs := Trim(mmo1.Lines[i]);
      if strs='' then Continue;
      if SameText('#EXTM3U',Copy(strs,1,7)) then begin  //通常为M3U格式文件第一行，做个标记，忽略
        isM3u := True;
        Continue;
      end;
      if SameText('#EXTINF',Copy(strs,1,7)) then begin  //为M3U格式文件分组频道名称行，获取分组和频道名
        isM3u := True;
        grp := ''; chn := ''; url := ''; epg := '';
        GetM3UGrpChn(grp,chn,epg,strs);
        Continue;
      end;
      if SameText('#EXT',Copy(strs,1,4)) then begin  //通常为M3U格式文件其他标记，做个标记，忽略
        isM3u := True;
        Continue;
      end;

      if not isM3u then begin//为Txt格式文件
        j := Pos(',',strs);  //查找分类关键字：’，'
        if j<=0 then begin   //不存在','作为分类行
          grp := Trim(strs);
          Continue;
        end;

        subs := Trim(GetSubStr(strs,','));  //切除到’,‘之后,subs为,之前的内容
        if SameText('#genre#',Copy(strs,1,7)) then begin  //为带,#genre#标记的分类行
          grp := Trim(subs);
          Continue;
        end;

        chn := Trim(subs);         //前面作为频道名
        strs := Trim(strs);        //后面作为频道地址链接
        epg := '';                 //等待后续处理
      end;
      subs := Trim(GetSubstr(strs,','));  //如果有','号，前面为url，后面为epg
      if epg='' then               //M3U格式时未从EXTINF:行获得EPG，或TXT格式
        epg := Trim(strs);         //处理频道源行的EPG
      strs := subs;
      //地址行:有可能多源以’#‘分割，每个分割作为一个源追加到数据库
      repeat
        subs := Trim(GetSubStr(strs,'#'));
        if subs = '' then  Break;

        with aDataSet do begin
          Append;
          FieldByName('fGroup').AsString := grp;
          FieldByName('fChannel').AsString := chn;
          FieldByName('fUrl').AsString := subs;
          FieldByName('fRemark').AsString := epg;
          try
            Inc(cnt);
            Post;
            Inc(added);
          except
            Cancel;
          end;
        end;
        strs := Trim(strs);
      until strs='';
    end;
  finally
    aDataSet.EnableControls;
    Screen.Cursor := crDefault;
  end;
  TimeMessageFmt(5,'本次共处理了%d 个频道源，追加了 %d 个，忽略了 %d 个。',[cnt,added,cnt-added]);
  Close;
end;

//打开文件对话框，指定文件并处理之。
procedure TfImTrans.btnOpenClick(Sender: TObject);
var
	afilename:String;
begin
	afilename := '';
	with TOpenDialog.Create(Self) do begin
    Filter := 'Channel Files(*.m3u8,*.m3u,*.txt)|*.m3u8;*.m3u;*.txt|All Files(*.*)|*.*';
    Options := Options + [ofPathMustExist, ofFileMustExist];
  	if Execute then afilename := Filename;
  	Free;
  end;
  if afilename='' then Exit;
  ProcFile(afilename,mmo1.Lines)
end;

procedure TfImTrans.FormShow(Sender: TObject);
begin
	DragAcceptFiles(handle, True);
end;

end.
