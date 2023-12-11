program EmuladorPrint;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
 Application.Initialize;
  Application.MainFormOnTaskbar := True;

  // Oculta la ventana principal
  Application.ShowMainForm := False;
  Application.CreateForm(TForm1, Form1);

  // Asegura que la aplicación continúe ejecutándose
  while not Application.Terminated do
  begin
    Application.ProcessMessages;
    // Puedes agregar aquí cualquier lógica adicional que necesites
  end;
end.
