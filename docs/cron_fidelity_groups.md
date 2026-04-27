# CRON Fidelity Groups (T^7 + 40 setores)

Este documento traduz seu modelo em uma implementação executável **simples, direta e sem dependências pesadas**.

## O que “carrega o conhecimento” no pipeline

No modelo implementado em `tools/cron_fidelity_grouping.py`, o conhecimento efetivo é carregado pela combinação de 4 trilhas:

1. **Estado toroidal `s ∈ [0,1)^7`**: memória geométrica compacta por setor.
2. **Coerência/entropia dinâmica (`C_t`, `H_t`)**: memória temporal (filtro EMA, α=0.25).
3. **Integridade de fluxo (`FNV + CRC32`)**: rastro de causalidade dos bytes processados.
4. **Invariante geométrico `I = Φ(s,S,H,C,G)`**: valor escalar de decisão para agrupamento e frequência “NEON”.

Em termos práticos: **não é um único campo que carrega tudo**, mas a composição destes 4 sinais em cada iteração.

---

## Mapeamento das equações para execução

- Eq. 1–4,45: `toroidal_map(...)` gera `s=(u,v,ψ,χ,ρ,δ,σ)`.
- Eq. 5–7: `coherence_update(...)` atualiza `C_{t+1}` e `H_{t+1}`.
- Eq. 8: `φ=(1−H)·C` dentro de `geometric_invariant(...)`.
- Eq. 12/44: `cardioid_resonance(...)` para `R`.
- Eq. 31/32/33: `fnv_step(...)` + `zlib.crc32(...)`.
- Eq. 46: `bits_geom = log2(M×N)`.
- Eq. 50: `I = Φ(s,S,H,C,G)` implementado como composição ponderada e normalizada.

---

## Comandos básicos (LOW BASIC COMMANDS)

### 1) Rodar benchmark padrão (1000 iterações por setor)

```bash
python tools/cron_fidelity_grouping.py
```

### 2) Rodar com seed específica

```bash
python tools/cron_fidelity_grouping.py --seed 123
```

### 3) Salvar saída em JSON

```bash
python tools/cron_fidelity_grouping.py --iterations 1000 --seed 42 --output /tmp/cron40.json
```

### 4) Ler resumo rápido dos grupos

```bash
python tools/cron_fidelity_grouping.py --output /tmp/cron40.json
python - <<'PY'
import json
p='/tmp/cron40.json'
obj=json.load(open(p,'r',encoding='utf-8'))
for k,v in sorted(obj['groups'].items()):
    print(k, v['name'], 'setores=', v['sectors'], 'medI=', v['median_I'])
PY
```

---

## Licenciamento e conformidade

- Esta implementação usa apenas biblioteca padrão Python (`hashlib`, `zlib`, etc.).
- Não inclui código de terceiros copiado.
- Compatível com o repositório sem alterar licenças existentes.

