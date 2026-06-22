# Guía de publicación en Google Play (HolyApp)

Documento de apoyo para completar la ficha de Play Console. Refleja lo que la
app **realmente** hace hoy (login opcional con Google, progreso en Firestore,
sin analítica ni publicidad).

---

## 1. Artefacto a subir
- **App Bundle firmado:** `build/app/outputs/bundle/release/app-release.aab`
- Firmado con el keystore de publicación `android/app/upload-keystore.jks`
  (alias `upload`). **Guarda ese archivo y su contraseña en lugar seguro**: sin
  él no podrás publicar actualizaciones.
- Se recomienda activar **Play App Signing** (Google custodia la clave de firma
  de la app y tu keystore queda como "clave de subida").

> Símbolos de depuración (para desofuscar crashes): `build/debug-symbols/`.

---

## 2. Seguridad de los datos (Data Safety) — respuestas sugeridas

**¿La app recopila o comparte datos de usuario?** → **Sí** (solo si el usuario
inicia sesión; en modo invitado no se recopila nada).

**¿Los datos están cifrados en tránsito?** → **Sí** (HTTPS/TLS de Firebase).

**¿El usuario puede solicitar la eliminación de sus datos?** → **Sí**
(Configuración → Cuenta → «Eliminar mi cuenta y datos», y por correo).

### Tipos de datos recopilados

| Categoría | Tipo de dato | ¿Recopilado? | ¿Compartido con terceros? | Propósito | ¿Opcional? |
|-----------|--------------|--------------|---------------------------|-----------|------------|
| Información personal | Nombre | Sí | No¹ | Funcionalidad de la app (perfil, ranking) | Sí (solo con login) |
| Información personal | Dirección de correo | Sí | No¹ | Funcionalidad de la app (identificar la cuenta) | Sí (solo con login) |
| Fotos | Foto de perfil (URL de Google) | Sí | No¹ | Funcionalidad de la app (avatar, ranking) | Sí (solo con login) |
| Identificadores | ID de usuario (UID) | Sí | No¹ | Funcionalidad de la app (asociar progreso) | Sí (solo con login) |
| Actividad en la app | Progreso de juego (puntaje, niveles, historial) | Sí | No¹ | Funcionalidad de la app (sincronizar entre dispositivos) | Sí (solo con login) |

¹ Los datos se almacenan en **Google Firebase** (Authentication + Cloud
Firestore), que actúa como proveedor de infraestructura/encargado del
tratamiento, no como un tercero con fines propios. No se venden ni se usan para
publicidad. En el ranking, *nombre, foto y puntaje* son visibles para otros
usuarios autenticados; el correo nunca es público.

**Datos NO recopilados:** ubicación, contactos, mensajes, archivos, historial de
navegación o búsqueda, datos de salud, información financiera, analítica de
terceros, identificadores de publicidad.

---

## 3. Ficha de la tienda (campos clave)
- **Política de privacidad (URL):** https://holyapp-8b41f.web.app/privacidad
- **Términos de uso (URL):** https://holyapp-8b41f.web.app/terminos
- **Categoría:** Educación (o Estilo de vida).
- **Clasificación de contenido:** completar el cuestionario IARC; la app es apta
  para todo público (contenido educativo religioso, sin violencia ni material
  sensible).
- **Anuncios:** No contiene anuncios.
- **Acceso (login de prueba para revisores):** indica que el login es **opcional**
  y que toda la app es accesible en modo invitado, así que no necesitan
  credenciales de prueba.

---

## 4. Cumplimiento técnico previo a publicar
- [ ] **Registrar el SHA-1 de subida** en Firebase para que el login con Google
      funcione en el build de Play (ver más abajo). Si activas Play App Signing,
      registra **también el SHA-1 que Google te asigne** (Play Console →
      Configuración → Integridad de la app → certificado de firma de la app).
- [ ] `targetSdk` al nivel exigido por Play (actualmente sigue
      `flutter.targetSdkVersion`; verifica que sea ≥ 34).
- [ ] Restringir la **API key** en Google Cloud (huella + paquete para Android;
      referrers para web).
- [ ] (Opcional) Activar **App Check** para proteger Firestore de clientes no
      autorizados.

### SHA-1 a registrar en Firebase
- **Keystore de depuración** (para probar en desarrollo):
  `9E:B2:A5:4F:CC:67:AF:29:AE:CE:16:C1:40:D3:B9:09:7D:6B:E2:37`
- **Keystore de publicación** (`upload-keystore.jks`, para el build de Play):
  - SHA-1: `D0:ED:1F:92:10:5C:F9:92:13:DD:C6:73:29:4D:B9:C3:F5:89:10:7F`
  - SHA-256: `61:6E:8D:18:E3:93:C5:77:73:9E:61:49:C4:4A:6B:17:DF:5D:77:12:17:64:30:3B:FA:B6:C7:A9:8A:5E:53:5F`

Tras agregar las huellas, **descarga el `google-services.json` actualizado** y
reemplaza `android/app/google-services.json` antes de recompilar el `.aab`.
