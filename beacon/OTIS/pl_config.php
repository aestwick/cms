<?php
require_once "pl_path.php";
require "top_config.php";

if(use_https)
{
if(!empty($_SERVER["HTTP_CF_VISITOR"]))
{
	if((stristr($_SERVER["HTTP_CF_VISITOR"],"https") === false))
	{
		$_SERVER["HTTPS"] = 'on';
		header("location: $confessor_url" . $_SERVER['REQUEST_URI']);
		exit("");
	}
}
else
{
	if(empty($_SERVER["HTTPS"]))
	{
		header("location: $confessor_url" . $_SERVER["REQUEST_URI"]); 
		exit("");
	}
}
}

require_once root_dir . "/pl_config_defines.php";
require_once root_dir . "/pl_config_functs.php";

session_cache_limiter("nocache");
header('Expires: Tue, 1 Jan 1980 12:00:00 GMT');
header('Last-Modified: ' . gmdate('D, d M Y H:i:s') . ' GMT');
header('Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0, no-transform');
header('Pragma: no-cache');
session_start();

$_SESSION['wait'] = 2;

/*==================================*
 * set timezone for station
 * don't forget to set it in global
 *==================================*/

// most of this if not all is superceded by entries in top_vars.php and top_config.php
$server_protocol = 'https://';
$my_host = $server_protocol . $_SERVER['HTTP_HOST'];
// why not $confessor_url from top_config?
$my_dir = rtrim(dirname($_SERVER['SCRIPT_NAME']),'/');
$my_abs_dir = rtrim(dirname($_SERVER["SCRIPT_FILENAME"]),"/");
$my_full_path = $root_dir . $my_dir;
$my_full_url = $my_host . $my_dir;
$hidden_dir = rtrim(dirname($_SERVER["DOCUMENT_ROOT"]),"/");
// end that comment
$now_playing_path = $my_abs_dir . "playlist/now_playing.txt";

$my_full_path = home_dir;
$my_full_url = confessor_url;

if(!empty($_SESSION['log_me_out'])) 
	header("location: " . login_url . "/logout.php");

if(!defined("debug"))
	define("debug",0);

if(!defined("front_debug"))
	define("front_debug",0);

// this is so pl_top1 can run without a login
if(!defined("no_login"))
	define("no_login",0);

if(debug > 1)
print "session '" . session_id() . "' =<pre>" . print_r($_SESSION,true) . "</pre>\n";

error_reporting(E_ALL & ~E_DEPRECATED);
ini_set('display_errors',"1");

if(debug || front_debug)
{
	error_reporting(E_ALL & ~E_DEPRECATED);
	ini_set('display_errors',"1");
}
else
{
	error_reporting(0);		// don't forget to change this back to 0
	ini_set('display_errors',"0");
}
if(!defined("ALIVE_TEST_INTERVAL"))
	define("ALIVE_TEST_INTERVAL",20);

if(!defined("not_secure"))
	define("not_secure",0);

$fee_tier = '0';				// if we go over $3000 ...

$pnb_mailto = "webmaster@pacifica.org";
$pnb_mailfrom = "webmaster@pacifica.org";

$id3v2_path = '/usr/local/bin/id3v2';
$mp3length_path = '/usr/local/bin/mp3length';

$confessor_start_date = strtotime("2-1-2010");

if(debug > 1)
print "TZ=" . getenv("TZ") . "<br>\n";

if(debug > 1)
print "sessid=" . session_id() . " sesname=" . session_name() . "<br>\n";
if(debug > 1)
echo "<!-- start " . basename(__FILE__) . " pamember ## Version 0.0.2 ## -->\n";


function split_filename($str)
{
//	$str = xml_undo(str_replace(' ','_',strtolower($str)));
	$str = xml_undo($str);
	if(strpos($str,'.') && ((strrpos($str,'.') == strlen($str) - 4) || ((strrpos($str,'.') == strlen($str) - 5))))
		$ext = substr($str,strrpos($str,'.'));
	else
		$ext = '';
if(debug)
	print "split_filename: ext=$ext<br>\n";
	if($ext)
		$str = str_replace($ext,'',$str);
	$ary = array('filename' => $str,'ext' => $ext);
if(debug)
print "split_filename: aray=<pre>" . print_r($ary,true) . "</pre>\n";

	return($ary);
}

