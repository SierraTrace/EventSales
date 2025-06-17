-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Producto 5
--
-- Grupo: Cnv20241_Grupo07: [DB Masters]
--
-- Database: [fp_046_07]
-- --------------------------------------------------------------


--
-- NOTA:    Se ha intentado habilitar el servidor en AWS para que ejecute eventos pero no contamos
--          con los permisos necesarios para ejecutar "SET GLOBAL event_scheduler = ON;"
--          Posteriormente, durante el trabajo, nos hemos dado cuenta que los eventas ya están activos.
--


--
-- Punto 1:
--
--  Crear manualmente (CREATE TABLE) una tabla denominada "show_semanales".
--  Agregar los siguientes campos: año: smallint, mes: char(5),semana: smallint, catname: varchar(10),
--  eventname: varchar(200), localidad: varchar(15), starttime timestamp
--


CREATE TABLE IF NOT EXISTS shows_semanales(
    show_id INT NOT NULL AUTO_INCREMENT,
    anyo smallint NOT NULL COMMENT 'Los cuatro dígitos del año',
    mes char(5) NOT NULL COMMENT 'Nombre del mes (abreviado), ejemplo: JUN',
    semana smallint NOT NULL COMMENT 'Número de semana, ejemplo: 26',
    catname varchar(10) NOT NULL COMMENT 'Nombre descriptivo abreviado de un tipo de eventos en un grupo, ejemplo: Opera',
    eventname varchar(200) NOT NULL COMMENT 'Nombre del evento, ejemplo: Hamlet.',
    localidad varchar(150) NOT NULL COMMENT 'Nombre del recinto, ejemplo: Cleveland Browns Stadium, concatenado con el nombre de la ciudad, ejemplo: Cleveland.',
    starttime timestamp NOT NULL COMMENT 'Fecha y hora de inicio del evento, ejemplo: 2008-10-10 19:30:00',
    PRIMARY KEY (show_id)
)
DEFAULT CHARACTER SET = utf8mb4;
/*
*   Se crea la tabla con las columnas y se incluie "show_id" como clave primaria autoincremental para preservar la consistencia
*   de los datos y facilitar los posteriores tratamientos que pueda tener la tabla.
*   Se establece utf8mb4 como formato de caracteres en uso para preservar la coherencia con el resto de tablas.
*   "Año" se ha definido como "anyo" ya que podria dar problemas al usar un caracter especial.
*   Localidad se nos daba con longitud 15 pero se amplia a 150 ya que se están concatenando dos columnas
*   con longitudes más largas.
*/


--
-- Punto 2:
-- 
--  Crear un procedimiento almacenado denominado "show_semana_proxima" que realice lo siguiente:
--  * Vaciar la tabla show_semanales.
--  * Llenar la tabla con los shows planificados para la semana siguiente a la semana en curso.
--

DELIMITER //
CREATE PROCEDURE shows_semana_proxima()

BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Se ha producido un error. La tabla shows_semana ha quedado vacía.';
    END;
    START TRANSACTION;

    TRUNCATE TABLE shows_semanales; -- -- No se recupera por ROLLBACK

    INSERT INTO shows_semanales(anyo, mes, semana, catname, eventname, localidad, starttime)
        SELECT  d.year, d.month, d.week, c.catname, e.eventname,
                CONCAT(v.venuecity, ', ', v.venuename),
                e.starttime
        FROM date d
        JOIN event e ON e.dateid = d.dateid
        JOIN category c ON c.catid = e.catid
        JOIN venue v ON v.venueid = e.venueid
        WHERE   d.week = WEEKOFYEAR(CURDATE()) +1 AND d.year = YEAR(CURDATE());
    COMMIT;
END//
DELIMITER ;
/*
*   Puesto que los datos contenidos en esta tabla solamente son utiles para la semana en curso podemos hacer uso
*   de TRUNCATE en lugar de DELETE para borrar la tabla. TRUNCATE no permite recuperación, y estos datos se pueden volver
*   a obtener de la BBDD.
*   El HANDLER que se ha establecido en caso de fallo no dejará la tabla con datos incompletos si no que la dejará vacía,   
*   de esta forma no tendremos una tabla incompleta o con datos de la semana anterior.
*/


