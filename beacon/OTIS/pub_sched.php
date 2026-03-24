<?php
// time_on_right
// date for sched
// tooltips
ob_start();
define("include_shows",1);
include "../pl_config.php";
if(!defined("log_stuff"))
	define("log_stuff",1);
if(log_stuff)
{
	$log_name = 'pub1.out';
	$db->set_log(log_dir . "/" . $log_name,"w");
}
//include "Shows.php";
$gl_row = get_global();
$log_name = log_dir . "/" . "pub1.out";
$db->set_log($log_name,"w");
error_reporting(E_ALL & ~E_DEPRECATED);
ini_set("display_errors",1);

if(!defined("local_debug"))
	define("local_debug",0);

if(!empty($_GET["op"]))
{
	$op = substr($_GET['op'],0,5);
	$dte = intval($_GET['dte']);
}
else
{
	$op = '';
	$dte = time();
	$sundte = get_sunday($dte);
}

if(!empty($op))
{
	switch($op)
	{
	case 'next':
		$sundte = get_sunday($dte + (SECS_IN_WEEK + SECS_IN_DAY));
		break;
	case 'prev':
		$sundte = get_sunday($dte - (SECS_IN_DAY));
		break;
	default:
		$sundte = get_sunday($dte);
		break;
	}
}
$now = $sundte;

$showsDb = new Scheds($db,0,0,"start_date:$sundte");

//===== page stuff =======//

// sets positions of time bar and
// size of schedule container
// these vary according to height of key divs
if(local_debug)
	$center_str = "";
else
	$center_str = 'align="center"';
$time_top = '37px';				// where the time starts - depends on height of key
$hidden_height = '40px';		// so top row is below bottom of time
$time_bottom = '44px;';			// where time at the bottom starts - depends on height of key
$main_margin_top = '-5px';		// whatever
$main_margin_bottom = '64px';	// so bottom row is above time
$guides_top = 35;

// grid layout
$main_top = sched_key_height + sched_logo_height;
//$page_width = 900;		// width of keys
$page_width = sched_page_width;		// width of keys
$sched_left = 10;
$main_left = 10;
//$key_height = 30;
$key_height = sched_key_height;
$grid_top = 60;
//$height_per_unit = 25;	// this changes the size of the unit
$height_per_unit = sched_height_per_unit;	// this changes the size of the unit
//$unit_width = 110;		// this changes the width of the whole schedule
$unit_width = sched_unit_width;		// this changes the width of the whole schedule
//$time_width = 50;
$time_width = sched_time_width;
$time_height = 30;
//$font_size = 10;
$font_size = sched_font_size;


$page_bg_color = "#000033";
$body_bg_color = "#000000";

$page_padding_top = '4px';
$page_border_color = '#ffffff';

$time_font_size = "12px";
$time_text_color = "#ffffff";
$time_even_bgcolor = "#333333";
$time_odd_bgcolor = "#666666";

$title_text_color = "#ffffff";
$title_bg_color = "#333333";

$talk_bg_color = "#003300";

$show_bg_color = "#330000";
$show_text_color = "#ffffff";
$show_font_size = "10px";
$show_default_color = "#000000";
$show_bg_default_color = "#ffffff";

$host_text_color = "#cccccc";

$link_text_color = "#ffffff";
$hover_text_color = "#ffffff";

$tooltip_bg_color = "#000000";
$tooltip_text_color = "#ffffff";
$tooltip_border_color = "#00ff00";
$tooltip_width = "220px";

$icon_bottom_padding = "4px";
$icon_left_offset = '-' . intval(((99 - $gl_row["gl_catxthumb"]) / 2) - 2) . "px";

$daytime_background_color = "#e0e0e0";
$nighttime_background_color = "#303050";
//$icon_left_offset = "-38px";


$style_str = <<<FOFO
<style type="text/css">
body
{
	background-color:$body_bg_color;
}
.odd_tr
{
	height:22px;
}
.even_tr
{
	height:22px;
}
td
{
	font-size: $show_font_size;
	font-weight: normal;
	font-family: Arial,Helvetica,sans-serif;
}
.even_time
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$time_even_bgcolor;
	font-size:$time_font_size;
	text-align:right;
	color:$time_text_color;
}
.odd_time
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$time_odd_bgcolor;
	font-size:$time_font_size;
	text-align:right;
	color:$time_text_color;
}
.day_time
{
	border-right:1px solid $page_border_color;
	border-top:1px solid #000000;
	background-color:$daytime_background_color;
	font-size:$time_font_size;
	text-align:right;
	color:#000000;
}
.nite_time
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$nighttime_background_color;
	font-size:$time_font_size;
	text-align:right;
	color:#ffffff;
}
.title
{
	border-bottom: 1px solid $page_border_color;
	background-color:$title_bg_color;
	color:$title_text_color;
	text-align:center;
	font-size:10px;
}



