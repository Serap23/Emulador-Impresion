unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdTCPServer, IdContext, Vcl.StdCtrls, Printers,
  IdCustomTCPServer, ShellAPI, Vcl.ExtCtrls, Vcl.Menus;

type
  TForm1 = class(TForm)
    MemoLog: TMemo;
    //TrayIcon1: TTrayIcon;
    IdTCPServer1: TIdTCPServer;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    Cerrar: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    function FiltrarCaracteresASCII(const Texto: string): string;
    function ValoresNA(Valor : string) : boolean;
    procedure CerrarClick(Sender: TObject);
    procedure ImprimirConSaltoDeLinea(const Texto: string);

    private
    procedure Log(const Msg: string);
    procedure ImprimirEnImpresoraLocal(Datos: TStringList);
    procedure WMTrayIcon(var Msg: TMessage); message WM_USER + 1;
    Function CleanString(const s: string): string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  IdTCPServer1.DefaultPort := 9100;
  IdTCPServer1.Active := True;
  Log('Servidor en escucha en el puerto 9100');
  form1.Hide;

  // Inicializar el ícono de la bandeja del sistema
  TrayIcon1.Visible := True;
  TrayIcon1.Icon := Application.Icon;
  TrayIcon1.Hint := 'EmulatorPrint Jamensoft';
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
      // Si la línea está vacía, imprimir y reiniciar los datos acumulados
      if Datos.Count > 0 then
      begin
        ImprimirEnImpresoraLocal(Datos);
        Datos.Clear;
      end;
    end;

  until not AContext.Connection.Connected;

  // Imprimir las líneas acumuladas si hay alguna
  if Datos.Count > 0 then ImprimirEnImpresoraLocal(Datos);

  // Registrar en el memo que se han recibido y enviado todos los datos
  Log('Todos los datos recibidos y enviados a la impresora local.');
end;

procedure TForm1.ImprimirEnImpresoraLocal(Datos: TStringList);
var
  I : integer;
begin
  // Configurar la impresora local
  Printer.Printers[0];

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
end;

procedure TForm1.ImprimirConSaltoDeLinea(const Texto: string);
var
  Rect: TRect;
begin
  Printer.BeginDoc;
  try
    // Configurar el rectángulo de impresión
    Rect.Left := 10;
    Rect.Top := 10;
    Rect.Right := Printer.PageWidth - 10;
    Rect.Bottom := Printer.PageHeight - 10;

    // Imprimir el texto con un salto de línea al final
    //Printer.Canvas.TextRect(Rect, Texto + sLineBreak, [tfWordBreak]);
  finally
    Printer.EndDoc;
  end;
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

function Tform1.CleanString(const s: string): string;
var
  i: Integer;
begin
  // Convertir la cadena a mayúsculas
  Result := UpperCase(s);

  // Eliminar caracteres no alfanuméricos y no deseados
  for i := 1 to Length(Result) do
  begin
    if not (Result[i] in ['A'..'Z', '0'..'9']) then
      Result[i] := ' ';
  end;

  // Eliminar espacios en blanco adicionales
  Result := Trim(Result);
end;

function Tform1.FiltrarCaracteresASCII(const Texto: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Texto) do
  begin
    if Ord(Texto[I]) in [32..127] then
      Result := Result + Texto[I];
  end;
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

end.
