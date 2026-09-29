# WSL2 + Docker Desktop + PostgreSQL + LazyVim/Dadbod

Guía para reproducir la configuración revisada el 28 de septiembre de 2026.


> **Actualización: carga automática de credenciales.** La configuración actual ya no requiere direnv para abrir Neovim. Sigue la sección 17 después de instalar los archivos; los ejemplos anteriores con direnv continúan siendo compatibles. Las credenciales reales están en ~/.config/dadbod/.env.

## 1. Arquitectura y alcance

Windows → Ubuntu en WSL2 → Neovim/LazyVim → Dadbod → psql → PostgreSQL en Docker.

Docker Desktop se instala en Windows. Neovim, direnv y psql se ejecutan dentro de Ubuntu. PostgreSQL se ejecuta en Docker. El psql del contenedor no sustituye al cliente que Dadbod necesita en Ubuntu.

| Componente | Valor observado |
| --- | --- |
| Ubuntu | 24.04.2 LTS, WSL2 |
| Neovim | 0.12.5 |
| Docker Engine / Compose | 29.8.0 / 5.5.1 |
| psql en Ubuntu | 16.15 |
| Imagen de PostgreSQL | postgres:16.10 |
| Datos | Chinook 1.4.5 |
| Base / esquema | Chinook / public |
| Usuario | dadbod_ro |
| Dirección desde Ubuntu | localhost:15432 |
| Alias de Dadbod | test_postgres |

Se verificó la URL de Dadbod con psql: conexión a Chinook como dadbod_ro, 11 tablas visibles y 275 artistas. La guía completa aún no se ha ejecutado en una segunda PC.

