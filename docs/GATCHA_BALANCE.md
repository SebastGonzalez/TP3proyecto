# Balance del gatcha (Firestore)

Toda la probabilidad del gatcha se configura en **`gatcha_machines`**.  
`monsters` es solo catálogo; `monsters_rarity.weight` es orden/UI (no es % de drop).

## Colecciones

| Colección | Campo | Rol |
|-----------|--------|-----|
| `monsters_rarity/{id}` | `gachaEligible` | `false` = esa rareza **nunca** sale en gacha (ej. Fusion) |
| `monsters_rarity/{id}` | `weight` | Orden de tier, reveal, home — **no es % de gacha** |
| `gatcha_machines/{id}` | `rarityRates` | **Obligatorio.** % por rareza en esta máquina (claves = `label`) |
| `gatcha_machines/{id}` | `monsterWeights` | Opcional: peso relativo de un monstruo dentro de su rareza |
| `gatcha_machines/{id}` | `poolMode` / `poolMonsterIds` | Opcional: acotar qué monstruos entran |

## Campos que ya no se usan (podés borrarlos en Firestore)

| Colección | Campo | Acción |
|-----------|--------|--------|
| `gatcha_machines` | `rarityBoosts` | Eliminar en todos los docs |
| `monsters` | `dropWeight` | Eliminar en todos los docs (opcional por lote en consola) |

## Tirada

1. Elige rareza según `rarityRates` (normalizado a 100% entre las claves listadas).
2. Elige monstruo ponderado (`monsterWeights[id]` o peso `1`).

### Ejemplo: máquina estándar (sin Fusion)

```json
{
  "rarityRates": {
    "Común": 72,
    "Raro": 23,
    "Legendario": 5
  }
}
```

### Tres máquinas (más cara = más legendario)

| Máquina | Común | Raro | Legendario |
|---------|------:|-----:|-----------:|
| Barata | 72 | 23 | 5 |
| Media | 60 | 30 | 10 |
| Cara | 50 | 35 | 15 |

### Fusion fuera del gacha

`monsters_rarity/fusion`:

```json
{ "gachaEligible": false }
```

## Limpieza en Firebase Console

1. **`gatcha_machines`**: confirmá que **todas** las máquinas activas tienen `rarityRates`. Borrá `rarityBoosts` si queda alguno.
2. **`monsters`**: borrá el campo `dropWeight` de cada documento (no afecta al juego si ya migraste).
3. **`monsters_rarity`**: Fusion (u otras) con `gachaEligible: false` si no deben salir nunca.

## Claves de `rarityRates`

Deben coincidir con **`monsters_rarity.label`** (ej. `"Legendario"`).

## Resumen

| Querés… | Editá… |
|---------|--------|
| Fusion nunca en gacha | `monsters_rarity` → `gachaEligible: false` |
| % por rareza | `gatcha_machines` → `rarityRates` |
| Monstruo destacado en un tier | `gatcha_machines` → `monsterWeights` |
