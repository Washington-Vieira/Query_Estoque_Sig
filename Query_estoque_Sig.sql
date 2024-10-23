     SELECT
    data_movimento,
    pe.nome AS empresa,
    g.nome AS grupo,
    p.cod_produto,
    p.nome AS produto,
    SUM(m.valor) AS valor,
    SUM(m.quantidade) AS quantidade,
    SUM(m.tributos_sobre_vendas) AS tributos_sobre_vendas,
    m.preco_medio,
    COALESCE(saldo.quantidade, 0) AS qtd_saldo,
    COALESCE(saldo.valor, 0) AS custo_medio
FROM
    relatorios.movimentacao_produtos_com_lucro_bruto_medio(
        47058, 
        0, 
        2, 
        0, 
        '01/01/2023',  -- Data inicial
        current_date   -- Data final como data atual
    ) m  
INNER JOIN produtos p ON (m.cod_produto = p.cod_produto)
INNER JOIN grupos g ON (p.cod_grupo = g.cod_grupo)
INNER JOIN pessoas pe ON (m.cod_empresa = pe.cod_pessoa)
LEFT JOIN relatorios.saldos_produtos_com_preco_medio(
        0,
        0,
        '70, 90',
        0,  -- saldo para todos os depósitos
        current_date  -- Data de referência para o saldo
    ) AS saldo
    ON (m.cod_produto = saldo.cod_produto AND m.cod_empresa = saldo.cod_empresa)
WHERE
    m.tipo_lancamento IN ('V')
    AND p.tipo IN ('U','C','M','D','P')
    AND m.data_movimento BETWEEN '01/01/2023' AND current_date
GROUP BY
    m.data_movimento,
    pe.nome,
    p.cod_produto,
    p.nome,
    g.nome,
    m.preco_medio,
    saldo.quantidade,
    saldo.valor
