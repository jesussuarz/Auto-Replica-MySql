<p align="center">
   <img src="https://github.com/jesussuarz/Auto-Replica-MySql/raw/main/img_start.png">
</p>

# Auto Replica MySql

Este script te servira para montar replicas mysql para 2 bases de datos o mas segun las definas, Este scipt le permite montar automaticamente una replica de bases de datos.

**Para que funcione correctamente debe colocar en las variables de bases de datos y de rutas los valores adecuados. **

Debe tener instalado mysql-server y estar creado el usuario con permisos adecuados en el servidor replica.

Este codigo fue desarrollado por mi como parte de un arreglo para montar automaticamente una replica que estaba dañada en un servidor de un cliente dentro de IFX NETWORK DATACENTER. Y es publicado de forma colaborativa para que otros puedan resolver el mismo problema en el furuto y puedan montar replicas de forma automatizadas.

Algunos datos para tener en cuenta:
<p align="center">
#================================================================#
</p>

Nombre : Auto Replica

Autor : Jesus D. Suarez H.

Correo : jdsuarez@ifxcorp.com

Nombre del Archivo : autoreplica.sh

Licencia : El codigo se distribuye bajo licencia GPLv3

Descripción : Script para montar replicas MySql

Descargo de responsabilidad : Este código se ejecuta bajo su total responsabilidad

Ayuda : Solo coloque la contraseña de SSH del maestro hasta que deje de solicitarla

NOTAS : Proporcione permisos de ejecución al script: chmod +x autoreplica.sh

                              Si se desconecta ssh y debe iniciar de nuevo borre el .sql/.gz en el master/slave

Recomendaciones : Este script solo debe ejecutarse en su servidor replica/esclavo, nunca en el servidor master

                              Podría causar el borrado de todas sus bases de datos si intenta ejecutarlo en el server master
<p align="center">
#================================================================#"
</p>
Este codigo solo debe ejecutarse en su servidor replica, jamas y nunca en el servidor maestro. Por favor realice respaldos de sus bases de datos antes de ejecutar el codigo por seguridad.

# FUTURAS MEJORAS
<p align="center">
#================================================================#
</p>
Mejoras que se pueden realizar de este código a futuro
<ul><li>
Implementar un reintentar si hay un error en la contraseña de ssh maestro
</li><li>
Barra de progreso en cada uno de los procesos con el paquete PV ej: [===> ] 20%
</li><li>
Detectar si existe la contraseña agregada en el archivo my.cnf de ser asi inicie sin pedir contraseña
</li><li>
Detectar si no existe configuración de usuario en /root/.my.cnf y en ese caso solicitar la contraseña
</li><li>
Obtener bases de datos a realizar DROP desde my.cnf si esta definido, si no obtener todas
</li><li>
Detectar si se encuentra instalado mysql, de lo contrario instalarlo
</li><li>
Crear usuario de replica automaticamente con permisos
</li><li>
Configurar bases de datos en el proceso de ejecucion
</li><li>
Conectarse a SSH con sshkey para luego usar ssh-agent para no solicitar multiples veces la contraseñas
  </li> </ul>
<p align="center">
#================================================================#
</p>
Si necesitas contactarme lo puedes hacer en: jdsuarez@ifxcorp.com
