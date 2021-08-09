unit utools;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, Grids, DBGrids, DB, ADODB,
  comobj, ActiveX, uTimMsgDlg;

const
  APlayerDLLFile   = '.\APlayer.dll';
  APlayStateStr : array[0..6] of string =
  ('�ѹر�','��..','��ͣ..','����ͣ','����..','������','�ر�..');
  ResultStr : array[0..3] of string =  ('','OK','NG','TO');

const
	BASE_UM = WM_USER+1000;
  //�����ù����ڴ棬�ܵ����ȷ�ʽ���ͽ������һ�ѵ���Ϣ������
	UM_PLAY_END1 = BASE_UM+1;	//������������Ϣ
	UM_PLAY_END2 = BASE_UM+2;	//������������Ϣ
	UM_PLAY_END3 = BASE_UM+3;	//������������Ϣ
	UM_PLAY_END = BASE_UM+10;	//������������Ϣ

type
  PIUnknown = ^IUnknown;
  TAtlAxAttachControl = function(Control: IUnknown; hwind: hwnd; ppUnkContainer: PIUnknown): HRESULT; stdcall;

type
  TcdsField = record
  	eTitle:string;           //�ֶ�����Ӣ�ļ����Ժã�
    ftype:TFieldType;        //�ֶ�����
    fsize:Integer;           //�ֶ��ֽ���
    cTitle:string;           //��������ʾ��
    cLength:integer;         //�����ʾ�ֽڿ��
    cFormat:string;          //�����ʾ��ʽ
    cHide:Boolean;
    cAlignment:TAlignment;
  end;

const
  CDSFIELDS : array [0..10] of TcdsField =
  (
  (eTitle:'fID';       ftype:ftAutoInc;    fsize:0;    cTitle:'���';      cLength:5),    //0
  (eTitle:'fGroup';    ftype:ftWideString; fsize:16;   cTitle:'������';    cLength:8),     //1
  (eTitle:'fChannel';  ftype:ftWideString; fsize:40;   cTitle:'Ƶ����';    cLength:16),    //2
  (eTitle:'fUrl';      ftype:ftWideString; fsize:255;  cTitle:'��ַ����';   cLength:32),   //3
  (eTitle:'fResult';   ftype:ftString; fsize:4;    cTitle:'���';       cLength:4; cAlignment: taCenter),    //4
  (eTitle:'fVWidth';   ftype:ftInteger; fsize:0;    cTitle:'���';      cLength:4),    //5
  (eTitle:'fVHeight';  ftype:ftInteger; fsize:0;    cTitle:'�߶�';      cLength:4),    //6
  (eTitle:'fConnect';  ftype:ftInteger; fsize:0;    cTitle:'����ms';     cLength:5),    //8
  (eTitle:'fSpeed';    ftype:ftInteger; fsize:0;    cTitle:'�ٶ�KB';     cLength:5),    //9

  (eTitle:'fRemark';   ftype:ftString; fsize:128;  cTitle:'��ע';      cLength:10),     //10
  (eTitle:'fThread';   ftype:ftInteger; fsize:0;    cTitle:'�߳�';     cLength:4)    //7
  );

