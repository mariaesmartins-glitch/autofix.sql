CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mecanicos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50) NOT NULL,
    valor_hora NUMERIC(10, 2) NOT NULL CHECK (valor_hora > 0)
);

CREATE TABLE veiculos (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    placa VARCHAR(7) UNIQUE NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    ano INT NOT NULL CHECK (ano > 1900),
    
    CONSTRAINT fk_veiculo_cliente 
        FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) 
        ON DELETE CASCADE
);

CREATE TABLE ordens_servico (
    id SERIAL PRIMARY KEY,
    veiculo_id INT NOT NULL,
    mecanico_id INT NOT NULL,
    data_abertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_mao_obra NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (valor_mao_obra >= 0),
    status VARCHAR(20) DEFAULT 'Em Aberto' CHECK (status IN ('Em Aberto', 'Em Andamento', 'Concluida', 'Cancelada')),
    
    CONSTRAINT fk_os_veiculo 
        FOREIGN KEY (veiculo_id) 
        REFERENCES veiculos(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_os_mecanico 
        FOREIGN KEY (mecanico_id) 
        REFERENCES mecanicos(id) 
        ON DELETE RESTRICT
);

CREATE TABLE pecas_os (
    id SERIAL PRIMARY KEY,
    os_id INT NOT NULL,
    nome_peca VARCHAR(100) NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    valor_unitario NUMERIC(10, 2) NOT NULL CHECK (valor_unitario > 0),
    
    CONSTRAINT fk_peca_os 
        FOREIGN KEY (os_id) 
        REFERENCES ordens_servico(id) 
        ON DELETE CASCADE
);

INSERT INTO clientes (nome, email, telefone, cpf) VALUES 
('Roberto carlos', 'carlos.roberto12@email.com', '(48) 9041-5433', '45735645389'),
('Antonia Ferreira', 'antonia.ferreira@email.com', '(48) 98822-4455', '82765966778'),
('Regiane dos Santos', 'regi.santos@email.com', '(48) 97733-6677', '85342350124');

INSERT INTO mecanicos (nome, especialidade, valor_hora) VALUES 
('Rafael Oliveira', 'Motor e Câmbio', 120.00),
('Bruno Almeida', 'Suspensão e Freios', 85.00),
('Lucas Martins', 'Elétrica e Injeção', 100.00);

INSERT INTO veiculos (cliente_id, placa, modelo, marca, ano) VALUES 
(1, 'QWE2F45', 'HB20 1.0', 'Hyundai', 2021),       -- Veículo 1 (Roberto)
(1, 'RTY7G89', 'T-Cross 1.4', 'Volkswagen', 2023), -- Veículo 2 (Roberto)
(2, 'UIO3H21', 'Kwid 1.0', 'Renault', 2019),       -- Veículo 3 (Regiane)
(3, 'PAS6J54', 'Tracker 1.2', 'Chevrolet', 2022);  -- Veículo 4 (Antonia)

INSERT INTO ordens_servico (veiculo_id, mecanico_id, valor_mao_obra, status) VALUES 
(1, 2, 280.00, 'Concluida'),   
(2, 3, 320.00, 'Em Andamento'),   
(3, 1, 450.00, 'Concluida'),
(4, 2, 190.00, 'Cancelada');   

INSERT INTO pecas_os (os_id, nome_peca, quantidade, valor_unitario) VALUES 
(1, 'Filtro de Ar', 1, 75.00),
(1, 'Óleo 5W40 Sintético', 5, 55.00),
(2, 'Kit de Pastilhas Traseiras', 1, 210.00),
(3, 'Filtro de Combustível', 1, 95.00),
(4, 'Correia de Acessórios', 1, 130.00);

SELECT 
    v.marca,
    v.modelo,
    v.placa,
    v.ano,
    c.nome AS proprietario,
    c.telefone
FROM veiculos v
INNER JOIN clientes c ON v.cliente_id = c.id
ORDER BY v.marca ASC, v.modelo ASC;

SELECT 
    os.id AS os_id,
    v.placa,
    v.modelo,
    os.data_abertura,
    m.nome AS mecanico,
    os.status
FROM ordens_servico os
INNER JOIN veiculos v ON os.veiculo_id = v.id
INNER JOIN clientes c ON v.cliente_id = c.id
INNER JOIN mecanicos m ON os.mecanico_id = m.id
WHERE c.nome = 'Rafael oliveira'
ORDER BY os.data_abertura DESC;

SELECT 
    os.id AS os_id,
    v.placa,
    m.nome AS mecanico,
    os.valor_mao_obra,
    COALESCE(SUM(p.quantidade * p.valor_unitario), 0.00) AS total_pecas,
    (os.valor_mao_obra + COALESCE(SUM(p.quantidade * p.valor_unitario), 0.00)) AS valor_total_os
FROM ordens_servico os
INNER JOIN veiculos v ON os.veiculo_id = v.id
INNER JOIN mecanicos m ON os.mecanico_id = m.id
LEFT JOIN pecas_os p ON os.id = p.os_id
GROUP BY os.id, v.placa, m.nome, os.valor_mao_obra
ORDER BY os.id;

SELECT 
    nome AS mecanico,
    especialidade,
    valor_hora
FROM mecanicos
WHERE valor_hora > 90.00
ORDER BY valor_hora DESC;

SELECT 
    m.especialidade,
    COUNT(os.id) AS qtd_servicos_concluidos,
    COALESCE(SUM(os.valor_mao_obra), 0.00) AS faturamento_mao_obra
FROM mecanicos m
LEFT JOIN ordens_servico os ON m.id = os.mecanico_id AND os.status = 'Concluida'
GROUP BY m.especialidade
ORDER BY faturamento_mao_obra DESC;

CREATE VIEW vw_veiculos_clientes AS
SELECT 
    v.marca,
    v.modelo,
    v.placa,
    v.ano,
    c.nome AS proprietario,
    c.telefone
FROM veiculos v
INNER JOIN clientes c ON v.cliente_id = c.id
ORDER BY v.marca ASC, v.modelo ASC;

SELECT * from
vw_veiculos_clientes

CREATE VIEW vw_ordens_rafael as
select
    os.id AS os_id,
    v.placa,
    v.modelo,
    os.data_abertura,
    m.nome AS mecanico,
    os.status
FROM ordens_servico os
INNER JOIN veiculos v ON os.veiculo_id = v.id
INNER JOIN clientes c ON v.cliente_id = c.id
INNER JOIN mecanicos m ON os.mecanico_id = m.id
WHERE c.nome = 'Rafael oliveira'
ORDER BY os.data_abertura DESC;

SELECT * from
vw_ordens_rafael

Create view vw_mecanico_especialidade AS
SELECT 
    nome AS mecanico,
    especialidade,
    valor_hora
FROM mecanicos
WHERE valor_hora > 90.00
ORDER BY valor_hora DESC;

SELECT * from
vw_mecanico_especialidade

create view vw_especialidade_faturamento AS
SELECT 
    m.especialidade,
    COUNT(os.id) AS qtd_servicos_concluidos,
    COALESCE(SUM(os.valor_mao_obra), 0.00) AS faturamento_mao_obra
FROM mecanicos m
LEFT JOIN ordens_servico os ON m.id = os.mecanico_id AND os.status = 'Concluida'
GROUP BY m.especialidade
ORDER BY faturamento_mao_obra DESC;

SELECT * from
vw_especialidade_faturamento