# Colección `owned_monsters`

Un documento por cada captura (gatcha, recompensa SBC, etc.).

## Campos

| Campo       | Tipo      | Descripción                          |
|------------|-----------|--------------------------------------|
| `ownerId`  | string    | UID de Firebase Auth (dueño)         |
| `monsterId`| string    | Id del catálogo en `monsters/{id}`   |
| `name`     | string    | Nombre del monstruo (copia del catálogo, para la consola) |
| `createdAt`| timestamp | Server timestamp al crear            |

## Ejemplo

```json
{
  "ownerId": "abc123uid",
  "monsterId": "pikachu",
  "name": "Pikachu",
  "createdAt": "<server>"
}
```

## Índice

Firestore puede pedir un índice compuesto para:

- `ownerId` (equality)

## Migración

Si el usuario tenía el array legado `users/{uid}.monsters` con `{ monsterId, count }`,
la app expande cada unidad de `count` en un documento en `owned_monsters` y borra el array.

## Reglas

Ver `firebase/firestore.rules`: solo el dueño puede leer, crear y borrar sus instancias.
