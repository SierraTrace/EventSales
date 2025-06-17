-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Producto 3
--
-- Grupo: Cnv20241_Grupo07: [DB Masters]
-- 
--
-- Database: [fp_046_07]
-- --------------------------------------------------------------

--
-- Punto 9:
--
-- Mostrar aquellos eventos que se lleven a cabo durante el mes que coincida con el mes en curso.
-- (Ejemplo: si la consulta se hace en marzo, los eventos de marzo de 2008)
-- El listado deberá mostrar los siguientes campos, y estar ordenado por las semanas del mes (week):
-- eventid, eventname, caldate, week, coincideSemana (sí/no).
--

SELECT e.eventid, e.eventname, d.caldate, d.week,
    CASE
        WHEN d.week = WEEK(CURDATE()) THEN 'Sí'
        ELSE 'No'
    END AS CoincideSemana
FROM event e
JOIN date d on e.dateid = d.dateid
WHERE MONTH(d.caldate) = MONTH(CURDATE());
/*  
*   WEEK(CURDATE()) devuelve el numero de semana del año, se compara con la columna date.week con un CASE y
*   posteriormente acotamos los resultados para el mes en curso.
*/

--
-- Punto 10:
--
-- Mostrar cuántos usuarios que han comprado entradas para los eventos de la semana 9 son "locales".
-- Se considera que un usuario es local, si el nombre de la ciudad donde se realiza el evento es igual a la ciudad natal del usuario,
-- de lo contrario es un visitante. Utilizar la función IF y agrupar.
--

-- Sentencia solución:
SELECT 
    CONCAT(e.eventid, ' - ', e.eventname) AS Evento,
    SUM(IF(u.city = TRIM(v.venuecity), 1, 0)) AS AsistentesLocales,
    SUM(IF(u.city != TRIM(v.venuecity), 1, 0)) AS Visitantes
FROM sales s
JOIN event e ON s.eventid = e.eventid
JOIN date d ON s.dateid = d.dateid
JOIN users u ON s.buyerid = u.userid
JOIN venue v ON e.venueid = v.venueid
WHERE d.week = 9
GROUP BY e.eventid, e.eventname;

-- Sentencias para Verificar:
SELECT COUNT(*) AS total_visitantes
FROM sales s
JOIN event e ON s.eventid = e.eventid
JOIN date d ON s.dateid = d.dateid
JOIN users u ON s.buyerid = u.userid
JOIN venue v ON e.venueid = v.venueid
WHERE u.city != TRIM(v.venuecity);

SELECT u.userid, e.eventid, d.dateid, d.caldate, d.week
FROM sales s
JOIN event e ON s.eventid = e.eventid
JOIN date d ON s.dateid = d.dateid
JOIN users u ON s.buyerid = u.userid
JOIN venue v ON e.venueid = v.venueid
WHERE u.city = TRIM(v.venuecity);
/*
* Se ha realizado la verificación para comparar entre users.city y venue.venuecity, se ha observado que vennuecity tiene
* espacios en blanco en el primer caracter del String por lo cual se ha usado TRIM() limpiando la cadena por detras y por delante de
* espacios. Usando las consulta anotadas como --Verificar y jugando con el simbolo entre u.city = o != podemos ver que existen
* 27 locales y 66825 visitantes entre los datos de toda la BBDD.
* La segunda sentencia para verificar se ha usado para obtener semanas donde existan usuarios locales, obteniendo los 27 casos
* que existen en la BBDD, con ello podemos jugar con el WHERE d.week = (a una semana de esta lista) y verificar el uso con datos
* que sabemos que deberian dar un resultado con usuarios locales.

** En semana 11 hay locales y visitantes

*/

-- 
-- Punto 11:
-- 
-- Eliminar de la tabla users a todos aquellos usuarios registrados que no hayan comprado ni vendido ninguna entrada.
-- Antes de eliminarlos, copiarlos a una tabla denominada backup_users para poder recuperarlos en caso de ser necesario.
--

DROP TABLE IF EXISTS backup_users;
CREATE TABLE backup_users LIKE users;
INSERT INTO backup_users(userid, username, firstname, lastname, city, state, email, phone,
    likesports, liketheatre, likeconcerts, likejazz, likeclassical, likeopera,  likerock, likevegas, likebroadway, likemusicals, vip, birthdate)
