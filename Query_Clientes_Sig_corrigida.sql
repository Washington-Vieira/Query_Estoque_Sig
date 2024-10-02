WITH precos_medios AS (
  SELECT
    cod_empresa,
    cod_produto,
    cod_deposito,
    data_movimento,
	   
    /* Agregando o preço médio para evitar divisão de registros */
    CAST(MAX(COALESCE(preco_medio, 0)) AS numeric(18,8)) AS preco_medio,
	
    tipo_lancamento,
    SUM(CASE WHEN tipo_lancamento = 'V' THEN valor ELSE -valor END) AS total_valor_vendas,
    SUM(tributos_sobre_vendas) AS total_tributos_sobre_vendas
  FROM
    relatorios.movimentacao_produtos_com_lucro_bruto_medio(2, null, 0, null, '01/09/2024', current_date)
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
  mov.cod_empresa,
  mov.empresa,
  mov.id_classe,
  mov.classe,
  mov.cod_responsavel,
  mov.responsavel,
  mov.id_grupo,
  mov.grupo,
  mov.cod_produto,
  mov.produto,
  mov.preco,
  mov.preco_medio,
  
  /* Agregação de quantidade, custo, valor, lucro e tributos */
  SUM(CASE WHEN mov.tipo_lancamento = 'X' THEN -mov.quantidade ELSE mov.quantidade END) AS total_quantidade,
  SUM(CASE WHEN mov.tipo_lancamento = 'X' THEN -mov.custo ELSE mov.custo END) AS custo_total,
  SUM(CASE WHEN mov.tipo_lancamento = 'X' THEN -mov.valor ELSE mov.valor END) AS total_valor,
  SUM(CASE WHEN mov.tipo_lancamento = 'X' THEN -(mov.valor - mov.custo - mov.tributos_sobre_venda) 
           ELSE (mov.valor - mov.custo - mov.tributos_sobre_venda) END) AS lucro_medio,
  SUM(CASE WHEN mov.tipo_lancamento = 'X' THEN -mov.tributos_sobre_venda 
           ELSE mov.tributos_sobre_venda END) AS total_tributos_sobre_venda
FROM (
  SELECT
    lp.cod_empresa,
    em.nome AS empresa,
    cl.id AS id_classe,
    cl.nome AS classe,
    lf.cod_pessoa AS cod_responsavel,
    pe.nome_fantasia AS responsavel,
    gr.id AS id_grupo,
    gr.nome AS grupo,
    lp.cod_produto,
    pr.nome AS produto,
    lp.preco,
    pm.preco_medio,
    lp.tipo_lancamento,
    lp.quantidade,
    
    /* Cálculo de custo baseado no preço médio */
    CAST(lp.quantidade * pm.preco_medio AS numeric(14,2)) AS custo,
    lp.valor,
    
    /* Cálculo dos tributos sobre venda */
    CAST(lp.valor * 
         (CASE WHEN pm.total_valor_vendas <> 0 THEN (pm.total_tributos_sobre_vendas / pm.total_valor_vendas) ELSE 0 END)
         AS numeric(14,2)) AS tributos_sobre_venda
  FROM
    lancamentos_produtos lp
    INNER JOIN produtos pr ON (lp.cod_produto = pr.cod_produto)
    LEFT JOIN precos_medios pm ON (lp.cod_empresa = pm.cod_empresa) 
      AND lp.cod_produto = pm.cod_produto 
      AND lp.data_movimento = pm.data_movimento 
      AND COALESCE(lp.cod_deposito, 0) = COALESCE(pm.cod_deposito, 0)
      AND lp.tipo_lancamento = pm.tipo_lancamento
    INNER JOIN grupos gr ON (pr.cod_grupo = gr.cod_grupo)
    INNER JOIN lancamentos_financeiros lf ON (lp.cod_lanc_financeiro = lf.cod_lanc_financeiro)
    INNER JOIN pessoas pe ON (lf.cod_pessoa = pe.cod_pessoa)
    INNER JOIN classes cl ON (pe.cod_classe = cl.cod_classe)
    INNER JOIN pessoas em ON (em.cod_pessoa = lp.cod_empresa)
  WHERE
    (2 = 0 OR lp.cod_empresa = 0)
    AND (0 = 0 OR lf.cod_pessoa = 0)
    AND (lp.data_movimento BETWEEN '01/09/2024' AND current_date)
    AND lp.situacao = 2
    AND NOT lp.cancelado
    AND lp.tipo_lancamento IN ('V', 'X')
    AND (0 = 0 OR gr.id ILIKE 0 || '%')
    AND (0 = 0 OR cl.id ILIKE 0 || '%')
) AS mov
GROUP BY
  mov.cod_empresa,
  mov.empresa,
  mov.id_classe,
  mov.classe,
  mov.cod_responsavel,
  mov.responsavel,
  mov.id_grupo,
  mov.grupo,
  mov.cod_produto,
  mov.produto,
  mov.preco,
  mov.preco_medio
ORDER BY
  mov.cod_empresa,
  converte_id_para_comparar(mov.id_classe),
  mov.cod_responsavel,
  converte_id_para_comparar(mov.id_grupo),
  mov.cod_produto;