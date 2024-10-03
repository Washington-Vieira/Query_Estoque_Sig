WITH precos_medios AS (
  SELECT
    cod_empresa,
    cod_produto,
    cod_deposito,
    data_movimento,
    
    -- Preço médio por depósito e data
    CAST(MAX(COALESCE(preco_medio, 0)) AS numeric(18,8)) AS preco_medio,
    
    tipo_lancamento,
    SUM(CASE WHEN tipo_lancamento = 'V' THEN valor ELSE -valor END) AS total_valor_vendas,
    SUM(tributos_sobre_vendas) AS total_tributos_sobre_vendas -- Para as devoluções, os tributos sobre vendas já estão negativos
  FROM
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
  data_movimento,
  cod_empresa,
  empresa,
  id_classe,
  classe,
  cod_responsavel,
  responsavel,
  id_grupo,
  grupo,
  cod_produto,
  produto,
  preco,
  preco_medio,
  SUM(CASE WHEN tipo_lancamento = 'X' THEN -quantidade ELSE quantidade END) AS total_quantidade,
  SUM(CASE WHEN tipo_lancamento = 'X' THEN -custo ELSE custo END) AS custo_total,
  SUM(CASE WHEN tipo_lancamento = 'X' THEN -valor ELSE valor END) AS total_valor,
  SUM(CASE WHEN tipo_lancamento = 'X' THEN -(valor - custo - tributos_sobre_venda) ELSE (valor - custo - tributos_sobre_venda) END) AS lucro_medio,
  SUM(CASE WHEN tipo_lancamento = 'X' THEN -tributos_sobre_venda ELSE tributos_sobre_venda END) AS total_tributos_sobre_venda
FROM
  (
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
      lp.data_movimento,
      lp.quantidade,
      CAST(lp.quantidade * pm.preco_medio AS numeric(14,2)) AS custo,
      lp.valor,
      CAST(lp.valor * (CASE WHEN total_valor_vendas <> 0 THEN (total_tributos_sobre_vendas / total_valor_vendas) ELSE 0 END) 
      AS numeric(14,2)) AS tributos_sobre_venda
    FROM
      lancamentos_produtos lp
      INNER JOIN produtos pr ON (lp.cod_produto = pr.cod_produto)
      LEFT JOIN precos_medios pm ON (lp.cod_empresa = pm.cod_empresa AND lp.cod_produto = pm.cod_produto 
        AND lp.data_movimento = pm.data_movimento AND COALESCE(lp.cod_deposito, 0) = COALESCE(pm.cod_deposito, 0)
        AND lp.tipo_lancamento = pm.tipo_lancamento)
      INNER JOIN grupos gr ON (pr.cod_grupo = gr.cod_grupo)
      INNER JOIN lancamentos_financeiros lf ON (lp.cod_lanc_financeiro = lf.cod_lanc_financeiro)
      INNER JOIN pessoas pe ON (lf.cod_pessoa = pe.cod_pessoa)
      INNER JOIN classes cl ON (pe.cod_classe = cl.cod_classe)
      INNER JOIN pessoas em ON (em.cod_pessoa = lp.cod_empresa)
    WHERE
      (COALESCE(0, lp.cod_empresa) = 0) AND
      (COALESCE(0, lf.cod_pessoa) = 0) AND
      lp.data_movimento BETWEEN '01/10/2024' AND current_date AND
      lp.situacao = 2 AND
      NOT lp.cancelado AND
      lp.tipo_lancamento IN ('V', 'X')
  ) AS mov
GROUP BY
  cod_empresa,
  empresa,
  id_classe,
  classe,
  cod_responsavel,
  responsavel,
  id_grupo,
  grupo,
  cod_produto,
  produto,
  preco,
  preco_medio,
  data_movimento
ORDER BY
  cod_empresa,
  converte_id_para_comparar(id_classe),
  cod_responsavel,
  converte_id_para_comparar(id_grupo),
  cod_produto;
