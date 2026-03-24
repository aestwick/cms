<?php

// archive stuff
if(!defined("sh_download"))
	define("sh_download",0x01);
if(!defined("sh_pod"))
	define("sh_pod",0x02);
if(!defined("sh_delete_file"))
	define("sh_delete_file",0x04);
if(!defined("sh_invisible"))
	define("sh_invisible",0x08);
if(!defined("sh_shohost"))
	define("sh_shohost",0x10);
if(!defined("sh_shodesc"))
	define("sh_shodesc",0x20);
if(!defined("sh_pitch"))
	define("sh_pitch",0x40);


if(!defined("sh_upload"))
	define("sh_upload",0x80);
if(!defined("sh_tone"))
	define("sh_tone",0x100);
if(!defined("sh_unsched"))
	define("sh_unsched",0x200);

// more archive stuff
if(!defined("sh_no_overlap"))
	define("sh_no_overlap",0x400);
if(!defined("sh_copysafe"))
	define("sh_copysafe",0x800);
if(!defined("sh_private"))
	define("sh_private",0x1000);
if(!defined("sh_shonow"))
	define("sh_shonow",0x2000);

if(!defined("sh_talk"))
	define("sh_talk",0x4000);
if(!defined("sh_gone"))
	define("sh_gone",0x8000);
if(!defined("sh_norecord"))
	define("sh_norecord",0x10000);
if(!defined("sh_nopledge"))
	define("sh_nopledge",0x20000);
if(!defined("sh_duptitle"))
	define("sh_duptitle",0x40000);
if(!defined("sh_customurl"))
	define("sh_customurl",0x80000);
if(!defined("sh_waitnoise"))
	define("sh_waitnoise",0x100000);

if(!defined("sh_default_mask"))
	define("sh_default_mask",sh_download|sh_pod|sh_delete_file|sh_invisible|sh_shohost|sh_shodesc|sh_pitch|
							sh_upload|sh_no_overlap|sh_copysafe|sh_private|sh_shonow|sh_talk|sh_gone|sh_duptitle|sh_waitnoise);

// default for talk show
if(!defined("sh_talk_default"))
	define("sh_talk_default",sh_download|sh_pod);

$sh_day_list = array("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
$sh_big_day_list = array("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");
?>
