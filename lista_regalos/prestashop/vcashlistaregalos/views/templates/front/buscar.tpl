{extends file='page.tpl'}

{block name='page_title'}
  {l s='Listas de regalos' d='Modules.Vcashlistaregalos.Shop'}
{/block}

{block name='page_content'}
  <section class="vclr-buscar">
    <p>{l s='Busque la lista por el nombre de los padres o del bebé, o escriba el código que le han dado.' d='Modules.Vcashlistaregalos.Shop'}</p>
    <form method="get" action="{$vclr_url_buscar}" class="vclr-formulario-buscar">
      <input type="hidden" name="fc" value="module">
      <input type="hidden" name="module" value="vcashlistaregalos">
      <input type="hidden" name="controller" value="buscar">
      <div class="input-group">
        <input class="form-control" type="search" name="q" minlength="3" maxlength="100" required value="{$vclr_texto}" aria-label="{l s='Nombre o código de la lista' d='Modules.Vcashlistaregalos.Shop'}" placeholder="{l s='Nombre o código de la lista' d='Modules.Vcashlistaregalos.Shop'}">
        <span class="input-group-btn">
          <button class="btn btn-primary" type="submit">{l s='Buscar' d='Modules.Vcashlistaregalos.Shop'}</button>
        </span>
      </div>
    </form>

    {if $vclr_buscado}
      {if $vclr_resultados}
        <ul class="vclr-resultados">
          {foreach from=$vclr_resultados item=lista}
            <li>
              <a href="{$lista.url}">
                <strong>{$lista.titulo}</strong>
                {if $lista.homenajeado} · {$lista.homenajeado}{/if}
                {if $lista.fecha_evento} · {$lista.fecha_evento|date_format:'%d/%m/%Y'}{/if}
              </a>
            </li>
          {/foreach}
        </ul>
      {else}
        <p class="alert alert-warning">{l s='No hay ninguna lista con ese nombre o código.' d='Modules.Vcashlistaregalos.Shop'}</p>
      {/if}
    {/if}
  </section>
{/block}
