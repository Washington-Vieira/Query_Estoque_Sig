SELECT 
    m.data_movimento,
    pe.nome AS empresa,
    g.nome AS grupo,
    p.cod_produto,
    p.nome AS produto,
    m.preco_medio,
    COALESCE(saldo.quantidade, 0) AS qtd_saldo,
    COALESCE(saldo.valor, 0) AS custo_medio,
    COUNT(*) AS qtd_registros
FROM
    relatorios.movimentacao_produtos_com_lucro_bruto_medio(
        47058, 
        1000, 
        2, 
        0, 
        '09/09/2024', -- Data inicial
        '09/09/2024'   -- Data final como data atual
    ) m
INNER JOIN produtos p ON (m.cod_produto = p.cod_produto)
INNER JOIN grupos g ON (p.cod_grupo = g.cod_grupo)
INNER JOIN pessoas pe ON (m.cod_empresa = pe.cod_pessoa)
LEFT JOIN relatorios.saldos_produtos_com_preco_medio(
        47058,
        1000,
        2,
        0,  
        current_date  
    ) AS saldo
    ON (m.cod_produto = saldo.cod_produto AND m.cod_empresa = saldo.cod_empresa)
WHERE
    m.tipo_lancamento IN ('V')
    AND p.tipo IN ('U','C','M','D','P')
    AND m.data_movimento BETWEEN '09/09/2024' AND '09/09/2024'
GROUP BY
    m.data_movimento,
    pe.nome,
    p.cod_produto,
    p.nome,
    g.nome,
    m.preco_medio,
    saldo.quantidade,
    saldo.valor
HAVING COUNT(*) > 0;
