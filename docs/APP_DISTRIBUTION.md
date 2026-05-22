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

## 3. Subir una versión nueva (recomendado: un comando)

Requisitos (una vez):

```powershell
npm install -g firebase-tools
firebase login
```

Desde la raíz del repo:

```powershell
.\scripts\distribute-android.ps1 -ReleaseNotes "Walkmons 1.0 — primera build"
```

El script:

1. Lee `version` en `pubspec.yaml` (ej. `1.0.0+1` → se muestra como **1.0**).
2. `flutter build apk --release`
3. Sube el APK a App Distribution.
4. Si todo OK, deja en `pubspec.yaml` la **próxima** versión (`1.1.0+2`, luego `1.2.0+3`, …).

La segunda vez podés omitir notas (usa un texto por defecto):

```powershell
.\scripts\distribute-android.ps1
```

Con grupo (invite link atado al grupo `beta`):

```powershell
.\scripts\distribute-android.ps1 -Groups "beta"
```

Sin auto-versionado:

```powershell
.\scripts\distribute-android.ps1 -NoVersionBump -ReleaseNotes "Hotfix"
```

### Consola manual (sin script)

1. `flutter build apk --release`
2. APK: `build/app/outputs/flutter-apk/app-release.apk`
3. App Distribution → **Releases** → arrastrar el APK → **Distribute**.

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

Formato en `pubspec.yaml`: `version: 1.0.0+1`

| Parte | Significado | Ejemplo |
|-------|-------------|---------|
| `1.0.0` | Nombre visible (1.0, 1.1, 1.2…) | minor sube con cada `distribute-android.ps1` |
| `+1` | `versionCode` Android (siempre distinto) | +1 por cada build |

Primera distribución: `1.0.0+1`. Después del script queda `1.1.0+2` listo para la siguiente.
