program TVChnlTest;

uses
  Forms,
  uplayer in 'uplayer.pas' {frmplay},
  umain in 'umain.pas' {fmain},
  utools in 'utools.pas',
  uImport in 'uImport.pas' {fImTrans},
  uExport in 'uExport.pas' {fExTrans},
  APlayer3Lib_TLB in 'APlayer3Lib_TLB.pas',
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