//��Ԥ��ע��OCX�࣬����ʱ���ļ�����OCX��
function CreateComObjectFromDll(CLSID: TGUID; DllHandle: THandle): IUnknown;
//��ʽ�����ݼ�ÿ���ֶεĿ�ȣ��������ģ��Ƿ���ʾ����ʾ��ʽ
procedure  FormatDataSetView(DataSet: TDataSet);
//��EXCEL��WPS/ET������һ���¹�����������DataSet���ݼ���SHEET1
procedure ExportToExcel(Caption:string; DataSet:TDataSet);
//�ӵ�ǰ���ŵ�EXCEL��WPS/ET���ĵ�ǰ�������ĵ�ǰSHEET1��ȡ���ݣ�����DataSet���ݼ���׷�ӷ�ʽ����ɾ��ԭ���ݣ�
//Ϊ�˼򵥣����Ե�һ�еڶ��У��ӵ����п�ʼֱ�������е�һ��Ϊ��Ϊֹ��������ֶ�˳�򣬰���DataSet��Fields˳������
procedure ImportFromExcel(DataSet:TDataSet);
//�����ݿ����ӵ�Tab���У�����Where������������Col��Ψһ����������б�List�в����أ����ǰ���Listԭ�����ݣ�
//select distinct col from table�ķ�ʽ��ѯ���Ľ�����򲻿�֪�����Ҫ�ϸ��ձ���ڵ�����˳�򷵻أ�Ӧ���ã�
//select col from table group by col order by min(Primarykey)
procedure FillListWithColumn(Conn:TADOConnection; Tab,Col,Where,sort:String; List:TStrings);
function	IncSerialNo(sn:string):string;
function GetSubStr(var Str: string; const sub:string):string;
//��ȡSQL��ѯ����е�where����
function GetWherePart(const Str: string):string;
function GetIpAddr(const Url:string):string;


implementation

//��Ԥ��ע��OCX�࣬����ʱ���ļ�����OCX��
function CreateComObjectFromDll(CLSID: TGUID; DllHandle: THandle): IUnknown;
var
  Factory: IClassFactory;
  DllGetClassObject: function(const CLSID, IID: TGUID; var Obj): HResult; stdcall;
  hr: HRESULT;
begin
  DllGetClassObject := GetProcAddress(DllHandle, 'DllGetClassObject');
  if Assigned(DllGetClassObject) then
  begin
    hr := DllGetClassObject(CLSID, IClassFactory, Factory);
    if hr = S_OK then
    try
      hr := Factory.CreateInstance(nil, IUnknown, Result);
      if hr <> S_OK then
      begin
        Result := nil;
      end;
    except
      Result := nil;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function GetTitleIndex(str:string):integer;
var
	i:integer;
begin
  for i:=Low(CDSFIELDS) to High(CDSFIELDS) do begin
		if SameText(str,CDSFIELDS[i].eTitle) then begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

//��ʽ�����ݼ�ÿ���ֶεĿ�ȣ��������ģ��Ƿ���ʾ����ʾ��ʽ
procedure  FormatDataSetView(DataSet: TDataSet);
var
  i,idx:Integer;
  lstr,tstr:string;
begin
  with DataSet do for i := 0 to Fields.Count-1 do begin
    lstr := Fields[i].DisplayLabel; tstr := ''; //���⴦����1-144β��
    idx := GetTitleIndex(lstr);
    if idx<0 then Continue;
    Fields[i].Visible := not CDSFIELDS[idx].cHide;
    Fields[i].DisplayLabel := CDSFIELDS[idx].cTitle+tstr;
    Fields[i].DisplayWidth := CDSFIELDS[idx].cLength;
    if CDSFIELDS[idx].cAlignment<>taLeftJustify then
      Fields[i].Alignment := CDSFIELDS[idx].cAlignment;

    if CDSFIELDS[idx].cFormat<>'' then begin
      if Fields[i] is TAggregateField then
        TAggregateField(Fields[i]).DisplayFormat := CDSFIELDS[idx].cFormat;
      if Fields[i] is TDateTimeField then
        TDateTimeField(Fields[i]).DisplayFormat := CDSFIELDS[idx].cFormat;
      if Fields[i] is TNumericField then
        TNumericField(Fields[i]).DisplayFormat := CDSFIELDS[idx].cFormat;
      if Fields[i] is TSQLTimeStampField then
        TSQLTimeStampField(Fields[i]).DisplayFormat := CDSFIELDS[idx].cFormat;
    end;
  end;
end;


//�����ݿ����ӵ�Tab���У�����Where������������Col��Ψһ����������б�List�в����أ����ǰ���Listԭ�����ݣ�
//select distinct col from table�ķ�ʽ��ѯ���Ľ�����򲻿�֪�����Ҫ�ϸ��ձ���ڵ�����˳�򷵻أ�Ӧ���ã�
//select col from table group by col order by min(Primarykey)
procedure FillListWithColumn(Conn:TADOConnection; Tab,Col,Where,sort:String; List:TStrings);
var
	Query: TADOQuery;
  str:string;