.even_time_td_right
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$time_even_bgcolor;
	font-size:12px;
	text-align:right;
	color:$time_text_color;
	top: 0px;
}
.odd_time_td_right
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$time_odd_bgcolor;
	font-size:12px;
	text-align:right;
	color:$time_text_color;
	top: 0px;
}
.title_td
{
	border-bottom: 1px solid $page_border_color;
	border-right: 1px solid $page_border_color;
	background-color:$title_bg_color;
	color:$title_text_color;
	text-align:center;
}
.show_td
{
	border-top: 1px solid $page_border_color;
	border-right: 1px solid $page_border_color;
	padding-top: $page_padding_top;
	background-color: $show_bg_color;
	color:$show_text_color;
	text-align:center;
}
a.show_td:link
{
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	padding-top: $page_padding_top;
	background-color: $show_bg_color;
	color:$show_text_color;
	text-align:center;
}
a.show_td:visited
{
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	padding-top: $page_padding_top;
	background-color: $show_bg_color;
	color:$show_text_color;
	text-align:center;
}
a.show_td:hover
{
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	padding-top: $page_padding_top;
	background-color: $show_bg_color;
	color:$show_text_color;
	text-align:center;
}
a.show_td:active
{
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	padding-top: $page_padding_top;
	background-color: $show_bg_color;
	color:$show_text_color;
	text-align:center;
}
.host_span
{
	color:$host_text_color;
	font-size: 10px;
}
.talk_td
{
	border-top: 1px solid $page_border_color;
	border-right: 1px solid $page_border_color;
	padding-top: $page_padding_top;
	background-color: $talk_bg_color;
	color:$show_text_color;
	text-align:center;
}
a.talk_link:link
{
	padding-top: $page_padding_top;
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	color:$show_text_color;
}
a.talk_link:visited
{
	padding-top: $page_padding_top;
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	color:$show_text_color;
}
a.talk_link:hover
{
	padding-top: $page_padding_top;
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	color:$show_text_color;
	font-style: italic;
}
a.talk_link:active
{
	padding-top: $page_padding_top;
	border-top: 0px solid $page_border_color;
	border-right: 0px solid $page_border_color;
	color:$show_text_color;
	font-style: italic;
}
.blank_td
{
	border-right:1px solid $page_border_color;
	background-color: $show_bg_color;
	color:$show_text_color;
	text-align:center;
}
.blank_talk_td
{
	border-right:1px solid $page_border_color;
	background-color: $talk_bg_color;
	color:$show_text_color;
	text-align:center;
}
a.show_link:link
{
	color: $link_text_color;
	padding-top: $page_padding_top;
	text-decoration:underline;
	font-style: normal;
	font-size:10px;
}
a.show_link:visited
{
	color: $link_text_color;
	padding-top: $page_padding_top;
	text-decoration:underline;
	font-style: normal;
	font-size: 10px;
}
a.show_link:hover
{
	color: $hover_text_color;
	padding-top: $page_padding_top;
	text-decoration:underline;
	font-weight:normal;
	font-style: italic;
	font-size: 10px;
}
a.show_link:active
{
	color: $link_text_color;
	padding-top: $page_padding_top;
	text-decoration:none;
	font-style: normal;
	font-size: 10px;
}
.tooltipShadow 
{
	background: url(shadow.png); 
}
.tooltipContent 
{
	left: -4px; top: -4px;      
	background-color: $tooltip_bg_color;    
	color:$tooltip_text_color;
	font-family: Arial, Helvetica, sans-serif;
	font-size:12px;
	font-weight: normal;
	border: solid $tooltip_border_color 1px;  
	padding: 15px;            
	padding-bottom:20px;
	border-radius: 10px 10px;
	-moz-border-radius: 10px; 
	-webkit-border-radius: 10px; 
	box-shadow: 5px 5px 5px rgba(0, 0, 0, 0.1); 
	-webkit-box-shadow: 5px 5px rgba(0, 0, 0, 0.1);
	-moz-box-shadow: 5px 5px rgba(0, 0, 0, 0.1);
	margin-left: 0; 
	width: $tooltip_width;
	z-index:80;
}
</style>
FOFO;

$head_str = <<<HEAD
<!DOCTYPE html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
<title>{$gl_row["gl_station"]} Schedule Grid</title>
<script type="text/javascript" language="javascript" src="../script/tooltip.js"></script>

HEAD;

// day: sun=0, sat=6
// dte: sunday midnight
function get_day_midnight($dte,$i,$hour)
{
	$dtary = getdate($dte);
	$dte = mktime($hour,0,0,$dtary["mon"],$dtary["mday"] + $i,$dtary["year"]);
	return($dte);
}

// hour = 0-24
function get_sunday_hour($now,$hour)
{
	$dtary = getdate($now);
	$diff = $dtary["mday"] - $dtary["wday"];
	$sundte = mktime($hour,0,0,$dtary["mon"],$diff,$dtary["year"]);
	return($sundte);
}

function chk_prev_shows($big_ary)
{
	global $db;
	global $gl_row;
	global $now;
	$tmp = Array();

	$begin_dte = get_sunday_hour($now,$gl_row["gl_schedfold"]);		// where we're supposed to start
//$db->write_log("begin_dte=" . date("D n-d-y H:i",$begin_dte) . "\n");
	$dtes = array_keys($big_ary);	
//$db->write_log("dtes=" . print_r($dtes,true) . "\n");
	$first_dte = $dtes[0]; // where we're starting now
//$db->write_log("first_dte=" . date("D n-d-y H:i",$first_dte) . "\n");
	$diff = $first_dte - $begin_dte;		// total len to supply previous shows for
	if($diff)
	{
		$sql = "select * from " . $db->confessor_tables("ph_table,sh_table,ca_table");
		$sql .= " where sh_id=ph_shid";
		$sql .= " and ca_id=sh_caid";
		$sql .= " and ph_date < " . $begin_dte;
//		$sql .= " order by ph_date desc limit " . (($diff / 60) / $gl_row["gl_schedintrvl"]);			// max number of shows possible in diff secs
		$sql .= " order by ph_date desc limit " . (($diff / 60) / $gl_row["gl_schedvisintrvl"]);			// max number of shows possible in diff secs
		$ary = $db->confessor_data($sql,$num,true);

		$rev = array_reverse($big_ary,true);					// putting stuff on start of big_ary
		
		foreach($ary as $row)
		{
			if($diff <= $row["ph_shlen"])		// overlap - one show only
			{
				$start_dte = $begin_dte;
				$def_time = Array("dte" => $start_dte,"len" => $diff,"id" => $row["ph_id"]);
				$row["def_time"] = $def_time;
				$row["OVERLAP"] = 1;
				$row["ADDED"] = 1;
				$rev[$start_dte] = $row;
				break;
			}
			else
			{
				$def_time = Array("dte" => $row["ph_date"],"len" => $row["ph_shlen"],"id" => $row["ph_id"]);
				$row["def_time"] = $def_time;
				$rev[$row["ph_date"]] = $row;
			}
		}
		$big_ary = array_reverse($rev,true);
	}
	return($big_ary);
}

