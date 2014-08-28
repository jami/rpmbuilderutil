Summary: webapp binary package
Name: webapp
Version: 1.0.0
Release: 1
License: none
Group: internet
URL: none
Requires: httpd,php > 5.0.0

%description
Webapp that do stuff

%files
/var/www/htdocs/webapp/config/autoload/databases.local.php
/etc/apache2/sites-enable/webapp.conf
/var/www/htdocs/webapp/composer.json
/var/www/htdocs/webapp/composer.phar
/var/www/htdocs/webapp/init_autoloader.php
/var/www/htdocs/webapp/vendor/README.md
/var/www/htdocs/webapp/vendor/.gitignore
/var/www/htdocs/webapp/public/.htaccess
/var/www/htdocs/webapp/public/index.php
/var/www/htdocs/webapp/public/img/zf2-logo.png
/var/www/htdocs/webapp/public/img/favicon.ico
/var/www/htdocs/webapp/public/css/bootstrap.css
/var/www/htdocs/webapp/public/css/bootstrap-theme.min.css
/var/www/htdocs/webapp/public/css/bootstrap-theme.css
/var/www/htdocs/webapp/public/css/style.css
/var/www/htdocs/webapp/public/css/bootstrap.min.css
/var/www/htdocs/webapp/public/fonts/glyphicons-halflings-regular.svg
/var/www/htdocs/webapp/public/fonts/glyphicons-halflings-regular.ttf
/var/www/htdocs/webapp/public/fonts/glyphicons-halflings-regular.eot
/var/www/htdocs/webapp/public/fonts/glyphicons-halflings-regular.woff
/var/www/htdocs/webapp/public/js/bootstrap.min.js
/var/www/htdocs/webapp/public/js/jquery-1.10.2.min.map
/var/www/htdocs/webapp/public/js/jquery.min.js
/var/www/htdocs/webapp/public/js/respond.min.js
/var/www/htdocs/webapp/public/js/bootstrap.js
/var/www/htdocs/webapp/public/js/html5shiv.js
/var/www/htdocs/webapp/config/application.config.php
/var/www/htdocs/webapp/config/autoload/global.php
/var/www/htdocs/webapp/module/Application/Module.php
/var/www/htdocs/webapp/module/Application/src/Application/Controller/IndexController.php
/var/www/htdocs/webapp/module/Application/config/module.config.php
/var/www/htdocs/webapp/module/Application/language/pl_PL.po
/var/www/htdocs/webapp/module/Application/language/it_IT.mo
/var/www/htdocs/webapp/module/Application/language/pl_PL.mo
/var/www/htdocs/webapp/module/Application/language/de_DE.mo
/var/www/htdocs/webapp/module/Application/language/es_ES.po
/var/www/htdocs/webapp/module/Application/language/nl_NL.mo
/var/www/htdocs/webapp/module/Application/language/zh_TW.mo
/var/www/htdocs/webapp/module/Application/language/zh_CN.po
/var/www/htdocs/webapp/module/Application/language/pt_BR.mo
/var/www/htdocs/webapp/module/Application/language/ar_JO.po
/var/www/htdocs/webapp/module/Application/language/zh_TW.po
/var/www/htdocs/webapp/module/Application/language/zh_CN.mo
/var/www/htdocs/webapp/module/Application/language/en_US.po
/var/www/htdocs/webapp/module/Application/language/nb_NO.po
/var/www/htdocs/webapp/module/Application/language/tr_TR.mo
/var/www/htdocs/webapp/module/Application/language/ru_RU.po
/var/www/htdocs/webapp/module/Application/language/fr_CA.mo
/var/www/htdocs/webapp/module/Application/language/tr_TR.po
/var/www/htdocs/webapp/module/Application/language/it_IT.po
/var/www/htdocs/webapp/module/Application/language/de_DE.po
/var/www/htdocs/webapp/module/Application/language/fr_FR.po
/var/www/htdocs/webapp/module/Application/language/en_US.mo
/var/www/htdocs/webapp/module/Application/language/ar_SY.po
/var/www/htdocs/webapp/module/Application/language/es_ES.mo
/var/www/htdocs/webapp/module/Application/language/sl_SI.po
/var/www/htdocs/webapp/module/Application/language/nl_NL.po
/var/www/htdocs/webapp/module/Application/language/uk_UA.mo
/var/www/htdocs/webapp/module/Application/language/pt_BR.po
/var/www/htdocs/webapp/module/Application/language/ar_SY.mo
/var/www/htdocs/webapp/module/Application/language/ja_JP.po
/var/www/htdocs/webapp/module/Application/language/uk_UA.po
/var/www/htdocs/webapp/module/Application/language/fr_CA.po
/var/www/htdocs/webapp/module/Application/language/ar_JO.mo
/var/www/htdocs/webapp/module/Application/language/ru_RU.mo
/var/www/htdocs/webapp/module/Application/language/cs_CZ.po
/var/www/htdocs/webapp/module/Application/language/ja_JP.mo
/var/www/htdocs/webapp/module/Application/language/nb_NO.mo
/var/www/htdocs/webapp/module/Application/language/cs_CZ.mo
/var/www/htdocs/webapp/module/Application/language/fr_FR.mo
/var/www/htdocs/webapp/module/Application/language/sl_SI.mo
%pre
echo 'preinstall gogo'
%post
echo 'postinstall gogo'
(cd /var/www/htdocs/webapp && php -f composer.phar install)
apachectl restart
%preun
echo 'preuninstall gogo'
%postun
echo 'postuninstall gogo'

