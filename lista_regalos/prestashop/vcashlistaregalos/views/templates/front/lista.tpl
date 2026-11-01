{extends file='page.tpl'}

{block name='page_title'}
  {$vclr_lista.titulo}
{/block}

{block name='page_content'}
  <section class="vclr-lista">
    <header class="vclr-cabecera">
      {if $vclr_lista.homenajeado}
        <p class="vclr-homenajeado">{$vclr_lista.homenajeado}</p>
      {/if}
      <p class="vclr-titulares">
        {l s='Lista de %titulares%' sprintf=['%titulares%' => $vclr_lista.titulares] d='Modules.Vcashlistaregalos.Shop'}
        {if $vclr_lista.fecha_evento}
          · {$vclr_lista.fecha_evento|date_format:'%d/%m/%Y'}
        {/if}
      </p>
      {if $vclr_lista.mensaje}
        <blockquote class="vclr-mensaje">{$vclr_lista.mensaje|escape:'html':'UTF-8'|nl2br nofilter}</blockquote>
      {/if}
      {if $vclr_lista.tipo_entrega == 'TIENDA'}
        <p class="alert alert-info">
          {l s='La familia recogerá los regalos en la tienda. Puede elegir la recogida en tienda al finalizar el pedido.' d='Modules.Vcashlistaregalos.Shop'}
        </p>
      {/if}
      <p class="vclr-clave">
        {l s='Código de la lista:' d='Modules.Vcashlistaregalos.Shop'}
        <strong>{$vclr_lista.clave}</strong>
      </p>
    </header>

    {if !$vclr_lineas}
      <p class="alert alert-warning">
        {l s='La familia todavía no ha añadido regalos a esta lista.' d='Modules.Vcashlistaregalos.Shop'}
      </p>
    {else}
      <form method="post" action="{$vclr_url}" class="vclr-invitado card card-block">
        <h2 class="h4">{l s='¿Quién regala?' d='Modules.Vcashlistaregalos.Shop'}</h2>
        <div class="row">
          <div class="col-md-6 form-group">
            <label for="vclr-nombre">{l s='Su nombre (lo verá la familia)' d='Modules.Vcashlistaregalos.Shop'}</label>
            <input id="vclr-nombre" class="form-control" type="text" name="nombre" maxlength="150" required value="{$vclr_formulario.nombre}">
          </div>
          <div class="col-md-6 form-group">
            <label for="vclr-email">{l s='Correo electrónico (opcional)' d='Modules.Vcashlistaregalos.Shop'}</label>
            <input id="vclr-email" class="form-control" type="email" name="email" maxlength="150" value="{$vclr_formulario.email}">
          </div>
        </div>
        <div class="form-group">
          <label for="vclr-mensaje">{l s='Mensaje para la familia (opcional)' d='Modules.Vcashlistaregalos.Shop'}</label>
          <textarea id="vclr-mensaje" class="form-control" name="mensaje" maxlength="500" rows="2">{$vclr_formulario.mensaje}</textarea>
        </div>
        <input type="hidden" name="token" value="{$vclr_token}">

        <ul class="vclr-lineas">
          {foreach from=$vclr_lineas item=linea}
            <li class="vclr-linea{if $linea.pendiente == 0} vclr-completa{/if}">
              {if !empty($linea.imagen)}
                <a href="{$linea.url}"><img src="{$linea.imagen}" alt="{$linea.descripcion}" loading="lazy"></a>
              {/if}
              <div class="vclr-datos">
                <p class="vclr-nombre">
                  {if !empty($linea.url)}<a href="{$linea.url}">{$linea.descripcion}</a>{else}{$linea.descripcion}{/if}
                  {if $linea.imprescindible}
                    <span class="badge badge-info">{l s='Imprescindible' d='Modules.Vcashlistaregalos.Shop'}</span>
                  {/if}
                </p>
                {if $linea.observaciones}
                  <p class="vclr-observaciones">{$linea.observaciones}</p>
                {/if}
                <p class="vclr-recuento">
                  {l s='Desean %deseada%, regalados %regalados%' sprintf=['%deseada%' => $linea.cantidad_deseada, '%regalados%' => $linea.regalado_total] d='Modules.Vcashlistaregalos.Shop'}
                  {if $linea.reservado_propio > 0}
                    · {l s='%n% en su carrito' sprintf=['%n%' => $linea.reservado_propio] d='Modules.Vcashlistaregalos.Shop'}
                  {/if}
                </p>
                {if !empty($linea.precio)}<p class="vclr-precio">{$linea.precio}</p>{/if}
              </div>
              <div class="vclr-accion">
                {if $linea.comprable}
                  {if $linea.variantes}
                    <select class="form-control form-control-select" name="variante_{$linea.linea}" aria-label="{l s='Talla o color' d='Modules.Vcashlistaregalos.Shop'}">
                      {foreach from=$linea.variantes item=variante}
                        <option value="{$variante.id}"{if $variante.id == $linea.id_product_attribute} selected{/if}>{$variante.nombre}</option>
                      {/foreach}
                    </select>
                  {/if}
                  <input class="form-control vclr-cantidad" type="number" name="cantidad_{$linea.linea}" min="1" max="{$linea.pendiente}" value="1" aria-label="{l s='Cantidad' d='Modules.Vcashlistaregalos.Shop'}">
                  <button class="btn btn-primary" type="submit" name="vclr_linea" value="{$linea.linea}">
                    {l s='Regalar' d='Modules.Vcashlistaregalos.Shop'}
                  </button>
                {elseif $linea.agotado && $linea.pendiente > 0}
                  <span class="vclr-estado">{l s='Agotado en la web; puede regalarlo en la tienda' d='Modules.Vcashlistaregalos.Shop'}</span>
                {elseif $linea.pendiente == 0 && $linea.reservado_otros > 0 && $linea.regalado_total < $linea.cantidad_deseada}
                  <span class="vclr-estado">{l s='Reservado por otro invitado' d='Modules.Vcashlistaregalos.Shop'}</span>
                {elseif $linea.pendiente == 0}
                  <span class="vclr-estado">{l s='Ya regalado' d='Modules.Vcashlistaregalos.Shop'}</span>
                {else}
                  <span class="vclr-estado">{l s='Disponible en la tienda' d='Modules.Vcashlistaregalos.Shop'}</span>
                {/if}
              </div>
            </li>
          {/foreach}
        </ul>
      </form>
    {/if}
    <p><a href="{$vclr_url_buscar}">{l s='Buscar otra lista' d='Modules.Vcashlistaregalos.Shop'}</a></p>
  </section>
{/block}
