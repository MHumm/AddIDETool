object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'FormMain'
  ClientHeight = 72
  ClientWidth = 320
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 304
    Height = 56
    Caption = '&Click me!'
    TabOrder = 0
    OnClick = Button1Click
  end
end