SELECT userid, username, firstname, lastname, city, state, email, phone,
    likesports, liketheatre, likeconcerts, likejazz, likeclassical, likeopera,  likerock, likevegas, likebroadway, likemusicals, vip, birthdate
FROM users u
LEFT JOIN sales s1 ON s1.sellerid = u.userid
LEFT JOIN sales s2 ON s2.buyerid = u.userid
WHERE s1.sellerid IS NULL AND s2.buyerid IS NULL;

-- Verificacion = 7438 Usuarios a borrar.
SELECT COUNT(*) AS TotalUsuariosABorrar
FROM backup_users;

-- Verificación = 49990 Usuarios totales antes de borrar.
SELECT COUNT(*) FROM users;

CREATE TABLE users_backup_preborrado AS
SELECT * FROM users;


SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM users
WHERE userid IN (SELECT userid FROM backup_users);
SET FOREIGN_KEY_CHECKS = 0;


-- Resultado final de la tabla users deberia ser: 49990 - 7438 = [42552]
SELECT COUNT(*) FROM users;

/*
* Se han probado las dos sentencias siguientes antes de llegar a esta conclusión. Es interesante saber que MySQL
* nos obliga a crear primero una tabla desde la que lanzar el DELETE para borrar por comparación.
*/

-- Descartada por error 2013
DELETE FROM users
WHERE userid IN (
    SELECT u.userid
    FROM users u
    LEFT JOIN sales s1 ON u.userid = s1.sellerid
    LEFT JOIN sales s2 ON u.userid = s2.buyerid
    LEFT JOIN listing l ON u.userid = l.sellerid
    WHERE IFNULL(s1.sellerid, 0) = 0 
    AND IFNULL(s2.buyerid, 0) = 0 
    AND IFNULL(l.sellerid, 0) = 0
);
/* 
* Se ha intentado usar la sentencia anterior pensando que el ejercicio se debe resolver con funciones condicionales,
* se ha usado IFNULL pero la BBDD da error code 2013 que es un error de tiempo excedido, la sentencia es muy lenta y excede el tiempo.
*/

-- Descartada: Sentencia más optima que no excede del tiempo
DELETE FROM users
WHERE userid IN (
    SELECT u.userid
    FROM users u
    LEFT JOIN sales s1 ON u.userid = s1.sellerid
    LEFT JOIN sales s2 ON u.userid = s2.buyerid
    LEFT JOIN listing l ON u.userid = l.sellerid
    WHERE s1.sellerid IS NULL 
    AND s2.buyerid IS NULL 
    AND l.sellerid IS NULL
);
/*
* Con esta sentencia no se puede borrar. MySQL da error 1093, Para borrar primero se debe crear una tabla y despues
* por seleccion se deben borrar los campos.
*/


--
-- Punto 12:
-- 
-- Mostrar una lista de usuarios donde se especifique para cada usuario si éste es un comprador (sólo ha comprado entradas),
-- un vendedor (sólo ha vendido entradas) o ambos. Utilizar la función CASE y agrupar.
--

CREATE VIEW compra_venta AS
SELECT u.userid, u.username, u.firstname, u.lastname,
    CASE 
        WHEN s1.sellerid IS NOT NULL AND s2.buyerid IS NOT NULL THEN 'Ambos'
        WHEN s1.sellerid IS NOT NULL THEN 'Vendedor'
        WHEN s2.buyerid IS NOT NULL THEN 'Comprador'
    END AS rol
FROM users u
LEFT JOIN (SELECT DISTINCT sellerid FROM sales) s1 ON u.userid = s1.sellerid
LEFT JOIN (SELECT DISTINCT buyerid FROM sales) s2 ON u.userid = s2.buyerid
GROUP BY rol, u.userid, u.username, u.firstname, u.lastname;


-- Verificamos el total de usuarios
SELECT rol, COUNT(*) AS total
FROM compra_venta
GROUP BY rol;

/*
*   Hemos crado la selección como vista ya que es más fácil aplicar posteriormente la consulta de verificacíon y poder
*   comprovar que todos los valores se ajustan a una de las categorias.
*/


--
-- Punto 13:
--
-- Inventar una consulta que haga uso de una de las siguientes funciones: COALESCE, IFNULL, NULLIF.
-- Explicar su objetivo en los comentarios.
--


SELECT 
    venuename, venuecity,
    IFNULL(venueseats, 'No disponible') AS 'Asientos disponibles'
