program events;
{$APPTYPE CONSOLE}
{$RTTI EXPLICIT METHODS([vcPublic, vcPublished])
                PROPERTIES([vcPublic, vcPublished])
                FIELDS([vcPrivate, vcProtected, vcPublic])}

uses
  System.SysUtils,
  Spring,
  Spring.Events;

type
  TPedido = record
    ID: Integer;
    Cliente: string;
    Total: Double;
    Email: string;
    Cupon:string;
  end;

  // Activa RTTI para este tipo
  {$M+}
  TPedidoEvent = reference to procedure(Sender: TObject; var Pedido: TPedido);
  {$M-}

  TGestorPedidos = class
  private
    FOnPedidoPagado: Event<TPedidoEvent>;
  public
    procedure ProcesarPago(AID: Integer; ACliente: string; ATotal: Double; AEmail: string);
    property OnPedidoPagado: Event<TPedidoEvent> read FOnPedidoPagado;
  end;

procedure TGestorPedidos.ProcesarPago(AID: Integer; ACliente: string; ATotal: Double; AEmail: string);
var
  Pedido: TPedido;
begin
  Pedido.ID := AID;
  Pedido.Cliente := ACliente;
  Pedido.Total := ATotal;
  Pedido.Email := AEmail;

  Writeln('--- Procesando pago en el Gestor ---');

  // Disparo del evento
  FOnPedidoPagado.Invoke(Self, Pedido);
end;

var
  Gestor: TGestorPedidos;
begin
  Gestor := TGestorPedidos.Create;
  try
    // Suscriptor A: Marketing
    Gestor.OnPedidoPagado.Add(
      procedure(Sender: TObject; var Pedido: TPedido)
      begin
        if (Pedido.Total > 500) then
        begin
          Pedido.Cupon := 'PROMO_2026';
          Writeln('Marketing: Se ha generado un cupón para ' + Pedido.Cliente);
        end;

      end
    );

    // Suscriptor B: Log
    Gestor.OnPedidoPagado.Add(
      procedure(Sender: TObject; var Pedido: TPedido)
      begin
        Writeln(Format('Log: Pedido %d procesado.', [Pedido.ID]));
      end
    );

    // Suscriptor C: Email al cliente
    Gestor.OnPedidoPagado.Add(
      procedure(Sender: TObject; var Pedido: TPedido)
      begin
        Writeln('Email: Enviado a ' + Pedido.Email);
      end
    );
    // EJECUCIÓN
    Gestor.ProcesarPago(101, 'Juan Perez', 600.00, 'juan@ejemplo.com');
    Writeln;
    Writeln('Presione Enter para salir...');
    Readln;
  finally
    Gestor.Free;
  end;
end.
