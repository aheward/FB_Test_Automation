#!/usr/bin/env ruby
# coding: UTF-8

require '../config/fido_env'

site = @accounts_index.open_site @fido.test_data['site_2']
campaign = site.open_campaign "dynamic"
test("Pixel Implementation Instructions")

campaign.uat_pixels

if @browser.div(:id, "uatNonsecure").visible?
  puts "UAT Link passed"
else
  puts ""
  puts "=============="
  puts "UAT Link Broken!"
  puts "=============="
  puts ""
end

creative_home = campaign.open_creative @fido.test_data['test_creative']

test("Creative Overview: #{@fido.test_data['test_creative']}")

nav("Creative Keywords")
test("To delete all entries, submit an empty input box.")

nav("Creative Home")
test("Creative Assets")
creative = Creative.new @browser
#More time to test file uploads
sleep(5) # TODO: Add file upload code.

flashclickTag = <<goof
<script type='text/javascript' language='javascript' src='$protocol://$swfObjectHost$swfObjectPath'></script>
<script type='text/javascript' language='javascript'>
var flashvars = {
'clickTag':'$esc.url("http://$clickHost$clickPath?xrx=$timestamp&crid=$this.creativeId&bcrid=$this.baseCreativeId&tid=$request.adTagId&said=$siteAction.id&clicktrack=$request.clicktrack")'
};
var params = {
'allowScriptAccess':'always',
'wmode':'transparent',
'quality':'high'
};
fetchback.fn.swfobject.embedSWF('$protocol://$imageDefault', 'FetchBack_flash', '$width','$height', '9.0.0', false, flashvars, params);
</script>
<div id='FetchBack_flash'>  <table width="${creativeType.width}" height="${creativeType.height}" border="1" cellspacing="0" cellpadding="0" bordercolor="#666666" bgcolor="#dfdfdf"><tr><td align="center"><a href="http://get.adobe.com/flashplayer/" target="_blank">Can not display content.<br>Please download Flash Player.</td></tr></table>
</div>
<!-- $this.campaignId -->
goof

creative.showhide_template
creative.template_third_party="3rd Party Tag"
creative.third_party_tag="flash:clickTag"
creative = creative.update
creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == flashclickTag.chomp
  puts ">>> flash:clickTag test passed."
else
  puts ""
  puts "=============="
  puts "flash:clickTag Test failed!"
  puts "=============="
  puts ""
  puts creative.third_party_tag
  puts
  p flashclickTag
  p creative.third_party_tag
end

flash_clickTAG = <<goof
<script type='text/javascript' language='javascript' src='$protocol://$swfObjectHost$swfObjectPath'></script>
<script type='text/javascript' language='javascript'>
var flashvars = {
'clickTAG':'$esc.url("http://$clickHost$clickPath?xrx=$timestamp&crid=$this.creativeId&bcrid=$this.baseCreativeId&tid=$request.adTagId&said=$siteAction.id&clicktrack=$request.clicktrack")'
};
var params = {
'allowScriptAccess':'always',
'wmode':'transparent',
'quality':'high'
};
fetchback.fn.swfobject.embedSWF('$protocol://$imageDefault', 'FetchBack_flash', '$width','$height', '9.0.0', false, flashvars, params);
</script>
<div id='FetchBack_flash'>  <table width="${creativeType.width}" height="${creativeType.height}" border="1" cellspacing="0" cellpadding="0" bordercolor="#666666" bgcolor="#dfdfdf"><tr><td align="center"><a href="http://get.adobe.com/flashplayer/" target="_blank">Can not display content.<br>Please download Flash Player.</td></tr></table>
</div>
<!-- $this.campaignId -->
goof

creative.third_party_tag="flash:clickTAG"
creative = creative.update

if creative.template_fields_element.visible?
  puts ""
  puts "=============="
  puts "Template not hiding on update!"
  puts "=============="
  puts ""
end

creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == flash_clickTAG.chomp
  puts ">>> flash:clickTAG test passed."
else
  puts ""
  puts "=============="
  puts "flash:clickTAG Test failed!"
  puts "=============="
  puts ""

end

flashproduct = <<goof
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		<title>FetchBack | ${creativeType.width}x${creativeType.height}</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
		<style>
			body { background: #d3d3d3; }
		</style>
		<script type="text/javascript" src="http://$swfObjectHost$swfObjectPath"></script>
		<script type="text/javascript">
			var flashvars = {};
			flashvars.globalClick = "$esc.url("http://$clickHost$clickPath?xrx=$timestamp&crid=$creative.creativeId&bcrid=$creative.baseCreativeId&tid=$request.adTagId&said=$siteAction.id&clicktrack=$request.clicktrack")";
			flashvars.policy = "http://$crossDomainPolicy";
			flashvars.controlInteraction = escape("http://$engageHost$engagePath?crid=$creative.creativeId&tid=$request.adTagId&et=inter");
			flashvars.logo = "${logo}_${creativeType.width}x${creativeType.height}.jpg";
			flashvars.foreground = "${fg}_${creativeType.width}x${creativeType.height}.jpg";
			flashvars.background = "${bg}_${creativeType.width}x${creativeType.height}.jpg";
			flashvars.salesText = "$msg";
#foreach( $product in $recoSiteProducts )
#set ($count = $velocityCount - 1)
flashvars.product$count = "$esc.url($unesc.html($product.name)) | $esc.url($unesc.html($product.description)) | $number.currency($product.price) | $esc.url($product.imageProxyUrl) | $esc.url("http://$clickHost$clickPath?xrx=$timestamp&crid=$creative.creativeId&bcrid=$creative.baseCreativeId&tid=$request.adTagId&said=$siteAction.id&spid=$product.siteProductId&clicktrack=$request.clicktrack")";
#end
	 		var params = {};
			params.base = "http://$imageHost$assetPath/$creative.campaignId/$creative.baseCreativeId/";
			params.wmode = "transparent";
			params.allowscriptaccess = "always";
			var attributes = {};
			attributes.id = "banner";
			fetchback.fn.swfobject.embedSWF("http://$imageHost$assetPath/$creative.campaignId/$creative.baseCreativeId/${prefix}_${creativeType.width}x${creativeType.height}.swf", "myAlternativeContent", "${creativeType.width}", "${creativeType.height}", "9.0.0", false, flashvars, params, attributes);
		</script>

	</head>
	<body>
          <div id="myAlternativeContent">
              <table width="${creativeType.width}" height="${creativeType.height}" border="1" cellspacing="0" cellpadding="0" bordercolor="#666666" bgcolor="#dfdfdf"><tr><td align="center"><a href="http://get.adobe.com/flashplayer/" target="_blank">Can not display content.<br>Please download Flash Player.</td></tr></table>
          </div>
	</body>
</html>
goof

creative.third_party_tag="flash:product"
creative = creative.update
creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == flashproduct.chomp
  puts ">>> flash:product test passed."
else
  puts ""
  puts "=============="
  puts "flash:product Test failed if you're testing on qa-fido"
  puts "=============="
  puts creative.third_party_tag
  puts ""

end

default = <<goof
<style type="text/css">body {margin: 0; padding: 0;}</style><a href="http://$clickHost$clickPath?xrx=$timestamp&crid=$this.creativeId&bcrid=$this.baseCreativeId&tid=$request.adTagId&said=$siteAction.id&clicktrack=$request.clicktrack" target="_blank"><img border="0" src="$protocol://$imageDefault" alt="Click Here!"></a><!-- $this.campaignId -->
goof

creative.third_party_tag="static:default"
creative = creative.update
creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == default.chomp
  puts ">>> static:default test passed."
else
  puts ""
  puts "=============="
  puts "static:default Test failed!"
  puts "=============="
  puts ""

end

@browser.close