function chk_following_shows($big_ary)
{
	global $db;
	global $gl_row;

	$dtes = array_keys($big_ary);
	$cur_last_end = $dtes[count($dtes) - 1] + $big_ary[$dtes[count($dtes) - 1]]["def_time"]["len"];	// end of last show
	$cur_last_start = $dtes[count($dtes) - 1];		// start of last show
//print __LINE__ . ": cur_last_dte=" . date("D n-d-y H:i",$cur_last_start) . "<br>";

	$end_dte = get_day_midnight($dtes[0],1,$gl_row["gl_schedfold"]);									// have to fill to here
//print __LINE__ . ": end_dte=" . date("D n-d-y H:i",$end_dte) . "<br>";
//	$lim = (($end_dte - $cur_last_end) / 60) / $gl_row["gl_schedintrvl"];		// possible shows
	$lim = (($end_dte - $cur_last_end) / 60) / $gl_row["gl_schedvisintrvl"];		// possible shows
//print __LINE__ . ": lim=$lim<br>\n";
	
	$sql = "select * from " . $db->confessor_tables("ph_table,sh_table,ca_table");
	$sql .= " where sh_id=ph_shid";
	$sql .= " and ca_id=sh_caid";
	$sql .= " and ph_date < " . $end_dte;
	$sql .= " order by ph_date desc limit $lim";
	$tmp = $db->confessor_data($sql,$num,true);
	$ary = array_reverse($tmp);
	foreach($ary as $row)
	{
		if($row["ph_date"] > $cur_last_start)
		{
//print __LINE__ . ": ph_date=" . date("D n-d-y H:i",$row["ph_date"]) . " ph_shlen=" . $row["ph_shlen"] . "<br>";
			$nu_end = $row["ph_date"] + $row["ph_shlen"];
//print __LINE__ . ": nu_end=" . date("D n-d-y H:i",$nu_end) . "<br>\n";
			if($nu_end <= $end_dte)
			{
				$len = $row["ph_shlen"];
			}
			else
			{
				$len = $end_dte - $row["ph_date"];
			}
			$def_time = Array("len" => $len,"dte" => $row["ph_date"],"id" => $row["ph_date"]);
			$row["def_time"] = $def_time;
			$big_ary[$row["ph_date"]] = $row;
			if($len < $row["ph_shlen"])
			{
				$big_ary[$row["ph_date"]]["OVERLAP"] = 1;
			}
		}
	}
	return($big_ary);
}

function get_pf_list($week)
{
	global $db;

	$big_ary = Array();

	$sql = "select pf_idkey,pf_schedtime,pf_host from " . $db->confessor_tables("pf_table");
	$sql .= " where pf_week=$week";
	$sql .= " and pf_info & " . (pf_subhost);
	$sql .= " order by pf_schedtime";
	$ary = $db->confessor_data($sql,$num,true);
	foreach($ary as $row)
	{
		$big_ary[$row["pf_schedtime"]] = $row;
	}
$db->write_log("big_ary=" . print_r($big_ary,true) . "\n");
	return($big_ary);
}

function set_pf_host($pf_ary,&$sh_ary)
{
	foreach($pf_ary as $schedtime => $pf_row)
	{
		if(array_key_exists($pf_row["pf_idkey"],$sh_ary))
		{
			foreach($sh_ary[$pf_row["pf_idkey"]]["def_time"] as $key => &$val)
			{
				if($val["dte"] == $pf_row["pf_schedtime"])
				{
					$val["host"] = $pf_row["pf_host"];
				}
			}
		}
	}
}

function get_shows()
{
	global $db;
	global $showsDb;
	global $gl_row;
	global $sundte;

	$ary = $showsDb->get_all_shows();
	$pf_ary = get_pf_list($sundte);
	set_pf_host($pf_ary,$ary);
$db->write_log("ary=" . print_r($ary,true) . "\n");
	if(empty($ary))
		return(0);

	$tmp = Array();
	$day_ary = Array();

//$my_plistid = $db->confessor_plistid();
//$db->write_log("plistid=$my_plistid\n");

	foreach($ary as $key => $val)
	{
		if($val["sh_plistid"] == my_plistid)
		{
			foreach($val["def_time"] as $times)
			{
				$day_ary[$times["dte"]] = $val;
				$day_ary[$times["dte"]]["def_time"] = $times;
				if(!empty($times["host"]))
					$day_ary[$times["dte"]]["sh_djname"] = $times["host"];
			}
		}
	}
	ksort($day_ary);
//$db->write_log("day_ary=" . print_r($day_ary,true) . "\n");
	return($day_ary);
}

