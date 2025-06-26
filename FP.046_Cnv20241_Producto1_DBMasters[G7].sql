-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Producto 1
--
-- Grupo: Cnv20241_Grupo07: [DB Masters]

--
-- Database: [fp_046_07]
-- --------------------------------------------------------------
/* Utilizar la misma numeración de preguntas de la actividad. Ejemplos: */



--
-- Ejercicio 3:
-- Crear 2 campos adicionales en la tabla "users" VIP (enum: sí, no default no) y birthdate (DATE)         
--


ALTER TABLE `users`
ADD `birthdate` DATE NULL DEFAULT NULL,
ADD `vip` ENUM ( '0', '1')NULL DEFAULT '0';



--
-- Ejercicio 4:
--
-- Relacionar las tablas de la Base de Datos tomando en cuenta aquellas columnas que tienen en su descripción 
-- el texto Referencia de clave externa a la tabla xxx.. Al crear las claves foráneas, agregar las cláusulas 
-- ON UPDATE y ON DELETE
--

-- TABLA "LISTING"

ALTER TABLE `listing`
MODIFY `sellerid` INT NOT NULL,
MODIFY `eventid` INT NOT NULL,
MODIFY `dateid` SMALLINT NOT NULL;
/*
*   Se considera que estas variables han de ser NOT NULL para mantener la integridad de la base de datos
*   van a ser usadas como claves foraneas e inicialmente no estaban declaradas como NOT NULL.
*/

ALTER TABLE `listing`
DROP INDEX `idx_dateidlisting`;
/*
*   Este primer DROP se hace para que en el siguiente ALTER poder detallar ASC y VISIBLE
*/

ALTER TABLE `listing`
ADD INDEX `idx_dateidlisting` (`dateid` ASC) VISIBLE,
ADD INDEX `fk_listing_event_idx` (`eventid` ASC) VISIBLE,
ADD INDEX `fk_listing_users_idx` (`sellerid` ASC) VISIBLE;

-- Se agraga comentario al final del porqué se deshabilitan las verificaciones de fk.
SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE `listing`
ADD CONSTRAINT `fk_listing_event`
FOREIGN KEY (`eventid`)
REFERENCES `event` (`eventid`)
ON DELETE RESTRICT
ON UPDATE RESTRICT;
/*
*   Para delete y update la relación con event ha de ser inmutable ya que event es el producto que quieres vender.
*   y no se deberia 
*/


SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE `listing`
ADD CONSTRAINT `fk_listing_date`
FOREIGN KEY (`dateid`)
REFERENCES `date` (`dateid`)
ON DELETE NO ACTION
ON UPDATE CASCADE;
/*
*   No se puede eliminar una fecha si hay listados asociados a ella; 
*   las actualizaciones se reflejarán en los listados.
*/



ALTER TABLE `listing`
ADD CONSTRAINT `fk_listing_users`
FOREIGN KEY (`sellerid`)
REFERENCES `users` (`userid`)
ON DELETE RESTRICT
ON UPDATE CASCADE;
/*
*   si se elimina un usuario no debemos perderlo de listing por historico.
*   Si se actualizan los datos de usuario queremos que se reflejen.
*/

-- TABLA "EVENT"

ALTER TABLE `event`
DROP INDEX `idx_dateid`;
/*
*   Este primer DROP se hace para que en el siguiente ALTER poder detallar ASC y VISIBLE
*/

ALTER TABLE `event`
ADD INDEX `idx_dateid` (`dateid` ASC) VISIBLE,
ADD INDEX `fk_event_category_idx` (`catid` ASC) VISIBLE,
ADD INDEX `fk_event_venue_idx` (`venueid` ASC) VISIBLE;

ALTER TABLE `event`
ADD CONSTRAINT `fk_event_date`
FOREIGN KEY (`dateid`)
REFERENCES `date` (`dateid`)
ON DELETE RESTRICT
ON UPDATE CASCADE;
/*
*   No se puede eliminar una fecha si hay eventos asociados a ella;
*   las actualizaciones se reflejarán en los eventos.
*/


ALTER TABLE `event`
ADD CONSTRAINT `fk_event_category`
FOREIGN KEY (`catid`)
REFERENCES `category` (`catid`)
ON DELETE NO ACTION
ON UPDATE CASCADE;
/*
*   Si se elimina una category, no nos interesa que se borren los eventos que todavia no han pasado o pueden esta en uso 
*   si se actualiza, se reflejará en los eventos.
*/


