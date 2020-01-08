-- MySQL dump 10.13  Distrib 5.6.28, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: infoceanos
-- ------------------------------------------------------
-- Server version	5.6.28-1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `datos`
--

DROP TABLE IF EXISTS `datos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descarga_datos` text COMMENT 'reference',
  `estatus_datos` tinyint(2) NOT NULL DEFAULT '1' COMMENT 'dataset_available',
  `licencia_uso` varchar(255) NOT NULL DEFAULT 'cc_by_nc',
  `descripcion_base` text,
  `metadatos` text,
  `publicaciones` text,
  `publicacion_url` varchar(1000) DEFAULT NULL,
  `publicacion_fecha` date DEFAULT NULL COMMENT 'publication_year',
  `descarga_informe` varchar(1000) DEFAULT NULL,
  `forma_citar` text,
  `restricciones` text,
  `numero_ejemplares` int(11) DEFAULT NULL COMMENT 'data_time_points',
  `tipo_unidad` varchar(255) DEFAULT NULL COMMENT 'unit_type',
  `resolucion_temporal` varchar(255) DEFAULT NULL COMMENT 'temporal_resolution',
  `resolucion_espacial` varchar(255) DEFAULT NULL COMMENT 'spatial_resolution',
  `titulo_compilacion` varchar(255) DEFAULT NULL COMMENT 'compilation_title',
  `titulo_conjunto_datos` varchar(255) DEFAULT NULL COMMENT 'dataset_title',
  `interaccion` varchar(255) DEFAULT NULL COMMENT 'se_interaction',
  `notas_adicionales` text COMMENT 'notes',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datos`
--

LOCK TABLES `datos` WRITE;
/*!40000 ALTER TABLE `datos` DISABLE KEYS */;
/*!40000 ALTER TABLE `datos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `directorio`
--

DROP TABLE IF EXISTS `directorio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `directorio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cargo` varchar(255) DEFAULT NULL,
  `grado_academico` varchar(255) DEFAULT NULL,
  `tema_estudio` varchar(255) DEFAULT NULL,
  `linea_investigacion` varchar(500) DEFAULT NULL,
  `region_estudio` varchar(255) DEFAULT NULL,
  `telefono` varchar(255) DEFAULT NULL,
  `pagina_web` varchar(255) DEFAULT NULL,
  `institucion_id` int(11) DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL COMMENT 'ID de la tabla usuarios, de la base enciclovida',
  PRIMARY KEY (`id`),
  KEY `fk_directorio_instituciones1_idx` (`institucion_id`),
  CONSTRAINT `fk_directorio_instituciones1` FOREIGN KEY (`institucion_id`) REFERENCES `instituciones` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `directorio`
--

LOCK TABLES `directorio` WRITE;
/*!40000 ALTER TABLE `directorio` DISABLE KEYS */;
/*!40000 ALTER TABLE `directorio` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `especies_estudiadas`
--

DROP TABLE IF EXISTS `especies_estudiadas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `especies_estudiadas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `especie_id` int(11) DEFAULT NULL COMMENT 'ID de la tabla Nombre en catalogocentralizado',
  `nombre_cientifico` varchar(255) DEFAULT NULL,
  `proyecto_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_especies_estudiadas_proyectos1_idx` (`proyecto_id`),
  CONSTRAINT `fk_especies_estudiadas_proyectos1` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `especies_estudiadas`
--

LOCK TABLES `especies_estudiadas` WRITE;
/*!40000 ALTER TABLE `especies_estudiadas` DISABLE KEYS */;
/*!40000 ALTER TABLE `especies_estudiadas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `info_adicional`
--

DROP TABLE IF EXISTS `info_adicional`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `info_adicional` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `informacion_objeto` text,
  `informacion_posterior` text,
  `informacion_adicional` text,
  `colaboradores` text,
  `instituciones_involucradas` text,
  `equipo` text,
  `comentarios` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `info_adicional`
--

