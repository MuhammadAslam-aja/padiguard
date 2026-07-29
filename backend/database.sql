-- SQL Schema untuk Klasifikasi Hama & Kematangan Tanaman Padi (YOLOv12)

CREATE TABLE IF NOT EXISTS `users` (
  `id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(20) NOT NULL DEFAULT 'petani',
  `avatar` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `detections` (
  `id` varchar(50) NOT NULL,
  `userEmail` varchar(100) NOT NULL,
  `userName` varchar(100) NOT NULL,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `imageUrl` varchar(255) NOT NULL,
  `hamaName` varchar(50) DEFAULT NULL,
  `hamaConfidence` double NOT NULL DEFAULT '0',
  `kematangan` varchar(50) NOT NULL,
  `kematanganConfidence` double NOT NULL DEFAULT '0',
  `boundingBoxes` text NOT NULL,
  `dangerLevel` varchar(20) NOT NULL,
  `description` text NOT NULL,
  `treatment` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dataset` (
  `id` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `imageUrl` varchar(255) DEFAULT NULL,
  `uploadedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `model_performance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `accuracy` double NOT NULL,
  `precision` double NOT NULL,
  `recall` double NOT NULL,
  `f1` double NOT NULL,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
