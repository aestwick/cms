<?php
if(!defined("__DEFINES__DATE__"))
	define("__DEFINES__DATE__",230425);

if(!defined("SECS_IN_MIN"))
	define("SECS_IN_MIN",60);
if(!defined("SECS_IN_HOUR"))
	define("SECS_IN_HOUR",SECS_IN_MIN * 60);
if(!defined("SECS_IN_DAY"))
	define("SECS_IN_DAY",SECS_IN_HOUR * 24);
if(!defined("SECS_IN_WEEK"))
	define("SECS_IN_WEEK",SECS_IN_DAY * 7);

if(!defined("MAX_INT"))
	define("MAX_INT",2147483647);

if(!defined("MAX_SMALLINT"))
	define("MAX_SMALLINT",32767);

// session info
if(!defined("se_onair"))
	define("se_onair",0x01);
if(!defined("se_timeout"))
	define("se_timeout",0x02);

// report to public digital (npr)
if(!defined("nf_hideips"))
	define("nf_hideips",0x01);
if(!defined("nf_pros"))
	define("nf_pros",0x02);
if(!defined("nf_doalways"))
	define("nf_doalways",0x04);

// pubfile
if(!defined("pf_updated"))		// this is not set until file is uploaded
	define("pf_updated",0x01);
if(!defined("pf_added"))		// for added show
	define("pf_added",0x02);
if(!defined("pf_subhost"))
	define("pf_subhost",0x04);
if(!defined("pf_not_reported"))
	define("pf_not_reported",0x08);
if(!defined("pf_deleted"))
	define("pf_deleted",0x10000);

// pubfile issues
if(!defined("pi_not_reported"))
	define("pi_not_reported",0x01);

// header info
if(!defined("ph_realtime"))
	define("ph_realtime",0x01);
if(!defined("ph_offline"))
	define("ph_offline",0x02);
if(!defined("ph_onair"))
	define("ph_onair",0x04);
if(!defined("ph_listonly"))
	define("ph_listonly",0x08);
if(!defined("ph_rawonly"))
	define("ph_rawonly",0x10);
if(!defined("ph_modified"))
	define("ph_modified",0x20);
if(!defined("ph_template"))
	define("ph_template",0x80);
if(!defined("ph_spillover"))
	define("ph_spillover",0x100);		// means show starts in previous week - write_header ignores
if(!defined("ph_startstop"))
	define("ph_startstop",0x200);
if(!defined("ph_noauto"))
	define("ph_noauto",0x400);
if(!defined("ph_rawauto_only"))
	define("ph_rawauto_only",0x800);
if(!defined("ph_type_mask"))
	define("ph_type_mask",ph_realtime|ph_offline|ph_onair|ph_listonly|ph_rawonly|ph_rawauto_only);

// playlist info
if(!defined("pl_talk"))
	define("pl_talk",0x01);
if(!defined("pl_copyright"))
	define("pl_copyright",0x02);		// basic music - shows up in playlist - sent to sound exchange
if(!defined("pl_auto"))
	define("pl_auto",0x04);
if(!defined("pl_psa"))
	define("pl_psa",0x08);
if(!defined("pl_sponsored"))
	define("pl_sponsored",0x10);
if(!defined("pl_syndicated"))
	define("pl_syndicated",0x20);
if(!defined("pl_misc"))
	define("pl_misc",0x40);
if(!defined("pl_onair"))
	define("pl_onair",0x80);
if(!defined("pl_playlist"))
	define("pl_playlist",0x100);				// show in playlist
if(!defined("pl_new"))
	define("pl_new",0x200);
// leaving space for 3 addl items
if(!defined("pl_reports"))
	define("pl_reports",0x800);			// send to sound exchange
if(!defined("pl_edited"))
	define("pl_edited",0x10000);

if(!defined("pl_not_music_mask"))
	define("pl_not_music_mask",pl_psa|pl_sponsored|pl_syndicated);

// group info - must match pl_info thru 0x1000
if(!defined("gp_talk"))
	define("gp_talk",0x01);				
if(!defined("gp_copyright"))
	define("gp_copyright",0x02);		// basic music
if(!defined("gp_auto"))
	define("gp_auto",0x04);				// info only
if(!defined("gp_psa"))
	define("gp_psa",0x08);
if(!defined("gp_sponsored"))
	define("gp_sponsored",0x10);
if(!defined("gp_syndicated"))				
	define("gp_syndicated",0x20);
if(!defined("gp_misc"))
	define("gp_misc",0x40);
// pl_onair is at 0x80
if(!defined("gp_playlist"))
	define("gp_playlist",0x100);		// appears in playlist
// pl_new is at 0x200
if(!defined("gp_promo"))
	define("gp_promo",0x400);
// leaving space
if(!defined("gp_reports"))
	define("gp_reports",0x800);

// leaving space for additions
if(!defined("gp_show_onair"))
	define("gp_show_onair",0x1000);		// shows in onair dropdown
