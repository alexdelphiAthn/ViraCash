<div class="vclr-carrito card card-block">
  <h2 class="h5">{l s='Regalos de listas en este carrito' d='Modules.Vcashlistaregalos.Shop'}</h2>
  <ul>
    {foreach from=$vclr_reservas item=reserva}
      <li>
        {$reserva.cantidad} × {$reserva.descripcion}
        — {$reserva.titulo}
        {if $reserva.nombre}({l s='de %nombre%' sprintf=['%nombre%' => $reserva.nombre] d='Modules.Vcashlistaregalos.Shop'}){/if}
      </li>
    {/foreach}
  </ul>
  <p class="small">{l s='Los regalos quedan apartados para usted durante un tiempo limitado; finalice el pedido para que cuenten en la lista.' d='Modules.Vcashlistaregalos.Shop'}</p>
</div>
