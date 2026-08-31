# Red Semanal (Weekly Net)

La **Red Semanal** es el chequeo periódico de la malla: los operadores envían un
mensaje de texto por la red con un hashtag acordado y la página `/net` arma
automáticamente la lista de quién se reportó.

En PRMesh el hashtag es **`#PRMeshNet`**.

## Cómo participar

1. Durante la ventana del net, envía un mensaje de texto por la malla en el canal
   principal.
2. Usa el formato indicado en el mensaje amarillo que aparece arriba de la página:

   ```
   (NOMBRE LARGO) - (PUEBLO EN QUE ESTÁS) #PRMeshNet
   ```

3. Con que el mensaje **contenga `#PRMeshNet`** ya cuenta. No hace falta registrarse
   en ningún lado.
4. Solo se toma en cuenta tu **primer** reporte: si mandas varios mensajes, la lista
   muestra el más temprano.

## Qué muestra la página `/net`

| Elemento | Descripción |
|---|---|
| Mensaje amarillo | Texto configurable (`weekly_net_message`) con la fecha/hora del net y el formato del reporte. |
| Total messages | Cantidad de **nodos únicos** que hicieron checkin en la ventana. |
| Lista | Una fila por nodo: hora y fecha del reporte, canal (con enlace al paquete ✉️), nombre del nodo (con enlace a su página) y el texto del mensaje. |

> Nota: solo se lista el reporte más temprano de cada equipo.

## Cómo funciona por dentro

La vista es completamente del lado del cliente (`meshview/templates/net.html`) y
hace **una sola consulta** al cargar la página — no hay refresco automático, hay
que recargar para ver nuevos checkins.

1. Lee la configuración del sitio y muestra `weekly_net_message`; toma el valor de
   `net_tag`.
2. Llama a la API:

   ```
   /api/packets?portnum=1&contains=<net_tag>&since=<hace 6 días>&limit=1000
   ```

   - `portnum=1` → `TEXT_MESSAGE_APP` (solo mensajes de texto).
   - `contains` → el hashtag del net.
   - `since` → últimos 6 días (en microsegundos).

3. La API devuelve los mensajes de texto que contienen el hashtag
   (sin distinguir mayúsculas/minúsculas) y descarta los payloads que son solo
   secuencias de prueba.
4. El cliente agrupa por nodo de origen y se queda con el **paquete más temprano
   de cada nodo**.
5. Ordena de más reciente a más antiguo y pinta la lista. El contador "Total
   messages" es la cantidad de nodos distintos.

## Configuración (`config.ini`, sección `[site]`)

| Clave | Ejemplo (PRMesh) | Para qué |
|---|---|---|
| `net` | `True` | Activa la pestaña "Red Semanal" en el menú. |
| `net_tag` | `#PRMeshNet` | Hashtag que identifica los mensajes del net. |
| `weekly_net_message` | `Chequeo semanal de la malla. Formato del mensaje: (NOMBRE LARGO) - (PUEBLO EN QUE ESTÁS) #PRMeshNet.` | Texto informativo que se muestra arriba. |

Si no se configuran, se usan los valores por defecto definidos en
`meshview/web_api/api.py` (`#BayMeshNet` y un mensaje genérico en inglés).