// splits shows that span midnight
// split show's len and start time are adjusted
// show on next day is marked with "overflow=1" in main array
function get_day($shows_ary,$day_num)
{
	global $db;
	global $gl_row;
	global $now;
	$big_ary = Array();

$db->write_log("shows_ary=" . print_r($shows_ary,true) . "\n");
	$sundte = get_sunday_hour($now,$gl_row["gl_schedfold"]);
$db->write_log("sundte=" . date("D n-d-y H:i",$sundte) . "\n");

	$day_dte = get_day_midnight($sundte,$day_num,$gl_row["gl_schedfold"]);
$db->write_log("day_dte=" . date("D n-d-y H:i",$day_dte) . "\n");
	$end_dte = get_day_midnight($sundte,$day_num+1,$gl_row["gl_schedfold"]);
$db->write_log("end_dte=" . date("D n-d-y H:i",$end_dte) . "\n");

	foreach($shows_ary as $key => $val)
	{
$db->write_log("key=$key - val=" . print_r($val,true) . "\n");
		if($key >= $day_dte)
		{
			if($key >= $end_dte)
				break;
			$big_ary[$key] = $val;
		}
	}
	return($big_ary);
}

function build_day_ary($shows_ary)
{
	global $db;
	global $gl_row;
	global $now;
	$big_ary = Array();

//$db->write_log("shows_ary=" . print_r($shows_ary,true) . "\n");
// just break the big array into arrays by day
	for($day_num=0; $day_num<7; $day_num++)
	{
		$day_ary = get_day($shows_ary,$day_num);
//$db->write_log("day_ary=" . print_r($day_ary,true) . "\n");
		if(!empty($day_ary))
		{
			if($day_num == 0)
				$day_ary = chk_prev_shows($day_ary);
			if($day_num == 6)
				$day_ary = chk_following_shows($day_ary);
		}
		if(empty($day_ary))
        {
			print '<div style="height:100%; width=100%;background-color:#000033;color:white;font-family:arial,helvetica,sans-serif;font-size:40pt;">';
            print '<div style="position:absolute;top:10%;left:20%;">';
            print "you have to build the schedule<br>and generate a couple of weeks";
            print "</div></div>";
			print "<script>setTimeout(() => { window.close();},2500);</script>";
        }

		$big_ary[$day_num] = $day_ary;
	}

// now test for hold overs (called overlaps)
	for($day_num=0; $day_num<7; $day_num++)
	{
		$sundte = get_sunday($now,$gl_row["gl_schedfold"]);
		$end_dte = get_day_midnight($sundte,$day_num+1,$gl_row["gl_schedfold"]);
		$count = count($big_ary[$day_num]);
		$keys = array_keys($big_ary[$day_num]);

		if($big_ary[$day_num][$keys[$count - 1]]["def_time"]["dte"] + $big_ary[$day_num][$keys[$count-1]]["def_time"]["len"] > $end_dte)
		{
			$big_ary[$day_num][$keys[$count - 1]]["OVERLAP"] = 1;
			$len = $big_ary[$day_num][$keys[$count -1]]["def_time"]["len"];
			$big_ary[$day_num][$keys[$count - 1]]["def_time"]["len"] = $end_dte - $big_ary[$day_num][$keys[$count-1]]["def_time"]["dte"];
			$nu_keys = array_keys($big_ary[$day_num]);
			$overlap_ary = $big_ary[$day_num][$keys[$count - 1]];
			$overlap_ary["def_time"]["dte"] = $end_dte;
			$overlap_ary["def_time"]["len"] = $len - $big_ary[$day_num][$keys[$count - 1]]["def_time"]["len"];
			$overlap_ary["ADDED"] = 1;
//print "<br>add_ary=" . print_r($add_ary,true) . "<br>";
			if($day_num < 6)
			{
				$rary = array_reverse($big_ary[$day_num + 1],true);
				$rary[$end_dte] = $overlap_ary;
				$big_ary[$day_num + 1] = array_reverse($rary,true);
			}
		}
	}
//$db->write_log("big_ary=" . print_r($big_ary,true) . "\n");

	return($big_ary);
}

function print_images($big_ary)
{
	global $gl_row;
	global $db;

	$str = '<script type="text/javascript">' . "\n";

	foreach($big_ary as $day)
	{
		foreach($day as $key => $row)
		{
			if(!empty($row['sh_med_photo']))
			{
				$pix = pix_url . "/" . $row["sh_med_photo"];
				if(file_exists(pix_dir . "/" . $row['sh_med_photo']))
				{
					$str .= <<<RYYP
(new Image()).src = "$pix";\n
RYYP;
				}
			}
		}
	}
	$str .= "</script>\n";
	return($str);
}