Conserva este Markdown junto a la carpeta **configuracion/**: incluye el Compose y scripts corregidos, plantilla de variables, plugin Dadbod y lockfile. No incluye contraseñas reales.

El Compose también define MySQL y SQL Server; esta guía inicia y valida únicamente PostgreSQL. Los otros motores no se verificaron en esta sesión.

## 2. Windows: instalar WSL2

En **PowerShell como administrador**, si Ubuntu aún no está instalado:

~~~powershell
wsl --install -d Ubuntu
~~~

Reinicia si Windows lo solicita. Abre Ubuntu y crea tu usuario Linux. Después, en PowerShell:

~~~powershell
wsl --update
wsl --list --verbose
~~~

Ubuntu debe mostrar VERSION 2. Si aparece VERSION 1:

~~~powershell
wsl --set-version Ubuntu 2
~~~

No reinstales una distribución existente. A partir del paso 4, ejecuta los comandos en **Ubuntu**, salvo indicación contraria.

Fuente: [instalación oficial de WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

## 3. Docker Desktop: habilitar Ubuntu

Instala [Docker Desktop para Windows](https://docs.docker.com/desktop/setup/install/windows-install/) y ábrelo.

1. Settings → General: activa **Use WSL 2 based engine**, si aparece.
2. Settings → Resources → WSL Integration: habilita **Ubuntu**.
3. Aplica los cambios y espera al arranque del motor.
4. Si no aparece WSL Integration, comprueba que Docker use contenedores Linux.

En una terminal de Ubuntu:

~~~bash
docker version
docker compose version
~~~

**Punto de control:** docker version debe mostrar Client y Server. La aplicación abierta por sí sola no confirma que Ubuntu tenga acceso.

Este procedimiento utiliza Docker Desktop; no instales otro Docker Engine dentro de Ubuntu.

Fuente: [integración de Docker con WSL2](https://docs.docker.com/desktop/features/wsl/).

## 4. Instalar herramientas de Ubuntu

~~~bash
sudo apt update
sudo apt install -y git curl unzip build-essential ripgrep fd-find postgresql-client direnv python3
psql --version
direnv version
~~~

postgresql-client instala psql. No hace falta instalar el servidor PostgreSQL de Ubuntu.

## 5. Instalar Neovim en Ubuntu

Comprueba si ya existe:

~~~bash
command -v nvim
nvim --version
uname -m
~~~

Conserva una instalación que ya sea compatible con tu LazyVim. En la PC original se observó Neovim 0.12.5.

Para una instalación nueva, descarga una versión concreta de Linux desde [Neovim Releases](https://github.com/neovim/neovim/releases). Revisa los [requisitos de LazyVim](https://www.lazyvim.org/). Anota la versión elegida: usar “latest” cambia el resultado con el tiempo.

Ejemplo si descargaste nvim-linux-x86_64.tar.gz a tu directorio de inicio y uname -m muestra x86_64:

~~~bash
mkdir -p ~/.local/opt ~/.local/bin
tar -xzf ~/nvim-linux-x86_64.tar.gz -C ~/.local/opt
ln -s ~/.local/opt/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim
export PATH="$HOME/.local/bin:$PATH"
nvim --version
~~~

Si el enlace ya existe, revísalo antes de continuar; no lo reemplaces a ciegas. Para ARM64 utiliza el archivo y directorio nvim-linux-arm64.

Añade una sola vez a ~/.bashrc o ~/.zshrc, según tu shell:

~~~bash
export PATH="$HOME/.local/bin:$PATH"
~~~

Configura una Nerd Font en Windows Terminal para mostrar los iconos correctamente.

Fuente: [instalación de Neovim](https://github.com/neovim/neovim/blob/master/INSTALL.md).

## 6. Llevar LazyVim a la PC nueva

### Opción A: conservar la configuración personal

El repositorio observado fue https://github.com/armandopbringas/nvim.git.

Había cambios locales y archivos sin seguimiento. **Clonar el repositorio no garantiza obtener estas correcciones hasta que estén guardadas en Git.** No se hizo commit ni push en esta sesión.

Para transportar la configuración local, en Ubuntu de la PC original:

~~~bash
tar --exclude='nvim/.git' --exclude='nvim/.env' --exclude='nvim/db_ui' --exclude='nvim/.envrc' -czf ~/nvim-config-sin-credenciales.tar.gz -C ~/.config nvim
~~~

Revisa el contenido antes de compartirlo: se excluyen los lugares conocidos de credenciales, pero otros archivos personales podrían contener datos privados. No se incluyen volúmenes de Docker ni plugins descargados.

Copia el archivo al directorio de inicio de Ubuntu de la PC nueva. Respalda la configuración anterior antes de extraer:

~~~bash
mkdir -p ~/.config
if [ -e ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)
fi
tar -xzf ~/nvim-config-sin-credenciales.tar.gz -C ~/.config
~~~

La configuración personal incluye plugins ajenos a bases de datos. Se observó python3_host_prog apuntando a /opt/homebrew/anaconda3/bin/python: adapta o elimina esa asignación de macOS en la PC nueva. Dadbod no necesita ese proveedor.

Abre Neovim, ejecuta **:Lazy restore** para recuperar los commits de lazy-lock.json y revisa **:checkhealth**. Los plugins personales pueden requerir dependencias adicionales.

### Opción B: LazyVim limpio

Para reproducir la conexión sin trasladar todos tus plugins, respalda cualquier configuración existente y utiliza el [starter oficial](https://www.lazyvim.org/installation):

~~~bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
~~~

Esta opción reproduce el acceso a PostgreSQL, pero no todas tus personalizaciones ni las mismas versiones de plugins.

## 7. Copiar los archivos corregidos

Copia la carpeta completa de esta guía a **~/wsl2-postgres-dadbod** dentro de Ubuntu de la PC nueva. Después:

~~~bash
cd ~/wsl2-postgres-dadbod
mkdir -p ~/.config/nvim/docker/bootstrap ~/.config/nvim/lua/plugins
cp configuracion/compose.yaml ~/.config/nvim/
cp configuracion/.env.example configuracion/.envrc ~/.config/nvim/
cp configuracion/docker/bootstrap/*.sh ~/.config/nvim/docker/bootstrap/
cp configuracion/lua/plugins/dadbod.lua ~/.config/nvim/lua/plugins/
~~~

Estos comandos reemplazan los archivos del mismo nombre: usa primero el respaldo del paso anterior. Mantén finales de línea LF en los scripts.

El lockfile adjunto sirve como referencia de la configuración completa. Para la opción A usa el del respaldo; no lo copies sobre el starter limpio.

Las correcciones incluidas son:

- postgres_init define **PGHOST: postgres** y **PGUSER: postgres**.
- El importador omite las instrucciones originales de borrar/crear la base y reconectarse.
- Importa en **Chinook**, con mayúscula.
- Detecta la tabla **public.artist**, en minúsculas, para evitar repetir la carga.
- Concede los permisos a dadbod_ro dentro de Chinook.

El filtro del SQL está preparado para Chinook 1.4.5. Revisa el formato antes de actualizar esa versión.

## 8. Crear credenciales locales

~~~bash
cd ~/.config/nvim
test -f .env || cp .env.example .env
chmod 600 .env
nano .env
~~~

Sustituye todos los marcadores por contraseñas propias. La URL tiene esta estructura:

~~~dotenv
DADBOD_TEST_POSTGRES_URL=postgresql://dadbod_ro:CONTRASENA_CODIFICADA@localhost:15432/Chinook
~~~

DADBOD_RO_PASSWORD contiene la contraseña original. La URL contiene la misma contraseña codificada para URL. Para obtener esa representación sin escribir la contraseña en el historial:

~~~bash
python3 -c 'from getpass import getpass; from urllib.parse import quote; print(quote(getpass("Contraseña dadbod_ro: "), safe=""))'
~~~

Copia el resultado a la URL. Si usas una contraseña aleatoria compuesta solo de letras y números, las dos representaciones coinciden.

El Compose completo contiene variables obligatorias para MySQL y SQL Server: rellena también esos campos aunque solo arranques PostgreSQL. Eso no inicia esos motores.

Asegúrate de que ~/.config/nvim/.gitignore incluya:

~~~gitignore
.env
db_ui/connections.json
~~~

## 9. Cargar variables y configurar Dadbod

El .envrc incluido contiene:

~~~bash
dotenv_if_exists .env
~~~

Añade una sola vez el hook correspondiente a tu shell.

En ~/.bashrc:

~~~bash
eval "$(direnv hook bash)"
~~~

O en ~/.zshrc:

~~~bash
eval "$(direnv hook zsh)"
~~~

Abre una terminal nueva, revisa .envrc y autorízalo:

~~~bash
cd ~/.config/nvim
direnv allow
~~~

Fuente: [hooks de direnv](https://direnv.net/docs/hook.html).

La configuración personal ya define las conexiones antes de require("config.lazy"). En un starter limpio agrega este bloque **antes** de esa llamada en init.lua:

~~~lua
local connections = {
  test_postgres = os.getenv("DADBOD_TEST_POSTGRES_URL"),
  test_mysql = os.getenv("DADBOD_TEST_MYSQL_URL"),
  test_sqlserver = os.getenv("DADBOD_TEST_SQLSERVER_URL"),
}
local dbs = {}
for name, url in pairs(connections) do
  if url and url ~= "" then
    dbs[name] = url
  end
end
vim.g.dbs = dbs
~~~

No dupliques el bloque si ya existe. El plugin dadbod.lua incluido instala Dadbod, Dadbod UI y completion y conserva los atajos.

## 10. Validar e iniciar PostgreSQL

~~~bash
cd ~/.config/nvim
docker compose config --quiet
docker compose up -d postgres_init
docker compose wait postgres_init
docker compose ps -a
docker compose logs --tail 30 postgres_init
~~~

El primer comando valida sin imprimir contraseñas. Arrancar postgres_init inicia también sus dependencias: descarga los SQL y levanta PostgreSQL; después importa datos y configura el usuario.

No uses docker compose up -d sin indicar servicio si solo quieres PostgreSQL: también iniciaría MySQL y SQL Server.

| Servicio | Resultado esperado |
| --- | --- |
| chinook_assets | Exited (0) |
| postgres | Up, healthy |
| postgres_init | Exited (0) |

Healthy confirma disponibilidad, no que los datos y permisos estén correctos. Continúa con la prueba SQL.

## 11. Verificar antes de abrir Neovim

Abre una shell temporal con las variables:

~~~bash
cd ~/.config/nvim
direnv exec . bash
~~~

Dentro de esa shell:

~~~bash
PGCONNECT_TIMEOUT=5 psql "$DADBOD_TEST_POSTGRES_URL" -X -w -v ON_ERROR_STOP=1 -c 'SELECT current_database(), current_user;' -c 'SELECT count(*) AS artistas FROM public.artist;' -c "SELECT count(*) AS tablas FROM information_schema.tables WHERE table_schema='public';"
~~~

Resultado esperado para los datos de ejemplo sin modificaciones:

- Base Chinook, usuario dadbod_ro.
- 275 artistas.
- 11 tablas visibles.

Escribe exit para cerrar la shell temporal. Si falla, resuelve primero la base, credenciales o red antes de diagnosticar la interfaz de Neovim.

## 12. Abrir Dadbod

~~~bash
cd ~/.config/nvim
direnv exec . nvim
~~~

Espera a que terminen de instalarse los plugins. Abre **:DBUI**, selecciona test_postgres y crea un buffer de consulta desde esa conexión.

~~~sql
SELECT current_database(), current_user;
SELECT * FROM public.artist LIMIT 10;
~~~

Selecciona la consulta y ejecuta con **<leader>r**; en LazyVim el leader suele ser Espacio. El mapeo visual permite controlar qué texto se ejecuta.

Comprobaciones dentro de Neovim sin revelar contraseñas:

~~~vim
:echo executable('psql')
:lua print(vim.env.DADBOD_TEST_POSTGRES_URL ~= nil)
:lua print(vim.g.dbs and vim.g.dbs.test_postgres ~= nil)
~~~

Esperado: 1, true, true.

Las tablas de esta edición están en minúsculas: usa public.artist, no "Artist". El archivo antiguo de consultas usaba el nombre incorrecto; toma el ejemplo anterior como referencia corregida.

## 13. Uso diario y datos persistentes

Abre Docker Desktop y, en Ubuntu:

~~~bash
cd ~/.config/nvim
docker compose start postgres
direnv exec . nvim
~~~

Para detenerlo:

~~~bash
cd ~/.config/nvim
docker compose stop postgres
~~~

El volumen conserva los datos. No hay que repetir la importación cada día.

**No uses docker compose down -v para solucionar problemas de conexión:** elimina los volúmenes del proyecto.

Cambiar POSTGRES_ADMIN_PASSWORD en .env después de crear el volumen no cambia automáticamente la contraseña del servidor. Si la rotas, actualiza también el rol PostgreSQL.

La detección de public.artist evita recargar datos, pero no repara una importación parcial que ya haya creado esa tabla. Si los conteos no coinciden, revisa los logs antes de reintentar.

## 14. Errores conocidos

| Síntoma | Qué revisar |
| --- | --- |
| Docker no disponible en Ubuntu | WSL Integration y Client/Server en docker version. |
| psql: command not found | Instalar postgresql-client dentro de Ubuntu. |
| Autenticación fallida para root | Falta PGUSER: postgres en postgres_init. |
| Connection refused en localhost:15432 | Motor Docker, contenedor y puerto publicado. |
| No aparece test_postgres | Variables y vim.g.dbs; abrir con direnv exec. |
| Conecta, pero no hay tablas | Chinook y chinook son bases distintas; revisar current_database(). |
| relation "Artist" does not exist | Usar public.artist, en minúsculas. |
| Autenticación fallida para dadbod_ro | Contraseña y codificación URL; salida de postgres_init. |
| Permission denied | GRANT debe ejecutarse dentro de Chinook. |
| Puerto 15432 ocupado | Identificar el servicio; si cambias puerto, cambiar también URL. |
| .envrc bloqueado | Revisar contenido y ejecutar direnv allow. |
| Neovim conserva variables anteriores | Cerrar y abrir con direnv exec. |

Logs:

~~~bash
cd ~/.config/nvim
docker compose logs --tail 50 postgres
docker compose logs --tail 50 postgres_init
~~~

En Neovim: **:messages**. Oculta contraseñas y URLs completas al compartir errores.

## 15. Respaldos y comprobación final

La configuración recrea el entorno y los datos de ejemplo; no transporta datos propios de los volúmenes.

Para respaldar una base que hayas modificado:

~~~bash
cd ~/.config/nvim
docker compose exec -T postgres pg_dump -U postgres -d Chinook -Fc > ~/Chinook-backup.dump
~~~

Comprueba que terminó correctamente antes de copiar el archivo. Planea la restauración según los datos existentes en destino; no la mezcles con una importación nueva de Chinook.

- [ ] Ubuntu utiliza WSL2.
- [ ] Docker muestra Client y Server desde Ubuntu.
- [ ] psql y Neovim funcionan en Ubuntu.
- [ ] Archivos corregidos y .env local preparados.
- [ ] postgres healthy; postgres_init terminó en 0.
- [ ] URL conecta a Chinook como dadbod_ro.
- [ ] 11 tablas y 275 artistas en la carga inicial.
- [ ] DBUI muestra test_postgres y ejecuta una consulta.
- [ ] Respaldo de configuración sin secretos.
- [ ] Datos propios respaldados por separado.

## 16. Apariencia dentro de tmux

La configuración revisada tenía dos default-terminal contradictorios y Zsh sobrescribía TERM con xterm-256color. Se unificó tmux en tmux-256color y se eliminó esa sobrescritura de ~/.zshrc. No fuerces TERM en el archivo de shell.

Ajustes esenciales en ~/.tmux.conf:

~~~tmux
set -g default-terminal "tmux-256color"
set -as terminal-features ",xterm-256color:RGB"
~~~

Conserva tus plugins y atajos; elimina otras asignaciones contradictorias de default-terminal. Recarga con tmux source-file ~/.tmux.conf. Los panes existentes conservan su entorno: abre una ventana nueva con el prefijo configurado y luego c (en esta PC: Ctrl+a, después c). Allí echo $TERM debe mostrar tmux-256color.

En init.lua, el ancho inicial de Dadbod se ajustó al 30% del terminal, entre 20 y 40 columnas:

~~~lua
vim.g.db_ui_winwidth = math.min(40, math.max(20, math.floor(vim.o.columns * 0.30)))
~~~

Con 74 columnas da 22, en lugar de las 40 anteriores. Este cálculo se realiza al iniciar Neovim; no reajusta automáticamente un panel ya abierto al redimensionar.

Se verificó que tmux usa tmux-256color y una shell interactiva Zsh lo conserva. La apariencia final debe comprobarse en la terminal del usuario.

Referencia: [FAQ de tmux sobre colores](https://github.com/tmux/tmux/wiki/FAQ#how-do-i-use-rgb-colour).


## 17. Credenciales automáticas desde cualquier carpeta

Neovim carga ~/.config/dadbod/.env antes de LazyVim, mediante lua/config/dadbod.lua. Solo registra las URLs en vim.g.dbs; no exporta las contraseñas administrativas a todas las terminales. El archivo tiene permisos 600 y su directorio 700.

En la PC actual ya está aplicado y verificado desde /tmp, sin variables DADBOD heredadas: conexión como dadbod_ro a Chinook, con 275 artistas.

Para reproducirlo en otra PC, después de crear .env en los pasos anteriores, ejecuta una sola vez (si el destino ya existe, revisa ambos archivos en vez de sobrescribirlo):

~~~bash
mkdir -p ~/.config/dadbod
chmod 700 ~/.config/dadbod
test ! -e ~/.config/dadbod/.env && mv ~/.config/nvim/.env ~/.config/dadbod/.env
chmod 600 ~/.config/dadbod/.env
ln -s ~/.config/dadbod/.env ~/.config/nvim/.env
mkdir -p ~/.config/nvim/lua/config
cp ~/wsl2-postgres-dadbod/configuracion/dadbod-loader.lua ~/.config/nvim/lua/config/dadbod.lua
~~~

El enlace permite que Compose encuentre el mismo archivo, sin duplicarlo. Si ~/.config/nvim/.env ya existe, no fuerces el enlace: verifica que apunta al archivo correcto.

En init.lua reemplaza el bloque anterior que construía vim.g.dbs desde os.getenv por:

~~~lua
vim.g.dbs = require("config.dadbod")
~~~

Debe ir antes de require("config.lazy"). No dejes el bloque anterior después porque reemplazaría las conexiones.

Formato admitido: una asignación CLAVE=valor por línea, opcionalmente con el valor entre comillas simples o dobles. Usa URLs completas con contraseñas codificadas; no uses export, interpolación de variables, comandos de shell, valores multilínea ni comentarios al final de una asignación. El lector trata el archivo como datos y no ejecuta su contenido.

Los valores del archivo tienen prioridad sobre variables heredadas. Si falta una clave, se permite su variable de entorno como alternativa. Cambios en credenciales requieren reiniciar Neovim.

Uso diario desde cualquier directorio:

~~~bash
nvim
~~~

Abre :DBUI. Docker Desktop y PostgreSQL deben seguir activos; esta carga no inicia contenedores. Las URLs de MySQL y SQL Server también aparecen, pero sus servidores deben iniciarse y verificarse por separado.

Mantén .env en .gitignore aunque ahora sea un enlace. No copies credenciales reales en el respaldo compartible. Para respaldar los secretos usa un método privado separado y restaura permisos 600.
