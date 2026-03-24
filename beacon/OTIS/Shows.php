<?php
require_once "sh_infos.php";
require_once "sho_infos.php";
require_once "filn_infos.php";
if(!defined("cf_noncf"))
	define("cf_noncf",0x01);
if(!defined("cf_signal"))
	define("cf_signal",0x04);
if(!defined("cf_scheduled"))
	define("cf_scheduled",0x10);

// user info
if(!defined("u_updater"))
	define("u_updater",0x01);
if(!defined("u_root"))				// can access all records for own station
	define("u_root",0x02);
if(!defined("u_rootroot"))			// can create root
	define("u_rootroot",0x04);
if(!defined("u_superroot"))			// can create rootroot - access to all records
	define("u_superroot",0x08);
if(!defined("u_first_login"))
	define("u_first_login",0x200);

if(!defined("root_mask"))
	define("root_mask",(u_updater|u_root|u_rootroot|u_superroot));

class Shows
{
	protected $fn_ary;
	protected $sh_ary;
	protected $sh_ary_dte;
	protected $my_db;
	protected $gl_ary;
	protected $cf_ary = Array();
	protected $user_altids;
	protected $user_altid_str;
	protected $num;
	protected $archive_dbd_sav;
	protected $confessor_dbd_sav;
	protected $archive_dbd_cur;
	protected $confessor_dbd_cur;
	protected $confessor_db;
	protected $ca_ary;
	protected $none_older_than = 0;		// none older than <weeks before now>
	protected $oldest_date = 0;
	protected $no_gone_shows = 0;
	protected $no_music_shows = 0;
	protected $all_shows = 0;
	protected $user_access = '';
	protected $no_user_access = '';
	protected $user_info = 0;
	protected $signal_only = 0;
	protected $date_order = 0;
	protected $start_date = 0;			// to replace now for weeks before
	protected $shaltid = '';


	protected function _get_user_info($ulogin)
	{
		$sql = "select u_info from " . $this->my_db->users_tables("u_table");
		$sql .= " where u_login='" . $ulogin . "'";
		$row = $this->my_db->users_data($sql,$num);
		$this->user_info = $row["u_info"] & root_mask;
	}

	protected function _get_categories($db)
	{
		if(empty($this->ca_ary))
		{
			$sql = "select * from " . $db->confessor_tables("ca_table");
			$sql .= " order by ca_name";
			$ary = $db->confessor_data($sql,$num,true);
			foreach($ary as $val)
			{
				$this->ca_ary[$val['ca_id']] = $val;
			}
		}
	}

	protected function get_gl($db)
	{
		$sql = "select * from " . $db->confessor_tables("gl_table");
		$this->gl_ary = $db->confessor_data($sql,$num);
	}

	protected function set_fn_in_str()
	{
		$this->fn_in_str = '(';
		if(!empty($this->fn_ary))
			$this->fn_in_str .= implode(',',$this->fn_ary);
		else
			$this->fn_in_str .= '""';
		$this->fn_in_str .= ')';
	}

	public function get_fn_idkeys()
	{
		return($this->fn_in_str);
	}

	public function get_fn_idkey_ary()
	{
		return($this->fn_ary);
	}
	
// snid refers to sh_id when it's a confessor show and sn_id when it's an archive show
	protected function get_fns($db,$include_expired = 0)
	{
$db->write_log("include_expired=$include_expired\n");
		$now = time();
		$idkey_str = "";
		$ary = Array();

		if(empty($this->shaltid))
		{
			$sql = "select distinct idkey from " . $db->archive_tables("fn_table");
			$sql .= " where not info & (" . (filn_noshow) . ")";
			if(empty($include_expired))
				$sql .= " and expires > $now";
			$sql .= " and abspath != ''";
			$sql .= " and ((utime < $now) || (info & " . (filn_shonow) . "))";
			if(!empty($this->user_access))
			{
				if(!empty($this->user_altids))
				{
					$sql .= " and idkey in (" . $this->user_altid_str . ")";
					$ary = $db->archive_data($sql,$num,true);
//$this->my_db->write_log("sql=$sql - er=" . $this->my_db->last_error() . "\n");
				}
				else
				{
					$ary = Array();
				}
			}
			else if(!empty($this->no_user_access))
			{
				if(!empty($this->usr_altids))
				{
					$sql .= " and idkey not in (" . $this->user_altid_str . ")";
				}
				$ary = $db->archive_data($sql,$num,true);
			}
			else
				$ary = $db->archive_data($sql,$num,true);
//$this->my_db->write_log("sql=$sql - er=" . $this->my_db->last_error() . "\n");
			foreach($ary as $val)
			{
				$this->fn_ary[] = '"' . $val['idkey'] . '"';
			}
		}
		else
		{
			$this->fn_ary[] = '"' . $this->shaltid . '"';
		}
		$this->set_fn_in_str();
	}

	protected function _set_oldest_week()
	{
		$no_weeks = $this->none_older_than;
		$dtary = getdate();
		$dt = mktime(0,0,0,$dtary["mon"],$dtary["mday"] - ($no_weeks * 7),$dtary["year"]);
		$this->oldest_date = $dt;
		return($dt);
	}