FROM venue;
/*
*   Muestra si hay asientos disponibles o no para un evento usando IFNULL
*/


SELECT 
    u.userid, u.username, u.firstname, u.lastname,
    COALESCE(SUM(s.qtysold), 'No ha vendido nada') AS Ventas
FROM users u
LEFT JOIN sales s ON s.sellerid = u.userid
GROUP BY u.userid
ORDER BY u.userid ASC;
/* Esta consulta usa la función COALESCE para mostrar el id, nombre de usuario, nombre y apellido de los usuarios y la cantidad de ventas que han realizado
* o la frase "No ha vendido nada" en el caso de que este usuario en concreto no haya realizado ninguna venta.
*/



-- --------------------------------------------------------------
-- FUNCIONES UDF
-- --------------------------------------------------------------

--
-- Punto 14:
-- 
-- Crear una función UDF llamada NombreResumido que reciba como parámetros un nombre y un apellido y retorne un nombre en formato:
-- (Inicial de Nombre + "." + Apellido en mayúsculas. Ejemplo: L. LANAU).
-- Probar la función en una consulta contra la tabla de socios y enviando directamente el nombre con tus datos en forma literal, por ejemplo escribir:
-- SELECT NombreResumido("Rita", "de la Torre") para probar la función, deberá devolver: R. DE LA TORRE.


DELIMITER //
	CREATE FUNCTION NombreResumido(nombre VARCHAR(30), apellido VARCHAR (30))
	RETURNS VARCHAR (62)
	DETERMINISTIC
	BEGIN
      RETURN CONCAT(UPPER(LEFT(nombre, 1)) , '. ', UPPER(apellido));
	END; //
DELIMITER ;

-- Verificar
SELECT NombreResumido("Rita", "de la Torre") AS NombreResumido;
/*
*   Se retorna una VARCHAR(62) Teniendo en cuenta que si el nombre y el apellido ocuparan los 30 + 30 caracteres debemos añadir ". " que son 2 más.
*/


--
-- Punto 15:
--
-- Actualizar el campo VIP de la tabla de usuarios a sí a aquellos usuarios que hayan comprado más de 10 tickets para los eventos
-- o aquellos que hayan vendido más de 25 tickets.
--

-- Aseguramos los datos con una copia
CREATE TABLE users_backup_vip AS
SELECT * FROM users;

-- Creamos procedimiento almacenado
DELIMITER //
CREATE PROCEDURE UpdateVIPStatus()
BEGIN    
    -- Usuarios comprado + de 10 tickets
    UPDATE users
    SET vip = '1'
    WHERE userid IN (
        SELECT buyerid
        FROM sales
        GROUP BY buyerid
        HAVING SUM(qtysold) > 10
    );
    -- Usuarios vendido + de 25 tickets
    UPDATE users
    SET vip = '1'
    WHERE userid IN (
        SELECT sellerid
        FROM listing
        GROUP BY sellerid
        HAVING SUM(numtickets) > 25
    );
END//
DELIMITER ;

-- Eliminar Trigger
DROP TRIGGER IF EXISTS trg_check_username;
DROP TRIGGER IF EXISTS before_update_email;

-- Llamada del procedimiento evitando modo seguro
SET SQL_SAFE_UPDATES = 0;
CALL UpdateVIPStatus();
SET SQL_SAFE_UPDATES = 1;

-- Crear de nuevo los trigger del Producto 1
DELIMITER //
    CREATE TRIGGER trg_check_username
    BEFORE UPDATE ON users
    FOR EACH ROW
    BEGIN
        IF NOT (NEW.username REGEXP '^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[-_#@]).{1,}$') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username debe contener mayúsculas, minúsculas, dígitos y al menos uno de los símbolos: -_#@';
        END IF;
    END;

    CREATE TRIGGER before_update_email
    BEFORE UPDATE ON `users`
    FOR EACH ROW
    BEGIN
        IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El formato del email a de ser nombre@dominio.com';
        END IF;
    END//
DELIMITER ;

