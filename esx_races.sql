INSERT INTO `items` (name, label, `limit`) VALUES
	('solo_key', 'Cle conte la montre', 1)
;

CREATE TABLE IF NOT EXISTS `solo_race` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) NOT NULL,
  `record` int(11) NOT NULL,
  `race` int(11) NOT NULL,
  `vehicle` int(11) NOT NULL,
  `record_date` datetime NOT NULL,
  PRIMARY KEY (`id`)
);