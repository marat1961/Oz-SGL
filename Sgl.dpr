program Sgl;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Oz.SGL.Heap in 'src\Oz.SGL.Heap.pas',
  Oz.SGL.Collections in 'src\Oz.SGL.Collections.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
