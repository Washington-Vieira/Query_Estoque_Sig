with precos_medios as (
  select
    cod_empresa,
    cod_produto,
    cod_deposito,
    data_movimento,
	   
    /* É esperado que o preço médio seja único por depósito e data. Mas usamos a agregação para não ter que colocar o campo no GROUP BY, 
       pois poderia gerar divisão nos registros caso encontrasse, por algum erro no sistema, mais de um preço médio e isso causaria 
       sumarizações erradas na query principal por causa de lançamentos duplicados resultados no JOIN com precos_medios*/
    CAST(MAX(COALESCE(preco_medio,0)) AS numeric(18,8)) AS preco_medio,
	
    tipo_lancamento,
    SUM(CASE WHEN tipo_lancamento = 'V' THEN valor 
             ELSE -valor END) AS total_valor_vendas,
    SUM(tributos_sobre_vendas) AS total_tributos_sobre_vendas --Para as devoluções os tributos sobre vendas já estão negativos e são subtraídos no somatório.                                     
  from
   relatorios.movimentacao_produtos_com_lucro_bruto_medio(2, null, 0, null, '01/10/2024', current_date)
  WHERE
    tipo_lancamento IN ('V', 'X')                          
  GROUP BY
    cod_empresa,
    cod_produto,
    data_movimento,              
    cod_deposito,
    tipo_lancamento
)

SELECT
  cod_empresa,
  empresa,
  id_classe,
  classe,
  cod_responsavel,
  responsavel,
  id_grupo,
  grupo,
  sum(CASE WHEN tipo_lancamento = 'X' THEN -quantidade 
           ELSE quantidade END) as total_quantidade,
  sum(CASE WHEN tipo_lancamento = 'X' THEN -custo
           ELSE custo END) as custo_total,
  sum(CASE WHEN tipo_lancamento = 'X' THEN -valor
           ELSE valor END) as total_valor,
  sum(CASE WHEN tipo_lancamento = 'X' THEN -(valor - custo - tributos_sobre_venda)
           ELSE (valor - custo - tributos_sobre_venda) END) as lucro_medio,
  sum(CASE WHEN tipo_lancamento = 'X' THEN -tributos_sobre_venda
           ELSE tributos_sobre_venda END) as total_tributos_sobre_venda
FROM
  (select
     lp.cod_empresa,
     em.nome as empresa,
     cl.id as id_classe,
     cl.nome as classe,
     lf.cod_pessoa AS cod_responsavel,
     pe.nome_fantasia as responsavel,
     gr.id as id_grupo,
     gr.nome as grupo,
     lp.tipo_lancamento,
     lp.quantidade,
     CAST(lp.quantidade * pm.preco_medio AS numeric(14,2)) AS custo,
     lp.valor,
     CAST(lp.valor * (CASE WHEN total_valor_vendas <> 0 THEN (total_tributos_sobre_vendas/total_valor_vendas) ELSE 0 END) 
	   AS numeric(14,2)) AS tributos_sobre_venda
   from
     lancamentos_produtos lp
     inner join produtos pr ON (lp.cod_produto = pr.cod_produto)
     left join precos_medios pm ON (lp.cod_empresa = pm.cod_empresa AND lp.cod_produto = pm.cod_produto AND 
       lp.data_movimento = pm.data_movimento AND COALESCE(lp.cod_deposito,0) = COALESCE(pm.cod_deposito,0) AND --O depósito pode ser nulo no caso do serviços/receitas
       lp.tipo_lancamento = pm.tipo_lancamento)
     inner join grupos gr ON (pr.cod_grupo = gr.cod_grupo)
     inner join lancamentos_financeiros lf ON (lp.cod_lanc_financeiro = lf.cod_lanc_financeiro)
     inner join pessoas pe ON (lf.cod_pessoa = pe.cod_pessoa)
     inner join classes cl ON (pe.cod_classe = cl.cod_classe)
     inner join pessoas em on (em.cod_pessoa = lp.cod_empresa)
   where
     lp.cod_empresa = 2 and
     lf.cod_pessoa = 43463 and
     (lp.data_movimento between '01/10/2024' and current_date) and
     (lp.situacao = 2) and
     (not lp.cancelado) and
     (lp.tipo_lancamento IN ('V', 'X'))
     --(:p_cod_grupo = 0 or gr.id ilike :p_id_grupo || '%') and
    -- (:p_cod_classe = 0 or cl.id ilike :p_id_classe || '%')
  ) AS mov
group by
  cod_empresa,
  empresa,
  id_classe,
  classe,
  cod_responsavel,
  responsavel,
  id_grupo,
  grupo
order by
  cod_empresa,
  converte_id_para_comparar(id_classe),
  cod_responsavel,
  converte_id_para_comparar(id_grupo)