-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Producto 2
--
-- Grupo: Cnv20241_Grupo07: [DB Masters]
-- 
-- Integrantes: 
Esther Vanesa Sierra Sánchez
Daniel Carrasco Luque
--
-- Database: [fp_046_07]
-- --------------------------------------------------------------

-- --------------------------------------------------------------
-- COMBINACIONES EXTERNAS
-- --------------------------------------------------------------
--
-- Punto 14:
--
-- Crear una nueva tabla usuarios sin compras que deberá guardar aquellos usuarios que no han comprado ningún ticket
-- con los campos userid, firstname, lastname, phone.
--       

CREATE TABLE IF NOT EXISTS users_no_buy AS
SELECT u.userid, u.firstname, u.lastname, u.phone
FROM users u
LEFT JOIN sales s ON u.userid = s.buyerid
WHERE s.buyerid IS NULL;
/*
*   Se utiliza LEFT JOIN para devolver los datos de la primera tabla ("LEFT" izquierda) consultados respecto a la segunda a la derecha
*/


--
-- Punto 15:
--
-- Crear una nueva tabla usuarios sin ventas que deberá guardar aquellos usuarios que no han vendido ningún ticket
-- con los campos userid, firstname, lastname, phone.
--

CREATE TABLE IF NOT EXISTS users_no_sales AS
SELECT u.userid, u.firstname, u.lastname, u.phone
FROM users u
LEFT JOIN sales s ON u.userid = s.sellerid
WHERE s.sellerid IS NULL;
/*
*   El concepto es el mismo que en le punto 14.
*/


--
-- Punto 16:
--
-- Mostrar una lista con todos los usuarios que no se encuentren en la tabla listing con los campos userid, firstname, lastname, phone.
--

SELECT u.userid, u.firstname, u.lastname, u.phone
FROM users u
LEFT JOIN listing l ON u.userid = l.sellerid
WHERE l.sellerid IS NULL;

--
-- Punto 17:
-- 
-- Mostrar aquellas fechas en las cuales no ha habido ningún evento. Se deberá mostrar los campos caldate y holiday
--

SELECT d.caldate, d.holiday
FROM date d
LEFT JOIN event e ON d.dateid = e.dateid
WHERE e.dateid IS NULL;
/*
*   El listado que se muestra indica las 2 columnas caldate y holiday pero no muestra datos.
*   Eso implica que todas las fechas de la tabla date tienen almenos un evento asignado de la tabla event.
*/


-- --------------------------------------------------------------
-- SUBCONSULTAS
-- --------------------------------------------------------------
--
-- Punto 18:
--
-- Mostrar la cantidad de tickets vendidos y sin vender para las diferentes categorías de eventos.
--

SELECT  c.catname,
        (SELECT SUM(s.qtysold)
        FROM sales s
        JOIN listing l ON s.listid = l.listid
        JOIN event e ON l.eventid = e.eventid
        WHERE e.catid = c.catid) AS TicketsVendidos,
        (SELECT SUM(l.numtickets) - SUM(s.qtysold)
        FROM listing l
        LEFT JOIN sales s ON l.listid = s.listid
        JOIN event e ON l.eventid = e.eventid
        WHERE e.catid = c.catid) AS TicketsNoVendidos
FROM category c
GROUP BY c.catname;
/*
*   Dependiendo de como se interprete el enunciado podemos usar c.catname o c.catgrup.
*   Ambas consultas tienen la misma sentencia, solamente hay que intercambiar una por la otra en SELECT y GROPUP BY.
*   La diferencia es que obtendremos una selección más genérica acorde a lo que es catgrup.
*/


--
-- Punto 19:
--
-- Crea una consulta que calcule el precio promedio pagado por venta y la compare con el precio promedio por venta por trimestre.
-- La consulta deberá mostrar tres campos: trimestre, precio_promedio_por_trimestre, precio_promedio_total
--

SELECT  d.qtr AS trimestre,
        ROUND(AVG(s.pricepaid), 2) AS precio_promedio_por_trimestre,
        (SELECT ROUND(AVG(pricepaid), 2) FROM sales) AS precio_promedio_total
FROM sales s
JOIN date d ON s.dateid = d.dateid
GROUP BY d.qtr
ORDER BY d.qtr ASC;
/*
*   El SELECT principal está agrupado por trimestres, por lo cual calcula el promedio trimestral, mientras que el SELECT secundario
*   es una consulta independiente a la misma tabla sales pero sin aplicar filtro, lo cual calcula el promedio para todos los valores.
*/


--
-- Punto 20:
--
-- Muestra el total de tickets de entradas compradas de Shows y Conciertos.
--

SELECT
    (SELECT SUM(s.qtysold)
     FROM sales s
     JOIN listing l ON s.listid = l.listid
     JOIN event e ON l.eventid = e.eventid
     JOIN category c ON e.catid = c.catid
     WHERE c.catgroup = 'Shows') AS TicketsVendidosShows,
    (SELECT SUM(s.qtysold)
     FROM sales s
     JOIN listing l ON s.listid = l.listid
     JOIN event e ON l.eventid = e.eventid
     JOIN category c ON e.catid = c.catid
     WHERE c.catgroup = 'Concerts') AS TicketsVendidosConciertos;