function get_classes(&$icon_ary)
{
	global $db;
	global $showsDb;
	global $gl_row;

	global $ca_table;
	global $show_default_color;
	global $show_default_bg_color;
	global $link_text_color;
	global $page_border_color;
	global $page_padding_top;
	global $icon_bottom_padding;
	global $icon_left_offset;

	$sched_pix_width = sched_pix_width;

	$cat_ary = $showsDb->get_categories();

	$icon_ary = array();

	$str = '<style type="text/css">';

	foreach($cat_ary as $row)
	{
		$rows[] = $row;
		$icon_ary[$row["ca_id"]]["name"] = xml_undo($row["ca_name"]);
if(debug)
print __LINE__ . ": row=<pre>" . print_r($row,true) . "</pre>\n";
		if($row["ca_color"] !== null && $row["ca_color"] != '')
		{
			$color = 'color:#' . $row["ca_color"] . ";";
			$icon_ary[$row["ca_id"]]["color"] = $color;
		}
		else
			$color = 'color:' . $show_default_color . ";";
if(debug)
print __LINE__ . ": color=$color<br>\n";

		if(($row["ca_bgcolor"] !== null && $row["ca_bgcolor"] != ''))
		{
			$bgcolor = 'background-color:#' . $row["ca_bgcolor"] . ";";
			$icon_ary[$row["ca_id"]]["bgcolor"] = $bgcolor;
			$border_color = _do_set_color($row["ca_bgcolor"]);
		}
		else
		{
			$bgcolor = $show_default_bg_color;
			$border_color = $page_border_color;
		}
if(debug)
print __LINE__ . ": bgcolor=$bgcolor<br>\n";

		if(!empty($row["ca_icon"]))
		{
			preg_match("/(.*)\.(.*)/",$row["ca_icon"],$out);
			$thumb = $out[1] . "_thumb." . $out[2];
			$icon_ary[$row["ca_id"]]["icon"] = pix_url . "/" . $thumb;
//				$icon = "background-image:url('" . $gl_row["gl_pixurl"] . "/" . $thumb . "');";
//				$backrepeat = "background-repeat: no-repeat;";
//				$backpos = "background-position: left top;";
		}
		else
		{
			$icon = '';
			$backrepeat = '';
			$backpos = '';
			$thumb = '';
		}
		if($row["ca_lcolor"] !== null || $row["ca_lcolor"] != '')
			$link_color = 'color:#' . $row["ca_lcolor"] . ';';
		else if($row["ca_bgcolor"] !== null || $row["ca_bgcolor"] != '')
			$link_color = 'color:#' . _do_set_color($row["ca_bgcolor"]) . ";";
		else
			$link_color = 'color:#' . $link_text_color . ';';

if(debug)
print __LINE__ . ": thumb=$thumb - icon=$icon - backrepeat=$backrepeat - backpos=$backpos<br>\n";

		$str .= <<<ORYXU

.cat_{$row["ca_id"]}
{
$color
$bgcolor
font-weight: bold;
padding-top: $page_padding_top;
text-align:center;
}
.cat_thumb_{$row["ca_id"]}
{
$bgcolor
height:{$gl_row["gl_catythumb"]};
width:{$gl_row["gl_catxthumb"]};
}
.cat_blank_{$row["ca_id"]}
{
$bgcolor
$color
border-right: 1px solid #$border_color;
}
.cat_host_{$row["ca_id"]}
{
$color
font-weight: normal;
font-style: italic;
text-align:center;
}
.cat_key_{$row["ca_id"]}
{
$color
$bgcolor
border-right: 2px solid #$border_color;
text-align:left;
font-size:10px;
font-weight:bold;
}
.cat_icon_{$row["ca_id"]}
{
border: {$gl_row["gl_thumborder"]}px solid black;
position: relative;
left: $icon_left_offset;
margin-bottom: $icon_bottom_padding;
}
a.cat_link_{$row["ca_id"]}:link
{
$link_color
font-weight: bold;
text-align:center;
border-top: 0px solid #$border_color;
border-right: 0px solid #$border_color;
}
a.cat_link_{$row["ca_id"]}:visited
{
$link_color
text-align:center;
font-weight: bold;
border-top: 0px solid #$border_color;
border-right: 0px solid #$border_color;
}
a.cat_link_{$row["ca_id"]}:hover
{
$link_color
font-style: italic;
font-weight: bold;
text-align:center;
border-top: 0px solid #$border_color;
border-right: 0px solid #$border_color;
}
a.cat_link_{$row["ca_id"]}:active
{
color: white;
font-weight: bold;
font-style: italic;
text-align:center;
border-top: 0px solid #$border_color;
border-right: 0px solid #$border_color;
}
.dj_img
{
position:relative;
height:auto;
top:10px;
border: 1px solid #0030ff;
border-radius: 12px;
width: {$sched_pix_width}px;
}

ORYXU;
	}
	$str .= "</style>";
	return($str);
}

function print_keys($icon_ary)
{
	global $page_width;
	global $page_bg_color;
	global $title_text_color;
	global $key_height;
	global $main_left;
	global $main_top;

	$main_top += 24;
	
	$blocking_height = $key_height + 10;
	$key_top = sched_key_top;

	$top_str = <<<PKEYS
	<div style="background-color:#000000;position:fixed;top:{$main_top}px;left:0px;height:{$blocking_height}px;width:{$page_width}px;z-index:70;">
	<div style="color:#ffffff;background-color:#000000; position:fixed; top:{$key_top}px; left:{$main_left}px;height:{$key_height}px;z-index:80;">
	 <table width="$page_width" border="0" cellpadding="2px" style="border-collapse:collapse;">
PKEYS;
	$bottom_str = <<<PKEYS
	<div style="background-color:#000000;position:fixed;bottom:0px;left:0px;height:{$key_height}px;width:{$page_width}px;z-index:70;">
	<div style="color:#ffffff;background-color:#000000; position:fixed; height:{$key_height}px;bottom:0px; left:{$main_left}px;z-index:80;">
	 <table width="$page_width" border="0" cellpadding="2px" style="border-collapse:collapse;">
PKEYS;

	$cur_count = 0;

	$key_str = '';
	foreach($icon_ary as $key => $val)
	{
		if($cur_count == 0)
			$key_str .= '<tr valign="middle" height=' . $key_height . '">';

		if(!empty($val["icon"]))
		{
			$key_str .= <<<OXOOO
			<td class="cat_thumb_$key"><img src="{$val["icon"]}" ></td>
OXOOO;
			$colspan = '';
		}
		else
			$colspan = ' colspan="2" ';

		$key_str .= <<<XAIXAI
			<td class="cat_key_{$key}" $colspan>{$val["name"]}</td>
XAIXAI;
		$cur_count++;
	}
	$end_str = <<<ORYYY
	</tr>
   </table>
  </div>
  </div>
ORYYY;
	$str = <<<XXIIXXII
	$top_str
	$key_str
	$end_str
	$bottom_str
	$key_str
	$end_str
XXIIXXII;
	return($str);
}

