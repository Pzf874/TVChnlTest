object fExTrans: TfExTrans
  Left = 0
  Top = 0
  Caption = #26684#24335#21270#23548#20986#39057#36947#20449#24687
  ClientHeight = 503
  ClientWidth = 652
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object spl1: TSplitter
    Left = 115
    Top = 97
    Height = 406
    ExplicitLeft = 176
    ExplicitTop = 184
    ExplicitHeight = 100
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 652
    Height = 97
    Align = alTop
    TabOrder = 0
    DesignSize = (
      652
      97)
    object lbl1: TLabel
      Left = 447
      Top = 73
      Width = 40
      Height = 13
      Hint = #36755#20986#26102#25351#23450#30340#25991#20214#21517#25110#20998#21106#30446#24405#65292#31354#30333#21017#20026'"TV"'#65292#22914#26524#20026#39'#'#39#24320#22836#21017#20998#21106#22810#25991#20214#26102#65292#21069#32512'900#'#36215
      Caption = #20445#23384#20110':'
    end
    object lbl2: TLabel
      Left = 21
      Top = 11
      Width = 88
      Height = 13
      Hint = #23548#20986#37197#32622#30340#39033#30446#26041#26696#65292#21521#19979#31661#22836#26032#22686#19968#20010#65292'CTRL+DEL'#21024#38500#19968#20010
      Caption = #36755#20986#37197#32622#30340#26041#26696':'
    end
    object btnSave: TBitBtn
      Left = 16
      Top = 36
      Width = 81
      Height = 35
      Hint = #25353#24403#21069#26041#26696#20445#23384#39057#36947#25968#25454#25991#20214'(TXT'#65292'M3U)'#21040#25351#23450#30340#25991#20214#21517#25110#20998#21106#30446#24405
      Caption = #20445#23384'(&S)'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object dbrgrpfEncode: TDBRadioGroup
      Left = 441
      Top = 7
      Width = 203
      Height = 33
      Hint = #20445#23384#25991#20214#26102#65292#25351#23450#30340#20869#23481#32534#30721#26684#24335
      Caption = #23383#31526#32534#30721
      Columns = 3
      DataField = 'fEncode'
      DataSource = ds1
      Items.Strings = (
        'ASCII'
        'UTF-8'
        'UNICODE')
      ParentBackground = True
      TabOrder = 1
      Values.Strings = (
        '0'
        '1'
        '2')
    end
    object dbrgrpfFormat: TDBRadioGroup
      Left = 304
      Top = 7
      Width = 105
      Height = 33
      Hint = #20445#23384#25991#20214#26102#20351#29992#30340#36755#20986#25991#20214#26684#24335
      Caption = #25991#20214#26684#24335
      Columns = 2
      DataField = 'fFormat'
      DataSource = ds1
      Items.Strings = (
        'TEXT'
        'M3U8')
      ParentBackground = True
      TabOrder = 2
      Values.Strings = (
        '0'
        '1')
      OnChange = dbrgrpfFormatChange
    end
    object dbchk1Tag: TDBCheckBox
      Left = 304
      Top = 49
      Width = 137
      Height = 17
      Hint = #20998#31867#21517#21518#26159#21542#21152#21518#32512',#genre#'#65292#20165'TEXT'#26684#24335#20445#23384#26102#26377#25928
      Caption = #20998#31867#21152#19978'",#genre#"'
      DataField = 'fGrpTag'
      DataSource = ds1
      TabOrder = 3
      ValueChecked = 'True'
      ValueUnchecked = 'False'
      OnClick = dbrgrpfFormatChange
    end
    object dbchk1Combi: TDBCheckBox
      Left = 447
      Top = 47
      Width = 161
      Height = 17
      Hint = #24403#19968#20010#39057#36947#26377#22810#20010#28304#38142#25509#26102#65292#26159#21542#20445#23384#22312#19968#34892#20869#24182#20197'#'#21495#38548#24320
      Caption = #21333#34892#39057#36947#65292#21508#28304#20197'"#"'#38548#24320
      DataField = 'fOneline'
      DataSource = ds1
      TabOrder = 4
      ValueChecked = 'True'
      ValueUnchecked = 'False'
      OnClick = dbrgrpfFormatChange
    end
    object dbchk1Split: TDBCheckBox
      Left = 304
      Top = 72
      Width = 137
      Height = 17
      Hint = #22810#20010#20998#31867#20197#20998#31867#21517#20026#25991#20214#21517#31216#65292#20445#23384#20110#25351#23450#30340#30446#24405#20869#12290
      Caption = #25353#20998#31867#21517#20998#21106#22810#25991#20214
      DataField = 'fSplit'
      DataSource = ds1
      TabOrder = 5
      ValueChecked = 'True'
      ValueUnchecked = 'False'
      OnClick = dbrgrpfFormatChange
    end
    object dbedt1Dir: TDBEdit
      Left = 493
      Top = 70
      Width = 151
      Height = 21
      Hint = #36755#20986#30340#25991#20214#21517#25110#20998#21106#30446#24405#65292#31354#30333'="TV"'#12290#22914#26524#20026#39'#'#39#24320#22836#24182#20026#20998#21106#22810#25991#20214#26102#65292#21152'900#'#36215#30340#21069#32512
      Anchors = [akLeft, akTop, akRight]
      DataField = 'fDir'
      DataSource = ds1
      TabOrder = 6
    end
    object dbgrd1: TDBGrid
      Left = 115
      Top = 12
      Width = 171
      Height = 80
      Hint = #23548#20986#37197#32622#30340#39033#30446#26041#26696#65292#21521#19979#31661#22836#26032#22686#19968#20010#65292'CTRL+DEL'#21024#38500#19968#20010
      DataSource = ds1
      Options = [dgEditing, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 7
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'fName'
          Width = 148
          Visible = True
        end>
    end
  end
  object pgc1: TPageControl
    Left = 118
    Top = 97
    Width = 534
    Height = 406
    Align = alClient
    TabOrder = 1
  end
  object pnl2: TPanel
    Left = 0
    Top = 97
    Width = 115
    Height = 406
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'pnl2'
    TabOrder = 2
    object pnl3: TPanel
      Left = 0
      Top = 0
      Width = 115
      Height = 24
      Hint = #36755#20986#26102#30340#20998#31867#39034#24207#65292#19978#19979#25302#21160#21487#37325#26032#25490#21015
      Align = alTop
      BevelOuter = bvNone
      Caption = #20998#31867#25490#24207
      TabOrder = 0
    end
    object lstGrp: TListBox
      Left = 0
      Top = 24
      Width = 115
      Height = 382
      Hint = #36755#20986#26102#30340#20998#31867#39034#24207#65292#19978#19979#25302#21160#21487#37325#26032#25490#21015
      Align = alClient
      DragMode = dmAutomatic
      ItemHeight = 13
      TabOrder = 1
      OnClick = lstgrpClick
      OnDragDrop = lstGrpDragDrop
      OnDragOver = lstGrpDragOver
    end
  end
  object qrycfg: TADOQuery
    Connection = fmain.conEDB
    CursorType = ctStatic
    AfterPost = qrycfgAfterPost
    Parameters = <>
    SQL.Strings = (
      'select * from savecfg')
    Left = 120
    Top = 32
  end
  object ds1: TDataSource
    DataSet = qrycfg
    Left = 160
    Top = 32
  end
  object dtsp: TDataSetProvider
    DataSet = fmain.qryDatV
    Left = 552
    Top = 96
  end
  object cds1: TClientDataSet
    Aggregates = <>
    Params = <>
    OnFilterRecord = cds1FilterRecord
    Left = 584
    Top = 96
  end
  object tmrReGen: TTimer
    Enabled = False
    Interval = 300
    OnTimer = tmrReGenTimer
    Left = 616
    Top = 96
  end
end