if(!defined("gp_fill_field"))
	define("gp_fill_field",0x2000);		// fills artist field
if(!defined("gp_default_music"))
	define("gp_default_music",0x4000);
if(!defined("gp_default_talk"))
	define("gp_default_talk",0x8000);

if(!defined("gp_type_mask"))			// also matches pl
	define("gp_type_mask",gp_talk|gp_copyright|gp_auto|gp_psa|gp_sponsored|gp_syndicated|gp_misc|gp_playlist|gp_reports|gp_promo);

if(!defined("gp_control_mask"))
	define("gp_control_mask",gp_auto|gp_show_onair|gp_fill_field);

// category info
if(!defined("ca_talk"))
	define("ca_talk",0x01);

// global info
if(!defined("gl_favory"))
	define("gl_favory",0x01);
if(!defined("gl_shoutcast"))
	define("gl_shoutcast",0x02);
if(!defined("gl_sho_nxt_pix"))
	define("gl_sho_nxt_pix",0x04);
if(!defined("gl_sho_djname"))
	define("gl_sho_djname",0x08);
if(!defined("gl_sendmsg"))
	define("gl_sendmsg",0x10);
if(!defined("gl_iconfavory"))
	define("gl_iconfavory",0x20);
if(!defined("gl_itunes_favory"))
	define("gl_itunes_favory",0x40);
if(!defined("gl_med_fovory"))
	define("gl_med_favory",0x80);
if(!defined("gl_use_automation"))
	define("gl_use_automation",0x100);
if(!defined("gl_use_playlist"))
	define("gl_use_playlist",0x200);
if(!defined("gl_use_locks"))
	define("gl_use_locks",0x400);
if(!defined("gl_use_acr"))
	define("gl_use_acr",0x800);
if(!defined("gl_favor_acr"))
	define("gl_favor_acr",0x1000);
if(!defined("gl_use_rds"))
	define("gl_use_rds",0x2000);
if(!defined("gl_reports_to_sx"))
	define("gl_reports_to_sx",0x4000);
if(!defined("gl_report_playlist"))
	define("gl_report_playlist",0x8000);
if(!defined("gl_update_icecast"))
	define("gl_update_icecast",0x10000);
if(!defined("gl_24hr_clock"))
	define("gl_24hr_clock",0x20000);
if(!defined("gl_ampm"))
	define("gl_ampm",0x40000);
if(!defined("gl_allow_open"))
	define("gl_allow_open",0x80000);
if(!defined("gl_do_not_disable"))
	define("gl_do_not_disable",0x100000);

// iceparms
if(!defined("ip_jsondecode"))
	define("ip_jsondecode",0x01);

// mobtxt info
if(!defined("mb_addaddr"))
	define("mb_addaddr",0x01);

// user info
if(!defined("u_updater"))
	define("u_updater",0x01);
if(!defined("u_root"))				// can access all records for own station
	define("u_root",0x02);
if(!defined("u_rootroot"))			// can create root
	define("u_rootroot",0x04);
if(!defined("u_superroot"))			// can create rootroot - access to all records
	define("u_superroot",0x08);
if(!defined("u_errmail"))
	define("u_errmail",0x10);
if(!defined("u_first_login"))
	define("u_first_login",0x200);
if(!defined("u_closed"))
	define("u_closed",0x80000000);

if(!defined("root_mask"))
	define("root_mask",u_root|u_rootroot|u_superroot);

// week info
if(!defined("wk_template"))
	define("wk_template",0x01);
if(!defined("wk_modified"))
	define("wk_modified",0x02);
if(!defined("wk_dst_change"))
	define("wk_dst_change",0x04);

if(!defined("wk_template_date"))
	define("wk_template_date","1/01/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_02"))
	define("wk_template_date_02","1/08/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_03"))
	define("wk_template_date_03","1/15/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_04"))
	define("wk_template_date_04","1/22/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_05"))
	define("wk_template_date_05","1/29/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_06"))
	define("wk_template_date_06","2/05/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_07"))
	define("wk_template_date_07","2/12/2006");		// year that begins with a sunday - before confessor ever started
if(!defined("wk_template_date_08"))
	define("wk_template_date_08","2/19/2006");		// year that begins with a sunday - before confessor ever started

$__wk_template_date_ary = Array(
	wk_template_date,
	wk_template_date_02,
	wk_template_date_03,
	wk_template_date_04,
	wk_template_date_05,
	wk_template_date_06,
	wk_template_date_07,
	wk_template_date_08,
	);

// archive confessor info
if(!defined("cf_noncf"))
	define("cf_noncf",0x01);
if(!defined("cf_upload"))
	define("cf_upload",0x02);
if(!defined("cf_signal"))
	define("cf_signal",0x04);
if(!defined("cf_shoutcast"))
	define("cf_shoutcast",0x08);
if(!defined("cf_scheduled"))
	define("cf_scheduled",0x10);

// show info

include "sh_infos.php";

?>
