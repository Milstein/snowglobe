package io.bamos.snowglobe

import scala.collection.immutable.ListMap

object Helper {
  val headers = Seq("app_id", "platform", "collector_tstamp", "dvce_tstamp", "event", "event_vendor", "event_id", "txn_id", "v_tracker", "v_collector", "v_etl", "user_id", "user_ipaddress", "user_fingerprint", "domain_userid", "domain_sessionidx", "network_userid", "geo_country", "geo_region", "geo_city", "geo_zipcode", "geo_latitude", "geo_longitude", "page_title", "page_urlscheme", "page_urlhost", "page_urlport", "page_urlpath", "page_urlquery", "page_urlfragment", "refr_urlscheme", "refr_urlhost", "refr_urlport", "refr_urlpath", "refr_urlquery", "refr_urlfragment", "refr_medium", "refr_source", "refr_term", "mkt_medium", "mkt_source", "mkt_term", "mkt_content", "mkt_campaign", "contexts", "se_category", "se_action", "se_label", "se_property", "tr_orderid", "tr_affiliation", "tr_total", "tr_tax", "tr_shipping", "tr_city", "tr_state", "tr_country", "ti_orderid", "ti_sku", "ti_name", "ti_category", "ti_price", "ti_quantity", "pp_xoffset_min", "pp_xoffset_max", "pp_yoffset_min", "pp_yoffset_max", "useragent", "br_name", "br_family", "br_version", "br_type", "br_renderengine", "br_lang", "br_features_pdf", "br_features_flash", "br_features_java", "br_features_director", "br_features_quicktime", "br_features_realplayer", "br_features_windowsmedia", "br_features_gears", "br_features_silverlight", "br_cookies", "br_colordepth", "br_viewwidth", "br_viewheight", "os_name", "os_family", "os_manufacturer", "os_timezone", "dvce_type", "dvce_ismobile", "dvce_screenwidth", "dvce_screenheight", "doc_charset", "doc_width", "doc_height")
  def tsvToCanonicalOutput(tsv: String): Option[ListMap[String,String]] = {
    val tsvFields = tsv.split("\t")
    if (tsvFields.size != headers.size) None
    else Option(ListMap(headers.zip(tsvFields): _*))
  }
}