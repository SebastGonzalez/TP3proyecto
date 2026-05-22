# Ícono de launcher (cuadrado)

`LogoJuego.png` del login es **apaisado** (~669×373). Los íconos de Android/iOS deben ser **cuadrados**; si usás el PNG del login directo, el sistema **estira** el ancho o el alto y se ve mal.

`app_icon.png` es el mismo logo **centrado** en un lienzo 1024×1024 (proporción correcta, fondo blanco).

Regenerar íconos:

```bash
dart run flutter_launcher_icons
```

Para regenerar solo `app_icon.png` desde `LogoJuego.png` (PowerShell en la raíz del repo):

```powershell
.\scripts\build-app-icon.ps1
```