function print_guides()
{
	global $db;
	global $gl_row;
	global $time_width;
	global $time_height;
	global $height_per_unit;
	global $unit_width;
	global $key_height;
	global $grid_top;
	global $main_left;
	global $sched_left;
	global $guides_top;
	global $main_top;

	$clock_24_hr = $gl_row["gl_info"] & (gl_24hr_clock);
	$use_ampm = $gl_row["gl_info"] & (gl_ampm);

	$right_left = $unit_width * 7;

	$days = Array("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");

	// days
	$str = '<div class="title" style="position:fixed;top:' . ($guides_top + $main_top) . 'px;left:' . ($main_left + $sched_left) . 'px;z-index:80;">';
	$str .= '<div style="background-color:inherit;position:absolute;top:0px;left:0px;height:' . $time_height . 'px;width:' . $time_width . 'px;outline:#d0d0d0 solid 1px;text-align:center;">';
	$str .= '<div style="position:absolute;top:8px;text-align:center;width:inherit;">Time</div></div>';
	$str .= '<div style="background-color:inherit;position:absolute;top:0px;left:' . ($right_left + $time_width) . 'px;height:' . $time_height . 'px;width:' . $time_width . 'px;outline:#d0d0d0 solid 1px;text-align:center;">';
	$str .= '<div style="position:absolute;top:8px;text-align:center;width:inherit;">Time</div></div>';
	$day = 0;
	foreach($days as $day_str)
	{
		$str .= '<div style="background-color:inherit;position:absolute;top:0px;left:' . (($unit_width * $day) + $time_width) . 'px;height:' . $time_height . 'px;width:' . $unit_width . 'px;outline:#d0d0d0 solid 1px;text-align:center;"><div style="position:absolute;top:8px;text-align:center;width:inherit;">';
		$str .= $day_str . "</div>";
		$str .= "</div>";
		$day++;
	}
	$str .= '</div>';

	// times
	//  left

	$start_hr = SECS_IN_HOUR * $gl_row["gl_schedfold"];
	$hr = $start_hr;
//	$incr = 60 * $gl_row["gl_schedintrvl"];
	$incr = 60 * $gl_row["gl_schedvisintrvl"];
	$lim = 24 * (SECS_IN_HOUR / $incr);
	$str .= '<div style="position:absolute;left:' . $sched_left . 'px;top:0px;width:' . $time_width . 'px;">';
	for($i=0; $i<$lim; $i++)
	{
		if(!$clock_24_hr)
		{
			if($use_ampm)
				$class = ($i % 2) ? "odd_time" : "even_time";
			else
			{
				if(($hr / SECS_IN_HOUR) >= 19 || ($hr / SECS_IN_HOUR) < 6)
					$class = "nite_time";
				else
					$class = "day_time";
			}
		}
		else
			$class = ($i % 2) ? "odd_time" : "even_time";
		$str .= '<div class="' . $class . '" style="position:absolute;left:0px;top:' . ($height_per_unit * $i + $grid_top + $main_top) . 'px;width:' . $time_width . 'px;height:' . $height_per_unit . 'px;"><div style="position:absolute;top:11px;width:inherit;height:inherit;font-size:11px;">';
		if(empty($hr))
			$time_str = 'Midnight';
//		else if($hr < SECS_IN_HOUR)
//			$time_str = '00:30';
		else if($hr == SECS_IN_HOUR * 12)
			$time_str = 'Noon';
		else
			$time_str = dt_time_from_secs($hr,$clock_24_hr,$use_ampm);
		$str .= $time_str . "&ensp;</div></div>\n";
		$str .= '<div class="' . $class . '" style="position:absolute;left:' . ($right_left + $time_width) . 'px;top:' . ($height_per_unit * $i + $grid_top + $main_top) . 'px;width:' . $time_width . 'px;height:' . $height_per_unit . 'px;"><div style="position:absolute;top:11px;width:inherit;height:inherit;font-size:11px;">';
		$str .= $time_str . "&ensp;</div></div>\n";
		$hr += $incr;
		if($hr >= (SECS_IN_HOUR * 24))
			$hr = 0;
	}
	$str .= '</div>';
	return($str);
}