/* 
*   Se ha optado por crear un procedimiento y su llamada ya que es un tipo de actualización que seguramente se use de forma periodica y
*   para poder llevar a cabo el proceso de actualización requiere de multiples acciones diferentes.
*   Las sentencias de update requieren desactivar el modo seguro de las consultas ya que obteniamos el error 1175
*   este error se da ya que las subconsultas no contienen WHERE y modifica una gran cantidad de filas, Por este motivo,
*   se activa y desactiva el modo seguro SQL_SAFE_UPDATES.
*   Existen 2 Trigger que se crearon en Producto 1 que imposibilitan la actualizacion de los campos de la tabla users, se han borrado
*   y posteriormente creado de nuevo. No hemos visto otra forma de deshabilitarlos.
*/

--
-- Punto 16:
--
-- Crear una función UDF llamada Pases_cortesia. Se regalará 1 pase de cortesía por cada 10 tickets comprados o vendidos, a los usuarios VIP.
-- Hacer una consulta denominada pases_usuarios para probar la función y guardarla como una vista.
-- Los campos de la misma deberán ser: userid, username, NombreResumido, número de pases.
--

DROP FUNCTION IF EXISTS Pases_cortesia;
DELIMITER //
CREATE FUNCTION Pases_cortesia(cantidad INT,es_vip ENUM('0', '1'))
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN IF(es_vip = 1, cantidad DIV 10, 0);
END//
DELIMITER ;

/* 
*   Creamos una función que data una cantidad de compra/ventas genera el número de pases de coresía que le corresponden al usuario
*   siempre que se trate de un usuario vip.
*/

DROP VIEW IF EXISTS pases_usuarios;
CREATE VIEW pases_usuarios AS
SELECT u.userid, 
       u.username, 
       NombreResumido(u.firstname, u.lastname) AS NombreResumido,
       Pases_cortesía(SUM(s.qtysold), u.vip) AS `número_de_pases`
FROM users u
JOIN sales s ON (s.sellerid = u.userid OR s.buyerid = u.userid)
GROUP BY u.userid, u.vip
HAVING Pases_cortesía(SUM(s.qtysold), u.vip) > 0
ORDER BY u.userid;
/* 
*   Creamos una vista que guarda los pases que tiene cada usuario.
*   Usa la funcion Nombre resumido creada en el punto 14 y la funcion Pases_cortesia recien creada en esta misma pregunta.
*   Une la tabla ventas a la tabla usuarios ya sea un usuario vendedor o comprador.
*   Agrupa los datos por id de usuario y por su estatus de vip o no.
*   Condiciona los datos a usuarios que tengan 1 o más pases de cortesía.
*   Ordena los daros por id de usuario.
*/


--
-- Punto 17:
--
-- Actualizar el campo birthdate de la tabla users, creado en el P1. Con la sentencia proporcionada.
--

-- Aseguramos los datos con una copia
CREATE TABLE users_backup_birthdate AS
SELECT * FROM users;

DROP TRIGGER IF EXISTS trg_check_username;
DROP TRIGGER IF EXISTS before_update_email;

SET SQL_SAFE_UPDATES = 0;

update users
set birthdate = str_to_date(
concat(
   floor(1 + rand() * (12-1)), '-',
   floor(1 + rand() * (28-1)), '-',
   floor(1 + rand() * (1998-1940) + 1940)),'%m-%d-%Y');

SET SQL_SAFE_UPDATES = 1;

DELIMITER //
    CREATE TRIGGER trg_check_username
    BEFORE UPDATE ON users
    FOR EACH ROW
    BEGIN
        IF NOT (NEW.username REGEXP '^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[-_#@]).{1,}$') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username debe contener mayúsculas, minúsculas, dígitos y al menos uno de los símbolos: -_#@';
        END IF;
    END;

    CREATE TRIGGER before_update_email
    BEFORE UPDATE ON `users`
    FOR EACH ROW
    BEGIN
        IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El formato del email a de ser nombre@dominio.com';
        END IF;
    END//
DELIMITER ;

DROP TABLE users_backup_birthdate;
/*
*   De nuevo, para actualizar la tabla users se deben eliminar los Triggers, deshabilitar el modo seguro, ejecutar la sentencia
*   y volver a crear los triggers del Producto 1.
*/


--
-- Punto 18:
--
-- Crear una función UDF llamada Kit_Eventos. Se regalará un kit a aquellos usuarios VIP que cumplan años durante el mes
-- (que recibirá la función por parámetro). La función devolverá "Kit" o "-". Hacer una consulta pertinente para probar la función.
-- 

