unit UfrmPrincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  OpenGLContext, gl;

type

  { Input }

  TEstadoInput = record
     vForward,
     vBackward,
     vStrafeLeft,
     vStrafeRight,
     vRotateLeft,
     vRotateRight: Boolean;
  end;

  TEstadoCamera = (
     etTopDown,
     etRelativa,
     etPerspectiva
  );

  { TfrmPrincipal }

  TfrmPrincipal = class(TForm)
    MainMenu1: TMainMenu;
    MenuArquivo: TMenuItem;
    MenuCameraRelativa: TMenuItem;
    MenuCameraTopDown: TMenuItem;
    MenuCameraPerspectiva: TMenuItem;
    MenuVisualizacaoWireframe: TMenuItem;
    MenuVisualizacaoPreencher: TMenuItem;
    MenuVisualizacao: TMenuItem;
    MenuPerspectiva: TMenuItem;
    MenuSair: TMenuItem;
    glControl: TOpenGLControl;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure glControlKeyDown(Sender: TObject; var Key: Word;
          {%H-}Shift: TShiftState);
    procedure glControlKeyUp(Sender: TObject; var Key: Word;
          {%H-}Shift: TShiftState);
    procedure glControlMakeCurrent(Sender: TObject; var Allow: boolean);
    procedure glControlPaint(Sender: TObject);
    procedure MenuCameraPerspectivaClick(Sender: TObject);
    procedure MenuCameraRelativaClick(Sender: TObject);
    procedure MenuCameraTopDownClick(Sender: TObject);
    procedure MenuSairClick(Sender: TObject);
    procedure MenuVisualizacaoPreencherClick(Sender: TObject);
    procedure MenuVisualizacaoWireframeClick(Sender: TObject);
  private
    // Coordenadas para o segmento de linha representando uma "parede"
    vx1, vy1, vx2, vy2: Single;

    // Posição do jogador
    px, py, angulo: Single;

    vInput: TEstadoInput;
    vEstado: TEstadoCamera;

    procedure DefineEstadoInput(pKey: Word; pEstado: Boolean);
    procedure MovimentaPeloInput;
    procedure InicializaVariaveis;
    procedure DesenhaMapa;
    procedure DesenhaMapaTransformado;
    procedure DesenhaMapaTransformadoPerspectiva;
    procedure DefineViewport(pLargura, pAltura: Integer);

    function cross(x1, y1, x2, y2: Single): Single;
    procedure intersecciona(x1, y1,  x2, y2,  x3, y3,  x4, y4: Single;
          out x, y: Single);
  public

  end;

Const
  LarguraInterna: Single = 100;
  AlturaInterna: Single  = 100;
  Paredes: Array [0 .. 34] of Single = (
  {  x1  y1   x2  y2   r  g  b  }
     70, 20,  70, 70,  1, 1, 0, // Amarelo
     40, 90,  70, 70,  1, 0, 1, // Magenta
     20, 80,  40, 90,  1, 0, 0, // Vermelho
     20, 80,  50, 10,  0, 1, 1, // Ciano
     50, 10,  70, 20,  0, 1, 0  // Verde
  );

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.lfm}

{ TfrmPrincipal }

procedure TfrmPrincipal.MenuSairClick(Sender: TObject);
begin
   Application.Terminate;
end;

procedure TfrmPrincipal.MenuVisualizacaoPreencherClick(Sender: TObject);
begin
   glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
end;

procedure TfrmPrincipal.MenuVisualizacaoWireframeClick(Sender: TObject);
begin
   glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
end;

procedure TfrmPrincipal.DefineEstadoInput(pKey: Word; pEstado: Boolean);
begin
   case pKey of
   87: vInput.vForward     := pEstado; // W
   38: vInput.vForward     := pEstado; // Seta cima
   83: vInput.vBackward    := pEstado; // S
   40: vInput.vBackward    := pEstado; // Seta baixo
   65: vInput.vStrafeLeft  := pEstado; // A
   68: vInput.vStrafeRight := pEstado; // D
   37: vInput.vRotateLeft  := pEstado; // Seta esquerda
   39: vInput.vRotateRight := pEstado; // Seta direita
   end;
end;

procedure TfrmPrincipal.MovimentaPeloInput;
begin
   if vInput.vForward then
   begin
      px := px + Cos(angulo);
      py := py + Sin(angulo);
   end;

   if vInput.vBackward then
   begin
      px := px - Cos(angulo);
      py := py - Sin(angulo);
   end;

   if vInput.vStrafeLeft then
   begin
      px := px + Sin(angulo);
      py := py - Cos(angulo);
   end;

   if vInput.vStrafeRight then
   begin
      px := px - Sin(angulo);
      py := py + Cos(angulo);
   end;

   if vInput.vRotateLeft then
   begin
      angulo := angulo - 0.1;
   end;

   if vInput.vRotateRight then
   begin
      angulo := angulo + 0.1;
   end;