	protected function _get_confessor_shows_sql($cf_db)
	{
		if(!empty($this->none_older_than))
		{
			$this->_set_oldest_week();

			$sql = "select * from " . $cf_db->confessor_tables("sh_table,ca_table,ph_table");
		}
		else
			$sql = "select * from " . $cf_db->confessor_tables("sh_table,ca_table");
		$sql .= " where ca_id=sh_caid";
		if(!$this->user_info)		// means either not user_access or no_user_access or user is a root
		{
			if(!empty($this->user_access))
			{
				if(!empty($this->user_altids))
					$sql .= " and sh_altid in (" . $this->user_altid_str . ")";
				else
					return("");
			}
			else if(!empty($this->no_user_access))
			{
				if(!empty($this->user_altids))
					$sql .= " and sh_altid not in (" . $this->user_altid_str . ")";
			}
		}
		if(!empty($this->shaltid))
			$sql .= " and sh_altid='" . $this->shaltid . "'";
		if(!empty($this->no_gone_shows))
			$sql .= " and not sh_info & " . (sh_gone);
		if(!empty($this->no_music_shows))
		{
			$sql .= " and sh_info & " . (sh_download);
			$sql .= " and sh_info & " . (sh_pod);
		}
		if(!empty($this->none_older_than))
		{
			$sql .= " and ph_shaltid=sh_altid";
			$sql .= " and ph_date > " . $this->oldest_date;
		}
		$sql .= " order by sh_altid";
//$this->my_db->write_log("sql=$sql\n");
		return($sql);
	}

	protected function _get_confessor_shows($cf_db,$cfrow)
	{
		$num = 0;

		$ary = Array();
		$sql = $this->_get_confessor_shows_sql($cf_db);
		if(!empty($sql))
			$ary = $cf_db->confessor_data($sql,$num,true);	
		if(empty($ary))
		{
			$this->sh_ary[$cfrow['cf_plistid']] = Array();
		}
		else
		{
			foreach($ary as $val)
			{
				$this->sh_ary[$cfrow['cf_plistid']][$val["sh_altid"]] = array_merge($val,$cfrow);
			}
		}
	}

	protected function _get_archive_shows_sql($db,$cfrow)
	{
		$sql = "select * from " . $db->archive_tables("sn_table");
		$sql .= " where sn_plistid='" . $cfrow['cf_plistid'] . "'";
		if(!$this->user_info)
		{
			if(!empty($this->user_access))
			{
				if(!empty($this->user_altids))
					$sql .= " and sn_idkey in (" . $this->user_altid_str . ")";
				else
					return("");
			}
			else if(!empty($this->no_user_access))
			{
				if(!empty($this->user_altids))
					$sql .= " and sn_idkey not in (" . $this->user_altid_str . ")";
			}
		}
		if(!empty($this->shaltid))
			$sql .= " and sn_idkey='" . $this->shaltid . "'";
		if(!empty($this->no_gone_shows))
			$sql .= " and not sn_info & " . (sho_gone);
		if(!empty($this->no_music_shows))
		{
			$sql .= " and sn_info & " . (sho_pod);
			$sql .= " and sn_info & " . (sho_download);
		}
		$sql .= " order by sn_idkey";
		return($sql);
	}

	protected function _get_archive_shows($db,$cfrow)
	{
		$num = 0;

		$shary = Array();
		$ary = Array();

		$sql = $this->_get_archive_shows_sql($db,$cfrow);
		if(!empty($sql))
			$ary = $db->archive_data($sql,$num,true);

		if(empty($ary))
		{
			$this->sh_ary[$cfrow['cf_plistid']] = Array();
		}
		else
		{
			foreach($ary as $val)
			{
				$shary = $this->my_db->cvt_sn_to_sh($val);
//if(empty($this->ca_ary[$shary["sh_caid"]]))
//$db->write_log("shary=" . print_r($shary,true) . " - sh_caid=" . $shary["sh_caid"] . " - this->ca_ary=" . print_r($this->ca_ary,true) . "\n");
				$this->sh_ary[$cfrow['cf_plistid']][$shary["sh_altid"]] = array_merge($shary,$this->ca_ary[$shary['sh_caid']],$cfrow);
			}
		}
	}

	protected function _get_confessors($db)
	{
		if(empty($this->cf_ary))
		{
			$sql = "select * from " . $db->archive_tables("cf_table");
			if($this->signal_only)
				$sql .= " where cf_info & " . cf_signal;
			$this->cf_ary = $db->archive_data($sql,$num,true);
		}
	}

	private function _do_get_shows($db)
	{
		foreach($this->cf_ary as &$val)
		{
			if(!empty($val["cf_dbd"]))
			{
				$this->confessor_db = new AllDb($this->archive_dbd_sav,$val["cf_dbd"]);
				if($val["cf_info"] & cf_signal)
					$this->_get_categories($this->confessor_db);		// only categories from signal confessor used
				$this->_get_confessor_shows($this->confessor_db,$val);
			}
		}

		foreach($this->cf_ary as $cf)
		{
			if(($cf["cf_info"] & cf_noncf))
				$this->_get_archive_shows($db,$cf);
		}
	}

	public function clear_shows()
	{
		$this->sh_ary = Array();
	}

	protected function _set_altids($db)
	{
		if(!empty($this->user_access))
			$login = $this->user_access;
		else
			$login = $this->no_user_access;

		$this->usr_altid_str = '';
		$this->user_altids = Array();
		$sql = "select sl_shaltid from " . $db->users_tables("sl_table");
		$sql .= " where sl_login='" . $login . "'";
		$ary = $db->users_data($sql,$num,true);
		foreach($ary as $row)
		{
			$this->user_altids[] = $row["sl_shaltid"];
			$this->user_altid_str .= "'" . $row["sl_shaltid"] . "',";
		}
		$this->user_altid_str = rtrim($this->user_altid_str,',');

$db->write_log("altids=" . print_r($this->user_altids,true) . "\n");
	}

// fills array with all existing shows from both archive and confessor
// sn_ variables from archive.shoname are renamed to sh_ equivalents in confessor.shows
	public function __construct($db)
	{
$db->write_log("toppa Shows\n");
		$pnum = func_num_args();
		$pary = func_get_args();

		if($pnum > 1)
		{
			$aary = explode(",",$pary[1]);		// since args not quoted they show up as one param
			$lim = count($aary);
			for($i=0; $i<$lim; $i++)
			{
				if(strpos($aary[$i],":") !== false)
				{
					$ary = explode(":",$aary[$i]);
					$nam = $ary[0];
					$this->$nam = $ary[1];
				}
			}
		}
		$this->my_db = $db;
		$this->archive_dbd_sav = $db->get_archive_dbd();
		$this->confessor_dbd_sav = $db->get_confessor_dbd();
		$this->get_gl($db);
		if(!empty($this->user_access) || !empty($this->no_user_access))
			$this->_set_altids($db);
		if(!empty($this->user_access))
			$this->_get_user_info($this->user_access);
		else if(!empty($this->no_user_access))
			$this->_get_user_info($this->no_user_access);

		$this->get_fns($db);
		$this->_get_confessors($db);

		$this->_do_get_shows($db);
	}
	
// sends archive.confessors
	public function get_confessors()
	{
		return($this->cf_ary);
	}