ALTER TABLE `event`
ADD CONSTRAINT `fk_event_venue`
FOREIGN KEY (`venueid`)
REFERENCES `venue` (`venueid`)
ON DELETE NO ACTION
ON UPDATE CASCADE;
/*
*   Si se elimina un venue, no nos interesa que se borren los eventos que todavia no han pasado o pueden esta en uso 
*   si se actualiza, se reflejará en los eventos.
*/

-- TABLA "SALES"

ALTER TABLE `sales`
DROP INDEX `idx_dateidsales`;
/*
*   Este primer DROP se hace para que en el siguiente ALTER poder detallar ASC y VISIBLE
*/

ALTER TABLE `sales`
ADD INDEX `idx_dateidsales` (`dateid` ASC) VISIBLE,
ADD INDEX `fk_sales_listing_idx` (`listid` ASC, `sellerid` ASC) VISIBLE,
ADD INDEX `fk_sales_users_idx` (`buyerid` ASC) VISIBLE,
ADD INDEX `fk_sales_event_idx` (`eventid` ASC) VISIBLE;

CREATE INDEX `idx_listid_sellerid_listing` ON  `listing` (`listid`, `sellerid`);
/*
*   Hay que crear un indice compuesto en la tabla listing para poder manejar la fk_sales_listing compuesta
*   que definiremos en el siguiente ALTER. Se podria haber creado tambien con la sentencia:
*   ALTER TABLE `listing`
*   ADD INDEX `idx_listid_sellerid_listing` (`listid` ASC, `sellerid` ASC) VISIBLE;
*   De esta forma vemos las diferentes formas de realizar una misma acción. 
*/

-- Se agraga comentario al final del porqué se deshabilitan las verificaciones de fk.
SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE `sales`
ADD CONSTRAINT `fk_sales_listing`
FOREIGN KEY (`listid` , `sellerid`)
REFERENCES `listing` (`listid` , `sellerid`)
ON DELETE RESTRICT
ON UPDATE NO ACTION;
/*
* Si se elimina o se actualiza una tabla no nos interesa que se refleje por historico.
*/

ALTER TABLE `sales`
ADD CONSTRAINT `fk_sales_event`
FOREIGN KEY (`eventid`)
REFERENCES `event` (`eventid`)
ON DELETE RESTRICT
ON UPDATE RESTRICT;
/*
* Si se elimina o se actualiza una tabla no nos interesa que se refleje por historico.
*/

SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE `sales`
ADD CONSTRAINT `fk_sales_users`
FOREIGN KEY (`buyerid`)
REFERENCES `users` (`userid`)
ON DELETE RESTRICT
ON UPDATE CASCADE;
/* 
*   No podemos borrar un comprador si hay una venta pero nos interesa tener los datos del comprador actualizados
*/

ALTER TABLE `sales`
ADD CONSTRAINT `fk_sales_date`
FOREIGN KEY (`dateid`)
REFERENCES `date` (`dateid`)
ON DELETE RESTRICT
ON UPDATE RESTRICT;  
/*
*   No se puede eliminar una fecha si hay ventas asociadas a ella; las actualizaciones
*   no deben verse se reflejarán en las ventas
*/


/*
*   Error 1452:
*   No se podia crear la clave foranea fk_listing_event porque no todos los datos entre la tabla listing y event casan
*   es decir, hay eventos creados que tienen una oferta de venta creada en listing. Esto obliga a deshabilitar las
*   verificaciones de clave foranea antes de realizar el ALTER y despues volver a habilitar.
*
*   Nos pasó lo mismo que en el caso anterior al crear la clave foranea fk_sales_listing y
*   fk_sales_event y se resolvío del mismo modo.
*
*/

--
-- Ejercicio 5.
-- Generar 2 restricciones de tipo check para controlar la integridad de los datos


ALTER TABLE `sales`
ADD CONSTRAINT `chk_qtysold` CHECK (`qtysold` BETWEEN 1 AND 8);
/*
* el campo "qtysold" debe limitarse de 1 a 8. es la cantidad mínima y máxima que se permite vender entradas.
*/

ALTER TABLE `listing`
ADD CONSTRAINT `chk_numtickets` CHECK (`numtickets` >= 0);
/*
* listing.numtickets no debe permitir vender más tickets de los que tiene, por lo cual nunca deberá se negativo
*/




--
-- Ejercicio 6.
-- Cambiar los campos que lo requieran por campos autocalculados.
--

ALTER TABLE `listing`
MODIFY COLUMN totalprice DECIMAL(8,2) GENERATED ALWAYS AS (`numtickets` * `priceperticket`) STORED;
/*
*   implementacion de listing.totalprice = numtickets * priceperticket
*/


