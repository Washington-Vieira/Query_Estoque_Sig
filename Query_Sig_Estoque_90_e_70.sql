SELECT
  saldo.cod_empresa,
  e.nome AS nome_empresa,
  g.cod_grupo,                                         
  p.nome AS nome_produto,
  sum(saldo.quantidade) as qtd_saldo,
  u.sigla,                                   
  g.id,
  g.nome AS nome_grupo,
  p.tipo,
  saldo.preco_medio,
  sum(saldo.valor) as custo_medio,  
  sum(saldo.diferenca) as diferenca,
  (sum(saldo.quantidade) + sum(saldo.diferenca)) as qtd_saldo_com_diferenca, -- Nova coluna com a soma
  (CASE WHEN 90 <> 0 THEN (d.cod_deposito || ' - ' || d.nome) ELSE NULL END) AS info_contexto_deposito_especifico,
  (CASE WHEN 70 <> 0 THEN d.tipo_deposito ELSE NULL END) AS tipo_dep_contexto_deposito_especifico
FROM
  relatorios.saldos_produtos_com_preco_medio(0, 0, 0, 0, current_date -1) saldo
LEFT JOIN public.pessoas e ON (saldo.cod_empresa = e.cod_pessoa)
LEFT JOIN public.produtos p ON (saldo.cod_produto = p.cod_produto)
LEFT JOIN public.unidades_medida u ON (p.cod_unidade = u.cod_unidade)
LEFT JOIN public.grupos g ON (p.cod_grupo = g.cod_grupo)
LEFT JOIN public.depositos d ON (saldo.cod_deposito = d.cod_deposito and saldo.cod_empresa = d.cod_empresa)
WHERE
   (d.finalidade = 'V')           
GROUP BY
  saldo.cod_empresa,
  e.nome,
  g.cod_grupo,
  p.nome,
  u.sigla,           
  g.id,
  g.nome,
  p.tipo,
  saldo.preco_medio,
  info_contexto_deposito_especifico,
  tipo_dep_contexto_deposito_especifico
ORDER BY
  saldo.cod_empresa, 
  converte_id_para_comparar(g.id), 
  p.nome;
