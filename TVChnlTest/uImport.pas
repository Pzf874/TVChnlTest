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
		procedure GetFile(var msg: Tmessage); message wm_dropfiles; //�����ļ�ʱ�յ�����Ϣ
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
    if (Byte(pstart^) < $80) then // (10000000): ֵС��0x80��ΪASCII�ַ�
    begin
      pstart := pstart+1;
    end
    else if (Byte(pstart^) < $C0) then // (11000000): ֵ����0x80��0xC0֮���Ϊ��ЧUTF-8�ַ�
    begin
      Result := false;
      break;
    end
    else if (Byte(pstart^) < $E0) then // (11100000): �˷�Χ��Ϊ2�ֽ�UTF-8�ַ�
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
    else if (Byte(pstart^) < $F0) then // (11110000): �˷�Χ��Ϊ3�ֽ�UTF-8�ַ�
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
    Text:= Utf8Decode(Text);  //UTF-8�ı��EE BB BF ���ᶪ������ת����3F(?)
  Result := Text;
end;

//�����ļ�ASCII��UTF-8��ʽת����������List
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
    //�������һ�е�����3F(?)
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

//�û��϶��ļ�������򴰿ڣ���ȡ�ļ�������֮��
procedure TfImTrans.GetFile(var msg: Tmessage);
var
	afilename,aext: string;
	ilen, iCount: integer;
begin
	iCount := DragQueryFile(msg.WParam, $FFFFFFFF, nil, 0);
  if iCount>1 then Exit;																//ֻ���϶�һ���ļ�
	setlength(afilename, 254);
	ilen := DragQueryFile(msg.WParam, 0, pchar(afilename), 254);//Ψһ���ļ�
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

  //#EXTINF:-1 tvg-name="51zmt-CCTV1"  group-title="����",CCTV-1�ۺ�
  //�������ַ����У����Grp,Chl,Epg��Ϣ
  procedure GetM3UGrpChn(var Group,Channel,Tvgname:string;strs:string);
  var
    i:Integer;
    subs:String;
  begin
    i := Pos('group-title',LowerCase(strs));  //���ҷ���ؼ��֣�group-title
    if(i>0) then begin
      subs := Copy(strs,i,Length(strs));      //��group-title֮��
      GetSubStr(subs,'"');                    //�г���������֮��
      subs := GetSubStr(subs,'"');            //subsΪ������֮�ڵ�����
      Group := Trim(GetSubStr(subs,','));     //����У���֮ǰΪ��������','�������
    end;
    i := Pos('tvg-name',LowerCase(strs));     //���ҷ���ؼ��֣�tvg-name
    if(i>0) then begin
      subs := Copy(strs,i,Length(strs));      //��tvg-name֮��
      GetSubStr(subs,'"');                    //�г���������֮��
      subs := GetSubStr(subs,'"');            //subsΪ������֮�ڵ�����
      Tvgname := Trim(subs);
    end;
    i := Pos(',',strs);  //���ҷ���ؼ��֣�����'
    if(i>0) then begin
      Delete(strs,1,i);             //�г�������'֮��
      Channel := Trim(strs);        //������ΪƵ����
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
      if SameText('#EXTM3U',Copy(strs,1,7)) then begin  //ͨ��ΪM3U��ʽ�ļ���һ�У�������ǣ�����
        isM3u := True;
        Continue;
      end;
      if SameText('#EXTINF',Copy(strs,1,7)) then begin  //ΪM3U��ʽ�ļ�����Ƶ�������У���ȡ�����Ƶ����
        isM3u := True;
        grp := ''; chn := ''; url := ''; epg := '';
        GetM3UGrpChn(grp,chn,epg,strs);
        Continue;
      end;
      if SameText('#EXT',Copy(strs,1,4)) then begin  //ͨ��ΪM3U��ʽ�ļ�������ǣ�������ǣ�����
        isM3u := True;
        Continue;
      end;

      if not isM3u then begin//ΪTxt��ʽ�ļ�
        j := Pos(',',strs);  //���ҷ���ؼ��֣�����'
        if j<=0 then begin   //������','��Ϊ������
          grp := Trim(strs);
          Continue;
        end;

        subs := Trim(GetSubStr(strs,','));  //�г�����,��֮��,subsΪ,֮ǰ������
        if SameText('#genre#',Copy(strs,1,7)) then begin  //Ϊ��,#genre#��ǵķ�����
          grp := Trim(subs);
          Continue;
        end;

        chn := Trim(subs);         //ǰ����ΪƵ����
        strs := Trim(strs);        //������ΪƵ����ַ����
        epg := '';                 //�ȴ���������
      end;
      subs := Trim(GetSubstr(strs,','));  //�����','�ţ�ǰ��Ϊurl������Ϊepg
      if epg='' then               //M3U��ʽʱδ��EXTINF:�л��EPG����TXT��ʽ
        epg := Trim(strs);         //����Ƶ��Դ�е�EPG
      strs := subs;
      //��ַ��:�п��ܶ�Դ�ԡ�#���ָÿ���ָ���Ϊһ��Դ׷�ӵ����ݿ�
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
  TimeMessageFmt(5,'���ι�������%d ��Ƶ��Դ��׷���� %d ���������� %d ����',[cnt,added,cnt-added]);
  Close;
end;

//���ļ��Ի���ָ���ļ�������֮��
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
