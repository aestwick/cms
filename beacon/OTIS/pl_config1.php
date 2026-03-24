<?php
require_once "pl_path.php";
require "top_config.php";
// for final
/*==================================*
 * dbd file - above doc root please
 *==================================*/
require_once root_dir . "/pl_config_defines.php";
require_once root_dir. "/pl_config_functs.php";

if(!defined("debug"))
	define("debug",0);

if(!defined("front_debug"))
	define("front_debug",0);

if(debug || front_debug)
{
	error_reporting(E_ALL ^ E_DEPRECATED);
	ini_set('display_errors',"1");
}
else
{
	error_reporting(0);		// don't forget to change this back to 0
	ini_set('display_errors',"0");
}

if(!defined("ALIVE_TEST_INTERVAL"))
	define("ALIVE_TEST_INTERVAL",20);

/*==================================*
 * don't forget to set timezone in global
 *==================================*/

if(!defined("not_secure"))
	define("not_secure",1);

$fee_tier = '0';				// if we go over $3000 ...

$pnb_mailto = "webmaster@pacifica.org";
$pnb_mailfrom = "webmaster@pacifica.org";

$id3v2_path = '/usr/local/bin/id3v2';
$mp3length_path = '/usr/local/bin/mp3length';

$confessor_start_date = strtotime("2-1-2010");

if(debug > 1)
print "TZ=" . getenv("TZ") . "<br>\n";

if(debug > 1)
echo "<!-- end " . basename(__FILE__) . " pamember ## Version 0.0.2 ## -->\n";
?>
