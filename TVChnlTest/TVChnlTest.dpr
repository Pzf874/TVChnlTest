program TVChnlTest;

uses
  Forms,
  umain in 'umain.pas' {fmain},
  utools in 'utools.pas',
  uImport in 'uImport.pas' {fImTrans},
  uExport in 'uExport.pas' {fExTrans},
  uTimMsgDlg in 'uTimMsgDlg.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'TVƵ��Դ������';
  Application.CreateForm(Tfmain, fmain);
  Application.CreateForm(TfImTrans, fImTrans);
  Application.CreateForm(TfExTrans, fExTrans);
  Application.Run;
end.