	private function _get_shows_by_idkey_ary($idkey_ary)
	{
		$ary = Array();

		foreach($idkey_ary as $idkey)
		{
			$nu_ary = $this->get_show_by_idkey($idkey);
			$ary[$idkey] = $nu_ary;
		}
		return($ary);
	}

// if idkey is a string sends row for that show
// if idkey is an array, sends array of rows as idkey->row
	public function get_show_by_idkey($idkey)
	{
		$ary = Array();

		if(is_array($idkey))
		{
			$ary = $this->_get_shows_by_idkey_ary($idkey);
		}
		else
		{
			foreach($this->sh_ary as $key => $val)
			{
				if(array_key_exists($idkey,$val))
				{
					$ary = $val[$idkey];
					break;
				}
			}
		}
		return($ary);
	}

// sends array of similar names to levenshtein 4
	public function get_show_by_name($name)
	{
		$ary = Array();

		foreach($this->sh_ary as $key => $val)
		{
			foreach($val as $row)
			{
				if(levenshtein($name,$row['sh_name']) < 2)
				{
					$ary = $row;
					break;
				}
			}
		}
		return($ary);
	}

// sends array of all shows in that plistid as idkey->row
	public function get_shows_by_plistid($plistid)
	{
		$ary = Array();
	
		if(array_key_exists($plistid,$this->sh_ary))
			$ary = $this->sh_ary[$plistid];

		uasort($ary,[$this, "cmp_show"]);
		return($ary);
	}

	protected function cmp_show($a,$b)
	{
		return(strcmp($a["sh_name"],$b["sh_name"]));
	}

	protected function cmp_dte($a,$b)
	{
		$ret_val = 0;

		if(isset($a["def_time"][0]["dte"]) && isset($b["def_time"][0]["dte"]))
			$ret_val = $b["def_time"][0]["dte"] - $a["def_time"][0]["dte"];

		return($ret_val);
	}

// sends all shows as idkey->row sorted by sh_name
	public function get_all_shows()
	{
		$big_ary = Array();
		foreach($this->sh_ary as $plistid => $val)
		{
			foreach($val as $altid => $row)
			{
				$big_ary[$altid] = $row;
			}
		}
		uasort($big_ary,[$this, "cmp_show"]);
		return($big_ary);
	}

// sends all shows as idkey->row sorted by sh_name
// just idkey->array(sh_name,sh_djname)
	public function get_all_shows_short()
	{
		$big_ary = Array();
		foreach($this->sh_ary as $plistid => $val)
		{
			foreach($val as $altid => $row)
			{
				$big_ary[$altid] = Array("sh_altid" => $altid,"sh_name" => $row["sh_name"],"sh_djname" => $row["sh_djname"],"sh_email" => $row["sh_email"],
										"ca_color" => $row["ca_color"],"ca_bgcolor" => $row["ca_bgcolor"],
										"cf_name" => $row["cf_name"],"cf_color" => $row["cf_color"],"cf_bgcolor" => $row["cf_bgcolor"],
										"sh_plistid" => $row["sh_plistid"],"sh_info" => $row["sh_info"],
										"def_time" => $row["sh_shour"],
										);
			}
		}
		uasort($big_ary,[$this, "cmp_show"]);
		return($big_ary);
	}

// sends all shows as plistid->idkey->show
	public function get_shows()
	{
		return($this->sh_ary);
	}

	public function get_show_by_id($plistid,$shid)
	{
		$val = Array();

		foreach($this->sh_ary[$plistid] as $val)
		{
			if($val["sh_id"] == $shid)
				break;
		}
		return($val);
	}

	// we'll assume no idkeys shared among confessors
	public function get_plistid_from_idkey($idkey)
	{
		$ret_val = '';

		foreach($this->sh_ary as $key => $val)
		{
			if(array_key_exists($idkey,$val))
			{
				$ret_val = $key;
				break;
			}
		}
		return($ret_val);
	}

	public function get_confessor_by_idkey($idkey)
	{
		$local_cf_ary = Array();

		$plistid = $this->get_plistid_from_idkey($idkey);
		$lim = count($this->cf_ary);
		for($i=0; $i<$lim; $i++)
		{
			if($this->cf_ary[$i]["cf_plistid"] == $plistid)
			{
				$local_cf_ary = $this->cf_ary[$i];
				break;
			}
		}
		return($local_cf_ary);
	}

