unit utools;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, Grids, DBGrids, DB, ADODB,
  comobj, ActiveX, uTimMsgDlg;

const
  APlayerDLLFile   = '.\APlayer.dll';
  APlayStateStr : array[0..6] of string =
  ('已关闭','打开..','暂停..','已暂停','播放..','播放中','关闭..');
  ResultStr : array[0..3] of string =  ('','OK','NG','TO');

const
	BASE_UM = WM_USER+1000;
  //懒得用共享内存，管道，等方式传送结果，用一堆的消息来传送
	UM_PLAY_END1 = BASE_UM+1;	//播放器结束消息
	UM_PLAY_END2 = BASE_UM+2;	//播放器结束消息
	UM_PLAY_END3 = BASE_UM+3;	//播放器结束消息
	UM_PLAY_END = BASE_UM+10;	//播放器结束消息

type
  PIUnknown = ^IUnknown;
  TAtlAxAttachControl = function(Control: IUnknown; hwind: hwnd; ppUnkContainer: PIUnknown): HRESULT; stdcall;

type
  TcdsField = record
  	eTitle:string;           //字段名（英文兼容性好）
    ftype:TFieldType;        //字段类型
    fsize:Integer;           //字段字节数
    cTitle:string;           //表格标题显示名
    cLength:integer;         //表格显示字节宽度
    cFormat:string;          //表格显示格式
    cHide:Boolean;
    cAlignment:TAlignment;
  end;

const
  CDSFIELDS : array [0..10] of TcdsField =
  (
  (eTitle:'fID';       ftype:ftAutoInc;    fsize:0;    cTitle:'序号';      cLength:5),    //0
  (eTitle:'fGroup';    ftype:ftWideString; fsize:16;   cTitle:'分类名';    cLength:8),     //1
  (eTitle:'fChannel';  ftype:ftWideString; fsize:40;   cTitle:'频道名';    cLength:16),    //2
  (eTitle:'fUrl';      ftype:ftWideString; fsize:255;  cTitle:'地址链接';   cLength:32),   //3
  (eTitle:'fResult';   ftype:ftString; fsize:4;    cTitle:'检查';       cLength:4; cAlignment: taCenter),    //4
  (eTitle:'fVWidth';   ftype:ftInteger; fsize:0;    cTitle:'宽度';      cLength:4),    //5
  (eTitle:'fVHeight';  ftype:ftInteger; fsize:0;    cTitle:'高度';      cLength:4),    //6
  (eTitle:'fConnect';  ftype:ftInteger; fsize:0;    cTitle:'连接ms';     cLength:5),    //8
  (eTitle:'fSpeed';    ftype:ftInteger; fsize:0;    cTitle:'速度KB';     cLength:5),    //9

  (eTitle:'fRemark';   ftype:ftString; fsize:128;  cTitle:'备注';      cLength:10),     //10
  (eTitle:'fThread';   ftype:ftInteger; fsize:0;    cTitle:'线程';     cLength:4)    //7
  );

//不预先注册OCX类，运行时从文件创建OCX类
function CreateComObjectFromDll(CLSID: TGUID; DllHandle: THandle): IUnknown;
//格式化数据集每个字段的宽度，标题中文，是否显示，显示格式
procedure  FormatDataSetView(DataSet: TDataSet);
//打开EXCEL或WPS/ET，创建一个新工作簿，填入DataSet数据集到SHEET1
procedure ExportToExcel(Caption:string; DataSet:TDataSet);
//从当前打开着的EXCEL或WPS/ET，的当前工作簿的当前SHEET1读取数据，填入DataSet数据集（追加方式，不删除原数据）
//为了简单，忽略第一行第二行，从第三行开始直到后续行第一列为空为止，不检查字段顺序，按照DataSet的Fields顺序填入
procedure ImportFromExcel(DataSet:TDataSet);
//从数据库链接的Tab表中，根据Where条件，检索出Col的唯一项表格，填充于列表List中并返回（填充前清除List原有数据）
//select distinct col from table的方式查询到的结果排序不可知，如果要严格按照表格内的主键顺序返回，应该用：
//select col from table group by col order by min(Primarykey)
procedure FillListWithColumn(Conn:TADOConnection; Tab,Col,Where,sort:String; List:TStrings);
function	IncSerialNo(sn:string):string;
function GetSubStr(var Str: string; const sub:string):string;
//截取SQL查询语句中的where部分
function GetWherePart(const Str: string):string;
function GetIpAddr(const Url:string):string;


implementation

//不预先注册OCX类，运行时从文件创建OCX类
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

//格式化数据集每个字段的宽度，标题中文，是否显示，显示格式
procedure  FormatDataSetView(DataSet: TDataSet);
var
  i,idx:Integer;
  lstr,tstr:string;
begin
  with DataSet do for i := 0 to Fields.Count-1 do begin
    lstr := Fields[i].DisplayLabel; tstr := ''; //特殊处理电池1-144尾标
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


//从数据库链接的Tab表中，根据Where条件，检索出Col的唯一项表格，填充于列表List中并返回（填充前清除List原有数据）
//select distinct col from table的方式查询到的结果排序不可知，如果要严格按照表格内的主键顺序返回，应该用：
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