// conform file names
// lowercased
// ' ' => _
// all punctuation removed
// returns array: new_filename,extension (with dot)
function fix_filename($str)
{
	$search = '/[\\W]*/';
	$ary = split_filename($str);
	$ary['filename'] = str_replace(' ','_',$ary['filename']);
	$ary['filename'] = preg_replace($search,'',$ary['filename']);
if(debug)
print "fix_filename: aray=<pre>" . print_r($ary,true) . "</pre>\n";

	return($ary);
}

if(not_secure)
{
	$sql = "select * from " . $db->users_tables("u_table");
	$sql .= " where u_info > 1 limit 1";
	$row = $db->confessor_data($sql,$num);
	if($num)
	{
if(debug > 1)
print "row=<pre>" . print_r($row,true) . "</pre>\n";
		setcookie("hash",get_hash($row['u_name']),0,'/','',0);
		$_SESSION['valid_user']['user'] = $row['u_login'];
		$_SESSION['valid_user']['u_id'] = $row['u_id'];
		$_SESSION['valid_user']['name'] = $row['u_name'];
		$_SESSION['valid_user']['info'] = $row['u_info'];
	}
	else
		die("no users!");
}

function is_login_page()
{
	if(not_secure)
		return(false);

	$login_page = array(
		"login",
		"pl_ureg",
		"pl_u_do"
	);
	foreach($login_page as $page)
		if(stristr($_SERVER['SCRIPT_NAME'],$page))
			return(true);
	if(!empty($_SESSION['set_pass']))
			return(true);
	return(false);
}

function i_am_an_updater()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) & !empty($_SESSION['valid_user']['info']))
		$er = ($_SESSION['valid_user']['info'] & (u_updater|u_root|u_rootroot|u_superroot));

	return($er);
}

function i_am_not_root()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$er = ($_SESSION['valid_user']['info'] & root_mask);

	return(!$er);
}

function i_am_root()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$er = ($_SESSION['valid_user']['info'] & (u_root|u_rootroot|u_superroot));

	return($er);
}

function my_info()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$er = $_SESSION['valid_user']['info'] & root_mask;

	return($er);
}

function i_am_rootroot()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$er = ($_SESSION['valid_user']['info'] & (u_rootroot|u_superroot));

	return($er);
}

function i_am_superroot()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$er = ($_SESSION['valid_user']['info'] & u_superroot);

	return($er);
}

function i_can_validate()
{
	$er = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$er = ($_SESSION['valid_user']['info'] & u_can_validate);

	return($er);
}

function is_secure_page()
{
	if(not_secure || no_login)
		return(false);

	$never_secure = array(
		"pl_top1",
		"public");

	$secure_page = array(
		"form",
		"admin",
		"empty",
		"monitor",
		"pl_top.php",
		"pl_fix",
		"setup",
		"mon",
		"_do",
		"dnd",
		"pl_upchange"
	);

	foreach($never_secure as $page)
	{
		if(stristr($_SERVER['SCRIPT_NAME'],$page))
			return(false);
	}

	foreach($secure_page as $page)
	{
		if(stristr($_SERVER['SCRIPT_NAME'],$page))
			return(true);
	}
	return(false);
}


if(is_secure_page() && !is_login_page())
{
	if(empty($_COOKIE['hash']) || empty($_SESSION['valid_user']['name']) ||
		empty($_SESSION['valid_user']) || empty($_SESSION['valid_user']['user']) ||
		$_COOKIE['hash'] != get_hash($_SESSION['valid_user']['name'])
	)
	{
if(debug)
print "hash and/or name empty<br>\n";
if(debug)
		exit('<a href="' . login_url . '/logout.php">Login...</a><br>'); 
else
{
		header("location: " . login_url . "/logout.php");
		exit("");
}
	}
}

function get_ulogin()
{
	$id = '';

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['user']))
		$id = $_SESSION['valid_user']['user'];
	
	return($id);
}


// returns id for logged-in user
function get_uid()
{
	$id = '';

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['u_id']))
		$id = $_SESSION['valid_user']['u_id'];
	
	return($id);
}

// returns u_rec for logged-in user

function get_uinfo()
{
	$info = 0;

	if(!empty($_SESSION['valid_user']) && !empty($_SESSION['valid_user']['info']))
		$info = $_SESSION['valid_user']['info'];

	return($info);
}

if(debug > 1)
echo "<!-- end " . basename(__FILE__) . " pamember ## Version 0.0.2 ## -->\n";
?>