	public function check_idkeys($plistid_param = '')
	{
		$big_ary = Array();
		$uniq_ary = Array();

		foreach($this->sh_ary as $plistid => $show_ary)		// key is plistid	show_ary is idkey=>array
		{
			foreach($show_ary as $idkey => $sh_row)
			{
				$big_ary[$plistid][] = $idkey;
			}
		}
		if(empty($plistid_param))
		{
			foreach($big_ary as $plistid => $ary)	
			{
				foreach($big_ary as $p1 => $ary1)
				{
					if($p1 == $plistid)
						continue;

					$ary_u[$p1] = array_intersect($ary,$ary1);
				}
				$uniq_ary[$plistid] = $ary_u;
				$ary_u = Array();
			}
		}
		else
		{
			$plistid = $plistid_param;
			$ary = $big_ary[$plistid];

			foreach($big_ary as $p1 => $ary1)
			{
				if($p1 == $plistid)
					continue;

				$ary_u[$p1] = array_intersect($ary,$ary1);
			}
			$uniq_ary[$plistid] = $ary_u;
			$ary_u = Array();
		}
		return($uniq_ary);
	}

	private function _set_prev_letter($ary)
	{
		if(empty($ary) || empty($ary[0]))
		{
			$val = 'a';
			$ary[0] = $val;
		}
		else
		{
			$lim = count($ary);
			$val = array_pop($ary);
			$x = ord($val);
			$x++;
			$val = chr($x);
			if($val > 'z')
			{
				$val = 'a';
				$ary = $this->_set_prev_letter($ary);
			}
			array_push($ary,$val);
		}
		return($ary);
	}

// this will always add to the existing idkey
// either a - z or if it's at z set it to a and append a-z etc
// root_idkey = idkey from sho name
// cur_idkey = current idkey for this show entry
	public function get_uniq_idkey($root_idkey,$cur_idkey)
	{

		if(empty($cur_idkey))
			$idkey = $root_idkey;
		else
			$idkey = $cur_idkey;

		if(!empty($this->sh_ary))
		{
			while(1)
			{
				foreach($this->sh_ary as $plistid => $sho_ary)
				{
					if(array_key_exists($idkey,$sho_ary))
					{
						$added_str = str_ireplace($root_idkey,"",$idkey);
						$ary = str_split($added_str);
						$nu_ary = $this->_set_prev_letter($ary);
						$idkey = $root_idkey . implode($nu_ary);
						continue 2;
					}
				}
				break;
			}
		}
		return($idkey);
	}

	public function get_categories()
	{
		return($this->ca_ary);
	}
}

// pubfile rows will be identified by idkey and date
// archive shows will be included if there's a def_time entry in shoname
// if no deftime - can't create until a file exists
class Scheds extends Shows
{
	protected $start_dte;
	protected $end_dte;
	protected $idkey;

	protected function _get_sunday($dte)
	{
		$dtary = getdate($dte);
		$diff = $dtary["mday"] - $dtary["wday"];
		$dte = mktime(0,0,0,$dtary["mon"],$diff,$dtary["year"]);
		return($dte);
	}

	// both weeks params 0 -> return only start_date week
	protected function _set_dates($weeks_before_now,$weeks_after_now)
	{
		if($this->start_date)
		{
$this->my_db->write_log("start_date=" . date('m-d-y -H:i:s',$this->start_date) . "\n");
			if(!empty($weeks_before_now) || !empty($weeks_after_now))
			{
				$dtary = getdate($this->start_date);
				$now = mktime(0,0,0,$dtary["mon"],$dtary["mday"] - $dtary["wday"] + 7,$dtary["year"]);		// has to be moved up a week to be included
			}
			else
			{
				$weeks_after_now = 1;			// for end_date
				$now = $this->start_date;
			}
		}
		else
		{
			$now = time();
		}

		$now_sun = $this->_get_sunday($now);
//$this->my_db->write_log("weeksbefore=$weeks_before_now - weeksafter=$weeks_after_now\n");
//$this->my_db->write_log("now_sun=" . date("m-d-y",$now_sun) . "\n");
		$dtary = getdate($now_sun);
		$diff = $dtary["mday"] - ($weeks_before_now * 7);
		$this->start_dte = mktime(0,0,0,$dtary["mon"],$diff,$dtary["year"]);
		$diff = $dtary["mday"] + ($weeks_after_now * 7);
		$this->end_dte = mktime(0,0,0,$dtary["mon"],$diff,$dtary["year"]);
//$this->my_db->write_log("start=" . date("m-d-y",$this->start_dte) . " - end=" . date("m-d-y",$this->end_dte) . "\n");
	}

	protected function _get_shows_altids_list($plistid)
	{
		$str = '';

		foreach($this->sh_ary[$plistid] as $key => $val)
		{
			$str .= '"' . $key . '",';
		}
		$str = rtrim($str,',');

		return($str);
	}