LOCK TABLES `info_adicional` WRITE;
/*!40000 ALTER TABLE `info_adicional` DISABLE KEYS */;
/*!40000 ALTER TABLE `info_adicional` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instituciones`
--

DROP TABLE IF EXISTS `instituciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `instituciones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_institucion` varchar(255) NOT NULL COMMENT 'institution',
  `tipo` varchar(255) DEFAULT NULL COMMENT 'institution_type',
  `sitio_web` varchar(255) DEFAULT NULL,
  `contacto` varchar(255) DEFAULT NULL COMMENT 'user_contact',
  `correo_contacto` varchar(255) DEFAULT NULL COMMENT 'user_contact',
  `slug` varchar(255) DEFAULT NULL,
  `ubicacion_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_instituciones_ubicacones1_idx` (`ubicacion_id`),
  CONSTRAINT `fk_instituciones_ubicacones1` FOREIGN KEY (`ubicacion_id`) REFERENCES `ubicaciones` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instituciones`
--

LOCK TABLES `instituciones` WRITE;
/*!40000 ALTER TABLE `instituciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `instituciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `keywords`
--

DROP TABLE IF EXISTS `keywords`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `keywords` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_keyword` varchar(255) NOT NULL COMMENT 'keywords',
  `slug` varchar(255) DEFAULT NULL,
  `proyecto_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_keywords_proyectos1_idx` (`proyecto_id`),
  CONSTRAINT `fk_keywords_proyectos1` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `keywords`
--

LOCK TABLES `keywords` WRITE;
/*!40000 ALTER TABLE `keywords` DISABLE KEYS */;
/*!40000 ALTER TABLE `keywords` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `periodos`
--

DROP TABLE IF EXISTS `periodos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `periodos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `periodicidad` varchar(255) DEFAULT NULL,
  `periodo_monitoreo_desde` date DEFAULT NULL,
  `periodo_monitoreo_hasta` date DEFAULT NULL,
  `periodo_sistematico_desde` date DEFAULT NULL,
  `periodo_sistematico_hasta` date DEFAULT NULL,
  `monitoreo_desde` date DEFAULT NULL COMMENT 'start_year',
  `monitoreo_hasta` date DEFAULT NULL COMMENT 'end_year',
  `comentarios` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `periodos`
--

LOCK TABLES `periodos` WRITE;
/*!40000 ALTER TABLE `periodos` DISABLE KEYS */;
/*!40000 ALTER TABLE `periodos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proyectos`
--

DROP TABLE IF EXISTS `proyectos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proyectos` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'MMID',
  `nombre_proyecto` varchar(255) NOT NULL COMMENT 'short_title',
  `financiamiento` text COMMENT 'research_fund',
  `autor` varchar(255) DEFAULT NULL COMMENT 'author',
  `tipo_monitoreo` varchar(255) DEFAULT NULL,
  `objeto_monitoreo` text,
  `campo_investigacion` varchar(255) DEFAULT NULL,
  `campo_ciencia` varchar(255) DEFAULT NULL,
  `finalidad` text,
  `metodo` text,
  `info_adicional_id` int(11) DEFAULT NULL,
  `periodo_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  `institucion_id` int(11) DEFAULT NULL,
  `dato_id` int(11) DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_proyectos_info_adicional_idx` (`info_adicional_id`),
  KEY `fk_proyectos_periodo1_idx` (`periodo_id`),
  KEY `fk_proyectos_ubicaciones1_idx` (`region_id`),
  KEY `fk_proyectos_instituciones1_idx` (`institucion_id`),
  KEY `fk_proyectos_datos1_idx` (`dato_id`),
  CONSTRAINT `fk_proyectos_datos1` FOREIGN KEY (`dato_id`) REFERENCES `datos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_proyectos_info_adicional` FOREIGN KEY (`info_adicional_id`) REFERENCES `info_adicional` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_proyectos_instituciones1` FOREIGN KEY (`institucion_id`) REFERENCES `instituciones` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_proyectos_periodo1` FOREIGN KEY (`periodo_id`) REFERENCES `periodos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_proyectos_ubicaciones1` FOREIGN KEY (`region_id`) REFERENCES `regiones` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Pestaña de proyectos';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proyectos`
--

LOCK TABLES `proyectos` WRITE;
/*!40000 ALTER TABLE `proyectos` DISABLE KEYS */;
/*!40000 ALTER TABLE `proyectos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `regiones`
--

DROP TABLE IF EXISTS `regiones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regiones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_region` varchar(255) DEFAULT NULL COMMENT 'region',
  `nombre_zona` varchar(255) DEFAULT NULL COMMENT 'area',
  `nombre_ubicacion` varchar(255) DEFAULT NULL COMMENT 'location',
  `region_pesca` varchar(255) DEFAULT NULL,
  `latitud` decimal(10,8) DEFAULT NULL COMMENT 'lat',
  `longitud` decimal(11,8) DEFAULT NULL COMMENT 'lon',
  `poligono` varchar(500) DEFAULT NULL,
  `entidad` varchar(255) DEFAULT NULL,
  `cuenca` varchar(255) DEFAULT NULL,
  `anp` varchar(255) DEFAULT NULL,
  `comentarios` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regiones`
--

LOCK TABLES `regiones` WRITE;
/*!40000 ALTER TABLE `regiones` DISABLE KEYS */;
/*!40000 ALTER TABLE `regiones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ubicaciones`
--

DROP TABLE IF EXISTS `ubicaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ubicaciones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `calle_numero` varchar(500) DEFAULT NULL,
  `colonia` varchar(255) DEFAULT NULL,
  `municipio` varchar(255) DEFAULT NULL,
  `ciudad` varchar(255) DEFAULT NULL,
  `entidad_federativa` varchar(255) DEFAULT NULL,
  `cp` smallint(4) unsigned zerofill DEFAULT NULL,
  `pais` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ubicaciones`
--

LOCK TABLES `ubicaciones` WRITE;
/*!40000 ALTER TABLE `ubicaciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `ubicaciones` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-06-13 19:27:23
