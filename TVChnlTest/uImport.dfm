object fImTrans: TfImTrans
  Left = 0
  Top = 0
  Caption = #23548#20837#26684#24335#21270#39057#36947#20449#24687
  ClientHeight = 437
  ClientWidth = 621
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object mmo1: TMemo
    Left = 0
    Top = 81
    Width = 621
    Height = 356
    Hint = #30452#25509#25302#20837#25991#20214#65292#25110'CTRL+V'#31896#36148#21098#36148#26495#20869#23481#65292#21452#20987#19978#37096#38754#26495#21306#28165#38500#26174#31034#20869#23481
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
    WantTabs = True
    WordWrap = False
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 621
    Height = 81
    Hint = #30452#25509#25302#20837#25991#20214#65292#25110'CTRL+V'#31896#36148#21098#36148#26495#20869#23481#65292#21452#20987#19978#37096#38754#26495#21306#28165#38500#26174#31034#20869#23481
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    OnDblClick = pnl1DblClick
    object pnl2: TPanel
      Left = 0
      Top = 0
      Width = 105
      Height = 81
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object btnOpen: TBitBtn
        Left = 16
        Top = 8
        Width = 81
        Height = 30
        Hint = #25171#24320#39057#36947#25968#25454#25991#20214'(TXT'#65292'M3U)'
        Caption = #25171#24320'(&O)'
        TabOrder = 0
        OnClick = btnOpenClick
      end
      object btnInput: TBitBtn
        Left = 16
        Top = 44
        Width = 81
        Height = 30
        Hint = #24403#21069#26174#31034#25968#25454#20869#23481#24182#20837#39057#36947#25968#25454#24211#20869#24182#20851#38381#27492#31383#21475
        Caption = #23548#20837'(&I)'
        TabOrder = 1
        OnClick = btnInputClick
      end
    end
    object mmoDis: TMemo
      Left = 105
      Top = 0
      Width = 516
      Height = 81
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Color = clBtnFace
      Ctl3D = False
      Lines.Strings = (
        '1.'#25171#24320#25110#25302#20837#30340#25991#20214#25110#31896#36148#30340#25991#26412#65292#20250#33258#21160#36716#25442'ASCII'#65292'UTF-8'#32534#30721
        ''
        '2.'#25509#21463#30340'M3U8'#26684#24335': ('#26041#25324#21495'[ ]'#20869#30340#19981#26159#24517#39035#30340')'
        '    #EXTINF:-1 [group-title="'#20998#31867#21517'"],'#39057#36947#21517
        '    '#39057#36947'URL'#38142#25509#22320#22336'1'#28304'[#'#39057#36947'URL'#38142#25509#22320#22336'2'#28304'#'#39057#36947'URL'#38142#25509#22320#22336'3'#28304'][,EPG'#21517']'
        ''
        '3.'#25509#21463#30340'TXT'#26684#24335': ('#26041#25324#21495'[ ]'#20869#30340#19981#26159#24517#39035#30340')'
        '    ['#20998#31867#21517'[,#genre#]]'
        '    '#39057#36947#21517','#39057#36947'URL'#38142#25509#22320#22336'1'#28304'[#'#39057#36947'URL'#38142#25509#22320#22336'2'#28304'#'#39057#36947'URL'#38142#25509#22320#22336'3'#28304'][,EPG'#21517']'
        ''
        '4.'#19981#25509#21463#30340#26684#24335': ('#22240#20026#26080#27861#21306#20998#65292#21448#25042#24471#28155#21152#36873#21017#39033')'
        '    '#20998#31867#21517','#39057#36947#21517','#39057#36947'URL'#38142#25509#22320#22336'1'#28304'.........'
        ''
        '5.TXT'#21644'M3U8'#26684#24335#19981#35201#28151#29992#65292#23548#20837#19968#31181#21518#21452#20987#26412#21306#22495#28165#38500#65292#20877#31896#36148#25110#25302#20837#21478#19968#31181#23548#20837)
      ParentCtl3D = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 1
      WantReturns = False
      WordWrap = False
      OnDblClick = pnl1DblClick
    end
  end
end