function print_schedule($big_ary,$icon_ary,$pf_ary)
{
	global $db;
	global $gl_row;
	global $height_per_unit;
	global $unit_width;
	global $grid_top;
	global $time_width;
	global $key_height;
	global $page_width;
	global $sched_left;
	global $font_size;
	global $main_top;
	
//	$incr = 60 * $gl_row["gl_schedintrvl"];
	$incr = 60 * $gl_row["gl_schedvisintrvl"];
	$lim = 24 * (SECS_IN_HOUR / $incr);
	$tot_height = $height_per_unit * $lim + $key_height;

//	$height_div = 60 * $gl_row["gl_schedintrvl"];
	$height_div = 60 * $gl_row["gl_schedvisintrvl"];

	$str = '<div id="sched_div" style="position:absolute;left:' . ($time_width + $sched_left) . 'px;width:' . $page_width . 'px;top:' . ($grid_top + $main_top) . 'px;height:' . $tot_height . 'px;">' . "\n";

	foreach($big_ary as $day => $ary)
	{
		$left = $day * $unit_width;
		$pf_row = $pf_ary[$day];
$db->write_log("pf_row=" . print_r($pf_row,true) . "\n");
		$top = 0;
		foreach($ary as $dte => $row)
		{
$db->write_log("row=" . print_r($row,true) . "\n");
			$height = ($row["def_time"]["len"] / $height_div) * $height_per_unit;
			$time = date("h:i A",$row["def_time"]["dte"]);
			$tooltip_str = '';
			$pix_str = '';
			if(empty($row["ADDED"]))
			{
				if(!empty($row['sh_desc']) || !empty($row['sh_med_photo']) || !empty($time))
				{
					$tooltip_str = <<<TOSTR
					style="cursor:pointer;" onmouseover="Tooltip.schedule(this,event);" tooltip='
					$time<br>
					<span style="font-weight:bold;color:#a0ffa0;">{$row["sh_name"]}</span><br><br>
TOSTR;
					if(!empty($row["sh_med_photo"]))
					{
						$pixname = pix_url . "/" . $row["sh_med_photo"];
						if(!empty($row["sh_djname"]))
							$alt = 'alt="' . $row["sh_djname"] . '" ';
						else
							$alt = "";
						$pix_str = '<div align="center"><img class="dj_img" src="' . $pixname . '" ' . $alt . '>';
					}
					if(!empty($row['sh_desc']))
					{
						$tooltip_str .= $row['sh_desc'];
						if(!empty($row["sh_med_photo"]))
						{
							$tooltip_str .= '<br>' . $pix_str;
							if(!empty($row['sh_djname']))
							{
								$tooltip_str .= '<div style="position:relative;top:10px;">';
								$tooltip_str .= $row['sh_djname'];
								$tooltip_str .= '</div>';
							}
						}
					}
					else if(!empty($pix_str))
					{
						$tooltip_str .= $pix_str;
						if(!empty($row['sh_djname']))
						{
							$tooltip_str .= '<div style="position:relative;top:10px;">';
//							$tooltip_str .= "<br>" . $row['sh_djname'];
							$tooltip_str .= $row['sh_djname'];
							$tooltip_str .= "</div>";
							$tooltip_str .= '</div>';
						}
					}
				}
$db->write_log("day=$day - dte=" . date("m-d-y H:i",$dte) . "\n");
				$guests_str = '';
				if(!empty($pf_row[$dte]))
				{
					if(empty($tooltip_str))
					{
						$tooltip_str = <<<TOSTR
					style="cursor:pointer;" onmouseover="Tooltip.schedule(this,event);" tooltip='
TOSTR;
					}
					$tooltip_str .= '<div style="font-size:10px;font-style:normal;"><br>On Today&#039;s Show:';
					$pf_count = 0;
					$guests_str = '<div style="font-size:8px;font-style:normal;width:' . intval($unit_width - 7) . 'px;border 3px solid black;background-color:#303030;border-radius:8px;color:#00ff00;">';
						
					foreach($pf_row[$dte] as $pf)
					{
//						if(!empty($pf["pf_gname"]))
//							$guests_str .= "Guest" . (count($pf_row[$dte]) > 1 ? "s<br>" : "<br>");
//						else if(!empty($pf["pf_gtopic"]))
							$guests_str .= $pf["pf_gtopic"];
//						$guests_str .= xml_undo($pf["pf_gname"]) . "<br>";
						if($pf_count)
							$tooltip_str .= '<span style="margin-left:20px;">' . "AND</span><br>";
						if(!empty($pf["pf_gname"]))
							$tooltip_str .= "<br>Guest: " . $pf["pf_gname"] . " - ";
						if(!empty($pf["pf_gtopic"]))
							$tooltip_str .= "<br>" . $pf["pf_gtopic"];
						if(!empty($pf["pf_host"]))
							$tooltip_str .= "<br>Host: " . $pf["pf_host"];
						if(!empty($pf["pf_notes"]))
							$tooltip_str .= "<br>" . $pf["pf_notes"] . "<br>";
						$pf_count++;
					}
					$guests_str .= "</div>";
					$tooltip_str .= "</div>";
				}
			}
			$str .= '<div class="cat_' . $row["ca_id"] . '" style="position:absolute;left:' . $left . 'px;top:' . $top . 'px;height:' . $height . 'px;width:' . ($unit_width - 5) . 'px;outline:#000000 solid 1px;padding:2px;font-size:' . $font_size . 'px;';
			if(!empty($tooltip_str))
				$str .= $tooltip_str . "'" . '">';
			else
				$str .= '">';

			if(empty($row["ADDED"]))
			{
				if(!empty($row["sh_url"]))
					$name_str = '<a class="cat_link_' . $row["ca_id"] . '" href="' . $row["sh_url"] . '" target="New">' . $row["sh_name"] . '</a>';
				else
					$name_str = $row["sh_name"];

				$str .= '<div>' . $name_str . '</div>';

				$str .= '<div class="cat_host_' . $row["ca_id"] . '">' . $row["sh_djname"] . "</div>";
				$str .= $guests_str;
			}
			else
			{
				$str .= '<div>' . "(" . $row["sh_name"] . ")</div>";
			}
			$str .= "</div>" . "\n";
			$top += $height;
		}
	}
	return($str);
}

