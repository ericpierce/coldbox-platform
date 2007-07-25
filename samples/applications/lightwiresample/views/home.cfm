<!--------------------------------------------------------------------
Generated Application: lightwiresample
Generated Date: July 24 2007
Generated By: ColdBox Ant Task.
---------------------------------------------------------------------->
<cfoutput>
<cfset rc = event.getCollection()>
	
<cfoutput>
<div align="center" class="mainDiv">

	<div style="font-size:25px;font-weight:bold" align="left">
	Lightwire Simple Example
	</div>

	<div align="left" style="margin-top:10px;border:1px solid black;background:##fffff0;padding:10px">
	 This sample illustrates how to connect LightWire IOC into your application. LightWire is distributed as an extra of the 
	 ColdBox framework, so you can have IOC capabilities right out of the box.
	</div>

	<div style="margin-top:10px;" align="left">
		<h3>Product Service:</h3>
		<cfdump var="#rc.ProductService#" expand="false"><br />
		
		<ul>
			<li>Contains product DAO which was constructor injected</li>
			<cfdump var="#rc.ProductService.getProductDAO()#" expand="false">
			
			<br />
			
			<li>Contains category service which was mixin or setter injected</li>
			<cfdump var="#rc.ProductService.getCategoryService()#" expand="false">
			
			<br />
			
		  <li>And the following mixed in properties:
		    <ul>
		      <li><strong>MyMixinTitle</strong> = #rc.ProductService.getMyMixinTitle()#</li>
	          <li><strong>AnotherMixinProperty</strong> = #rc.ProductService.getAnotherMixinProperty()#</li>
		    </ul>
			</li>
			</ul>
		
		<hr />
		
		<h3>Category Service</h3>
		<cfdump var="#rc.CategoryService#" expand="false"><br />
		
		
		<ul>
			<li>contains category DAO which was constructor injected</li>
			<cfdump var="#rc.CategoryService.getCategoryDAO()#" expand="false"><br />
			
			<li><strong>categoryDAO dsn injected via coldbox properties</strong> : #rc.CategoryService.getCategoryDAO().getDSN()#</li>
			<br />
			
			<li>and product service which was mixin or setter injected</li>
			<cfdump var="#rc.CategoryService.getProductService()#" expand="false">
		</ul>
		
		
		<hr />
		
		<h3>Product Bean (Transient)</h3/>
		<cfdump var="#rc.Product#" expand="false"><br />
		
		<ul>
			<li>contains a Product DAO that was constructor injected</li>
		</ul>
		<cfdump var="#rc.Product.getProductDAO()#" expand="false">
	</div>

</div>
</cfoutput>


</cfoutput>