# Contrato del backend intermedio

En producción, la app no debe contener claves de proveedores de IA. El adaptador
`BackendProxyClient` envía la petición a un servidor propio, que custodia la clave,
autentica al usuario y reenvía la solicitud al proveedor elegido.

## Petición

`POST {endpoint}` · `Content-Type: application/json`
`Authorization: Bearer <token de sesión>` (opcional; es el token del usuario ante
el backend, **no** la clave del proveedor).

```json
{
  "system": "rol del editor (texto)",
  "user": "prompt con secciones CONTEXTO DE DOMINIO / RESTRICCIONES / ESTILO / FORMATO DE SALIDA y el texto delimitado",
  "temperature": 0.3,
  "maxTokens": 4096,
  "expectJson": true,
  "model": "opcional; si se omite, el backend decide"
}
```

## Respuesta

`200 OK`

```json
{ "text": "salida bruta del modelo (se espera un objeto JSON en texto)" }
```

La app valida y repara el JSON de `text`; si es inválido, repite la petición una vez
con una instrucción de corrección.

## Errores

| HTTP | Interpretación en la app |
|---|---|
| 401 / 403 | `AuthenticationFailure` |
| 429 | `ProviderFailure` (límite de uso) |
| 4xx | `ProviderFailure` con `{"error": {"message": "..."}}` si existe |
| 5xx | `ProviderFailure` (falla temporal) |
| Sin conexión / timeout (120 s) | `ConnectionFailure` |

## Responsabilidades recomendadas del backend

- Guardar claves de proveedores en un gestor de secretos; nunca devolverlas.
- Autenticación de usuarios, cuotas y límites de tamaño.
- No registrar el texto de los usuarios por defecto (registrar solo metadatos).
- Política de retención y región de procesamiento acorde a la normativa aplicable a
  datos de salud.
- CORS restringido al dominio de la app Web.