	protected function set_sh_ary($ph_row,$plistid)
	{
		$wk = date("ymd",$ph_row["ph_wkweek"]);
		$shaltid = $ph_row["ph_shaltid"];
		$mp3 = $ph_row["mp3"];
		$sh_ary = $this->sh_ary[$plistid][$shaltid];
		$dte = $ph_row["ph_date"];
		$dtary = getdate($dte);
		$endte = mktime($dtary["hours"],$dtary["minutes"],$dtary["seconds"] + $ph_row["ph_shlen"],$dtary["mon"],$dtary["mday"],$dtary["year"]);
		$day_hour = $dtary["wday"] . ":" . $ph_row["ph_shour"];
		$this->sh_ary_dte[$wk][$day_hour]["dte"] = $dte;
		$this->sh_ary_dte[$wk][$day_hour]["starts"] = date("g:i A",$dte);
		$this->sh_ary_dte[$wk][$day_hour]["ends"] = date("g:i A",$endte);
		$this->sh_ary_dte[$wk][$day_hour]["day"] = date("l",$dte);
		$this->sh_ary_dte[$wk][$day_hour]["fulldate"] = date("F j, Y",$dte);
		$this->sh_ary_dte[$wk][$day_hour]["mp3"] = $mp3;
		foreach($sh_ary as $key => $val)
		{
			switch($key)
			{
				case 'sh_altid':
				case 'sh_name':
				case 'sh_desc':
				case 'sh_shortdesc':
				case 'sh_url':
				case 'sh_keywords':
				case 'sh_facebook':
				case 'sh_twitter':
				case 'sh_tumblr':
				case 'sh_djname':
				case 'sh_email':
				case 'sh_plistid':
				case 'ca_name':
				case 'ca_desc':
				case 'cf_listenurl':
					$this->sh_ary_dte[$wk][$day_hour][$key] = $val;
					break;
				case 'sh_photo':
				case 'sh_med_photo':
					if(empty($val))
						$this->sh_ary_dte[$wk][$day_hour][$key] = rtrim($sh_ary['cf_pixurl']) . "/" . $this->gl_ary["gl_stapix"];
					else
						$this->sh_ary_dte[$wk][$day_hour][$key] = rtrim($sh_ary['cf_pixurl']) . "/" . $val;
					break;
				case 'ca_info':
					$this->sh_ary_dte[$wk][$day_hour]['type'] = (($val & ca_talk) ? 'Talk' : 'Music');
					break;
				case 'sh_shour':
					$this->sh_ary_dte[$wk][$day_hour][$key] = $ph_row["ph_shour"];
					break;
				case 'sh_len':
					$this->sh_ary_dte[$wk][$day_hour][$key] = $ph_row["ph_shlen"];
					break;
				default:
					break;
			}
		}
	}

	protected function _get_confessor_scheds($cf_db,$plistid)
	{
		$sql = "select ph_id,ph_shaltid,ph_date,ph_day,ph_shour,ph_shlen from " . $cf_db->confessor_tables("ph_table");
		$sql .= " where ph_shaltid in (" . $this->_get_shows_altids_list($plistid)  . ")";
		if(empty($this->all_shows))
		{
			$sql .= " and ph_date >=" . $this->start_dte;
			$sql .= " and ph_date < " . $this->end_dte;
		}
		$sql .= " order by ph_shaltid,ph_date";
		$ary = $cf_db->confessor_data($sql,$num,true);
		$def_time_ary = Array();
		if(!empty($ary))
		{
			$last_altid = '';
			foreach($ary as $row)
			{
				if(empty($last_altid))
				{
					$last_altid = $row["ph_shaltid"];
				}
				if($row["ph_shaltid"] != $last_altid)
				{
					if(!empty($last_altid))
					{
						$this->sh_ary[$plistid][$last_altid]["def_time"] = $def_time_ary;
					}
					$def_time_ary = Array();
					$last_altid = $row["ph_shaltid"];
				}
				$def_time_ary[] = Array("dte" => $row["ph_date"],"day" => $row["ph_day"],"hour" => $row["ph_shour"],"len" => $row["ph_shlen"],"id" => $row["ph_id"]);
			}
			if(!empty($def_time_ary))
				$this->sh_ary[$plistid][$last_altid]["def_time"] = $def_time_ary;
		}
	}

	protected function _get_confessor_scheds_for_date_order($cf_db,$plistid)
	{
		$sql = "select ph_id,ph_wkweek,ph_shaltid,ph_date,ph_day,ph_shour,ph_shlen from " . $cf_db->confessor_tables("ph_table");
		$sql .= " where ph_shaltid in (" . $this->_get_shows_altids_list($plistid)  . ")";
		if(empty($this->all_shows))
		{
			$sql .= " and ph_date >=" . $this->start_dte;
			$sql .= " and ph_date < " . $this->end_dte;
		}
		$sql .= " order by ph_date";

		$ary = $cf_db->confessor_data($sql,$num,true);
		$def_time_ary = Array();
		if(!empty($ary))
		{
			$def_list = '';
			$fn_list_ary = [];
			foreach($ary as $ph_row)
			{
				$def_list .= $ph_row["ph_date"] . ",";
			}
			$def_list = rtrim($def_list,",");
			$sql = "select idkey,def_time,abspath from " . $cf_db->archive_tables("fn_table");
			$sql .= " where def_time in (" . $def_list . ")";
			$sql .= " and plistid='$plistid'";
			$sql .= " order by def_time";
			$fn_ary = $cf_db->archive_data($sql,$num,true);
			foreach($fn_ary as $fn_row)
				$fn_list_ary[$fn_row["def_time"]] = $fn_row;

			foreach($ary as $ph_row)
			{
				$ph_row["mp3"] = '';
				$dte = $ph_row["ph_date"];
				if(!empty($fn_list_ary[$dte]))
				{
					if($fn_list_ary[$dte]["idkey"] == $ph_row["ph_shaltid"])
						$ph_row["mp3"] = $fn_list_ary[$dte]["abspath"];
				}
				$this->set_sh_ary($ph_row,$plistid);
			}
		}
	}

	protected function _get_dte_ary($sh_row,$stdte,$endte,$day)
	{
		$big_ary = Array();
		
		$curdte = $stdte;
		$dt_ary = getdate($curdte);
		while($curdte <= $endte)
		{
			$curdte = mktime(0,0,$sh_row["sh_shour"],$dt_ary["mon"],$dt_ary["mday"] + $day,$dt_ary["year"]);
			$big_ary[] = $curdte;
			$day += 7;
		}
		return($big_ary);
	}

	private function cmp_def_time($a,$b)
	{
		return($b["def_time"] - $a["def_time"]);
	}

