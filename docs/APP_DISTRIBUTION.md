# Firebase App Distribution (Android) — link de invitación

Proyecto: **monsters-app-2660c**  
Nombre visible: **Walkmons**  
Package Android (no cambia Firebase): **com.example.prueba1**  
Firebase App ID: `1:1018920622215:android:05d27435de9b04b1404022`

Los testers se suman solos con un **invite link** (no hace falta cargar mails uno por uno). Igual deben **aceptar con una cuenta de Google** la primera vez.

---

## 1. Activar App Distribution (una vez)

1. [Firebase Console](https://console.firebase.google.com/project/monsters-app-2660c/appdistribution) → proyecto **monsters-app-2660c**.
2. Menú **App Distribution** (bajo *Release & Monitor* o *Build*).
3. Si no aparece la app Android, agregala con el mismo package que Flutter: `com.example.prueba1` (debe coincidir con `android/app/build.gradle.kts`).

---

## 2. Crear el link de invitación (una vez)

1. En App Distribution → pestaña **Invite links** (Enlaces de invitación).
2. **Create invite link** / Crear enlace.
3. Elegí:
   - **Solo esta app** (recomendado para el TP), o
   - Un **grupo** (ej. `beta`) si querés el mismo link para varias apps.
4. Copiá la URL (ej. `https://appdistribution.firebase.google.com/pub/...`).
5. Compartila (WhatsApp, README del repo, entrega del TP).

Quien abre el link:

1. Ingresa su email.
2. Inicia sesión con **Google** (misma cuenta o la que pida Firebase).
3. Queda registrado como tester de la app.

Opcional en **Testers & Groups**: activar *Restrict invitation acceptance to recipient's email* solo si querés limitar el Gmail que acepta; para clase abierta **dejalo desactivado**.

---

## 3. Subir una versión nueva

### Opción A — Consola (sin CLI)

1. `flutter build apk --release`
2. APK: `build/app/outputs/flutter-apk/app-release.apk`
3. App Distribution → **Releases** → arrastrar el APK → notas → **Distribute**.
4. Los testers que entraron por el invite link reciben aviso de la nueva build (email o [appdistribution.firebase.google.com](https://appdistribution.firebase.google.com)).

### Opción B — Script (CLI)

Requisitos:

```powershell
npm install -g firebase-tools
firebase login
```

Desde la raíz del repo:

```powershell
.\scripts\distribute-android.ps1 -ReleaseNotes "TP v0.1.0"
```

Con grupo (si creaste el invite link atado al grupo `beta`):

```powershell
.\scripts\distribute-android.ps1 -ReleaseNotes "TP v0.1.0" -Groups "beta"
```

---

## 4. Instalación en el celular (tester)

1. Abrir el invite link (o el mail de “nueva versión”).
2. Aceptar con Google.
3. Descargar / instalar el APK.
4. Si Android lo pide: permitir **instalar apps desconocidas** para Chrome o “Firebase App Distribution”.

---

## 5. Problemas frecuentes

| Problema | Qué hacer |
|----------|-----------|
| No llega el mail | Revisar spam; usar el invite link directo |
| “No tenés acceso” | Aceptar invitación con Google en el mismo link |
| APK no instala | Activar orígenes desconocidos; desinstalar versión anterior si cambió la firma |
| `google-services.json` falta | `flutterfire configure` o copiar desde Firebase → Configuración del proyecto → Android |

---

## 6. Versión en el APK

La versión sale de `pubspec.yaml` (`version: 0.1.0+1` → nombre `0.1.0`, build `1`). Subí el número antes de cada distribución para que en la consola se distingan las releases.
