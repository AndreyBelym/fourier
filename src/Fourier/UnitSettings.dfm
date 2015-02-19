object Form2: TForm2
  Left = 884
  Top = 198
  HelpContext = 2
  BorderIcons = [biSystemMenu, biMinimize, biMaximize, biHelp]
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 387
  ClientWidth = 426
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 425
    Height = 353
    HelpContext = 2
    ActivePage = TabSheet2
    TabOrder = 0
    object TabSheet1: TTabSheet
      HelpContext = 9
      Caption = #1047#1085#1072#1095#1077#1085#1080#1103' '#1087#1086' '#1091#1084#1086#1083#1095#1072#1085#1080#1102
      OnShow = TabSheet1Show
      object GroupBox1: TGroupBox
        Left = 0
        Top = 8
        Width = 161
        Height = 209
        HelpContext = 9
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1072#1085#1072#1083#1080#1079#1072
        TabOrder = 0
        object Label13: TLabel
          Left = 8
          Top = 16
          Width = 62
          Height = 13
          HelpContext = 9
          Caption = #1058#1086#1095#1077#1082' '#1041#1055#1060':'
        end
        object Bevel2: TBevel
          Left = 8
          Top = 160
          Width = 145
          Height = 41
          HelpContext = 9
          Shape = bsFrame
        end
        object Label14: TLabel
          Left = 16
          Top = 152
          Width = 110
          Height = 13
          HelpContext = 9
          Caption = #1062#1074#1077#1090' '#1089#1087#1077#1082#1090#1088#1086#1075#1088#1072#1084#1084#1099
        end
        object cbxFFTCount: TComboBox
          Left = 80
          Top = 16
          Width = 73
          Height = 21
          HelpContext = 9
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 3
          TabOrder = 0
          Text = '8192'
          Items.Strings = (
            '1024'
            '2048'
            '4096'
            '8192'
            '16384')
        end
        object rgWindowFuncs: TRadioGroup
          Left = 8
          Top = 40
          Width = 145
          Height = 113
          HelpContext = 9
          Caption = #1054#1082#1086#1085#1085#1072#1103' '#1092#1091#1085#1082#1094#1080#1103
          ItemIndex = 2
          Items.Strings = (
            #1041#1077#1079' '#1086#1082#1086#1085#1085#1086#1081' '#1092#1091#1085#1082#1094#1080#1080
            #1054#1082#1085#1086' '#1061#1072#1085#1085#1072
            #1054#1082#1085#1086' '#1061#1101#1084#1084#1080#1085#1075#1072
            #1054#1082#1085#1086' '#1041#1083#1077#1082#1084#1072#1085#1072)
          TabOrder = 1
        end
        object clbSpectum: TColorBox
          Left = 16
          Top = 168
          Width = 129
          Height = 22
          HelpContext = 9
          Selected = clRed
          ItemHeight = 16
          TabOrder = 2
        end
      end
      object GroupBox2: TGroupBox
        Left = 0
        Top = 224
        Width = 217
        Height = 97
        HelpContext = 9
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' MIDI'
        TabOrder = 1
        object Label15: TLabel
          Left = 12
          Top = 44
          Width = 61
          Height = 13
          HelpContext = 9
          Caption = #1048#1085#1089#1090#1088#1091#1084#1077#1085#1090
        end
        object Label5: TLabel
          Left = 48
          Top = 72
          Width = 27
          Height = 13
          HelpContext = 9
          Caption = #1058#1077#1084#1087
        end
        object cbxInstruments: TComboBox
          Left = 80
          Top = 36
          Width = 129
          Height = 21
          HelpContext = 9
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 0
          Text = #39'AcousticGrandPiano'#39','
          Items.Strings = (
            #39'AcousticGrandPiano'#39','
            #39'BrightAcousticPiano'#39','
            #39'ElectricGrandPiano'#39','
            #39'HonkyTonkPiano'#39','
            #39'ElectricPiano1'#39','
            #39'ElectricPiano2'#39','
            #39'Harpsichord'#39','
            #39'Clavinet'#39','
            #39'Celesta'#39','
            #39'Glockenspiel'#39','
            #39'MusicBox'#39','
            #39'Vibraphone'#39','
            #39'Marimba'#39','
            #39'Xylophone'#39','
            #39'TubularBells'#39','
            #39'Dulcimer'#39','
            #39'DrawbarOrgan'#39','
            #39'PercussiveOrgan'#39','
            #39'RockOrgan'#39','
            #39'ChurchOrgan'#39','
            #39'ReedOrgan'#39','
            #39'Accordion'#39','
            #39'Harmonica'#39','
            #39'TangoAccordion'#39','
            #39'AcousticNylonGuitar'#39','
            #39'AcousticSteelGuitar'#39','
            #39'JazzElectricGuitar'#39','
            #39'CleanElectricGuitar'#39','
            #39'MutedElectricGuitar'#39','
            #39'OverdrivenGuitar'#39','
            #39'DistortionGuitar'#39','
            #39'GuitarHarmonics'#39','
            #39'AcousticBass'#39','
            #39'FingeredElectricBass'#39','
            #39'PickedElectricBass'#39','
            #39'FretlessBass'#39','
            #39'SlapBass1'#39','
            #39'SlapBass2'#39','
            #39'SynthBass1'#39','
            #39'SynthBass2'#39','
            #39'Violin'#39','
            #39'Viola'#39','
            #39'Cello'#39','
            #39'Contrabass'#39','
            #39'TremoloStrings'#39','
            #39'PizzicatoStrings'#39','
            #39'OrchestralHarp'#39','
            #39'Timpani'#39','
            #39'StringEnsemble1'#39','
            #39'StringEnsemble2'#39','
            #39'SynthStrings1'#39','
            #39'SynthStrings2'#39','
            #39'ChoirAahs'#39','
            #39'VoiceOohs'#39','
            #39'SynthVoice'#39','
            #39'OrchestraHit'#39','
            #39'Trumpet'#39','
            #39'Trombone'#39','
            #39'Tuba'#39','
            #39'MutedTrumpet'#39','
            #39'FrenchHorn'#39','
            #39'BrassSection'#39','
            #39'SynthBrass1'#39','
            #39'SynthBrass2'#39','
            #39'SopranoSax'#39','
            #39'AltoSax'#39','
            #39'TenorSax'#39','
            #39'BaritoneSax'#39','
            #39'Oboe'#39','
            #39'EnglishHorn'#39','
            #39'Bassoon'#39','
            #39'Clarinet'#39','
            #39'Piccolo'#39','
            #39'Flute'#39','
            #39'Recorder'#39','
            #39'PanFlute'#39','
            #39'BlownBottle'#39','
            #39'Shakuhachi'#39','
            #39'Whistle'#39','
            #39'Ocarina'#39','
            #39'SquareLead'#39','
            #39'SawtoothLead'#39','
            #39'CalliopeLead'#39','
            #39'ChiffLead'#39','
            #39'CharangLead'#39','
            #39'VoiceLead'#39','
            #39'FifthsLead'#39','
            #39'BassandLead'#39','
            #39'NewAgePad'#39','
            #39'WarmPad'#39','
            #39'PolySynthPad'#39','
            #39'ChoirPad'#39','
            #39'BowedPad'#39','
            #39'MetallicPad'#39','
            #39'HaloPad'#39','
            #39'SweepPad'#39','
            #39'SynthFXRain'#39','
            #39'SynthFXSoundtrack'#39','
            #39'SynthFXCrystal'#39','
            #39'SynthFXAtmosphere'#39','
            #39'SynthFXBrightness'#39','
            #39'SynthFXGoblins'#39','
            #39'SynthFXEchoes'#39','
            #39'SynthFXSciFi'#39','
            #39'Sitar'#39','
            #39'Banjo'#39','
            #39'Shamisen'#39','
            #39'Koto'#39','
            #39'Kalimba'#39','
            #39'Bagpipe'#39','
            #39'Fiddle'#39','
            #39'Shanai'#39','
            #39'TinkleBell'#39','
            #39'Agogo'#39','
            #39'SteelDrums'#39','
            #39'Woodblock'#39','
            #39'TaikoDrum'#39','
            #39'MelodicTom'#39','
            #39'SynthDrum'#39','
            #39'ReverseCymbal'#39','
            #39'GuitarFretNoise'#39','
            #39'BreathNoise'#39','
            #39'Seashore'#39','
            #39'BirdTweet'#39','
            #39'TelephoneRing'#39','
            #39'Helicopter'#39','
            #39'Applause'#39','
            #39'Gunshot'#39)
        end
        object chkAutosave: TCheckBox
          Left = 8
          Top = 16
          Width = 121
          Height = 17
          HelpContext = 9
          Caption = #1040#1074#1090#1086#1089#1086#1093#1088#1072#1085#1077#1085#1080#1077
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
        object cbxTempo: TComboBox
          Left = 80
          Top = 68
          Width = 129
          Height = 21
          HelpContext = 9
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 3
          TabOrder = 2
          Text = 'Andante (60 bpm)'
          Items.Strings = (
            'Largo (44 bpm)'
            'Adagio (50 bpm)'
            'Lento (55 bpm)'
            'Andante (60 bpm)'
            'Moderato (90 bpm)'
            'Allegretto (105 bpm)'
            'Allegro (120 bpm)'
            'Vivo (175 bpm)'
            'Presto (200 bpm)')
        end
      end
      object GroupBox3: TGroupBox
        Left = 168
        Top = 8
        Width = 161
        Height = 169
        HelpContext = 9
        Caption = 'GroupBox3'
        TabOrder = 2
        object Label9: TLabel
          Left = 5
          Top = 104
          Width = 68
          Height = 13
          HelpContext = 9
          Caption = #1050#1086#1083'-'#1074#1086' '#1090#1086#1095#1077#1082':'
        end
        object Bevel1: TBevel
          Left = 8
          Top = 48
          Width = 145
          Height = 41
          HelpContext = 9
          Shape = bsFrame
        end
        object Label1: TLabel
          Left = 13
          Top = 40
          Width = 28
          Height = 13
          HelpContext = 9
          Caption = #1062#1074#1077#1090':'
        end
        object chkListSpectr: TCheckBox
          Left = 8
          Top = 128
          Width = 137
          Height = 25
          HelpContext = 9
          Caption = #1055#1088#1086#1083#1080#1089#1090#1099#1074#1072#1090#1100' '#1089#1087#1077#1082#1090#1088#1086#1075#1088#1072#1084#1084#1091
          Checked = True
          State = cbChecked
          TabOrder = 0
          WordWrap = True
        end
        object edtWavPoints: TEdit
          Left = 80
          Top = 96
          Width = 73
          Height = 21
          HelpContext = 9
          TabOrder = 1
          Text = '250'
        end
        object clbWaveform: TColorBox
          Left = 16
          Top = 56
          Width = 129
          Height = 22
          HelpContext = 9
          DefaultColorColor = clBlue
          Selected = clNavy
          ItemHeight = 16
          TabOrder = 2
        end
        object chkWaveform: TCheckBox
          Left = 8
          Top = 16
          Width = 105
          Height = 17
          HelpContext = 9
          Caption = #1043#1088#1072#1092#1080#1082' '#1074#1086#1083#1085#1099
          Checked = True
          State = cbChecked
          TabOrder = 3
        end
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 10
      Caption = #1063#1072#1089#1090#1086#1090#1099' '#1085#1086#1090
      ImageIndex = 1
      OnShow = TabSheet2Show
      object Label2: TLabel
        Left = 160
        Top = 8
        Width = 249
        Height = 249
        HelpContext = 10
        AutoSize = False
        WordWrap = True
      end
      object StringGrid1: TStringGrid
        Left = 16
        Top = 8
        Width = 133
        Height = 305
        HelpContext = 10
        ColCount = 2
        RowCount = 12
        FixedRows = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
        TabOrder = 0
        OnSelectCell = StringGrid1SelectCell
        OnSetEditText = StringGrid1SetEditText
        RowHeights = (
          24
          24
          24
          24
          24
          24
          24
          24
          24
          24
          24
          24)
      end
    end
    object TabSheet3: TTabSheet
      HelpContext = 11
      Caption = #1048#1085#1089#1090#1088#1091#1084#1077#1085#1090#1099' MIDI'
      ImageIndex = 2
      OnShow = TabSheet3Show
      object Label3: TLabel
        Left = 8
        Top = 8
        Width = 127
        Height = 13
        HelpContext = 11
        Caption = #1044#1086#1089#1090#1091#1087#1085#1099#1077' '#1080#1085#1089#1090#1088#1091#1084#1077#1085#1090#1099
      end
      object Label4: TLabel
        Left = 248
        Top = 8
        Width = 147
        Height = 13
        HelpContext = 11
        Caption = #1048#1089#1087#1086#1083#1100#1079#1091#1077#1084#1099#1077' '#1080#1085#1089#1090#1088#1091#1084#1077#1085#1090#1099
      end
      object ListBox1: TListBox
        Left = 8
        Top = 24
        Width = 153
        Height = 233
        HelpContext = 11
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 0
      end
      object ListBox2: TListBox
        Left = 248
        Top = 24
        Width = 161
        Height = 233
        HelpContext = 11
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 1
      end
      object Button5: TButton
        Left = 168
        Top = 104
        Width = 73
        Height = 25
        HelpContext = 11
        Caption = '>>'
        TabOrder = 2
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 168
        Top = 144
        Width = 73
        Height = 25
        HelpContext = 11
        Caption = '<<'
        TabOrder = 3
        OnClick = Button6Click
      end
      object ComboBox3: TComboBox
        Left = 8
        Top = 272
        Width = 129
        Height = 21
        HelpContext = 11
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 4
        OnChange = ComboBox3Change
      end
      object ComboBox4: TComboBox
        Left = 144
        Top = 272
        Width = 65
        Height = 21
        HelpContext = 11
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 5
      end
      object ComboBox5: TComboBox
        Left = 208
        Top = 272
        Width = 105
        Height = 21
        HelpContext = 11
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 6
      end
      object Button7: TButton
        Left = 320
        Top = 272
        Width = 89
        Height = 25
        HelpContext = 11
        Caption = #1055#1088#1086#1089#1083#1091#1096#1072#1090#1100
        TabOrder = 7
        OnMouseDown = Button7MouseDown
        OnMouseUp = Button7MouseUp
      end
    end
  end
  object Button1: TButton
    Left = 256
    Top = 360
    Width = 81
    Height = 25
    HelpContext = 2
    Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 344
    Top = 360
    Width = 81
    Height = 25
    HelpContext = 2
    Caption = #1053#1077' '#1089#1086#1093#1088#1072#1085#1103#1090#1100
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 0
    Top = 360
    Width = 81
    Height = 25
    HelpContext = 2
    Caption = #1057#1095#1080#1090#1072#1090#1100
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 88
    Top = 360
    Width = 89
    Height = 25
    HelpContext = 2
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    TabOrder = 4
    OnClick = Button4Click
  end
end