	// makes sure there's a date for each date in the date range
	// there would be no date if there weren't an existing filnam entry
	protected function _chk_archive_dates($stdte,$endte,$idkey)
	{
		$local_dte_ary = Array();

		$mask = 0x01;		// sunday

		foreach($this->sh_ary as $plistid => $val)
		{
//$this->my_db->write_log("idkey=$idkey - val=" . print_r($val,true) . "\n");
			if(array_key_exists($idkey,$val))
			{
				break;
			}
		}
		if(!empty($plistid) && !empty($val))
		{
			$sh_row = $val[$idkey];
			$sh_len = $sh_row["sh_len"];
//$this->my_db->write_log("sh_row=" . print_r($sh_row,true) . "\n");

			// get_days
			for($i=0; $i<7; $i++)
			{
				if($sh_row["sh_def_day"] & $mask)
				{
					$ary = $this->_get_dte_ary($sh_row,$stdte,$endte,$i);

					foreach($ary as $val)
					{
//$this->my_db->write_log("val=" . date("m-d-y H:i",$val) . " or $val\n");
						if(!empty($this->dte_ary))
						{
							foreach($this->dte_ary as $dkey => $dval)
							{
								if($dval["def_time"] == $val)
									break;
							}
							if($dval["def_time"] == $val)
								continue;
						}
						$this->dte_ary[] = Array("def_time" => $val, "lsecs" => $sh_len);
					}
				}
				$mask <<= 1;

			// any filnams?
			}
			usort($this->dte_ary,[$this, "cmp_def_time"]);
//$this->my_db->write_log("val=" . date("m-d-y H:i",$val) . " or $val\n");
		}
	}

	// gets def_times of existiing filnams within date range
	protected function _get_archive_dates($idkey)
	{
		$sql = "select def_time,lsecs from " . $this->my_db->archive_tables("fn_table");
		$sql .= " where idkey='" . $idkey . "'";
		$sql .= " and def_time >= " . $this->start_dte;
		$sql .= " and def_time <= " . $this->end_dte;
		$sql .= " order by def_time desc";
		$this->dte_ary = $this->my_db->archive_data($sql,$num,true);
//$this->my_db->write_log("dte_ary=" . print_r($this->dte_ary,true) . "\n");
		$this->_chk_archive_dates($this->start_dte,$this->end_dte,$idkey);
//$this->my_db->write_log("dte_ary=" . print_r($this->dte_ary,true) . "\n");
	}

	protected function _get_archive_scheds($db,$cf_row)
	{
		foreach($this->sh_ary[$cf_row["cf_plistid"]] as $key => &$val)
		{
			$this->_get_archive_dates($key);
			$this->sh_ary[$cf_row["cf_plistid"]][$key]["def_time"] = $this->dte_ary;
//			$this->sh_ary[$cf_row["cf_plistid"]][$key]["def_time"] = Array();
//$this->my_db->write_log("val=" . print_r($val,true) . "\n");
		}
	}

	public function __construct($db,$weeks_before_now = 0,$weeks_after_now = 0)
	{
		$pnum = func_num_args();
		$pary = func_get_args();
		if($pnum > 3)
			$pary_3 = $pary[3];
		else
			$pary_3 = 0;

//print __LINE__ . ": pnum=$pnum - pary=" . print_r($pary,true) . "\n";

		if(!empty($pary_3))
			parent::__construct($db,$pary_3);
		else
			parent::__construct($db);

//$this->my_db->write_log("pary=" . print_r($pary,true) . "\n");
//$this->my_db->write_log("sh_ary=" . print_r($this->sh_ary,true) . "\n");
//$this->my_db->write_log("fn_ary=" . print_r($this->fn_ary,true) . "\n");

		if(!empty($pary_3))
		{
			$aary = explode(",",$pary[3]);		// since args not quoted they show up as one param
			$lim = count($aary);
			for($i=0; $i<$lim; $i++)
			{
				if(strpos($aary[$i],":") !== false)
				{
					$ary = explode(":",$aary[$i]);
					$nam = $ary[0];
					$this->$nam = $ary[1];
//$this->my_db->write_log("ary=" . print_r($ary,true) . "\n");
				}
			}
		}

		if(empty($this->all_shows))
			$this->_set_dates($weeks_before_now,$weeks_after_now);

//$this->my_db->write_log("cf_ary=" . print_r($this->cf_ary,true) . "\n");
		foreach($this->cf_ary as $val)
		{
			if(!empty($val["cf_dbd"]))
			{
				$this->confessor_db = new AllDb($this->archive_dbd_sav,$val["cf_dbd"]);
				if($this->date_order)
					$this->_get_confessor_scheds_for_date_order($this->confessor_db,$val["cf_plistid"]);
				else
					$this->_get_confessor_scheds($this->confessor_db,$val["cf_plistid"]);
			}
			else
			{
				$this->_get_archive_scheds($db,$val);
			}
		}

		if(!$this->date_order)
		{
			foreach($this->sh_ary as $key => $val)
			{
				foreach($val as $idkey => $row)
				{
					if(empty($row["def_time"]))
					{
						unset($this->sh_ary[$key][$idkey]);
					}
				}
			}
		}
	}
// sends all shows as idkey->row sorted by sh_name
// just idkey->array(sh_name,sh_djname)
	public function get_all_shows_short()
	{
		$big_ary = Array();
		foreach($this->sh_ary as $plistid => $val)
		{
			foreach($val as $altid => $row)
			{
				if(!empty($row["def_time"]) && !empty($row["sh_id"]))
				{
					$big_ary[$altid] = Array("sh_altid" => $altid,"sh_name" => $row["sh_name"],"sh_djname" => $row["sh_djname"],"sh_email" => $row["sh_email"],
										"ca_color" => $row["ca_color"],"ca_bgcolor" => $row["ca_bgcolor"],
										"cf_color" => $row["cf_color"],"cf_bgcolor" => $row["cf_bgcolor"],
										"cf_name" => $row["cf_name"],
										"sh_plistid" => $row["sh_plistid"],"sh_info" => $row["sh_info"],
										"def_time" => $row["def_time"],
										);
				}
			}
		}
		uasort($big_ary,[$this, "cmp_show"]);
		return($big_ary);
	}
	public function get_all_shows()
	{
		if($this->date_order)
			return($this->sh_ary_dte);
		else
		{
			$big_ary = Array();
			foreach($this->sh_ary as $plistid => $val)
			{
				foreach($val as $altid => $row)
				{
					if(!empty($row["def_time"]))
						$big_ary[$altid] = $row;
				}
			}
			uasort($big_ary,[$this, "cmp_show"]);
			return($big_ary);
		}
	}
}

