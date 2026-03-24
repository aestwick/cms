<?php
include "pl_config2.php";

if(!defined("local_debug"))
	define("local_debug",0);
if(local_debug)
{
error_reporting(E_ALL);
ini_set('display_errors',"1");
}

if(!defined("got_global"))
{
	define("got_global",1);
function get_global()
{
	global $gl_table;
	static $gl_row;

	if(empty($gl_row))
	{
		$db = open_db();
		$sql = "select * from $gl_table limit 1";
		$result = mysql_query($sql,$db);
		if($result && mysql_num_rows($result))
			$gl_row = mysql_fetch_assoc($result);
	}
	return($gl_row);
}
}

$gl_row = get_global();

if(!defined("log_stuff"))
	define("log_stuff",1);

$fd = 0;
$log_name = $gl_row["gl_logdir"] . "/" . "sched.out";

if(log_stuff)
{
	$fd = fopen($log_name,"w");
	if($fd)
	{
		fwrite($fd,"--------------------- " . date("r") . " --------------------\n");
		@chmod($log_name,0666);
	}
}

if(!defined("fd"))
	define("fd",$fd);

$str = '';
if(empty($gl_row["gl_schedintrvl"]))
{
	$str .= "gl_schedintrvl must be set<br>\n";
	exit($str);
}

if(!defined("MIN_INTERVAL"))
	define("MIN_INTERVAL",$gl_row["gl_schedintrvl"] * 60);

if(!defined("FOLD_SECS"))
	define("FOLD_SECS",SECS_IN_HOUR * $gl_row["gl_schedfold"]);		// 5 am

function print_images()
{
	global $gl_row;
	global $sh_table;

	$db = open_db();

	$sql = "select sh_photo from $sh_table";
	$sql .= " where not (sh_info & " . (sh_gone|sh_unsched) . ")";
	$sql .= " order by sh_shour";
	$result = mysql_query($sql,$db);

	$str = '<script type="text/javascript" language="javascript">' . "\n";
	if($result && mysql_num_rows($result))
	{
		while($row = mysql_fetch_assoc($result))
		{
			if(!empty($row['sh_photo']))
			{
				$pix = $gl_row["gl_pixurl"] . "/" . $row["sh_photo"];
if(local_debug > 0)
print __LINE__ . ": pix=$pix<br>\n";
				if(file_exists($gl_row['gl_pixdir'] . "/" . $row['sh_photo']))
				{
					$str .= <<<RYYP
(new Image()).src = "$pix";\n
RYYP;
				}
			}
		}
	}
	$str .= "</script>\n";
	print $str;
}


function get_day($num)
{
	global $sh_table;

	$db = open_db();

	$mask = sh_sun << $num;

	$sql = "select * from shows";
	$sql .= " where (sh_info & " . $mask . ")";
	$sql .= " and not (sh_info & " . (sh_gone|sh_unsched) . ")";
	$sql .= " order by sh_shour";

	$result = mysql_query($sql,$db);
	if($result && mysql_num_rows($result))
		return($result);
	else
		return(0);
}

if(local_debug)
{
	$page_bg_color = "#ffffff";
	$body_bg_color = "#ffffff";
}
else
{
	$page_bg_color = "#000033";
	$body_bg_color = "#000000";
}