--
-- Punto 3:
--
--  Crear un evento que ejecute cada día sábado a las 8 de la mañana el procedimiento "shows_semana_proxima"
--  y que permita exportar la tabla "shows_semanales" generada por el procedimiento anterior a un archivo de texto.
--

DELIMITER //
CREATE EVENT shows_proxima_semana
ON SCHEDULE EVERY 1 WEEK
STARTS '2024-12-14 08:00:00'
DO
BEGIN
    CALL shows_semana_proxima();

    SELECT * INTO OUTFILE '/rdsdbdata/db/shows_semanales.txt' -- Ruta no comprobada.
    FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    FROM shows_semanales;
END //
DELIMITER ;
/*
*   - El evento está programado para iniciarse el sabado 14, al establecer la periodicidad en "EVERY 1 WEEK"
*     el evento se ejecutará cada sabado a las 8 AM.
*   - En el cuerpo del evento primero llamamos al procedimiento para realizar la ejecución y posteriormente
*     almacenamos los datos de la tabla en un fichero. El fichero no sabemos donde se puede crear en el servidor AWS
*     ni si tenemos permisos, por lo que hemos podido ver analizando la teoría los ficheros solamente se guardan en el lado
*     del servidor.
*   - De cara a la base de datos en AWS la ruta para el archivo la hemos tomado de MySQL Workbench "Server > Server Status" pero no está verificada.
*   - En las bases de dato locales se ha usado la ruta "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/eventos_semanales.txt"
*     que si es operativa y nos dejaba crear el archivo de texto.
*
*   - Para obtener la fecha lo hemos hecho de dos formas, una es la directa, estableciendo una fecha en sabado y comenzar a ejecutar en intervalos de 1 semana
*     pero tambien hemos visto que se puede realizar con un calculo de intervalos para que nuestro evento se ejecute:
*     Al crear el evento se calcula la proxima ejecución del evento teniendo en cuenta la sentencia que se le entregue en START. con la siguiente sentencia se podria calcular el primer sabado que se debe ejecutar
*     y evitariamos posibles errores al establecer una fecha directa.
*     STARTS (CURRENT_DATE() + INTERVAL (6 - WEEKDAY(CURRENT_DATE())) DAY + INTERVAL 8 HOUR)
*/


--
-- Punto 4:
--
--  Crear manualmente una tabla denominada "ventas_entradas". Agregar los siguientes campos: caldate, sellerid, sellername,
--  email, qtysold, pricepaid, profit.
--

CREATE TABLE IF NOT EXISTS ventas_entradas(
    venta_id INT AUTO_INCREMENT,
    caldate date NOT NULL COMMENT 'Fecha de calendario, como 2008-06-24',
    sellerid INT NOT NULL COMMENT 'Referencia de clave externa a la tabla USERS (el usuario que vendió los tickets)',
    sellername varchar(62) NOT NULL COMMENT 'Usar la función NombreResumido para llenar este campo',
    email varchar(100) NOT NULL COMMENT 'Dirección de correo electrónico del usuario',
    qtysold INT NOT NULL COMMENT 'La cantidad de entradas vendidas en una fecha',
    pricepaid decimal(8,2) NOT NULL COMMENT 'La suma del precio total por la venta de entradas',
    profit decimal(8,2) GENERATED ALWAYS AS ((pricepaid * 0.85)) STORED
                        COMMENT 'La suma de las ganancias 85% a pagar al vendedor para ese día',
    PRIMARY KEY (venta_id),
    FOREIGN KEY (sellerid) REFERENCES users (userid)
)
DEFAULT CHARACTER SET = utf8mb4;
/*
*   Se ha implemnetado un valor autocalculado para la columna "profit" para calcular la ganancia de la venta
*   al igual que se realizó, en un producto anterior, con "commission" en la tabla sales para calcular la comision de venta.
*   
*   "sellername" se le cambia la longitud de 35 a 62 caracteres ya que es lo que retorna nuestra funcion "NombreResumido".*

    Se ha incluido una clave foranea que relaciona sellerid y userid en caso de que esta tabla la utilicemos para realizar
    más consultas. En casso de no usar más consultas seria innecesaria.
*/


--
-- Punto 5:
--
--  Crear un procedimiento almacenado denominado "profit_sellers" que realice lo siguiente:
--  * Vaciar la tabla "ventas_entradas".
--  * Llenar la tabla para el día y mes que coincida con el día y el mes de la fecha actual (CURRENT_DATE()).
--    La tabla deberá tener un registro por cada vendedor cuyas ventas de ese día sean superiores a 0.
--


