<?php
$confessor_api = "http://confessor.kpft.org/_do_api.php";
$archive_api = "http://archive.kpft.org/_sh_do_api.php";
//error_reporting(E_ALL);
//ini_set("display_errors","1");
/*====================================================
 * all returns from this api are arrays
 *====================================================*/

/*====================================================
 * get_all_shows(no param)
 * returns:
 * array(<day num (0-6)> => <0-n>(shows in time order) =>
 *											[sh_id] => 71
 *											[sh_altid] => nightsounds
 *											[sh_name] => Pat &amp; Rosie&#039;s Night Sounds
 *											[sh_desc] =>
 *											[sh_url] => 
 *											[sh_facebook] =>
 *											[sh_twitter] =>
 *											[sh_tumblr] =>
 *											[sh_photo] => http://confessor.kpft.org/pix/pat__rosies_night_sounds_71.jpg
 *											[sh_djname] => Pat &amp; Rosie
 *											[sh_email] =>
 *											[start] => 1:00 AM
 *											[end] => 4:00 AM
 *											[sh_shour] => 3600
 *											[sh_len] => 10800
 *											[sh_info] => 64
 *											[day] => Saturday
 *)
 *====================================================*/
function get_all_shows()
{
	global $confessor_api;

	$buf = '';
	$buf = file_get_contents($confessor_api . "?req=getshows");
	$ary = unserialize(base64_decode($buf));
	return($ary);
}

/*====================================================
 * get_show_by_time(<timestamp> or no param)
 * gets a show by time:
 * if the single param is not used it gets the current show
 * if the single param is a timestamp, it gets the show that fits the time.

 * build a specific timestamp with mktime: 
 * (timestamp = mktime(hours,minutes,seconds,month,day,year);
 *
 * so:
 * $time_stamp = mktime(<hour>,<minute>,0,<month (1-12)>,<day (1-31)>,<year (2012, 2013, etc)>);
 * note: seconds=0
 *
 * or:
 * $time_stamp = mktime(0,0,<seconds as in sh_shour>,<month><day><year>);
 * 
 * returns:
 array(
 *	[sh_id] => 71
 *	[sh_altid] => nightsounds
 *	[sh_name] => Pat &amp; Rosie&#039;s Night Sounds
 *	[sh_desc] =>
 *	[sh_url] => 
 *	[sh_facebook] =>
 *	[sh_twitter] =>
 *	[sh_tumblr] =>
 *	[sh_photo] => http://confessor.kpft.org/pix/pat__rosies_night_sounds_71.jpg
 *	[sh_djname] => Pat &amp; Rosie
 *	[sh_email] =>
 *	[start] => 1:00 AM
 *	[end] => 4:00 AM
 *	[sh_shour] => 3600
 *	[sh_len] => 10800
 *	[sh_info] => 64
 *	[day] => Saturday
)
 *====================================================*/
function get_show_by_time($tim = 0)
{
	global $confessor_api;

	if(empty($tim))
		$tim = time();
	$buf = file_get_contents($confessor_api . "?req=getshow&dte=" . $tim);
	$ary = unserialize(base64_decode($buf));

	return($ary);
}

/*====================================================*
 * get_day(<day number (0-6))
 *
 * returns array of all shows for that day in order of start time:
 *
 * array => show (0-n) => 
 *	[sh_id] => 71
 *	[sh_altid] => nightsounds
 *	[sh_name] => Pat &amp; Rosie&#039;s Night Sounds
 *	[sh_desc] =>
 *	[sh_url] => 
 *	[sh_facebook] => 
 *	[sh_twitter] => 
 *	[sh_tumblr] => 
 *	[sh_photo] => http://confessor.kpft.org/pix/pat__rosies_night_sounds_71.jpg
 *	[sh_djname] => Pat &amp; Rosie
 *	[sh_email] =>
 *	[start] => 1:00 AM
 *	[end] => 4:00 AM
 *	[sh_shour] => 3600
 *	[sh_len] => 10800
 *	[sh_info] => 64
 *	[day] => Saturday
 *
 *
 *====================================================*/
function get_day($day_num)
{
	global $confessor_api;

	$buf = file_get_contents($confessor_api . "?req=getday&day=$day_num");
	$ary = unserialize(base64_decode($buf));
	return($ary);
}

/*====================================================*
 * get_filnam(<idkey>,<num (optional - defaults to 5)>
 * retrieves array of archive entries:
 * 
 *
 * array(
 * 	[0-n]
 *	(
 *	 	[pubfile] => Array
 *		(
 *			[0] => Array
 *			(
 *				[pf_host] => Sarah Gish
 *				[pf_gname] => Dr. Monica Roberson, a nontraditional women&#39;s wellness doctor
 *				[pf_gtopic] => Only Connect: People and Places That Make Houston Great
 *				[pf_gurl] => 
 *				[pf_issue1] => Health and Medicine
 *				[pf_issue2] => Miscellaneous
 *				[pf_issue3] => 
 *				[pf_notes] => 
 *			)
 *		)
 *		[idkey] => ojcs
 *		[title] => Open Journal - Community Spotlight
 *		[days] => 60
 *		[category] => Public Affairs
 *		[producer] => Community Members
 *		[link] => 
 *		[facebook] =>
 *		[twitter] =>
 *		[tumblr] =>
 *		[mp3] => http://archive.kpft.org/mp3/kpft_121219_093000ojcs.mp3
 *		[day] => Wednesday
 *		[date] => December 19, 2012
 *		[def_time] => 1355931000
 *		[expires] => 1361115000
 *		[txt] => 
 *		[lsecs] => 1811
 *	)
 *	.
 *	.
 *	.
 *	[n]
 *	(
 *		etc
 *	)
 *)
 *====================================================*/
function get_filnam($idkey,$num = 0)
{
	global $archive_api;

	$buf = file_get_contents($archive_api . "?req=$idkey&num=$num");
	$ary = unserialize(base64_decode($buf));
	return($ary);
}

/*====================================================*
 * get_nowplaying (unix time if different from now)
 * retrieves array of current song
 * 
 * array(
 *		['pl_artist'] = artist
 *		['pl_song'] = song
 *		['pl_album'] = album 
 *		['pl_label'] = label 
 *		)
 *====================================================*/
function get_nowplaying($now = 0)
{
	global $confessor_api;

	if(empty($now))
		$now = time();
	
	$buf = file_get_contents($confessor_api . "?req=getnow&time=$now");
	$ary = unserialize(base64_decode($buf));
	return($ary);
}

// for testing TESTING TESTING ONLY
// run it from command line 'php confessor_api.inc.php
//
// you can also run it from a web page, but the output will be garbled 
// unless you put <pre> before print_r and </pre> after
// like 'print __LINE__ . ": one day: ary=<pre>" . print_r($ary,true) . "</pre>\n";'
/*
$ary = get_day(2);
print __LINE__ . ": one day: ary=" . print_r($ary,true) . "\n";
$ary = get_show_by_time();
print __LINE__ . ": by_time: ary=" . print_r($ary,true) . "\n";
$ary = get_all_shows();
print __LINE__ . ": all: ary=" . print_r($ary,true) . "\n";
$ary = get_filnam("blueshifi");
print __LINE__ . ": filnam: ary=" . print_r($ary,true) . "\n";
$ary = get_nowplaying();
print __LINE__ . ": " . print_r($ary,true) . "\n";
*/
?> 