end;

procedure TfrmPrincipal.InicializaVariaveis;
begin
   vEstado := etTopDown;

   vx1    := 70.0;
   vy1    := 20.0;
   vx2    := 70.0;
   vy2    := 70.0;
   px     := 50.0;
   py     := 50.0;
   angulo := 0;

   vInput.vBackward    := False;
   vInput.vForward     := False;
   vInput.vRotateLeft  := False;
   vInput.vRotateRight := False;
   vInput.vStrafeLeft  := False;
   vInput.vStrafeRight := False;
end;

procedure TfrmPrincipal.DesenhaMapa;
   procedure DesenhaParede(I: Integer);
   begin
      I := I * 7;
      glPushMatrix;
         glColor4f(Paredes[I + 4], Paredes[I + 5], Paredes[I + 6], 1);
         glBegin(GL_LINES);
            glVertex2f(Paredes[I], Paredes[I + 1]);
            glVertex2f(Paredes[I + 2], Paredes[I + 3]);
         glEnd;
      glPopMatrix;
   end;
var
   I: Integer;
begin
   glPointSize(3);

   // Paredes
   for I := 0 to 4 do
       DesenhaParede(I);

   // Jogador
   glPushMatrix;
      glColor4f(0.3, 0.3, 0.3, 1);
      glBegin(GL_LINES);
         glVertex2f(px, py);
         glVertex2f(Cos(angulo) * 5.0 + px, Sin(angulo) * 5.0 + py);
      glEnd;

      glColor4f(1, 1, 1, 1);
      glBegin(GL_POINTS);
         glVertex2f(px, py);
      glEnd;
   glPopMatrix;
   glPointSize(1);
end;

procedure TfrmPrincipal.DesenhaMapaTransformado;
   procedure DesenhaParedeTransformada(I: Integer);
   var
      tx1, ty1, tx2, ty2, tz1, tz2: Single;
   begin
      I := I * 7;
      // Transforma os vértices relativos ao jogador
      tx1 := Paredes[I] - px;
      ty1 := Paredes[I + 1] - py;
      tx2 := Paredes[I + 2] - px;
      ty2 := Paredes[I + 3] - py;

      // Rotaciona os vértices ao redor da visão do jogador
      tz1 := tx1 * Cos(angulo) + ty1 * Sin(angulo);
      tz2 := tx2 * Cos(angulo) + ty2 * Sin(angulo);
      tx1 := tx1 * Sin(angulo) - ty1 * Cos(angulo);
      tx2 := tx2 * Sin(angulo) - ty2 * Cos(angulo);

      glPushMatrix;
         glColor4f(Paredes[I + 4], Paredes[I + 5], Paredes[I + 6], 1);
         glBegin(GL_LINES);
            glVertex2f(50 - tx1, 50 - tz1);
            glVertex2f(50 - tx2, 50 - tz2);
         glEnd;
      glPopMatrix;
   end;
var
   I: Integer;
begin
   glPointSize(3);

   // Paredes
   for I := 0 to 4 do
       DesenhaParedeTransformada(I);

   // Jogador
   glPushMatrix;
      glColor4f(0.3, 0.3, 0.3, 1);
      glBegin(GL_LINES);
         glVertex2f(50, 50);
         glVertex2f(50, 45);
      glEnd;

      glColor4f(1, 1, 1, 1);
      glBegin(GL_POINTS);
         glVertex2f(50, 50);
      glEnd;
   glPopMatrix;
   glPointSize(1);
end;

