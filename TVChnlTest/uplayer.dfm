object fPlayer: TfPlayer
  Left = 0
  Top = 0
  Hint = #26368#31616#25773#25918#30011#38754#65292#26080#25511#21046#21151#33021
  Caption = 'Aplayer'#20363#23376
  ClientHeight = 405
  ClientWidth = 720
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object tmrSpeed: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrSpeedTimer
    Left = 136
    Top = 40
  end
end