/*
*   Realizamos un SELECT conjunto de 2 SELECT y lo muetra todo en una sola tabla con 2 columnas.
*/

--
-- Punto 21:
--
-- Muestra el id, fecha, nombre del evento y localización del evento que más entradas ha vendido.
--

SELECT e.eventid, d.caldate AS fecha, e.eventname, v.venuename
FROM event e
JOIN date d ON e.dateid = d.dateid
JOIN venue v ON e.venueid = v.venueid
WHERE e.eventid =
    (SELECT eventid
    FROM sales
    GROUP BY eventid
    ORDER BY SUM(qtysold) DESC
    LIMIT 1);
/*
*   El SELECT contenido en WHERE nos devuelve el único eventid con mayor cantidad de entradas vendidas y sirve de filtro
*   del SELECT principal para dar los datos especificados del evento allado.
*/


-- --------------------------------------------------------------
-- Vistas
-- --------------------------------------------------------------
--
-- Punto 22:
-- 
-- Crea una vista con los eventos del mes de la tabla que coincida con el mes actual. Grabar la vista con el nombre Eventos del mes
--

CREATE VIEW EventosDelMes AS
SELECT e.eventname, e.starttime, c.catname, v.venuename
FROM event e
JOIN category c ON e.catid = c.catid
JOIN venue v ON e.venueid = v.venueid
JOIN date d ON e.dateid = d.dateid
WHERE   MONTH(d.caldate) = MONTH(CURDATE());


SELECT * FROM EventosDelMes;
/*
*   La vista está creada para mostrar los eventos del mes que coincidan con el mes actual tal como se indica en el enunciado.
*   Esta vista nos permitirá ver todos los eventos que sucedan en el més en curso de cualquier año contenido en nuestra BBDD.
*   Si solamnte quisieramos ver los eventos que deben suceder en el mes y año actual incluiriamos en el WHERE la siguiente sentencia:
*  
*   AND YEAR(d.caldate) = YEAR(CURDATE())*  
*/


--
-- Punto 23:
--
-- Crear una vista que muestre las ventas por trimestre y grupo de eventos. Guardar con el nombre Estadisticas
--

CREATE VIEW estadisticas AS
SELECT  d.qtr AS Trimestre,
        c.catgroup AS GrupoEvento,
        SUM(s.qtysold) AS TotalTicketsVendidos,
        SUM(s.pricepaid) AS TotalIngresos,
        SUM(s.commission) AS ComisionGanada
FROM sales s
JOIN date d ON s.dateid = d.dateid
JOIN event e ON s.eventid = e.eventid
JOIN category c ON e.catid = c.catid
GROUP BY d.qtr, c.catgroup;


SELECT * FROM estadisticas
ORDER BY Trimestre ASC, GrupoEvento;
/*
*   Como grupo de eventos hemos interpretado que se filtre por category.catgroup. Mostrando una tabla donde agrupa
*   por Sports, Shows y Concerts. Si la interpretación es para cada categoria solamente devemos cambiar c.catgoup
*   por c.catid. AS GrupoEvento.
*/


-- --------------------------------------------------------------
-- UNION
-- --------------------------------------------------------------
--
-- Punto 24:
--
-- Crear una consulta de UNION producto de las tablas usuarios sin compras y usuarios sin ventas.
--

SELECT userid, firstname, lastname, phone, 'sin compra' AS status
FROM users_no_buy
  UNION
SELECT userid, firstname, lastname, phone, 'sin venta' AS status
FROM users_no_sales;
/*
*   Seleccion resultante de unir las 2 tablas user_no_sales y user_no_buy e indicar con una columna nombrada
*   status si son los resultados 'sin compra' o 'sin venta'.
*/


--
-- Punto 25:
-- 
-- Crear una consulta de UNION que en forma de tabla las columnas mes, año, 'ventas' as concepto, totalventas y
-- a continuación mes, año, 'comisiones' as concepto, totalcomisiones. Guardarla en forma de vista con el nombre operaciones.
--

CREATE VIEW operaciones AS
SELECT  d.month AS mes,
        d.year AS año,
        'ventas' AS concepto,
        SUM(s.pricepaid) AS totalVentas,
        NULL AS totalComisiones
FROM sales s
JOIN date d ON s.dateid = d.dateid
GROUP BY d.month, d.year
UNION ALL
SELECT  d.month AS mes,
        d.year AS año,
        'comisiones' AS concepto,
        NULL AS totalVentas,
        SUM(s.commission) AS totalComisiones
FROM sales s
JOIN date d ON s.dateid = d.dateid
GROUP BY d.month, d.year;

SELECT * FROM operaciones;
/*
*   Creamos la vista a partir de la union de dos SELECT, el primero calcula el total de ventas y tiene en cuenta una columna NULL para totalcomisiones,
*   el segundo hace lo mismo para calcular el total de comisines pero antes tiene en cuenta una columna NULL de totalventas, de esta forma
*   conseguimos que los valores no se solapen en una misma columna y muestre 2 diferentes para totalVentas y TotalComisiones.
*
*/