$page_width = "860px";
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
.even_time_td
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$time_even_bgcolor;
	font-size:$time_font_size;
	text-align:right;
	color:$time_text_color;
	top: 0px;
}
.odd_time_td
{
	border-right:1px solid $page_border_color;
	border-top:1px solid $page_border_color;
	background-color:$time_odd_bgcolor;
	font-size:$time_font_size;
	text-align:right;
	color:$time_text_color;
	top: 0px;
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
.title_right_td
{
	border-bottom: 1px solid $page_border_color;
	background-color:$title_bg_color;
	color:$title_text_color;
	text-align:center;
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
	padding: 5px;            
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

function get_classes(&$icon_ary)
{
	global $ca_table;
	global $show_default_color;
	global $show_default_bg_color;
	global $link_text_color;
	global $page_border_color;
	global $page_padding_top;
	global $icon_bottom_padding;
	global $icon_left_offset;

	$icon_ary = array();

	$str = '<style type="text/css">';

	$gl_row = get_global();

	$db = open_db();

	$sql = "select * from $ca_table";
	$sql.= " order by ca_name";
	$result = mysql_query($sql,$db);
	if($result && mysql_num_rows($result))
	{
		while($row = mysql_fetch_assoc($result))
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
				$icon_ary[$row["ca_id"]]["icon"] = $gl_row["gl_pixurl"] . "/" . $thumb;
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
	border-top: 1px solid #$border_color;
	border-right: 1px solid #$border_color;
	text-align:center;
}
.cat_thumb_{$row["ca_id"]}
{
	$bgcolor
	height:{$gl_row["gl_thumb_pixy"]};
	width:{$gl_row["gl_thumb_pixx"]};
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
ORYXU;
		}
	}
	$str .= "</style>";
if(debug)
print __LINE__ . ": str=$str<br>\n";
	return($str);
}

function print_keys($icon_ary)
{
if(local_debug)
print __LINE__ . ": icon_ary=<pre>" . print_r($icon_ary,true) . "</pre>\n";
	global $page_width;
	global $page_bg_color;
	global $title_text_color;

	if(iphone_flag)
		$position = "absolute";
	else
		$position = "fixed";

	$top_str = <<<PKEYS
	<div style="color:#ffffff;background-color:#000000; position:$position; top:0px; left:11px;height:30px;z-index:80;">
	 <table width="$page_width" border="0" cellpadding="2px" style="border-collapse:collapse;">
PKEYS;
	if(!iphone_flag)
	{
	$bottom_str = <<<PKEYS
	<div style="color:#ffffff;background-color:#000000; position:fixed; bottom:0px; left:11px;height:30px;z-index:80;">
	 <table width="$page_width" border="0" cellpadding="2px" style="border-collapse:collapse;">
PKEYS;
	}
	else
		$bottom_str = '';

	$cur_count = 0;

	$key_str = '';
	foreach($icon_ary as $key => $val)
	{
		if($cur_count == 0)
			$key_str .= '<tr valign="middle">';

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

/*
		if(!empty($val["icon"]))
		{
			$colspan = '';
			$img_str = '<td style="border-left: 1px solid black;" class="cat_key_' . $key . '"><img src="' . $val["icon"] . '"' . '></td>';
		}
		else
		{
			$colspan = ' colspan="2" ';
			$img_str = '';
		}

		$key_str .= $img_str;
		$key_str .= '<td ' . $colspan . ' valign="middle" style="border-left: 1px solid black;" class="cat_key_' . $key . '" style="font-size:10px;">' . $val["name"] . '</td>';
*/
		$cur_count++;
	}
	$end_str = <<<ORYYY
	</tr>
   </table>
  </div>
<!--
  <table>
  </td>
 </tr>
-->
ORYYY;
	$str = <<<XXIIXXII
	$top_str
	$key_str
	$end_str
	$bottom_str
	$key_str
	$end_str;
XXIIXXII;
	return($str);
}

function build_ary()
{
	$ary = array();

	for($i=0; $i<7; $i++)
	{
		$secs = 0;
		for($j=0; $j<SECS_IN_DAY; $j+=MIN_INTERVAL)
		{
			$ary[$secs][$i]['class'] = "blank_td";
			$secs += MIN_INTERVAL;
		}
	}
	return($ary);
}

function chk_times($icon_ary)
{
	global $sh_day_list;

	$big_ary = array();
	$gl_row = get_global();

	$big_ary = build_ary();

	for($i=0; $i<7; $i++)
	{
		$result = get_day($i);

		if($result)
		{
			while($row = mysql_fetch_assoc($result))
			{
				$catid = $row["sh_caid"];
				$stim = $row['sh_shour'];
				$big_ary[$stim][$i]['show'] = $row;

				if(!empty($icon_ary[$catid]["icon"]))
				{
					$icon = $icon_ary[$catid]["icon"];
					$big_ary[$stim][$i]["icon"] = $icon;
				}
				$desc = $row['sh_desc'];
				$pix = $row['sh_photo'];
				$host = $row['sh_djname'];
				if(!empty($host))
					$big_ary[$stim][$i]['host'] = $host;
				if(!empty($desc))
					$big_ary[$stim][$i]['tooltip'] = $desc;
				if(!empty($pix))
					$big_ary[$stim][$i]['pix'] = $pix;
				if(!empty($catid))
				{
					$big_ary[$stim][$i]['catid'] = $catid;
					$show_td = 'cat_' . $catid;
					$blank_td = 'cat_blank_' . $catid;
					$host_class = 'cat_host_' . $catid;
					$link_class = 'cat_link_' . $catid;
				}
				else if($row['sh_info'] & sh_talk)
				{
					$show_td = "talk_td";
					$blank_td = "blank_talk_td";
					$host_class = "host_span";
					$link_class = "talk_link";
				}
				else
				{
					$show_td = "show_td";
					$blank_td = "blank_td";
					$host_class = "host_span";
					$link_class = "show_link";
				}
				$big_ary[$stim][$i]['class'] = $show_td;
				$big_ary[$stim][$i]['host_class'] = $host_class;
				$big_ary[$stim][$i]['link'] = $link_class;

				$end = $row['sh_shour'] + $row['sh_len'];
				$day = $i;
				for($j=$row['sh_shour']+MIN_INTERVAL; $j<$end; $j+=MIN_INTERVAL)
				{
					if($j < SECS_IN_DAY)
					{
						$big_ary[$j][$day]['class'] = $blank_td;
					}
					else
						break;
				}
				$end -= SECS_IN_DAY;
				$day = $i + 1;
				if($day >= 7)
					$day = 0;
				for($j=0; $j<$end; $j+=MIN_INTERVAL)
				{
					$big_ary[$j][$day]['class'] = $blank_td;
				}
			}
		}
if(local_debug > 1)
{
	if(!empty($big_ary[9]))
		print __LINE__ . ": big_ary 9!<br>\n";
}
	}
if(local_debug > 1)
print __LINE__ . ": big_ary=<pre>" . print_r($big_ary,true) . "</pre>";
	ksort($big_ary);
	return($big_ary);
}

function set_carrys(&$top,&$bottom)
{
if(local_debug > 1)
{
print __LINE__ . ": top=<pre>" . print_r($top,true) . "</pre>";
print __LINE__ . ": bottom=<pre>" . print_r($bottom,true) . "</pre>";
}
	foreach($bottom as $key => $val)
	{
if(local_debug > 1)
print __LINE__ . ": check_carry: key=" . time_from_secs($key,1) . "<br>";
		foreach($val as $day => $data)
		{
if(local_debug > 1)
print __LINE__ . ": check_carrys: day=$day - data=<pre>" . print_r($data,true) . "</pre>";
			if(!empty($data['show']))
			{
				$end = $data['show']['sh_shour'] + $data['show']['sh_len'];
if(local_debug > 1)
print __LINE__ . ": end=" . time_from_secs($end,1) . " - sh_name=" . $data['show']['sh_name'] . "<br>";
				if($end >= FOLD_SECS)
				{
					$nu_day = ($day >= 6) ? 0 : $day + 1;
					$top[FOLD_SECS][$nu_day]['carry'] = '(' . $data['show']['sh_name'] . ')';
				}
			}
		}
	}
if(local_debug > 1)
print __LINE__ . ": top=<pre>" . print_r($top,true) . "</pre>";
}

function fold_ary($ary,$secs)
{
	if(empty($secs))
	{
		return($ary);
	}
	$index = 0;
	$count = count($ary);
	foreach($ary as $key => $val)
	{
		if($key >= $secs)
		{
if(local_debug > 0)
print __LINE__ . ": key=$key - secs=$secs<br>";
if(fd)
fwrite(fd,__LINE__ . ": key=$key - secs=$secs\n");
			$top = array_slice($ary,0,$index,true);
if(local_debug > 1)
print __LINE__ . ": top=<pre>" . print_r($top,true);
if(fd)
fwrite(fd,__LINE__ . ": top=" . print_r($top,true) . "\n");
			$top_count = count($top);
			$bottom = array_slice($ary,$index,$count - $top_count,true);		// bottom of original array - but top of new
if(local_debug > 1)
print __LINE__ . ": bottom=<pre>" . print_r($bottom,true) . "</pre>";
			break;
		}
		$index++;
	}
	$nu = array();
	$local = array();
	foreach($top as $key => $val)
	{
		foreach($val as $key2 => $val2)
		{
if(local_debug > 1)
print __LINE__ . ": key2=$key2 - val=<pre>" . print_r($val2,true) . "</pre>";
			if($key2 == 0)
				$key2 = 6;
			else
				$key2--;
			$local[$key2] = $val2;
		}
		ksort($local);
		$nu[$key] = $local;
	}
	set_carrys($bottom,$nu);
if(local_debug > 1)
print __LINE__ . ": nu=<pre>" . print_r($bottom,true) . "</pre>";

	foreach($nu[0] as $key => $val)
	{
		if(empty($val['show']))
		{
			if($val['class'] == 'show_td')
				$nu[0][$key]['class'] = 'blank_td';
// what was this for?
//			else
//				$nu[9][$key]['class'] = 'blank_talk_td';
		}
	}

if(local_debug > 1)
print __LINE__ . ": nu_nu=<pre>" . print_r($nu,true) . "</pre>";
	$out = $bottom + $nu;
if(local_debug > 1)
{
	if(!empty($bottom[9]))
		print __LINE__ . ": bottom has a 9!<br>\n";
	if(!empty($nu[9]))
		print __LINE__ . ": nu has a 9!<br>\n";
	if(!empty($out[9]))
		print __LINE__ . ": big_ary 9!<br>\n";
}

	return($out);
}

function show_times($ary)
{
	global $gl_row;
	global $sh_day_list;

if(local_debug > 1)
{
	if(!empty($ary[9]))
		print __LINE__ . ": big_ary 9!<br>\n";
}

	$str = <<<WER
	<tr style="visibility:hidden;height:28px;">
	 <td class="title_td" width="60px">Time</td>
	 <td class="title_td" width="100px">Sun</td>
	 <td class="title_td" width="100px">Mon</td>
	 <td class="title_td" width="100px">Tue</td>
	 <td class="title_td" width="100px">Wed</td>
	 <td class="title_td" width="100px">Thu</td>
	 <td class="title_td" width="100px">Fri</td>
	 <td class="title_td" width="100px">Sat</td>
	 <td class="title_right_td" width="60px">Time</td>
	</tr>
WER;

	$index = 0;
	foreach($ary as $key => $val)
	{
if(local_debug > 1)
print __LINE__ . ": key=$key - val=<pre>" . print_r($val,true) . "</pre>";
		$start = short_time_from_secs_ampm($key,1);
		$tr_class = "even_tr";
		$index++;
		$time_td = ($index % 2) ? "odd_time_td" : "even_time_td";
		$right_time_td = ($index % 2) ? "odd_time_td_right" : "even_time_td_right";
		$right_time_str = <<<GHG
	 <td class="$right_time_td" valign="top">$start</td>
GHG;
		$str .= <<<RYR
	<tr class="$tr_class">
	 <td class="$time_td" valign="top">$start</td>
RYR;

if(local_debug > 1)
print "TIME=$start<br>";
		foreach($val as $daynum => $row)
		{
if(local_debug > 1)
print __LINE__ . ": row=<pre>" . print_r($row,true) . "</pre>\n";
			if(!empty($row['pix']))
			{
				$pixname = $gl_row["gl_pixurl"] . "/" . $row["pix"];
				$pix_str = '<div align="center"><img border="0" src="' . $pixname . '">';
			}
			else
				$pix_str = '';
if(local_debug > 1)
if(!empty($pix_str))
print "pix_str=$pix_str<br>\n";
			if(!empty($row['tooltip']) || !empty($row['pix']))
			{
				$tooltip_str = <<<TOSTR
	<span style="cursor:pointer;font-size:14pt;color:#00ff00;" onmouseover="Tooltip.schedule(this,event);" tooltip='
TOSTR;
				if(!empty($row['tooltip']))
				{
					$tooltip_str .= $row['tooltip'];
					if(!empty($pix_str))
					{
						$tooltip_str .= '<br>' . $pix_str;
						if(!empty($row['host']))
							$tooltip_str .= "<br>" . $row['host'];
						$tooltip_str .= '</div>';
					}
				}
				else if(!empty($pix_str))
				{
					$tooltip_str .= $pix_str;
					if(!empty($row['host']))
						$tooltip_str .= "<br>" . $row['host'];
					$tooltip_str .= '</div>';
				}
				if(!empty($row["icon"]))
					$tooltip_str .= "'" . '><img class="cat_icon_' . $row["catid"] . '" src="' . $row["icon"] . '" border="0"></span><br>';
				else
					$tooltip_str .= '\'>&diams;</span>&emsp;';

//				$tooltip_str .= '"';
			}
			else
				$tooltip_str = '';

			if(empty($tooltip_str))
			{
			/*
				if(!empty($row["icon"]))
				{
					$tooltip_str = <<<ORYY
				<img src="{$row["icon"]}" class="cat_icon_{$row["catid"]}" border="0"><br>
ORYY;
				}
				*/
			}

if(local_debug > 1)
if(!empty($tooltip_str))
print "tooltip_str=$tooltip_str<br>\n";
			if(!empty($row['show']))
			{
				$photo = $row['show']['sh_photo'];
				$name = $row['show']['sh_name'];
				$host = $row['show']['sh_djname'];
				if(!empty($row['show']['sh_url']))
				{
					$url_str = '<a href="' . $row['show']['sh_url'] . '" class="' . $row["link"] . '" target="_blank">';
					$url_end = '</a>';
				}
				else
				{
					$url_str = $url_end = '';
				}

				$end = $row['show']['sh_shour'] + $row['show']['sh_len'];
				$str .= '<td valign="top" class="' . $row['class'] . '">' . $tooltip_str . $url_str . $row['show']['sh_name'] . $url_end;
				if(!empty($host))
					$str .= '<br><span class="' . $row["host_class"] . '">' . $host . '</span>';
			}
			else
			{
if(local_debug > 1)
print "show_times:" . ((empty($row['carry'])) ? 'no carry' : $row['carry']) . "<br>";
				$str .= '<td valign="top" class="' . $row['class'] . '"' . $tooltip_str . '>';
				if(!empty($row['carry']))
				{
					$str .= $row['carry'];
if(local_debug > 1)
print "str=$str<br>";
				}
				else
					$str .= '&nbsp;';
if(local_debug > 1)
print "str=$str<br>";
			}
if(local_debug > 1)
print $sh_day_list[$daynum] . "&emsp;&emsp;$name - $end<br>";
		}
		$str .= $right_time_str;
		$str .= "</tr>\n";
	}
if(local_debug > 1)
print "ary=<pre>" . print_r($ary,true) . "</pre>";
	return($str);
}
// playlists for the current day
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
<title><?php print $gl_row["gl_station"]; ?> Schedule Grid</title>
<script type="text/javascript" language="javascript" src="../script/tooltip.js"></script>
<script type="text/javascript" language="javascript">
function foo()
{
	;
}
</script>
<?php
print_images();
print $style_str;
$icon_ary = array();
$class_rows = array();
print get_classes($icon_ary);
if(fd)
fwrite(fd,__LINE__ . ": icon_ary=" . print_r($icon_ary,true) . "\n");
print "</head><body>";
print '<script type="text/javascript" language="javascript" src="../script/geometry.js"></script>';

if(local_debug)
	$center_str = "";
else
	$center_str = 'align="center"';

$ary = chk_times($icon_ary);
print print_keys($icon_ary);
$str = <<<VVCVC
  <table>
  <tr>
  <td width="100%" $center_str>
VVCVC;

print $str;
print '<table width="' . $page_width . '" style="border: 1px solid white;" cellspacing="0">';
if(local_debug > 1)
print "big_ary=<pre>" . print_r($ary,true) . "</pre>";
$ary = fold_ary($ary,FOLD_SECS);
if(fd)
fwrite(fd,__LINE__ . ": ary=" . print_r($ary,true) . "\n");
$str = show_times($ary);

print $str;

print '<tr height="40px"><td>&nbsp;</td></tr></table>';

if(iphone_flag)
	$position = "absolute";
else
	$position = "fixed";

$str = <<<WERX
<div style="position:$position;width:$page_width;left:11px;height:30px;top:25px;background-color:#000000;">
	<table style="position:absolute;bottom:0px;outline:#ffffff solid 1px;" colspacing="0" colpadding="0">
	<tr>
	 <td class="title_td" width="60px">Time</td>
	 <td class="title_td" width="99px">Sun</td>
	 <td class="title_td" width="100px">Mon</td>
	 <td class="title_td" width="100px">Tue</td>
	 <td class="title_td" width="99px">Wed</td>
	 <td class="title_td" width="100px">Thu</td>
	 <td class="title_td" width="99px">Fri</td>
	 <td class="title_td" width="99px">Sat</td>
	 <td class="title_right_td" width="60px">Time</td>
	</tr>
	</table>
	</div>
WERX;

print $str;

$str = <<<WERX
<div style="position:fixed;width:$page_width;left:11px;bottom:30px;background-color:#000000;outline:#ffffff solid 1px;">
	<table colspacing="0" colpadding="0">
	<tr>
	 <td class="title_td" width="60px">Time</td>
	 <td class="title_td" width="99px">Sun</td>
	 <td class="title_td" width="100px">Mon</td>
	 <td class="title_td" width="100px">Tue</td>
	 <td class="title_td" width="99px">Wed</td>
	 <td class="title_td" width="100px">Thu</td>
	 <td class="title_td" width="99px">Fri</td>
	 <td class="title_td" width="99px">Sat</td>
	 <td class="title_right_td" width="60px">Time</td>
	</tr>
	</table>
	</div>
WERX;
if(!iphone_flag)
	print $str;


print '</body></html>'
?>