// gets the show identified by idkey
// if from_weeks (weeks before now) and to_weeks (weeks after now)
// are included, adds 'dates' array to show with :
// 	if confessor show: ph_dates within date range from existing headers
// 	if archive show: def_times within date range from existing filnam records
// used for public_file stuff
// all public_file records are in signal confessor
class OneShow extends Scheds
{
	protected $sh_ary = Array();
	protected $idkey = '';
	protected $dte_ary = Array();
	protected $local_cf_ary = Array();
	

	public function __construct($db,$idkey,$from_weeks = 0,$to_weeks = 1,$dte = 0)
	{
		$this->start_date = $dte;
		$this->my_db = $db;
		$this->get_gl($db);
		$this->idkey = $idkey;
$this->my_db->write_log("gl_arxxy=" . print_r($this->gl_ary,true) . "\n");
//		if($from_weeks && $to_weeks)
			$this->_set_dates($from_weeks,$to_weeks);
		$this->archive_dbd_sav = $db->get_archive_dbd();
		$this->confessor_dbd_sav = $db->get_confessor_dbd();

		$this->_get_confessors($db);

//$this->my_db->write_log("start=" . date("m-d-y",$this->start_dte) . " - end=" . date("m-d-y",$this->end_dte) . "\n");

		foreach($this->cf_ary as $val)
		{
			if(!empty($val["cf_dbd"]))
			{
				$this->confessor_db = new AllDb($this->archive_dbd_sav,$val["cf_dbd"]);
				if($val["cf_info"] & cf_signal)
					$this->_get_categories($this->confessor_db);		// only categories from signal confessor used
					/*
				$sql = "select * from " . $this->confessor_db->confessor_tables("gl_table");
				$gl_ary = $this->confessor_db->confessor_data($sql,$num);
					*/
				$val["gl_pixurl"] = $this->gl_ary["gl_pixurl"];
				$val["gl_pixdir"] = $this->gl_ary["gl_pixdir"];
				$val["gl_stapix"] = $this->gl_ary["gl_stapix"];
				$this->_get_confessor_shows($this->confessor_db,$val);
			}
			else
			{
				if($val["cf_info"] & cf_noncf)
					$this->_get_archive_shows($db,$val);
			}
		}

//		if($from_weeks && $to_weeks)
		if($to_weeks)
			$this->_do_dates($idkey);
	}

	private function cmp_def_time($a,$b)
	{
		return($b["def_time"] - $a["def_time"]);
	}

	protected function _do_dates($idkey)
	{
		$this->local_cf_ary = $this->get_confessor_by_idkey($idkey);

		if(!empty($this->local_cf_ary["cf_dbd"]))
		{
			$this->_get_confessor_dates();
			$dte_index = "ph_date";
			$len_index = "ph_shlen";
		}
		else
		{
			$this->_get_archive_dates($idkey);
			$dte_index = "def_time";
			$len_index = "lsecs";
		}
		foreach($this->dte_ary as $val)
		{
			$dtary = getdate($val[$dte_index]);
			$endte = mktime($dtary["hours"],$dtary["minutes"],$dtary["seconds"] + $val[$len_index],$dtary["mon"],$dtary["mday"],$dtary["year"]);
			$this->sh_ary[$this->local_cf_ary["cf_plistid"]][$this->idkey]["dates"][] = Array("stdte" => $val[$dte_index],"endte" => $endte,"len" => $val[$len_index]);
		}
	}

	protected function _get_confessor_shows_sql($cf_db)
	{
		$sql = "select * from " . $cf_db->confessor_tables("sh_table,ca_table");
		$sql .= " where ca_id=sh_caid";
		$sql .= " and sh_altid='" . $this->idkey . "'";
		return($sql);
	}

	protected function _get_archive_shows_sql($db,$cfrow)
	{
		$sql = "select * from " . $db->archive_tables("sn_table");
		$sql .= " where sn_plistid='" . $cfrow['cf_plistid'] . "'";
		$sql .= " and sn_idkey='" . $this->idkey . "'";
		return($sql);
	}

	protected function _get_confessor_dates()
	{
		$this->confessor_db = new AllDb($this->archive_dbd_sav,$this->local_cf_ary["cf_dbd"]);
		$sql = "select ph_date,ph_shlen from " . $this->confessor_db->confessor_tables("ph_table");
		$sql .= " where ph_shaltid='" . $this->idkey . "'";
		$sql .= " and ph_date >= " . $this->start_dte;
		$sql .= " and ph_date <= " . $this->end_dte;
		$sql .= " order by ph_date desc";
//$this->my_db->write_log("sql=$sql\n");
		$this->dte_ary = $this->confessor_db->confessor_data($sql,$num,true);
//$this->my_db->write_log("dte_ary=" . print_r($this->dte_ary,true) . "\n");
	}

	public function get_show()
	{
		return($this->get_show_by_idkey($this->idkey));
	}
}

// use when you already have done Shows so you don't have to access the
// database for that info
//
// gets the show identified by idkey
// if from_weeks (weeks before now) and to_weeks (weeks after now)
// are included, adds 'dates' array to show with :
// 	if confessor show: ph_dates within date range from existing headers
// 	if archive show: def_times within date range from existing filnam records
// used for public_file stuff
// all public_file records are in signal confessor
class OneShowSpecial extends OneShow
{
	protected $idkey = '';
	protected $dte_ary = Array();
	protected $local_cf_ary = Array();
	

