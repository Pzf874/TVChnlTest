object fmain: Tfmain
  Left = 0
  Top = 0
  Caption = 'fmain'
  ClientHeight = 556
  ClientWidth = 783
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 19
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 783
    Height = 145
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      783
      145)
    object lblCount: TLabel
      Left = 338
      Top = 116
      Width = 68
      Height = 19
      Anchors = [akTop, akRight]
      Caption = #26816#26597#32447#31243#25968':'
    end
    object lbl1: TLabel
      Left = 474
      Top = 116
      Width = 68
      Height = 19
      Anchors = [akTop, akRight]
      Caption = #26816#26597#36229#26102#31186':'
    end
    object btnCheck: TSpeedButton
      Left = 664
      Top = 111
      Width = 112
      Height = 28
      Hint = #25353#25351#23450#32447#31243#25968#21644#38142#25509#36229#26102#25773#25918#21508#39057#36947#28304#26816#26597#26377#25928#24615'('#38656#35201'Aplayer.dll'#21644#35299#30721#24211')'
      AllowAllUp = True
      Anchors = [akTop, akRight]
      GroupIndex = 1
      Caption = #24320#22987#26816#26597'(&D)'
      OnClick = btnCheckClick
    end
    object btnImport: TBitBtn
      Left = 9
      Top = 39
      Width = 81
      Height = 25
      Hint = #23548#20837#39057#36947#25968#25454#20174#20854#20182#25991#20214'(TXT'#65292'M3U)'#65292#21512#24182#21040#24403#21069#25968#25454#20013#65292#24573#30053#25481#37325#22797#22320#22336#36830#25509#12290
      Caption = #23548#20837'(&I)'
      TabOrder = 1
      OnClick = btnImportClick
    end
    object btnExport: TBitBtn
      Left = 9
      Top = 70
      Width = 81
      Height = 25
      Hint = #23548#20986#39057#36947#25968#25454#21040#20854#20182#25991#20214'(TXT'#65292'M3U)'#65292#20165#23548#20986#24403#21069#36807#28388#26465#20214#26174#31034#30340#20869#23481#34892#12290
      Caption = #23548#20986'(&E)'
      TabOrder = 2
      OnClick = btnExportClick
    end
    object grpNew: TGroupBox
      Left = 112
      Top = 8
      Width = 664
      Height = 97
      Hint = #21508#31181#26465#20214#36807#28388#39057#36947#20869#23481#65292#21452#20987#38388#38553#22788#28165#31354#36807#28388#26465#20214
      Anchors = [akLeft, akTop, akRight]
      Caption = #36807#28388#39057#36947
      TabOrder = 0
      OnDblClick = grpRewDblClick
      DesignSize = (
        664
        97)
      object lblgrp: TLabel
        Left = 16
        Top = 25
        Width = 29
        Height = 19
        Caption = #20998#31867':'
      end
      object lblchn: TLabel
        Left = 208
        Top = 25
        Width = 29
        Height = 19
        Caption = #39057#36947':'
      end
      object lblAdr: TLabel
        Left = 16
        Top = 58
        Width = 55
        Height = 19
        Caption = #22320#22336#38142#25509':'
      end
      object cbbGrp: TComboBox
        Left = 77
        Top = 21
        Width = 86
        Height = 27
        AutoComplete = False
        ItemHeight = 19
        TabOrder = 0
        OnChange = cbbChnGrpChange
        OnDropDown = cbbGrpDropDown
      end
      object cbbChn: TComboBox
        Left = 275
        Top = 21
        Width = 173
        Height = 27
        AutoComplete = False
        Anchors = [akLeft, akTop, akRight]
        ItemHeight = 19
        TabOrder = 1
        OnChange = cbbChnGrpChange
        OnDropDown = cbbChnDropDown
      end
      object edtUrl: TEdit
        Left = 77
        Top = 54
        Width = 371
        Height = 27
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
        OnChange = cbbChnGrpChange
      end
      object rgChecked: TRadioGroup
        Left = 482
        Top = 0
        Width = 182
        Height = 97
        Anchors = [akTop, akRight, akBottom]
        Caption = #26816#26597#32467#26524
        Columns = 2
        Items.Strings = (
          #31354'='#26410#30693
          'OK='#26377#25928
          'NG='#26080#25928
          'TO='#36229#26102
          '['#20840#20307']')
        TabOrder = 3
        OnClick = cbbChnGrpChange
      end
    end
    object btnClear: TBitBtn
      Left = 9
      Top = 8
      Width = 81
      Height = 25
      Hint = #28165#31354#24403#21069#25152#26377#26174#31034#30340#39057#36947#25968#25454#34892#65288#36807#28388#26465#20214#20197#22806#30340#19981#21463#24433#21709#65289
      Caption = #28165#31354'(&C)'
      TabOrder = 3
      OnClick = btnClearClick
    end
    object btnExportXLS: TBitBtn
      Left = 112
      Top = 114
      Width = 81
      Height = 25
      Hint = #23548#20986#39057#36947#25968#25454#21040'EXCEL'#25110'WPS/ET'#24403#21069#39029#38754#65288#35831#39044#20808#25171#24320#36719#20214#65289#65292#23548#20986#33539#22260#20026#24403#21069#26174#31034#25152#26377#34892'('#21463#36807#28388#24433#21709')'#12290
      Caption = 'XLS'#23548#20986'(&S)'
      TabOrder = 4
      OnClick = btnExportXLSClick
    end
    object btnImportXLS: TBitBtn
      Left = 9
      Top = 114
      Width = 81
      Height = 25
      Hint = #23548#20837#39057#36947#25968#25454#20174'EXCEL'#25110'WPS/ET'#24403#21069#39029#38754#65288#35831#39044#20808#25171#24320#36719#20214#65289#65292#21512#24182#21040#24403#21069#25968#25454#20013#65292#24573#30053#25481#37325#22797#22320#22336#36830#25509#12290
      Caption = 'XLS'#23548#20837'(&L)'
      TabOrder = 5
      OnClick = btnImportXLSClick
    end
    object neThread: TSpinEdit
      Left = 412
      Top = 111
      Width = 47
      Height = 29
      Anchors = [akTop, akRight]
      MaxValue = 10
      MinValue = 1
      TabOrder = 6
      Value = 4
    end
    object neTimeOut: TSpinEdit
      Left = 548
      Top = 111
      Width = 47
      Height = 29
      Anchors = [akTop, akRight]
      Increment = 5
      MaxValue = 60
      MinValue = 5
      TabOrder = 7
      Value = 10
    end
    object cbRemeNGTO: TCheckBox
      Left = 654
      Top = 111
      Width = 97
      Height = 17
      Hint = #35760#20303'NG/TO'#32467#26524#30340'IP'#65292#21518#38754#30896#21040#30456#21516'IP'#65292#30452#25509#26631#35760'NG/TO'#65292#21152#24555#21028#26029#36895#24230#65292#27880#24847#35823#21028#12290'('#27599#27425#26816#26597#21069#20250#28165#38500'IP'#34920')'
      Anchors = [akTop, akRight]
      Caption = #35760#24518'NG/TO'
      TabOrder = 8
      Visible = False
    end
    object cbFollow: TCheckBox
      Left = 602
      Top = 118
      Width = 44
      Height = 17
      Hint = #26816#26597#36807#31243#20013#65292#34920#26684#24403#21069#34892#36319#38543#26816#26597#20301#32622#24448#19979#28378#21160
      Anchors = [akTop, akRight]
      Caption = #36319#38543
      TabOrder = 9
    end
  end
  object dbgrd1: TDBGrid
    Left = 0
    Top = 145
    Width = 783
    Height = 392
    Hint = #21452#20987#20219#24847#34892':'#25171#24320#39057#36947#28304#65292#35266#23519#23454#38469#25773#25918#25928#26524'('#38656#35201#23436#25972#30340'codecs'#35299#30721#24211')'#12290
    Align = alClient
    DataSource = dsrc
    FixedColor = clSkyBlue
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #26032#23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = GB2312_CHARSET
    TitleFont.Color = clPurple
    TitleFont.Height = -13
    TitleFont.Name = #24494#36719#38597#40657
    TitleFont.Style = []
    OnDblClick = dbgrd1DblClick
  end
  object stat1: TStatusBar
    Left = 0
    Top = 537
    Width = 783
    Height = 19
    AutoHint = True
    Panels = <
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
  object dsrc: TDataSource
    DataSet = qryDatV
    Left = 464
    Top = 232
  end
  object conEDB: TADOConnection
    ConnectionString = 
      'Provider=Microsoft.Jet.OLEDB.4.0;Data Source="..\bin\TVDATA.MDB"' +
      ';'
    LoginPrompt = False
    Mode = cmShareDenyNone
    Provider = 'Microsoft.Jet.OLEDB.4.0'
    Left = 416
    Top = 192
  end
  object qryDatV: TADOQuery
    Connection = conEDB
    AfterOpen = dsetAfterOpen
    AfterPost = dsetAfterScroll
    AfterCancel = dsetAfterScroll
    AfterScroll = dsetAfterScroll
    Parameters = <>
    Prepared = True
    SQL.Strings = (
      'Select * from RecData order by fid;')
    Left = 464
    Top = 192
  end
  object cmdADO: TADOCommand
    Connection = conEDB
    Parameters = <>
    Left = 416
    Top = 232
  end
end
