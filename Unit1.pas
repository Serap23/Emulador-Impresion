unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdTCPServer, IdContext, Vcl.StdCtrls, Printers,
  IdCustomTCPServer, ShellAPI, Vcl.ExtCtrls, Vcl.Menus, system.IniFiles, IOUtils, system.DateUtils;

type
  TForm1 = class(TForm)
    MemoLog: TMemo;
    IdTCPServer1: TIdTCPServer;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    Cerrar: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    function ValoresNA(Valor : string) : boolean;
    procedure CerrarClick(Sender: TObject);

    private
    procedure Log(const Msg: string);
    procedure ImprimirEnImpresoraLocal(Datos: TStringList; ImpresoraNombre: string);
    procedure WMTrayIcon(var Msg: TMessage); message WM_USER + 1;
    procedure CargandoArchivoIni();
    procedure Addlog(Texto: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  ImpresoraNombre : string;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  CargandoArchivoIni();
  IdTCPServer1.DefaultPort := 9100;
  IdTCPServer1.Active := True;
  Addlog('Servidor en escucha en el puerto 9100');
  form1.Hide;

  // Inicializar el ícono de la bandeja del sistema
  TrayIcon1.Visible := True;
  TrayIcon1.Icon := Application.Icon;
  TrayIcon1.Hint := 'EmulatorPrint Conectado a: ' + ImpresoraNombre;
  TrayIcon1.PopupMenu := PopupMenu1;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  IdTCPServer1.Active := False;
end;

function GetDefaultPrinter: string;
var
  Buffer: array[0..255] of Char;
begin
  GetProfileString('windows', 'device', '', Buffer, SizeOf(Buffer));
  Result := Buffer;
end;

procedure TForm1.IdTCPServer1Execute(AContext: TIdContext);
const
Cortar = #$1B#$6D;
var
  Datos: TStringList;
  Linea: string;
begin
  // Inicializar la variable Datos
 Datos := TStringList.Create;

  repeat
    // Leer una línea del cliente
    Linea := AContext.Connection.IOHandler.ReadLn;

    // Si la línea no está vacía, agregarla a los datos acumulados
    if Linea <> Cortar then
    begin
      //Linea := FiltrarCaracteresASCII(Linea);
      if not valoresNA(Linea) then Datos.Add(Linea);
    end
    else
    begin
      // Si los datos no estan , imprimir y reiniciar los datos acumulados
      if Datos.Count > 0 then
      begin
        ImprimirEnImpresoraLocal(Datos, ImpresoraNombre);
        Datos.Clear;
      end;
    end;

  until not AContext.Connection.Connected;

  // Imprimir las líneas acumuladas si hay alguna
  if Datos.Count > 0 then ImprimirEnImpresoraLocal(Datos, ImpresoraNombre);

end;


procedure TForm1.ImprimirEnImpresoraLocal(Datos: TStringList; ImpresoraNombre: string);
var
  I, indexPrinter : integer;
begin

  // Buscar la impresora por nombre
  indexPrinter := -1;
  for I := 0 to Printer.Printers.Count - 1 do
  begin
    if SameText(Printer.Printers[I], ImpresoraNombre) then
    begin
      indexPrinter := I;
      Break;
    end;
  end;

  // Si la impresora no se encuentra, mostrar un mensaje de error y salir
  if indexPrinter = -1 then
  begin
    Addlog('No se encontró la impresora especificada: ' + ImpresoraNombre);
    Exit;
  end;

  // Configurar la impresora seleccionada
  Printer.PrinterIndex := indexPrinter;

  // Iniciar el trabajo de impresión
  Printer.BeginDoc;
  try
    for I := 0 to Datos.Count -1 do
    //EnviarComandosImpresoraDirecta(Datos[I]);
    Printer.Canvas.TextOut(10, I * Printer.Canvas.TextHeight('X'), Datos[I]);
  finally
    Printer.Canvas.TextOut(10,(I + 1) * Printer.Canvas.TextHeight('X'), ' ');
    Printer.EndDoc;
  end;

  Addlog('Todos los datos recibidos y enviados a la impresora local.');

end;



Function TForm1.valoresNA(Valor : string) : boolean;
var
  Lista : TstringList;
  Linea : string;
begin
  Lista := TstringList.Create;
  Result := false;

  Lista.add(#$1B#$61#$30);
  Lista.add(#$1B#$61#$31);
  lista.Add(#$1B'!'#0#$1B'a0');
  Lista.add(#$1B#$61#$32);
  Lista.add(#$1B#$21#$33);
  Lista.add(#$1B#$21#$00);
  Lista.add(#$1B#$40);
  Lista.add(#$1B#$64#$04);

  for linea in lista do
     if Valor = linea then Result := true;
end;

procedure TForm1.Log(const Msg: string);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + Msg);
end;

procedure TForm1.CerrarClick(Sender: TObject);
begin
  IdTCPServer1.Active := False;
  application.Terminate;
end;

procedure TForm1.WMTrayIcon(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_RBUTTONDOWN:
      begin
        // Mostrar el menú contextual en la posición actual del cursor
        SetForegroundWindow(Handle);
        PopupMenu1.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
      end;
  end;
end;


procedure TForm1.CargandoArchivoIni();
var
  ini : TIniFile;
  LocalPath,texto : string;
begin
  localpath := Tpath.GetFullPath(Application.ClassName).Replace('TApplication','conf.ini');
  Ini := Tinifile.Create(localpath);
  try
    ImpresoraNombre := Ini.ReadString('Impresion', 'NombreImpresora', '0');
  finally
    Ini.Free;
  end;
end;


procedure TForm1.Addlog(Texto: string);
var
  LogFile, BackupFile: TextFile;
  Text: string;
  LogFilePath, BackupFilePath: string;
  CurrentFileSizeKB: Integer;
  MaxFileSizeKB: Integer;
begin
  MaxFileSizeKB := 30000; // Limitando tamaño del archivo a 30 MB
  // Formateando Texto.
  Text := '[' + Now.ToString + ']' + '***' + Texto + '***';

  // Obtener la ruta completa del archivo de log
  LogFilePath := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetAppPath , 'logPrintJamen.txt');

  // Verificar y limitar el tamaño del archivo
  CurrentFileSizeKB := 0;
  if FileExists(LogFilePath) then CurrentFileSizeKB := Round(TFile.GetSize(LogFilePath) / 1024); // Convertir bytes a kilobytes

  if (CurrentFileSizeKB + (Length(Text) / 1024)) > MaxFileSizeKB then
  begin
    // El archivo excederá el tamaño máximo, realizar backup y truncar el archivo original
    BackupFilePath := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetAppPath, 'log-Npedidos1.txt');
    TFile.Copy(LogFilePath, BackupFilePath, True);

    // Truncar el archivo original
    Rewrite(LogFile);

    // Escribir el nuevo texto en el archivo original
    Writeln(LogFile, Text);
    CloseFile(LogFile);
  end
  else
  begin
    // Escribir Texto en el archivo original sin exceder el tamaño máximo
    try
      AssignFile(LogFile, LogFilePath);
      if FileExists(LogFilePath) then
        Append(LogFile)
      else
        Rewrite(LogFile);

      Writeln(LogFile, Text);
    finally
      CloseFile(LogFile);
    end;
  end;
end;


end.