DELIMITER //
CREATE TRIGGER before_insert_sales
BEFORE INSERT ON `sales`
FOR EACH ROW
BEGIN
    DECLARE price DECIMAL(8,2);
    
    SELECT `priceperticket` INTO price
    FROM `listing`
    WHERE `listid` = NEW.listid;

    SET NEW.pricepaid = price * NEW.qtysold;
END;
// DELIMITER;
/*
*   Implementación de sales.pricepaid = (listing.priceperticket * sales.qtysold)
*   Se realiza esta operacion con un trigger ya que debemos seleccionar el valor priceperticket de la tabla listing.
*   No podemos definir la operativa de una columna generada con una subconsulta.
*/

ALTER TABLE `sales`
MODIFY COLUMN `commission` DECIMAL(8,2) GENERATED ALWAYS AS (`pricepaid` * 0.15) STORED;
/*
*   Implementación de sales.commission = 15% de sales.pricepaid
*/


SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE `users`
MODIFY `userid` INT NOT NULL AUTO_INCREMENT;
ALTER TABLE `users` AUTO_INCREMENT = 49991;

ALTER TABLE `date`
MODIFY `dateid` SMALLINT NOT NULL AUTO_INCREMENT;
ALTER TABLE `date` AUTO_INCREMENT = 2192;

ALTER TABLE `sales`
MODIFY `salesid` INT NOT NULL AUTO_INCREMENT;
ALTER TABLE `sales` AUTO_INCREMENT = 127122;

ALTER TABLE `event`
MODIFY `eventid` INT NOT NULL AUTO_INCREMENT;
ALTER TABLE `event` AUTO_INCREMENT = 8799;

ALTER TABLE `venue`
MODIFY `venueid` SMALLINT NOT NULL AUTO_INCREMENT;
ALTER TABLE `venue` AUTO_INCREMENT = 310;

ALTER TABLE `category`
MODIFY `catid` SMALLINT NOT NULL AUTO_INCREMENT;
ALTER TABLE `category` AUTO_INCREMENT = 12;

ALTER TABLE `listing`
MODIFY `listid` INT NOT NULL AUTO_INCREMENT;
ALTER TABLE `listing` AUTO_INCREMENT = 19118;

SET FOREIGN_KEY_CHECKS = 1;
/*
*   Se han modificado los campos a autoincrementables y se ha definido el valor por el cual
*   deben comenzar a incrementarse.
*/


--
-- Ejercicio 7.
-- Agregar dos campos adicionales a la base de datos que enriquezcan la información de la misma
--

ALTER TABLE `users`
ADD COLUMN status ENUM('activo', 'inactivo', 'suspendido') DEFAULT 'activo' COMMENT 'Estado del usuario';

ALTER TABLE `sales`
ADD COLUMN paymetod ENUM('paypal', 'tarjeta') COMMENT 'Metodo de pago utilizado';



--
-- Ejercicio 8.
-- Crear un disparador que al actualizar el campo "username" de la tabla "users"  revise si su contenido 
-- contiene mayúsculas, minúsculas, digitos y alguno de los siguientes símbolos -_#@ No permitir la actualización si no es así.
-- 

DELIMITER //
CREATE TRIGGER trg_check_username
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NOT (NEW.username REGEXP '^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[-_#@]).{1,}$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username debe contener mayúsculas, minúsculas, dígitos y al menos uno de los símbolos: -_#@';
    END IF;
END;
//
DELIMITER ;
/*
*   Antes de cada actualizacion de la tabla 'users'se ejecuta el disparador y se aplica a cada fila que se intente actualizar.
*   Comprueba si el valor de 'username' cumple con el patrón.
*   Si el patrón no se cumple, se genera el error con el mensaje explicativo.
*/


--
-- Ejercicio 9.
-- Diseñar un disparador que prevenga que el campo "email" de la tabla "users" tenga un formato correcto
-- al actualizar o insertar un nuevo email.


DELIMITER //
CREATE TRIGGER before_update_email
BEFORE UPDATE ON `users`
FOR EACH ROW
BEGIN
IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El formato del email a de ser nombre@dominio.com';
END IF;
END;
// DELIMITER;
/*
*   Antes de cada actualizacion de la tabla 'users'se ejecuta el disparadory se aplica a cada fila que se intente actualizar.
*   Verifica si el nuevo valor de 'email' cumple con el formato de un correo electrónico válido.
*   genera un error explicativo si el formato no es correcto.
*/
--
-- Ejercicio 10.
-- Inventar una restricción que sirva de utilidad para mantener la integridad de la Base de Datos.
--


ALTER TABLE `date`
ADD CONSTRAINT chk_qtr CHECK (`qtr` IN ('1', '2', '3', '4'));
/*
*   Esta restriccion se asegura que no podamos definir otros valores fuera del rango de los valores que definimos para trimestres.
*/