DELIMITER //
CREATE PROCEDURE profit_sellers()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Se ha producido un error. La tabla venta_entradas ha quedado vacía.';
    END;
    START TRANSACTION;

    TRUNCATE TABLE venta_entradas; -- No se recupera por ROLLBACK

    INSERT INTO ventas_entradas(caldate, sellerid, sellername, email, qtysold, pricepaid)
        SELECT  d.caldate,
                s.sellerid,
                NombreResumido(u.firstname, u.lastname),
                u.email,
                s.qtysold,
                s.pricepaid
        FROM sales s
        JOIN date d ON s.dateid = d.dateid
        JOIN users u ON u.userid = s.sellerid
        WHERE DAY(d.caldate) = DAYOFMONTH(NOW())
        AND MONTH(d.caldate) = MONTH(now())
        -- AND YEAR(d.caldate) = 2008
        AND s.qtysold > 0;
    COMMIT;
END //
DELIMITER ;
/*
*   - De la misma forma que en el Punto 2 ROLLBACK no recupera los datos de TRUNCATE pero de esta forma
*     no dejamos la tabla a medias o con datos antiguos en caso de error.
*     Usamos TRUNCATE ya que los datos son recuperables del resto de tablas de la BBDD.
*   - "s.qtysold > 0" esta sentencia se ha colocado por seguridad ya que entendemos que si existe una venta esta no va a ser 0,
*     ya que en la tabla "sales" solamente almacenamos transacciones de venta no existiendo ningún "sellerid" que esté a cero.
*   
*/


--
-- Punto 6:
--
--  Crear un evento que ejecute cada día a las 23:59 el procedimiento "profit_sellers"
--


CREATE EVENT actualizar_profit_diario
ON SCHEDULE EVERY 1 DAY
STARTS '2024-12-14 23:59:00'
DO
    CALL profit_sellers();
/*
*   Se ha creado el procedimiento "profit_sellers" y se llama mediante este evento tal y como se solicita en el ejercicio
*   pero no compartimos la forma de proceder de este evento.
*   Motivo:
*     - Hacer llamada del procedimiento a las 23:59 puede causar que en el minuto que resta hasta las 0:00 tengamos ventas
*       que no se contabilicen en esta tabla, si se ajusta hasta las 23:59:59 tiene más peligro, ya  que podría entrar una venta en
*       el último segundo y/o que, debido a la carga de trabajo de la BBDD, nuestro procedimiento se ejecute fuera del día objetivo
*       no consiguiendo mostrar el resumen del día por estar ya en un nuevo día.
*   Forma de proceder que creemos más correcta:
*     - Crear el procedimiento para que cargue los datos en la tabla del día anterior.
*     - Lanzar el evento de forma diaria a las 0:00h si se requieren los datos del cierre en el momento o posponerlo a una hora
*       más tardía si los datos no se requieren de inmediato y sabemos que hay horas nocturnas con menos carga.      

*   Así como se hizo en el punto 3 tambien podemos buscar el primer día de ejecución mediante una sentencia en STRAT
*   STARTS CURRENT_DATE() + INTERVAL 23 HOUR + INTERVAL 59 MINUTE

*/


--
-- Punto 7:
--
--  Inventar un procedimiento almacenado que permita optimizar las operaciones del sistema. Justificarlo
--  SE HA DECIDIDO IMPLEMENTAR 2 PROCEDIMIENTOS EN LUGAR DE 1
--

-- PROCEDIMIENTO 1:

DELIMITER //
CREATE PROCEDURE UpdateVIPStatus()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Si ocurre un error, revertimos la transacción
        ROLLBACK;
        SELECT 'Se ha producido un error. Se ha establecido los datos previos.';
    END;

    -- Inicia la transacción
    START TRANSACTION;

    -- Usuarios que han comprado más de 10 tickets
    UPDATE users
    SET vip = '1'
    WHERE userid IN (
        SELECT buyerid
        FROM sales
        GROUP BY buyerid
        HAVING SUM(qtysold) > 10
    );

    -- Usuarios que han vendido más de 25 tickets
    UPDATE users
    SET vip = '1'
    WHERE userid IN (
        SELECT sellerid
        FROM listing
        GROUP BY sellerid
        HAVING SUM(numtickets) > 25
    );   
    
    -- Confirma la transacción si todo salió bien
    COMMIT;