//从数据集Dataset中导出所有数据行到Excel或ET表格中（需安装有WPS或MSOFFICE,无需预先打开，会创建新工作簿页面），
//数据填充到新工作簿的第一页，第一行为Caption内容，第二行为标题(DisplayLabel)，第三行开始为数据(DisplayText)
procedure ExportToExcel(Caption:string; DataSet:TDataSet);
var
	XApplica,XWorkBook,XDataSheet:Variant;
  i,j:integer;
begin
	with DataSet do begin
		if not Active then Exit;
    if RecordCount=0 then Exit;

    if varType(XApplica)<>VarDispatch then try
      //连接到打开着的MS Excel软件
      XApplica := CreateOleObject('Excel.Application');
    except
    //连接到打开着的WPS ET软件
      try
        XApplica := CreateOleObject('ET.Application');
      except
        try
          XApplica := CreateOleObject('KET.Application');
        except
          if varType(XApplica)<>VarDispatch then begin
            TimeMessage(5,'连接MS EXCEL/WPS ET软件失败！'#13#10'你必须先打开要处理的.xls文件');
            Exit;
          end;
        end;
      end;
    end;

    XApplica.Visible := True;
		try
			XWorkBook := XApplica.WorkBooks.Add;
			if varType(XWorkBook)<>VarDispatch then begin
				TimeMessage(5,'EXCEL打开记录文件失败！');
				Exit;
			end;
			try
				XDataSheet := XWorkBook.WorkSheets[1];	//只处理文件的第一页
        try
          if Caption<>'' then XDataSheet.Cells[1,1] := '过滤=';
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

//从当前打开着的EXCEL或WPS/ET，的当前工作簿的当前SHEET1读取数据，填入DataSet数据集（追加方式，不删除原数据）
//为了简单，忽略第一行第二行，从第三行开始直到后续行第一列为空为止，不检查字段顺序，按照DataSet的Fields顺序填入
procedure ImportFromExcel(DataSet:TDataSet);
var
	XApplica,XDataSheet:Variant;
  i,j:integer;
  value:string;
begin
	with DataSet do begin
		if not Active then Exit;

    if varType(XApplica)<>VarDispatch then try
      //连接到打开着的MS Excel软件
      XApplica := GetActiveOleObject('Excel.Application');
    except
    //连接到打开着的WPS ET软件
      try
        XApplica := GetActiveOleObject('ET.Application');
      except
        try
          XApplica := GetActiveOleObject('KET.Application');
        except
          if varType(XApplica)<>VarDispatch then begin
            TimeMessage(5,'连接MS EXCEL/WPS ET软件失败！'#13#10'你必须先打开要处理的.xls文件');
            Exit;
          end;
        end;
      end;
    end;

    XApplica.Visible := True;
		try
      XDataSheet := XApplica.ActiveSheet;	//只处理当前工作簿的当前页
			try
    		DisableControls;
        j := 3;
    		try
          repeat
            value := Trim(XDataSheet.Cells[j,1]); //第一列：判断是否为空，作为结束条件
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


//根据现有的序列号，+1后返回
function	IncSerialNo(sn:string):string;
var
 	sub:string;
  n,i:integer;
begin
	Result := '';
	n := Pos('-',sn);		//查找序列号分界符'-';
  if n=0 then     		//没有找到：将sn截取6个作为头部：2013-12-5
  	n := 6;

  Result := Copy(sn,1,n);	//连带'-'一起转移头部
 	sub := Copy(sn,n+1,Length(sn));//截取尾部

//将截取的尾部作为数字+1后再转换回去
	i := StrToIntDef(sub,-1);
  if i=-1 then begin	//没有转换成功：sn直接返回
	 	Result := Result + sub;
    Exit;
  end;
  Inc(i);
  sub := '%0.'+IntToStr(Length(sub))+'d';	//格式化成和原来一样长
  Result := Result + Format(sub,[i]);
end;

/////////////////////////////////////////////////////////////////////////////////////////
//取出以'aCh'分割的前部分字符串，原字符串切除到'aCh'为止。
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

//截取SQL查询语句中的where部分：必须全在一行不能分行，where后面只判断是否有group by/order by，不判断(left inner/outer) join
function GetWherePart(const Str: string):string;
var
	i:integer;
begin
  Result := '';
	i := Pos(' where ',LowerCase(str));
  if i = 0 then Exit;
	Result := Copy(Str,i,Length(Str));  //'where'开始的部分

	i := Pos(' group ',LowerCase(Result));
  if i > 0 then
  	Result := Copy(Result,1,i-1);          //'group'之前的部分

	i := Pos(' order ',LowerCase(Result));
  if i > 0 then
  	Result := Copy(Result,1,i-1);          //'order'之前的部分
end;

function GetIpAddr(const Url:string):string;
var
  str1:string;
begin
  str1 := Url;
  GetSubStr(str1,'//');           //切掉"//“之前
  Result := GetSubStr(str1,'/');  //获得”/"之前
end;

end.