procedure TfrmPrincipal.DesenhaMapaTransformadoPerspectiva;
   procedure DesenhaParedePerspectiva(I: Integer);
   var
      tx1, ty1, tx2, ty2, tz1, tz2,
      x1,  y1a, y1b, x2,  y2a, y2b,
      ix1, iz1, ix2, iz2: Single;
   begin
      I := I * 7;

      tx1 := Paredes[I] - px;
      ty1 := Paredes[I + 1] - py;
      tx2 := Paredes[I + 2] - px;
      ty2 := Paredes[I + 3] - py;
      tz1 := tx1 * Cos(angulo) + ty1 * Sin(angulo);
      tz2 := tx2 * Cos(angulo) + ty2 * Sin(angulo);
      tx1 := tx1 * Sin(angulo) - ty1 * Cos(angulo);
      tx2 := tx2 * Sin(angulo) - ty2 * Cos(angulo);

      // Cálculos de perspectiva e renderização da parede.
      // Só será desenhada se estivermos à sua frente.
      if (tz1 > 0) or (tz2 > 0) then
      begin
         // Se a linha cruza o viewplane do jogador, corte-a.
         intersecciona(tx1, tz1,  tx2, tz2,  -0.0001, 0.0001, -20, 5, ix1, iz1);
         intersecciona(tx1, tz1,  tx2, tz2,   0.0001, 0.0001,  20, 5, ix2, iz2);

         if (tz1 <= 0) then
         begin
            if (iz1 > 0) then
            begin
               tx1 := ix1;
               tz1 := iz1;
            end
            else
            begin
               tx1 := ix2;
               tz1 := iz2;
            end;
         end;

         if (tz2 <= 0) then
         begin
            if (iz1 > 0) then
            begin
               tx2 := ix1;
               tz2 := iz1;
            end
            else
            begin
               tx2 := ix2;
               tz2 := iz2;
            end;
         end;


         x1  := -tx1 * 16 / tz1;
         y1a := -50 / tz1;
         y1b := 50 / tz1;

         x2  := -tx2 * 16 / tz2;
         y2a := -50 / tz2;
         y2b := 50 / tz2;

         glPushMatrix;
            glColor4f(Paredes[I + 4], Paredes[I + 5], Paredes[I + 6], 1);
            glBegin(GL_QUADS);
               // Topo
               glVertex2f(50 + x1, 50 + y1a);
               glVertex2f(50 + x2, 50 + y2a);

               // Direita
               // glVertex2f(50 + x2, 50 + y2a);
               glVertex2f(50 + x2, 50 + y2b);

               // Chão
               glVertex2f(50 + x1, 50 + y1b);
               // glVertex2f(50 + x2, 50 + y2b);

               // Esquerda
               //glVertex2f(50 + x1, 50 + y1a);
               glVertex2f(50 + x1, 50 + y1b);
            glEnd;
         glPopMatrix;
      end;
   end;
var
  I: Integer;
begin
   glPointSize(3);

   // Paredes
   for I := 0 to 4 do
       DesenhaParedePerspectiva(I);

   glPointSize(1);
end;

procedure TfrmPrincipal.DefineViewport(pLargura, pAltura: Integer);
begin
   glClearColor(0, 0, 0, 1);
   glEnable(GL_DEPTH_TEST);

   glViewport(0, 0, pLargura, pAltura);
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity;
   // Eixo Y cresce para baixo, origem no canto superior esquerdo
   glOrtho(0, LarguraInterna, AlturaInterna, 0, -1, 1);
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity;
end;

function TfrmPrincipal.cross(x1, y1, x2, y2: Single): Single;
begin
   Result := x1 * y2 - y1 * x2;
end;

procedure TfrmPrincipal.intersecciona(x1, y1, x2, y2, x3, y3, x4, y4: Single;
      out x, y: Single);
var
  det: Single;
begin
   x   := cross(x1, y1,  x2, y2);
   y   := cross(x3, y3,  x4, y4);
   det := cross(x1 - x2, y1 - y2, x3 - x4, y3 - y4);
   x   := cross(x, x1 - x2, y, x3 - x4) / det;
   y   := cross(x, y1 - y2, y, y3 - y4) / det;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
   InicializaVariaveis;
   glControl.Invalidate;
   Application.AddOnIdleHandler(@ApplicationIdle);
end;

procedure TfrmPrincipal.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
   Done := False;
   MovimentaPeloInput;
   glControl.Invalidate;
end;

procedure TfrmPrincipal.FormResize(Sender: TObject);
begin
   DefineViewport(Width, Height);
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
   if glControl.CanSetFocus then
      glControl.SetFocus;
end;

procedure TfrmPrincipal.glControlKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
begin
   case Key of
   Ord('Q'): Application.Terminate;
   49: vEstado := etTopDown;
   50: vEstado := etRelativa;
   51: vEstado := etPerspectiva;
   end;

   DefineEstadoInput(Key, True);
end;

procedure TfrmPrincipal.glControlKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
begin
   DefineEstadoInput(Key, False);
end;

procedure TfrmPrincipal.glControlMakeCurrent(Sender: TObject;
      var Allow: boolean);
begin
   if Allow then
      DefineViewport(Width, Height);
end;

procedure TfrmPrincipal.glControlPaint(Sender: TObject);
begin
   glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

   glPushMatrix;
      case vEstado of
      etTopDown:     DesenhaMapa;
      etRelativa:    DesenhaMapaTransformado;
      etPerspectiva: DesenhaMapaTransformadoPerspectiva;
      end;
   glPopMatrix;

   glControl.SwapBuffers;
end;

procedure TfrmPrincipal.MenuCameraPerspectivaClick(Sender: TObject);
begin
   vEstado := etPerspectiva;
end;

procedure TfrmPrincipal.MenuCameraRelativaClick(Sender: TObject);
begin
   vEstado := etRelativa;
end;

procedure TfrmPrincipal.MenuCameraTopDownClick(Sender: TObject);
begin
   vEstado := etTopDown;
end;

end.