END //
DELIMITER ;



-- Evento que ejecuta UpdateVIPStatus() cada día a las 4 AM.
DELIMITER //
CREATE EVENT ActualizarVIPDiario
ON SCHEDULE EVERY 1 DAY
STARTS '2024-12-14 04:00:00'
DO

    DROP TRIGGER IF EXISTS trg_check_username;
    DROP TRIGGER IF EXISTS before_update_email;
    SET SQL_SAFE_UPDATES = 0;
    CALL UpdateVIPStatus();
    SET SQL_SAFE_UPDATES = 1;


    CREATE TRIGGER IF NOT EXISTS trg_check_username
    BEFORE UPDATE ON users
    FOR EACH ROW
    BEGIN
        IF NOT (NEW.username REGEXP '^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[-_#@]).{1,}$') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username debe contener mayúsculas, minúsculas, dígitos y al menos uno de los símbolos: -_#@';
        END IF;
    END;

    CREATE TRIGGER IF NOT EXISTS before_update_email
    BEFORE UPDATE ON `users`
    FOR EACH ROW
    BEGIN
        IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El formato del email a de ser nombre@dominio.com';
        END IF;
    END//

DELIMITER ;
/*
*   - Se ha aprovechado la sentencia que cremos en el producto 3 la cual activa el estatus VIP de los clientes
*     para usuarios con más de 10 tickets comprados y más de 25 vendidos para convertirla en un procedimiento alamcenado
*     que se ejecuta cada día a las 4 AM, aprovechando la baja carga de la BBDD y que este tipo de transacción podría llegar a consumir recursos.
*   - Se ha implementado un rollback en caso de cualquier posible error.
*     De esta forma se actualiza de form diaria el posible nuevo estatus de los clientes segun la politica de fidelización
*     que tiene implementada la empresa con sus clientes.
*
*   - El la corrección del producto 3 se nos indicó que los triguers se puede activar y desactivar con sentencias ALTER trigger nombre_trigger
*   - y lo mismo para los triggers de una tabla completa. Se ha probado la forma que se nos indicó pero MySQL nos da error, por este motivo
*     borramos con DROP lo triggers para volverlos a crear. Quizas esta no sea la mejor forma pero es como hemos conseguido no tener errores.
*/



-- PROCEDIMIENTO 2:

DROP PROCEDURE IF EXISTS historial;
DELIMITER //

CREATE PROCEDURE historial(IN usuario INT)
BEGIN
    SELECT u.userid AS ID, u.firstname AS Nombre, u.lastname AS Apellido, d.caldate AS Fecha, e.eventname AS Evento,
        CASE
            WHEN s.sellerid = usuario THEN 'Venta'
            WHEN s.buyerid = usuario THEN 'Compra'
        END AS Transaccion,
        s.qtysold AS Cantidad, s.pricepaid AS Precio
    FROM sales s
    JOIN date d ON s.dateid = d.dateid
    JOIN event e ON s.eventid = e.eventid
    JOIN users u ON u.userid = usuario
    WHERE s.sellerid = usuario OR s.buyerid = usuario;
END //

DELIMITER ;

CALL historial(1); 

/* Procedimiento que dice el historial de compras y ventas de un usuario.
 * 
 * Comprueba si el procedimiento historial ya existe y en tal caso lo borra para facilitar actualizaciones.
 * Crea el procedimiento historial con un parametro de entrada tipo INT llamado usuario.
 * Selecciona los datos que se van a mostrar enla tabla de salida,
 * En la columna transacción tiene en cuenta dos casos posibles venta o compra segun que id de usuario coincida
 * con el parametro de entrada si el id de vendedor o el de comprador.
 * Une las tablas correspondientes para poder acceder a sus datos.
 * En el caso de la tabla users la une mediante la variable usuario, ya que al intentar unirla mediante las columnas
 * selleir y buyerid generaba resultados indeseados añadiendo usuarios de más.
 * Filtra los usuarios que hayan realizado alguna compra o venta.
 * Ejecuta el procedimiento para verificar su funcionamiento para userid = 1
 *
 */