begin
  if(Sort<>'') then str := ' order by '+sort else str := '';
	Query := TADOQuery.Create(Application);
  with Query do try
  	Connection := Conn;
  	SQL.Clear;
    SQL.Add('select '+Col+' from '+Tab+' '+Where+' group by '+Col+str);
    Active := True;
    List.Clear;
    while not EOF do begin
    	str := Trim(Fields[0].AsString);
      if str<>'' then
	    	List.Add(str);
    	Next;
    end;
  finally
  	Free;
  end;
end;

//�����ݼ�Dataset�е������������е�Excel��ET����У��谲װ��WPS��MSOFFICE,����Ԥ�ȴ򿪣��ᴴ���¹�����ҳ�棩��
//������䵽�¹������ĵ�һҳ����һ��ΪCaption���ݣ��ڶ���Ϊ����(DisplayLabel)�������п�ʼΪ����(DisplayText)
procedure ExportToExcel(Caption:string; DataSet:TDataSet);
var
	XApplica,XWorkBook,XDataSheet:Variant;
  i,j:integer;
begin
	with DataSet do begin
		if not Active then Exit;
    if RecordCount=0 then Exit;

    if varType(XApplica)<>VarDispatch then try
      //���ӵ����ŵ�MS Excel���
      XApplica := CreateOleObject('Excel.Application');
    except
    //���ӵ����ŵ�WPS ET���
      try
        XApplica := CreateOleObject('ET.Application');
      except
        try
          XApplica := CreateOleObject('KET.Application');
        except
          if varType(XApplica)<>VarDispatch then begin
            TimeMessage(5,'����MS EXCEL/WPS ET���ʧ�ܣ�'#13#10'������ȴ�Ҫ�����.xls�ļ�');
            Exit;
          end;
        end;
      end;
    end;

    XApplica.Visible := True;
		try
			XWorkBook := XApplica.WorkBooks.Add;
			if varType(XWorkBook)<>VarDispatch then begin
				TimeMessage(5,'EXCEL�򿪼�¼�ļ�ʧ�ܣ�');
				Exit;
			end;
			try
				XDataSheet := XWorkBook.WorkSheets[1];	//ֻ�����ļ��ĵ�һҳ
        try
          if Caption<>'' then XDataSheet.Cells[1,1] := '����=';
          XDataSheet.Cells[1,2] := Caption;
          for i:=0 to FieldCount-1 do begin
            XDataSheet.Cells[2,i+1] := Fields[i].DisplayLabel;
          end;
          DisableControls;
          j := 3;
          try
            First;
            while not EOF do begin
              for i:=0 to FieldCount-1 do begin
                XDataSheet.Cells[j,i+1] := Trim(Fields[i].DisplayText);
              end;
              Inc(j);
              Next;
            end;
          finally
            EnableControls;
          end;
        finally
          XDataSheet := unAssigned;
        end;
			finally
//				XWorkBook.Close;
				XWorkBook := unAssigned;
			end;
		finally
//			XApplica.Quit;
			XApplica := unAssigned;
    end;
  end;
end;

//�ӵ�ǰ���ŵ�EXCEL��WPS/ET���ĵ�ǰ�������ĵ�ǰSHEET1��ȡ���ݣ�����DataSet���ݼ���׷�ӷ�ʽ����ɾ��ԭ���ݣ�
//Ϊ�˼򵥣����Ե�һ�еڶ��У��ӵ����п�ʼֱ�������е�һ��Ϊ��Ϊֹ��������ֶ�˳�򣬰���DataSet��Fields˳������
procedure ImportFromExcel(DataSet:TDataSet);
var
	XApplica,XDataSheet:Variant;
  i,j:integer;
  value:string;
begin
	with DataSet do begin
		if not Active then Exit;

    if varType(XApplica)<>VarDispatch then try
      //���ӵ����ŵ�MS Excel���
      XApplica := GetActiveOleObject('Excel.Application');
    except
    //���ӵ����ŵ�WPS ET���
      try
        XApplica := GetActiveOleObject('ET.Application');
      except
        try
          XApplica := GetActiveOleObject('KET.Application');
        except
          if varType(XApplica)<>VarDispatch then begin
            TimeMessage(5,'����MS EXCEL/WPS ET���ʧ�ܣ�'#13#10'������ȴ�Ҫ�����.xls�ļ�');
            Exit;
          end;
        end;
      end;
    end;

    XApplica.Visible := True;
		try
      XDataSheet := XApplica.ActiveSheet;	//ֻ����ǰ�������ĵ�ǰҳ
			try
    		DisableControls;
        j := 3;
    		try
          repeat
            value := Trim(XDataSheet.Cells[j,1]); //��һ�У��ж��Ƿ�Ϊ�գ���Ϊ��������
            if value='' then Break;
            Append;
		        for i:=0 to FieldCount-1 do if not (Fields[i].DataType in [ftAutoInc]) then begin
              value := Trim(XDataSheet.Cells[j,i+1]);
    		     	if value<>'' then Fields[i].AsString := value;
        		end;
            try
              Post;
            except
              Cancel;
            end;
            Inc(j);
          until False;
    		finally
    			EnableControls;
    		end;
      finally
        XDataSheet := unAssigned;
      end;
		finally
//			XApplica.Quit;
			XApplica := unAssigned;
    end;
  end;
end;


//�������е����кţ�+1�󷵻�
function	IncSerialNo(sn:string):string;
var
 	sub:string;
  n,i:integer;
begin
	Result := '';
	n := Pos('-',sn);		//�������кŷֽ��'-';
  if n=0 then     		//û���ҵ�����sn��ȡ6����Ϊͷ����2013-12-5
  	n := 6;

  Result := Copy(sn,1,n);	//����'-'һ��ת��ͷ��
 	sub := Copy(sn,n+1,Length(sn));//��ȡβ��

//����ȡ��β����Ϊ����+1����ת����ȥ
	i := StrToIntDef(sub,-1);
  if i=-1 then begin	//û��ת���ɹ���snֱ�ӷ���
	 	Result := Result + sub;
    Exit;
  end;
  Inc(i);
  sub := '%0.'+IntToStr(Length(sub))+'d';	//��ʽ���ɺ�ԭ��һ����
  Result := Result + Format(sub,[i]);
end;

/////////////////////////////////////////////////////////////////////////////////////////
//ȡ����'aCh'�ָ��ǰ�����ַ�����ԭ�ַ����г���'aCh'Ϊֹ��
function GetSubStr(var Str: string; const sub:string):string;
var
	i:integer;
begin
	Result := '';
	if Str = '' then Exit;
	i := Pos(sub,Str);
	if i = 0 then begin
		Result := Str;
		Str := '';
	end
	else begin
		Result := Copy(Str,1,i-1);
		Str := Copy(Str,i+Length(sub),Length(Str));
	end;
end;

//��ȡSQL��ѯ����е�where���֣�����ȫ��һ�в��ܷ��У�where����ֻ�ж��Ƿ���group by/order by�����ж�(left inner/outer) join
function GetWherePart(const Str: string):string;
var
	i:integer;
begin
  Result := '';
	i := Pos(' where ',LowerCase(str));
  if i = 0 then Exit;
	Result := Copy(Str,i,Length(Str));  //'where'��ʼ�Ĳ���

	i := Pos(' group ',LowerCase(Result));
  if i > 0 then
  	Result := Copy(Result,1,i-1);          //'group'֮ǰ�Ĳ���

	i := Pos(' order ',LowerCase(Result));
  if i > 0 then
  	Result := Copy(Result,1,i-1);          //'order'֮ǰ�Ĳ���
end;

function GetIpAddr(const Url:string):string;
var
  str1:string;
begin
  str1 := Url;
  GetSubStr(str1,'//');           //�е�"//��֮ǰ
  Result := GetSubStr(str1,'/');  //��á�/"֮ǰ
end;

end.