	public function __construct($db,$sh_ary,$cf_ary,$idkey,$from_weeks = 0,$to_weeks = 1,$dte = 0)
	{
		$this->start_date = $dte;
		$this->my_db = $db;
		$this->idkey = $idkey;
//		if($from_weeks && $to_weeks)
			$this->_set_dates($from_weeks,$to_weeks);
		$this->archive_dbd_sav = $db->get_archive_dbd();
		$this->confessor_dbd_sav = $db->get_confessor_dbd();

		$this->sh_ary = $sh_ary;
		$this->cf_ary = $cf_ary;

		if($to_weeks)
			$this->_do_dates($idkey);
		/*
		{
			$this->local_cf_ary = $this->get_confessor_by_idkey($idkey);

			if(!empty($this->local_cf_ary["cf_dbd"]))
			{
				$this->_get_confessor_dates();
				$dte_index = "ph_date";
				$len_index = "ph_shlen";
			}
			else
			{
				$this->_get_archive_dates($idkey);
				$dte_index = "def_time";
				$len_index = "lsecs";
			}
			foreach($this->dte_ary as $val)
			{
				$dtary = getdate($val[$dte_index]);
				$endte = mktime($dtary["hours"],$dtary["minutes"],$dtary["seconds"] + $val[$len_index],$dtary["mon"],$dtary["mday"],$dtary["year"]);
				$this->sh_ary[$this->local_cf_ary["cf_plistid"]][$this->idkey]["dates"][] = Array("stdte" => $val[$dte_index],"endte" => $endte,"len" => $val[$len_index]);
			}
		}
		*/
	}
}

// gets all shows who currently have a living archive mp3
class CurrentShows extends Shows
{
	protected $fn_ary = Array();
	protected $fn_in_str = '';


	protected function _get_confessor_shows_sql($cf_db)
	{
		$sql = "select * from " . $cf_db->confessor_tables("sh_table,ca_table");
		$sql .= " where ca_id=sh_caid";
		$sql .= " and sh_altid in " . $this->fn_in_str;
		if(!$this->user_info)
		{
			if(!empty($this->user_access))
			{
				if(!empty($this->user_altid_str))
					$sql .= " and sh_altid in (" . $this->user_altid_str . ")";
				else
					return("");
			}
			else if(!empty($this->no_user_access))
				$sql .= " and sh_altid not in (" . $this->user_altid_str . ")";
		}
		$sql .= " order by sh_altid";
//$this->my_db->write_log("sql=$sql\n");
		return($sql);
	}

	protected function _get_archive_shows_sql($db,$cfrow)
	{
		$sql = "select * from " . $db->archive_tables("sn_table");
		$sql .= " where sn_plistid='" . $cfrow['cf_plistid'] . "'";
		$sql .= " and sn_idkey in " . $this->fn_in_str;
		if(!$this->user_info)
		{
			if(!empty($this->user_access))
			{
				if(!empty($this->user_altid_str))
					$sql .= " and sn_idkey in (" . $this->user_altid_str . ")";
				else
					return("");
			}
			else if(!empty($this->no_user_access))
			{
				if(!empty($this->user_altid_str))
					$sql .= " and sn_idkey not in (" . $this->user_altid_str . ")";
			}
		}
		$sql .= " order by sn_idkey";
		return($sql);
	}

	public function __construct($db,$include_expired = 0)
	{
//$db->write_log("include_expired=$include_expired\n");
		$this->my_db = $db;
		$this->archive_dbd_sav = $db->get_archive_dbd();
		$this->confessor_dbd_sav = $db->get_confessor_dbd();

		$this->_get_confessors($db);
		$this->get_fns($db,$include_expired);

		foreach($this->cf_ary as $val)
		{
			if(!empty($val["cf_dbd"]))
			{
				$this->confessor_db = new AllDb($this->archive_dbd_sav,$val["cf_dbd"]);
				if($val["cf_info"] & cf_signal)
					$this->_get_categories($this->confessor_db);		// only categories from signal confessor used
				$sql = "select * from " . $this->confessor_db->confessor_tables("gl_table");
				$gl_ary = $this->confessor_db->confessor_data($sql,$num);
				$val["gl_pixurl"] = $gl_ary["gl_pixurl"];
				$val["gl_pixdir"] = $gl_ary["gl_pixdir"];
				$val["gl_stapix"] = $gl_ary["gl_stapix"];
				$this->_get_confessor_shows($this->confessor_db,$val);
			}
			else
			{
				$this->_get_archive_shows($db,$val);
			}
		}
	}
}

// gets all shows with a living podcast - i.e. unexpired filnam exists
// don't think user access is necessary
class Podcasts extends CurrentShows
{
	protected $fn_ary = Array();
	protected $fn_in_str = '';

	protected function get_fns($db,$include_expired = 0)
	{
		$now = time();

		if(empty($this->shaltid))
		{
	// snid refers to confessor show or shoname when not a confessor show
			$sql = "select distinct idkey from " . $db->archive_tables("fn_table");
			$sql .= " where info & (" . (filn_pod) . ")";
			$sql .= " and expires > $now";
			$sql .= " and not (info & " . (filn_deleted|filn_no_file_yet) . ")";
			$sql .= " and ((utime < $now) || (info & " . (filn_shonow) . "))";
			$ary = $db->archive_data($sql,$num,true);
			foreach($ary as $val)
			{
				$this->fn_ary[] = '"' . $val['idkey'] . '"';
			}
		}
		else
		{
			$this->fn_ary[] = '"' . $this->shaltid . '"';
		}
		$this->set_fn_in_str();
	}
}
?>
