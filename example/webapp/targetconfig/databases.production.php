<?php

return array(
   'db' => array(
      'driver'         => 'Pdo',
      'dsn'            => 'mysql:dbname=zf2tutorial;host=localhost',
   ),
   'service_manager' => array(
      'factories' => array(
         'Zend\Db\Adapter\Adapter' => 'Zend\Db\Adapter\AdapterServiceFactory',
      ),
   ),
);	

