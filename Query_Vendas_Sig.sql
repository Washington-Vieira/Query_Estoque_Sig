SELECT
    data_movimento,
    pe.nome AS empresa,
    g.nome AS grupo,
    p.nome AS produto,
    SUM(valor) AS valor,
    SUM(quantidade) AS quantidade,
    sum(m.tributos_sobre_vendas) AS tributos_sobre_vendas,
    preco_medio
FROM
    relatorios.movimentacao_produtos_com_lucro_bruto_medio(
        0, 
        0, 
        0, 
        0, 
        '01/01/2023',  -- Data inicial
        current_date   -- Data final como data atual
    ) m
INNER JOIN produtos p ON (m.cod_produto = p.cod_produto)
INNER JOIN grupos g ON (p.cod_grupo = g.cod_grupo)
INNER JOIN pessoas pe ON (m.cod_empresa = pe.cod_pessoa)
WHERE
    tipo_lancamento  in ('V')
    AND p.tipo in ('U','C','M','D','P')
    AND data_movimento BETWEEN '01/01/2023' AND current_date
GROUP BY
    data_movimento,
    pe.nome,
    p.nome,
    g.nome,
    preco_medio