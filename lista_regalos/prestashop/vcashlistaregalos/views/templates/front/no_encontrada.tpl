{extends file='page.tpl'}

{block name='page_title'}
  {l s='Lista no disponible' d='Modules.Vcashlistaregalos.Shop'}
{/block}

{block name='page_content'}
  <p>{l s='Esta lista no existe o la familia ya la ha cerrado.' d='Modules.Vcashlistaregalos.Shop'}</p>
  <p><a href="{url entity='module' name='vcashlistaregalos' controller='buscar'}">{l s='Buscar una lista' d='Modules.Vcashlistaregalos.Shop'}</a></p>
{/block}
