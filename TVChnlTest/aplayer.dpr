program aplayer;

uses
  Forms,
  utools in 'utools.pas',
  APlayer3Lib_TLB in 'APlayer3Lib_TLB.pas',
  uplayer in 'uplayer.pas' {fPlayer},
  uTimMsgDlg in 'uTimMsgDlg.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfPlayer, fPlayer);
  Application.Run;
end.
