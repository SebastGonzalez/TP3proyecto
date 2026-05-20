# Firestore — colección `users`

## Estructura del documento

**Ruta:** `users/{firebaseAuthUid}`

El `firebaseAuthUid` es el mismo valor que `FirebaseAuth.instance.currentUser!.uid`.

```json
{
  "username": "fede",
  "coins": 1000,
  "monsters": [
    { "monsterId": "Chispin", "count": 2 }
  ],
  "createdAt": "<server timestamp>",
  "updatedAt": "<server timestamp>"
}
```

`monsterId` = **Document ID** del monstruo en la colección `monsters`.

> Si creaste la colección `user` (singular) o el campo `monster_collection`, la app **no** los lee. Usá `users` y `monsters`.

## Queries en la app (`lib/core/data/user_repository.dart`)

| Operación | Query |
|-----------|--------|
| Leer perfil | `db.collection('users').doc(uid).get()` |
| Escuchar perfil | `db.collection('users').doc(uid).snapshots()` |
| Crear al primer login | `db.collection('users').doc(uid).set({ username, coins: 1000, monsters: [] })` |
| Actualizar monedas | `db.collection('users').doc(uid).update({ coins: N })` |
| Actualizar monstruos | `db.collection('users').doc(uid).update({ monsters: [...] })` |

## Reglas

Publicá `firebase/firestore.rules` en Firebase Console → Firestore → Reglas.

## Crear la lista de monstruos

1. **Automático:** jugá Gatcha; la app escribe en `monsters`.
2. **Manual:** en `users/<UID>`, campo `monsters` (array) con maps `{ monsterId, count }`.