function get_logo()
{
	global $gl_row;
	$height = (sched_logo_height + 5) . 'px';
	$img = pix_url . "/" . $gl_row["gl_stapix"];

	if(!empty($gl_row["gl_stapix"]))
	{
		$img_str = <<<IMGSTR
	 <img src="{$img}" alt="{$gl_row["gl_station"]}" height="{$height}">
IMGSTR;
	}
	else
	{
		$img_str = '<img src="">';
	}

	$str = <<<LOGOSTR
	<div id="logo" style="position:fixed;top:0px;left:0px;width:908px;height:{$height};background-color:#000000;z-index:80;text-align:center;">
	 $img_str
	</div>
LOGOSTR;
	return($str);
}

function get_dates($dte = 0,$empty_flag = false)
{
	global $page_width;
	global $now;

	if(empty($dte))
		$dte = $now;
	$sundte = get_sunday($dte);
	$dte_str = date("D n-d-y",$sundte);
	if($empty_flag)
		$dte_str .= " is Not Available Yet!";
	$top = (sched_logo_height + 5);

	$str = <<<DTE
	<input type="hidden" value="$sundte" id="sundte">
	<div id="dte_div" style="position:fixed;top:{$top}px;height:52px;width:{$page_width}px;background-color:#000000;color:#ffffff;z-index:80;">
	 <div style="position:absolute;top:5px;font-size:24px;width:inherit;text-align:center;">Schedule for Week of $dte_str</div>
	 <div style="position:absolute;left:40px;top:10px;width:30px;text-align:center;">
	  <button style="font-size:20px;" onclick="do_prev(this);">Prev</button>
	 </div>
DTE;
	if(!$empty_flag)	
		$str .= <<<DTE1
	 <div style="position:absolute;right:40px;top:10px;width:30px;text-align:center;">
	  <button style="font-size:20px;" onclick="do_next(this);">Next</button>
	 </div>
DTE1;
	$str .= '</div>';

	return($str);
}

function get_pfs($day_ary)
{
	global $db;

	$pf_day = [];
	$big_ary = [];

	foreach($day_ary as $day => $stuff)
	{
		$day_str = '';
		foreach($stuff as $shodte => $val)
		{
			$day_str .= $shodte . ",";
		}
		$day_str = rtrim($day_str,",");
		$pf_day[$day] = $day_str;
	}
	foreach($pf_day as $day => $str)
	{
		$sql = "select pf_schedtime,pf_host,pf_gname,pf_gtopic,pf_notes from " . $db->confessor_tables("pf_table");
		$sql .= " where pf_schedtime in ($str)";
		$sql .= " and pf_plistid='" . my_plistid . "'";
		$sql .= " and not pf_info & " . (pf_subhost);
		$ary = $db->confessor_data($sql,$num,true);
		$lil_ary = [];
		foreach($ary as $row)
		{
			$schedtime = $row["pf_schedtime"];
			if(!isset($lil_ary[$schedtime]))
				$lil_ary[$schedtime] = [];

			$lil_ary[$schedtime][] = $row;
		}
		$big_ary[$day] = $lil_ary;
	}
	return($big_ary);
}

$shows_ary = get_shows();

if(empty($shows_ary))
{
	$logo_str = get_logo();
	$date_str = get_dates($sundte,true);
}
else
{
$big_ary = build_day_ary($shows_ary);
$pf_ary = get_pfs($big_ary);
$db->write_log("pf_ary = " . print_r($pf_ary,true) . "\n");
$img_str = print_images($big_ary);
$icon_ary = Array();
$class_style_str = get_classes($icon_ary);
$db->write_log("icon_ary=" . print_r($icon_ary,true) . "\n");
//print __LINE__ . ": icon_ary=" . print_r($icon_ary,true) . "\n";
//print __LINE__ . ": class_style_str=" . $class_style_str . "<br>\n";

$logo_str = get_logo();
$date_str = get_dates($sundte);
$keys_str = print_keys($icon_ary);
$guides = print_guides();
$out = print_schedule($big_ary,$icon_ary,$pf_ary);
}
print $head_str;
?>
<script type="text/javascript" language="javascript">
<?php
print "here='" . $_SERVER["PHP_SELF"] . "';\n";
?>
//<!--
function do_next(obj)
{
	var dte = document.getElementById('sundte').value;
	location.href = here + '?dte=' + dte + '&op=next';
}

function do_prev(obj)
{
	var dte = document.getElementById('sundte').value;
	location.href = here + '?dte=' + dte + '&op=prev';
}
//-->
</script>
<?php

if(!empty($shows_ary))
{
	print $img_str;		// javascript preload images
	print $style_str;	// styles
	print $class_style_str;	// styles
}
print '</head><body style="font-family:Arial,Helvetica,sans-serif;font-size:10px;background-color:#000000;">' . "\n";
print '<script type="text/javascript" language="javascript" src="../script/geometry.js"></script>';
print '<div style="position:absolute;left:' . $main_left . 'px;width:' . $page_width . 'px;">';
print $logo_str;
print $date_str;
if(!empty($shows_ary))
{
print $keys_str;
print $guides;
print $out;
}
print '</div>';
print "</body></html>\n";
$obout = ob_get_contents();
$db->write_log($obout);
ob_flush()

/*
foreach($big_ary as $day_num => $day_ary)
{
	$keys = array_keys($day_ary);
	$first_show_ary = $day_ary[$keys[0]];
$db->write_log(">============== " .  date("D n-d-y H:i",$first_show_ary["def_time"]["dte"]) . " =============\n");

	foreach($day_ary as $key => $val)
	{
		$db->write_log(date("D n-d-y H:i",$key) . "\n");
		$db->write_log(print_r($val,true) . "\n");
	}
}
*/

?>