DROP FUNCTION IF EXISTS Kit_eventos;
DELIMITER //
CREATE FUNCTION Kit_eventos(cumpleanios DATE, mes INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    RETURN IF(MONTH(cumpleanios) = mes, 'Kit', '-');
END//
DELIMITER ;


SELECT  u.userid, username, u.birthdate,
        NombreResumido(u.firstname, u.lastname) AS Nombre,
        Kit_eventos(u.birthdate, MONTH(NOW())) AS Tiene_kit
FROM users u
WHERE vip = '1';
/*  Creo una función Kit_eventos la cual dada una fecha y un nuero de mes
* devuelve 'Kit' si le corresponde un kit al usuario (su cumpleaños es en el mes actual)
* o '-' si su cumpleaños es en cualquier otro mes.
* Filtrando con un WHERE vip = '1', obtenemos el resultado esperado por el enunciado.
*/

-- Verificar que la consulta anterior cuenta correctamente. Retorna 405 usuarios en Noviembre
SELECT userid, 
       NombreResumido(firstname, lastname) AS NombreResumido, 
       birthdate, 
       'Kit' AS Kit_Asignado
FROM users
WHERE vip = '1'
AND MONTH(birthdate) = MONTH(CURDATE());
/*
*
*/   

--
-- Punto 19:
-- 
-- Inventar una función UDF que permita optimizar las operaciones de la Base de Datos. Justificarla.
--

DELIMITER //
CREATE FUNCTION TotalVentasUsuario (user_id INT, fecha_inicio DATE, fecha_fin DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_ventas DECIMAL(10,2);

    SELECT SUM(pricepaid)
    INTO total_ventas
    FROM sales
    WHERE sellerid = user_id
    AND saletime BETWEEN fecha_inicio AND fecha_fin;

    RETURN COALESCE(total_ventas, 0);
END //
DELIMITER ;


SET @user_id = 8117;
SET @fecha_inicio = '2008-01-01';
SET @fecha_fin = '2008-12-31';

-- Utilizar la función en una consulta
SELECT  userid, username, 
        TotalVentasUsuario(@user_id, @fecha_inicio, @fecha_fin) AS TotalVentas
FROM users
WHERE userid = @user_id;
/*
*   Con esta función podemos calcular el monto total de ventas de un usuario en un periodo de tiempo
*   Al encapsular estos cálculos podemos simplificar las consultas y asegurarnos que si en un periodo de tiempo
*   especificado no hay ventas retornaremos 0 y no un valor nulo al usar COALESCE().
*/

-- --------------------------------------------------------------
-- VARIABLES DE @USUARIO
-- --------------------------------------------------------------

-- 
-- Punto 20:
--
-- Hacer una vista llamada cumpleanhos. La consulta de la vista, deberá tener los siguientes campos:
-- userid, username, NombreResumido, VIP, dia, mes, birthdate.
--

CREATE VIEW cumpleanhos AS
SELECT 
    userid, 
    username, 
    NombreResumido(firstname, lastname) AS NombreResumido, 
    vip, 
    DAY(birthdate) AS dia, 
    MONTH(birthdate) AS mes, 
    birthdate
FROM users;
/*
*   Con la vista obtenemos todos los usuarios de la tabla users en el formato que se indica para la consulata.   
*/

--
-- Punto 21:
-- 
-- Crear dos variables de usuario. Una denominada @esVIP y la otra @monthbirthday.
-- Asignar un valor a la variable @esVIP (true / false).
-- Asignar el valor del mes en curso a la variable @monthbirthday
-- 

SET @esVIP = TRUE;
SET @monthbirthday = MONTH(CURDATE());


--
-- Punto 22:
-- 
-- Hacer una consulta basada en la vista cumpleanhos que utilice las variables de usuario para filtrar los cumpleañeros del mes
-- en @monthbirthday cuyo valor en el campo VIP coincida con el asignado a la variable @esVIP.
--

SELECT userid, 
       username, 
       NombreResumido, 
       CASE 
           WHEN vip = '1' THEN 'Sí' 
           ELSE 'No' 
       END AS VIP, 
       dia, 
       mes, 
       birthdate
FROM cumpleanhos
WHERE mes = @monthbirthday
AND vip = IF(@esVIP, '1', '0');
/*
* Con esta consulta volvemos a verificar lo obtenido el Punto 18. Tenemos 405 usuarios vip que cumplen años en Noviembre.
*/
