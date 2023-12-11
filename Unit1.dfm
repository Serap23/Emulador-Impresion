object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object MemoLog: TMemo
    Left = 72
    Top = 8
    Width = 529
    Height = 417
    Lines.Strings = (
      'MemoLog')
    TabOrder = 0
  end
  object IdTCPServer1: TIdTCPServer
    Bindings = <>
    DefaultPort = 0
    OnExecute = IdTCPServer1Execute
    Left = 8
    Top = 16
  end
  object TrayIcon1: TTrayIcon
    Left = 16
    Top = 104
  end
  object PopupMenu1: TPopupMenu
    Left = 16
    Top = 208
    object Cerrar: TMenuItem
      Caption = 'Cerrar Emulator Print'
      OnClick = CerrarClick
    end
  end
end
